import io
import json
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path

from scripts.perf.compute_median import (
    _load_requirements,
    _parse_arguments,
    compute_median,
)


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

    def test_load_requirements_combines_common_and_checkpoint_metrics(self) -> None:
        manifest = self.directory / "requirements.json"
        manifest.write_text(
            json.dumps(
                {
                    "common_metrics": ["fps", "frame_count"],
                    "checkpoints": [
                        {
                            "scenario": "nav_cycles",
                            "label": "room_enter_cycle1",
                            "extra_metrics": ["transition_ms"],
                            "excluded_metrics": ["fps"],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )

        self.assertEqual(
            _load_requirements(str(manifest)),
            {
                ("nav_cycles", "room_enter_cycle1"): {
                    "frame_count",
                    "transition_ms",
                }
            },
        )

    def test_command_line_parser_accepts_options_between_paths(self) -> None:
        requirements = self.directory / "requirements.json"

        arguments = _parse_arguments(
            [
                self.logs[0],
                "--include-values",
                "--expected-samples",
                "3",
                "--requirements",
                str(requirements),
                self.logs[1],
                "median.json",
            ]
        )

        self.assertTrue(arguments.include_values)
        self.assertEqual(arguments.expected_samples, 3)
        self.assertEqual(arguments.requirements, requirements)
        self.assertEqual(arguments.logcat_files, self.logs[:2])
        self.assertEqual(arguments.output_file, "median.json")

    def test_command_line_parser_rejects_invalid_option_values(self) -> None:
        cases = (
            (["--expected-samples", "0", "run.log", "out.json"], "positive integer"),
            (
                ["--expected-samples", "many", "run.log", "out.json"],
                "positive integer",
            ),
            (
                ["--requirements", "--include-values", "run.log", "out.json"],
                "expected one argument",
            ),
        )

        for arguments, expected_error in cases:
            with self.subTest(arguments=arguments):
                stderr = io.StringIO()
                with redirect_stderr(stderr), self.assertRaises(SystemExit) as error:
                    _parse_arguments(arguments)
                self.assertEqual(error.exception.code, 2)
                self.assertIn(expected_error, stderr.getvalue())

    def test_android_requirements_exclude_frames_only_from_idle_checkpoints(
        self,
    ) -> None:
        requirements = _load_requirements(
            str(Path(__file__).parents[1] / "android_requirements.json")
        )
        frame_metrics = {
            "frame_window_ms",
            "fps",
            "build_p50_us",
            "build_p95_us",
            "build_p99_us",
            "raster_p50_us",
            "raster_p95_us",
            "raster_p99_us",
            "jank_count",
            "jank_rate",
        }
        idle_checkpoints = {
            ("scroll_room1", "scroll_end"),
            ("scroll_room1", "scroll_settled"),
            ("scroll_room2", "scroll_end"),
            ("scroll_room2", "scroll_settled"),
        }
        expected_checkpoints = {
            ("nav_cycles", "chat_list_baseline"),
            *(('nav_cycles', f'room_enter_cycle{cycle}') for cycle in range(1, 6)),
            *(
                ('nav_cycles', f'chat_list_after_cycle{cycle}')
                for cycle in range(1, 6)
            ),
            *(
                (scenario, label)
                for scenario, room in (("scroll_room1", 1), ("scroll_room2", 2))
                for label in (
                    "room_entered",
                    f"room{room}_scroll_step_5of15",
                    f"room{room}_scroll_step_10of15",
                    f"room{room}_scroll_step_15of15",
                    "scroll_end",
                    "scroll_settled",
                    "back_to_list",
                )
            ),
            ("chat_list_scroll", "list_top"),
            ("chat_list_scroll", "list_bottom"),
            ("chat_list_scroll", "list_top_again"),
        }
        always_required = {
            "rss_bytes",
            "cache_bytes",
            "cache_count",
            "cache_live",
            "cache_pending",
            "frame_count",
        }

        self.assertEqual(set(requirements), expected_checkpoints)
        self.assertEqual(len(requirements), 28)

        for checkpoint, metrics in requirements.items():
            self.assertTrue(always_required.issubset(metrics), checkpoint)
            if checkpoint in idle_checkpoints:
                self.assertTrue(frame_metrics.isdisjoint(metrics), checkpoint)
            else:
                self.assertTrue(frame_metrics.issubset(metrics), checkpoint)

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

    def test_expected_samples_rejects_incomplete_metric(self) -> None:
        Path(self.logs[1]).write_text(
            "PERF_METRIC | web_navigation | room_opened"
            " | transition_ms=102\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(
            ValueError,
            r"web_navigation/room_opened/fps has 2 sample\(s\); expected 3",
        ):
            compute_median(
                self.logs,
                str(self.directory / "median.json"),
                expected_samples=3,
            )

    def test_expected_samples_rejects_duplicate_repetition(self) -> None:
        combined_log = self.directory / "combined.log"
        combined_log.write_text(
            "PERF_METRIC | web_navigation | room_opened | run=r1 | fps=58\n"
            "PERF_METRIC | web_navigation | room_opened | run=r1 | fps=59\n"
            "PERF_METRIC | web_navigation | room_opened | run=r2 | fps=60\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(
            ValueError,
            r"duplicate sample.*web_navigation/room_opened.*r1",
        ):
            compute_median(
                [str(combined_log)],
                str(self.directory / "median.json"),
                expected_samples=3,
            )

    def test_expected_samples_rejects_two_android_samples_from_one_file(self) -> None:
        Path(self.logs[0]).write_text(
            "PERF_METRIC | nav_cycles | room_enter_cycle1 | run=r1 | fps=58\n"
            "PERF_METRIC | nav_cycles | room_enter_cycle1 | run=r2 | fps=59\n",
            encoding="utf-8",
        )
        Path(self.logs[1]).write_text(
            "PERF_METRIC | nav_cycles | room_enter_cycle1 | run=r3 | fps=60\n",
            encoding="utf-8",
        )
        Path(self.logs[2]).write_text("", encoding="utf-8")

        with self.assertRaisesRegex(
            ValueError,
            r"duplicate sample.*nav_cycles/room_enter_cycle1.*source 0",
        ):
            compute_median(
                self.logs,
                str(self.directory / "median.json"),
                expected_samples=3,
            )

    def test_requirements_reject_metric_absent_from_every_repetition(self) -> None:
        for index, path in enumerate(self.logs, start=1):
            Path(path).write_text(
                "PERF_METRIC | web_navigation | room_opened"
                f" | transition_ms={100 + index}\n",
                encoding="utf-8",
            )

        with self.assertRaisesRegex(
            ValueError,
            r"web_navigation/room_opened/fps is missing",
        ):
            compute_median(
                self.logs,
                str(self.directory / "median.json"),
                expected_samples=3,
                requirements={
                    ("web_navigation", "room_opened"): {
                        "fps",
                        "transition_ms",
                    },
                },
            )

    def test_requirements_reject_checkpoint_absent_from_every_repetition(self) -> None:
        with self.assertRaisesRegex(
            ValueError,
            r"required checkpoint web_navigation/scroll_completed is missing",
        ):
            compute_median(
                self.logs,
                str(self.directory / "median.json"),
                expected_samples=3,
                requirements={
                    ("web_navigation", "room_opened"): {"fps"},
                    ("web_navigation", "scroll_completed"): {"fps"},
                },
            )

    def test_missing_checkpoint_reduces_sample_count(self) -> None:
        Path(self.logs[1]).write_text("", encoding="utf-8")
        output = self.directory / "median.json"

        compute_median(self.logs, str(output))

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["sample_count"], 2)


if __name__ == "__main__":
    unittest.main()
