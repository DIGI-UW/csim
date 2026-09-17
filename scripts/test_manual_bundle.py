"""Structural checks for the client-facing Superset UI import bundle."""

from pathlib import Path
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[1]
MANUAL = ROOT / "release" / "client-update" / "manual"


class ManualBundleTest(unittest.TestCase):
    def entries(self, name: str) -> list[str]:
        with zipfile.ZipFile(MANUAL / name) as archive:
            return archive.namelist()

    def test_dataset_package(self):
        entries = self.entries("01-csim-reporting-datasets.zip")
        self.assertEqual(sum("/datasets/" in item and item.endswith(".yaml") for item in entries), 6)
        self.assertEqual(sum("/databases/" in item and item.endswith(".yaml") for item in entries), 1)
        self.assertFalse(any("/charts/" in item for item in entries))
        self.assertFalse(any("/dashboards/" in item for item in entries))

    def test_chart_package(self):
        entries = self.entries("02-csim-dashboard-charts.zip")
        self.assertEqual(sum("/charts/" in item and item.endswith(".yaml") for item in entries), 21)
        self.assertEqual(sum("/datasets/" in item and item.endswith(".yaml") for item in entries), 6)
        self.assertEqual(sum("/databases/" in item and item.endswith(".yaml") for item in entries), 1)
        self.assertFalse(any("/dashboards/" in item for item in entries))

    def test_dashboard_package(self):
        entries = self.entries("03-csim-dashboard.zip")
        self.assertEqual(sum("/dashboards/" in item and item.endswith(".yaml") for item in entries), 1)
        self.assertEqual(sum("/charts/" in item and item.endswith(".yaml") for item in entries), 21)
        self.assertEqual(sum("/datasets/" in item and item.endswith(".yaml") for item in entries), 6)
        self.assertEqual(sum("/databases/" in item and item.endswith(".yaml") for item in entries), 1)

    def test_no_reporting_records_or_cleartext_password(self):
        for archive_path in MANUAL.glob("*.zip"):
            with zipfile.ZipFile(archive_path) as archive:
                contents = b"\n".join(archive.read(item) for item in archive.namelist())
            self.assertNotIn(b"INSERT INTO", contents)
            self.assertIn(b"XXXXXXXXXX", contents)

    def test_datasets_do_not_reroute_the_destination_database(self):
        for archive_path in MANUAL.glob("*.zip"):
            with zipfile.ZipFile(archive_path) as archive:
                datasets = b"\n".join(
                    archive.read(item)
                    for item in archive.namelist()
                    if "/datasets/" in item and item.endswith(".yaml")
                )
            self.assertNotIn(b"catalog: csim_demo", datasets)
            self.assertIn(b"catalog: data", datasets)

    def test_source_instance_caches_are_not_shipped(self):
        for name in ("02-csim-dashboard-charts.zip", "03-csim-dashboard.zip"):
            with zipfile.ZipFile(MANUAL / name) as archive:
                chart_contents = b"\n".join(
                    archive.read(item) for item in archive.namelist() if "/charts/" in item
                )
            self.assertNotIn(b"  slice_id:", chart_contents)
            self.assertNotIn(b"  dashboards:", chart_contents)
        with zipfile.ZipFile(MANUAL / "03-csim-dashboard.zip") as archive:
            dashboard = b"\n".join(
                archive.read(item) for item in archive.namelist() if "/dashboards/" in item
            )
        self.assertNotIn(b"chartsInScope:", dashboard)


if __name__ == "__main__":
    unittest.main()
