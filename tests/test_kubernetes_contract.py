import pathlib
import re
import subprocess
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
K8S = ROOT / "k8s"


class KubernetesContract(unittest.TestCase):
    def test_kustomize_files_exist(self):
        required = [
            "base/kustomization.yaml",
            "base/zookeeper-statefulset.yaml",
            "base/kafka-zk-statefulset.yaml",
            "base/kraft-controller-statefulset.yaml",
            "base/pod-disruption-budgets.yaml",
            "overlays/local/kustomization.yaml",
            "overlays/final-kraft/kustomization.yaml",
            "overlays/production/kustomization.yaml",
        ]
        missing = [path for path in required if not (K8S / path).exists()]
        self.assertEqual([], missing)

    def test_statefulsets_have_three_replicas_and_storage(self):
        for path in [
            "base/zookeeper-statefulset.yaml",
            "base/kafka-zk-statefulset.yaml",
            "base/kraft-controller-statefulset.yaml",
        ]:
            text = (K8S / path).read_text(encoding="utf-8")
            with self.subTest(path=path):
                self.assertRegex(text, r"replicas:\s*3")
                self.assertIn("volumeClaimTemplates:", text)
                self.assertIn("readinessProbe:", text)
                self.assertIn("livenessProbe:", text)

    def test_base_kustomization_references_existing_resources(self):
        text = (K8S / "base/kustomization.yaml").read_text(encoding="utf-8")
        resources = re.findall(r"^\s+-\s+([\w./-]+\.yaml)$", text, flags=re.MULTILINE)
        missing = [resource for resource in resources if not (K8S / "base" / resource).exists()]
        self.assertEqual([], missing)

    def test_kubectl_kustomize_if_available(self):
        kubectl = subprocess.run(
            ["bash", "-lc", "command -v kubectl"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if kubectl.returncode != 0:
            self.skipTest("kubectl is not installed")

        for overlay in ["local", "final-kraft", "production"]:
            with self.subTest(overlay=overlay):
                subprocess.run(
                    ["kubectl", "kustomize", str(K8S / "overlays" / overlay)],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )

