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
    long_writes = usage.get("cache_write_1h_input_tokens", 0)
    fresh = max(0, usage.get("input_tokens", 0) - cached - writes - long_writes)
    # Output already includes reasoning; adding reasoning again would double count it.
    return (fresh * rates["input"] + cached * rates["cached"] + writes * rates["write"] +
            long_writes * rates.get("write_1h", rates["write"]) +
            usage.get("output_tokens", 0) * rates["output"]) / 1_000_000


class CodexSession:
    def __init__(self):
        self.total, self.previous, self.model, self.cost, self.priced = None, {}, None, 0.0, True

    def read(self, record):
        payload = record.get("payload", {})
        if record.get("type") == "turn_context":
            self.model = payload.get("model")
        if record.get("type") == "event_msg" and payload.get("type") == "token_count":
            usage = (payload.get("info") or {}).get("total_token_usage") or {}
            if isinstance(usage.get("total_tokens"), int):
                if self.total is None or usage["total_tokens"] > self.total:
                    delta = {key: max(0, value - self.previous.get(key, 0))
                             for key, value in usage.items() if isinstance(value, int)}
                    amount = estimate(delta, self.model)
                    self.priced = self.priced and amount is not None
                    self.cost += amount or 0
                    self.previous = usage
                self.total = usage["total_tokens"]

    def usage(self):
        return self.total, self.cost, self.priced


class ClaudeSession:
    def __init__(self):
        self.messages = {}

    def read(self, record):
        message = record.get("message") or {}
        if record.get("type") == "assistant" and message.get("id") and isinstance(message.get("usage"), dict):
            # Claude writes one record per content block, each repeating the message usage.
            self.messages[message["id"]] = (message.get("model"), message["usage"])

    def usage(self):
        total, cost, priced = None, 0.0, True
        for model, usage in self.messages.values():
            reads = usage.get("cache_read_input_tokens") or 0
            writes = usage.get("cache_creation_input_tokens") or 0
            long_writes = (usage.get("cache_creation") or {}).get("ephemeral_1h_input_tokens") or 0
            tokens = {"input_tokens": (usage.get("input_tokens") or 0) + reads + writes,
                      "cached_input_tokens": reads,
                      "cache_write_input_tokens": max(0, writes - long_writes),
                      "cache_write_1h_input_tokens": long_writes,
                      "output_tokens": usage.get("output_tokens") or 0}
            count = tokens["input_tokens"] + tokens["output_tokens"]
            if not count:
                continue
            total = (total or 0) + count
            amount = estimate(tokens, model)
            if amount is not None and usage.get("speed") == "fast":
                amount = amount * PRICES[model]["fast"] if "fast" in PRICES[model] else None
            priced = priced and amount is not None
            cost += amount or 0
        return total, cost, priced


SESSIONS = {"codex": CodexSession, "claude": ClaudeSession}


class Usage:
    def __init__(self):
        self.files = {}
        self.readers = {}
        self.scanned = float("-inf")

    def summary(self, agent, session):
        if not session:
            return "tok ?"
        if time.monotonic() - self.scanned > 60:
            codex = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
            claude = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
            self.files = {("codex", p.stem[-36:]): p for p in (codex / "sessions").glob("*/*/*/*.jsonl")}
            # Subagent transcripts live below the session directory, so this matches parents only.
            self.files.update({("claude", p.stem): p for p in (claude / "projects").glob("*/*.jsonl")})
            self.scanned = time.monotonic()
        path = self.files.get((agent, session))
        if path is None:
            return "tok ?"
        stat = path.stat()
        inode, offset, parsed = self.readers.get(path, (stat.st_ino, 0, None))
        if parsed is None or inode != stat.st_ino or stat.st_size < offset:
            offset, parsed = 0, SESSIONS[agent]()
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
                parsed.read(record)
        self.readers[path] = (stat.st_ino, offset, parsed)
        total, cost, priced = parsed.usage()
        if total is None:
            return "tok ?"
        return f"~${cost:.2f} · {compact(total)} tok" if priced else f"tok {compact(total)}"


def refresh(usage, preview=False):
    agents = api("agent", "list")["agents"]
    rows = []
    for agent in agents:
        if agent.get("agent") in SESSIONS:
            session = (agent.get("agent_session") or {}).get("value")
            rows.append(("pane", agent["pane_id"], {"usage": usage.summary(agent["agent"], session)}))
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
