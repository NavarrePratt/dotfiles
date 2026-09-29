import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from subprocess import CompletedProcess

spec = importlib.util.spec_from_file_location("sidebar", Path(__file__).resolve().parents[2] / "dot_config/herdr/sidebar/sidebar.py")
sidebar = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sidebar)


class SidebarTests(unittest.TestCase):
    def test_cost_discounts_cache_and_does_not_add_reasoning_twice(self):
        usage = {"input_tokens": 1_000_000, "cached_input_tokens": 800_000,
                 "cache_write_input_tokens": 100_000, "output_tokens": 100_000,
                 "reasoning_output_tokens": 90_000}
        self.assertAlmostEqual(sidebar.estimate(usage, "gpt-6-astra"), 8.05)
        self.assertIsNone(sidebar.estimate(usage, "unknown"))

    def test_price_follows_model_changes_without_repricing_previous_usage(self):
        def record(kind, payload):
            return json.dumps({"type": kind, "payload": payload}) + "\n"
        def count(n):
            return record("event_msg", {"type": "token_count", "info": {
                "total_token_usage": {"input_tokens": n, "total_tokens": n}}})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "rollout.jsonl"
            path.write_text(record("turn_context", {"model": "gpt-6-astra"}) + count(1_000_000) +
                            record("turn_context", {"model": "gpt-5.6-sol"}) + count(2_000_000))
            usage = sidebar.Usage()
            usage.files = {("codex", "test"): path}
            usage.scanned = sidebar.time.monotonic()
            self.assertEqual(usage.summary("codex", "test"), "~$14.00 · 2.0M tok")
            self.assertEqual(usage.summary("codex", "test"), "~$14.00 · 2.0M tok")

    def test_silent_successful_metadata_response(self):
        with patch.object(sidebar, "run", return_value=CompletedProcess([], 0, "", "")):
            self.assertEqual(sidebar.api("pane", "report-metadata"), {})

    def test_cumulative_tokens_are_not_added_and_partial_records_are_retried(self):
        def event(total):
            return json.dumps({"type": "event_msg", "payload": {"type": "token_count", "info": {"total_token_usage": {"total_tokens": total}}}}).encode()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "rollout.jsonl"
            path.write_bytes(event(1000) + b"\n" + event(2500))
            usage = sidebar.Usage()
            usage.files = {("codex", "test"): path}
            usage.scanned = sidebar.time.monotonic()
            self.assertEqual(usage.summary("codex", "test"), "tok 1.0k")
            with path.open("ab") as stream:
                stream.write(b"\n")
            self.assertEqual(usage.summary("codex", "test"), "tok 2.5k")
            self.assertEqual(usage.summary("codex", "test"), "tok 2.5k")
            path.write_bytes(event(5) + b"\n")
            self.assertEqual(usage.summary("codex", "test"), "tok 5")
            self.assertEqual(usage.summary("codex", None), "tok ?")

    def test_claude_usage_counts_each_message_once_with_cache_and_fast_rates(self):
        def assistant(message_id, model, **usage):
            return json.dumps({"type": "assistant", "message": {"id": message_id, "model": model, "usage": usage}}) + "\n"
        cached = assistant("a", "claude-opus-5-5", input_tokens=1_000_000, cache_read_input_tokens=1_000_000,
                           cache_creation_input_tokens=1_000_000, output_tokens=100_000,
                           cache_creation={"ephemeral_1h_input_tokens": 500_000, "ephemeral_5m_input_tokens": 500_000})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "session.jsonl"
            path.write_text(cached + cached + assistant("b", "claude-opus-5-5", output_tokens=100_000, speed="fast") +
                            assistant("c", "<synthetic>", input_tokens=0, output_tokens=0))
            usage = sidebar.Usage()
            usage.files = {("claude", "test"): path}
            usage.scanned = sidebar.time.monotonic()
            self.assertEqual(usage.summary("claude", "test"), "~$16.70 · 3.2M tok")



if __name__ == "__main__":
    unittest.main()
