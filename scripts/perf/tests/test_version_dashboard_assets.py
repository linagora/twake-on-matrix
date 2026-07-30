import tempfile
import unittest
from pathlib import Path

from scripts.perf.version_dashboard_assets import version_dashboard_assets


class VersionDashboardAssetsTest(unittest.TestCase):
    def test_versions_every_local_dashboard_asset(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            index_path = Path(directory) / "index.html"
            index_path.write_text(
                """<link rel=\"stylesheet\" href=\"styles.css\" />
<script src=\"vendor/chart.umd.min.js\"></script>
<script src=\"metrics.js\"></script>
<script src=\"app.js\"></script>
""",
                encoding="utf-8",
            )

            version_dashboard_assets(index_path, "abc123")

            html = index_path.read_text(encoding="utf-8")
            self.assertIn('href="styles.css?v=abc123"', html)
            self.assertIn('src="vendor/chart.umd.min.js?v=abc123"', html)
            self.assertIn('src="metrics.js?v=abc123"', html)
            self.assertIn('src="app.js?v=abc123"', html)


if __name__ == "__main__":
    unittest.main()
