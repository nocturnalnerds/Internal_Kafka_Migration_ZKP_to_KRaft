import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class BaselineRepositoryContract(unittest.TestCase):
    def test_baseline_files_exist(self):
        required = [
            "README.md",
            "docs/architecture.md",
            "Makefile",
            ".gitignore",
            ".editorconfig",
        ]

        missing = [path for path in required if not (ROOT / path).exists()]
        self.assertEqual([], missing)

    def test_readme_declares_migration_scope(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        for phrase in [
            "ZooKeeper",
            "KRaft",
            "Docker Compose",
            "Kubernetes",
            "Prometheus",
            "TLS",
            "SASL/SCRAM",
        ]:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, readme)


if __name__ == "__main__":
    unittest.main()

