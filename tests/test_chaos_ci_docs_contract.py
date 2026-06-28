import pathlib
import subprocess
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ChaosCIDocsContract(unittest.TestCase):
    def test_chaos_scripts_exist_and_parse(self):
        scripts = [
            "chaos/scenarios/lib.sh",
            "chaos/scenarios/kill-broker.sh",
            "chaos/scenarios/controller-failover.sh",
            "chaos/scenarios/zookeeper-failover.sh",
            "chaos/scenarios/network-isolate-broker.sh",
            "chaos/scenarios/disk-pressure.sh",
        ]
        for script in scripts:
            with self.subTest(script=script):
                path = ROOT / script
                self.assertTrue(path.exists())
                subprocess.run(["bash", "-n", str(path)], check=True)

    def test_ci_workflow_exists(self):
        workflow = ROOT / ".github/workflows/ci.yml"
        self.assertTrue(workflow.exists())
        text = workflow.read_text(encoding="utf-8")
        for phrase in ["make test", "docker compose", "kubectl kustomize", "go test ./...", "mvn -B test"]:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, text)

    def test_operational_docs_exist(self):
        required = [
            "docs/local-development.md",
            "docs/production-checklist.md",
            "docs/disaster-recovery.md",
            "docs/operations.md",
            "docs/commit-walkthrough.md",
            "docs/diagrams/migration-sequence.mmd",
            "docs/diagrams/observability-flow.mmd",
            "docs/diagrams/security-flow.mmd",
        ]
        missing = [path for path in required if not (ROOT / path).exists()]
        self.assertEqual([], missing)

