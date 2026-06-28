import os
import pathlib
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ExamplesContract(unittest.TestCase):
    def test_example_files_exist(self):
        required = [
            "examples/go/go.mod",
            "examples/go/cmd/producer/main.go",
            "examples/go/cmd/consumer/main.go",
            "examples/go/cmd/idempotent-producer/main.go",
            "examples/go/cmd/retry-worker/main.go",
            "examples/go/cmd/outbox-worker/main.go",
            "examples/go/cmd/outbox-enqueue/main.go",
            "examples/java/pom.xml",
            "examples/java/src/main/java/com/example/kafka/tx/TransactionalProducer.java",
            "examples/java/src/main/java/com/example/kafka/eos/ExactlyOnceProcessor.java",
        ]
        missing = [path for path in required if not (ROOT / path).exists()]
        self.assertEqual([], missing)

    def test_pattern_docs_cover_required_concepts(self):
        docs = "\n".join(
            [
                (ROOT / "docs/patterns/exactly-once.md").read_text(encoding="utf-8"),
                (ROOT / "docs/patterns/transactional-outbox.md").read_text(encoding="utf-8"),
                (ROOT / "docs/patterns/retry-dlq.md").read_text(encoding="utf-8"),
            ]
        )
        for phrase in [
            "Exactly-once",
            "transactional.id",
            "Transactional Outbox",
            "orders.retry.0",
            "orders.dlq",
        ]:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, docs)

    def test_go_internal_tests_if_go_available(self):
        go = subprocess.run(
            ["bash", "-lc", "command -v go"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if go.returncode != 0:
            self.skipTest("go is not installed")

        with tempfile.TemporaryDirectory() as cache_dir:
            subprocess.run(
                ["go", "test", "./internal/..."],
                cwd=ROOT / "examples/go",
                env={**os.environ, "GOWORK": "off", "GOCACHE": cache_dir},
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
