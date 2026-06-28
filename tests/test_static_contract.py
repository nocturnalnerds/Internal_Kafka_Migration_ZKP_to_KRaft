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
            "docker-compose.yml",
            ".env.example",
            "docker/README.md",
            "docker/scripts/create-topics.sh",
            "docker/kafka/client.properties",
            "scripts/README.md",
            "docs/runbooks/migration.md",
            "k8s/README.md",
            "docs/diagrams/kubernetes-topology.mmd",
            "observability/README.md",
            "docs/security.md",
            "security/README.md",
            "examples/README.md",
            "docs/patterns/exactly-once.md",
            "docs/patterns/transactional-outbox.md",
            "docs/patterns/retry-dlq.md",
            "chaos/README.md",
            ".github/workflows/ci.yml",
            "docs/operations.md",
            "docs/production-checklist.md",
            "docs/disaster-recovery.md",
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


class ComposeContract(unittest.TestCase):
    def setUp(self):
        self.compose = (ROOT / "docker-compose.yml").read_text(encoding="utf-8")

    def test_required_services_are_declared(self):
        for service in [
            "zookeeper-1",
            "zookeeper-2",
            "zookeeper-3",
            "kafka-1",
            "kafka-2",
            "kafka-3",
            "kraft-controller-1",
            "kraft-controller-2",
            "kraft-controller-3",
            "kafka-init",
        ]:
            with self.subTest(service=service):
                self.assertIn(f"  {service}:", self.compose)

    def test_compose_includes_operational_contracts(self):
        for phrase in [
            "healthcheck:",
            "volumes:",
            "KAFKA_ZOOKEEPER_CONNECT",
            "KAFKA_ZOOKEEPER_METADATA_MIGRATION_ENABLE",
            "KAFKA_CONTROLLER_QUORUM_VOTERS",
            'profiles: ["migration"]',
        ]:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, self.compose)


if __name__ == "__main__":
    unittest.main()
