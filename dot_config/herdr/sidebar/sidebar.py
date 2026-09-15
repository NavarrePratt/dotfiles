#!/usr/bin/env python3
"""Publish local session usage to Herdr sidebar tokens."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

HERDR = os.environ.get("HERDR_BIN_PATH", "herdr")
SOURCE = "npratt:sidebar"
INTERVAL = 15
TTL = 60000


def run(*args, cwd=None):
    return subprocess.run(args, cwd=cwd, text=True, capture_output=True, timeout=20)


def api(*args):
    result = run(HERDR, *args)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    if not result.stdout.strip():
        return {}
    data = json.loads(result.stdout)
    if "error" in data:
        raise RuntimeError(str(data["error"]))
    return data.get("result", {})


def compact(value):
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1000:
        return f"{value / 1000:.1f}k"
    return str(value)


PRICES = json.loads((Path(__file__).with_name("pricing.json")).read_text())["models"]


def estimate(usage, model):
    rates = PRICES.get(model)
    if rates is None:
        return None
    cached = usage.get("cached_input_tokens", 0)
    writes = usage.get("cache_write_input_tokens", 0)
    fresh = max(0, usage.get("input_tokens", 0) - cached - writes)
    # Output already includes reasoning; adding reasoning again would double count it.
    return (fresh * rates["input"] + cached * rates["cached"] +
            writes * rates["write"] + usage.get("output_tokens", 0) * rates["output"]) / 1_000_000


class Usage:
    def __init__(self):
        self.files = {}
        self.readers = {}
        self.scanned = 0

    def summary(self, session):
        if not session:
            return "tok ?"
        if time.monotonic() - self.scanned > 60:
            base = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
            self.files = {p.stem[-36:]: p for p in (base / "sessions").glob("*/*/*/*.jsonl")}
            self.scanned = time.monotonic()
        path = self.files.get(session)
        if path is None:
            return "tok ?"
        stat = path.stat()
        inode, offset, total, previous, model, cost, priced = self.readers.get(
            session, (stat.st_ino, 0, None, {}, None, 0.0, True))
        if inode != stat.st_ino or stat.st_size < offset:
            offset, total, previous, model, cost, priced = 0, None, {}, None, 0.0, True
        with path.open("rb") as stream:
            stream.seek(offset)
            while True:
                start = stream.tell()
                line = stream.readline()
                if not line or not line.endswith(b"\n"):
                    offset = start
                    break
                try:
                    record = json.loads(line)
                except (ValueError, UnicodeDecodeError):
                    continue
                payload = record.get("payload", {})
                if record.get("type") == "turn_context":
                    model = payload.get("model")
                if record.get("type") == "event_msg" and payload.get("type") == "token_count":
                    usage = (payload.get("info") or {}).get("total_token_usage") or {}
                    if isinstance(usage.get("total_tokens"), int):
                        if total is None or usage["total_tokens"] > total:
                            delta = {key: max(0, value - previous.get(key, 0))
                                     for key, value in usage.items() if isinstance(value, int)}
                            amount = estimate(delta, model)
                            priced = priced and amount is not None
                            cost += amount or 0
                            previous = usage
                        total = usage["total_tokens"]
        self.readers[session] = (stat.st_ino, offset, total, previous, model, cost, priced)
        if total is None:
            return "tok ?"
        return f"~${cost:.2f} · {compact(total)} tok" if priced else f"tok {compact(total)}"


def refresh(usage, preview=False):
    agents = api("agent", "list")["agents"]
    rows = []
    for agent in agents:
        if agent.get("agent") == "codex":
            session = (agent.get("agent_session") or {}).get("value")
            rows.append(("pane", agent["pane_id"], {"usage": usage.summary(session)}))
    for kind, target, tokens in rows:
        if preview:
            print(json.dumps({"target": target, **tokens}))
        else:
            args = [kind, "report-metadata", target, "--source", SOURCE, "--ttl-ms", str(TTL)]
            for key, value in tokens.items():
                args.extend(["--token", f"{key}={value}"])
            api(*args)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--start", action="store_true")
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("--preview", action="store_true")
    args = parser.parse_args()
    socket = os.environ.get("HERDR_SOCKET_PATH")
    if not socket:
        parser.error("Run inside Herdr or through its sidebar plugin")
    state = Path.home() / ".local/state/herdr-sidebar"
    if args.start or args.watch:
        state.mkdir(parents=True, exist_ok=True)
    key = hashlib.sha256(socket.encode()).hexdigest()[:16]
    if args.start:
        with (state / f"{key}.log").open("a") as log:
            subprocess.Popen([sys.executable, str(Path(__file__).resolve()), "--watch"],
                             stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True)
        return
    usage = Usage()
    if not args.watch:
        refresh(usage, args.preview)
        return
    with (state / f"{key}.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        while Path(socket).exists():
            try:
                refresh(usage)
            except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
                print(f"Sidebar refresh failed: {error}", flush=True)
            time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
