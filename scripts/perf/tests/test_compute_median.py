import json
import tempfile
import unittest
from pathlib import Path

from scripts.perf.compute_median import compute_median


class ComputeMedianTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)
        self.logs = []
        for index, fps in enumerate((58.0, 60.0, 62.0), start=1):
            path = self.directory / f"run-{index}.log"
            path.write_text(
                "PERF_METRIC | web_navigation | room_opened"
                f" | fps={fps} | transition_ms={100 + index}\n",
                encoding="utf-8",
            )
            self.logs.append(str(path))

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def test_default_output_keeps_existing_contract(self) -> None:
        output = self.directory / "median.json"
        compute_median(self.logs, str(output))

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["fps"], 60.0)
        self.assertNotIn("fps_values", checkpoint)

    def test_optional_raw_values_are_kept_with_aggregates(self) -> None:
        output = self.directory / "median.json"
        compute_median(self.logs, str(output), include_values=True)

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["sample_count"], 3)
        self.assertEqual(checkpoint["fps"], 60.0)
        self.assertEqual(checkpoint["fps_values"], [58.0, 60.0, 62.0])
        self.assertEqual(checkpoint["fps_range"], 4.0)
        self.assertEqual(checkpoint["fps_stddev"], 2.0)

    def test_optional_metric_does_not_reduce_checkpoint_sample_count(self) -> None:
        Path(self.logs[1]).write_text(
            "PERF_METRIC | web_navigation | room_opened"
            " | transition_ms=102\n",
            encoding="utf-8",
        )
        output = self.directory / "median.json"

        compute_median(self.logs, str(output), include_values=True)

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["sample_count"], 3)
        self.assertEqual(checkpoint["fps"], 60.0)
        self.assertEqual(checkpoint["fps_sample_count"], 2)
        self.assertEqual(checkpoint["fps_values"], [58.0, 62.0])
        self.assertEqual(checkpoint["transition_ms_sample_count"], 3)
        self.assertEqual(checkpoint["transition_ms_values"], [101.0, 102.0, 103.0])

    def test_missing_checkpoint_reduces_sample_count(self) -> None:
        Path(self.logs[1]).write_text("", encoding="utf-8")
        output = self.directory / "median.json"

        compute_median(self.logs, str(output))

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["sample_count"], 2)


if __name__ == "__main__":
    unittest.main()
