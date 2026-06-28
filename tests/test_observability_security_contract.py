import json
import pathlib
import subprocess
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ObservabilitySecurityContract(unittest.TestCase):
    def test_observability_files_exist(self):
        required = [
            "observability/prometheus/prometheus.yml",
            "observability/prometheus/alerts/kafka.yml",
            "observability/alertmanager/alertmanager.yml",
            "observability/grafana/provisioning/datasources/prometheus.yml",
            "observability/grafana/provisioning/dashboards/dashboards.yml",
            "observability/grafana/dashboards/kafka-overview.json",
            "observability/jmx/kafka-1.yml",
            "observability/jmx/kafka-2.yml",
            "observability/jmx/kafka-3.yml",
        ]
        missing = [path for path in required if not (ROOT / path).exists()]
        self.assertEqual([], missing)

    def test_grafana_dashboard_is_valid_json(self):
        dashboard = json.loads(
            (ROOT / "observability/grafana/dashboards/kafka-overview.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual("Kafka ZooKeeper to KRaft Overview", dashboard["title"])
        self.assertGreaterEqual(len(dashboard["panels"]), 3)

    def test_security_files_exist(self):
        required = [
            "docker-compose.secure.yml",
            "security/client-admin.properties",
            "security/client-admin-container.properties",
            "security/client-producer.properties",
            "security/client-consumer.properties",
            "scripts/security/generate-certs.sh",
            "scripts/security/create-scram-users.sh",
            "scripts/security/apply-acls.sh",
            "k8s/overlays/secure/kustomization.yaml",
        ]
        missing = [path for path in required if not (ROOT / path).exists()]
        self.assertEqual([], missing)

    def test_security_scripts_parse_as_bash(self):
        for script in [
            "scripts/security/generate-certs.sh",
            "scripts/security/create-scram-users.sh",
            "scripts/security/apply-acls.sh",
        ]:
            with self.subTest(script=script):
                subprocess.run(["bash", "-n", str(ROOT / script)], check=True)

    def test_compose_overlays_parse_if_docker_available(self):
        docker = subprocess.run(
            ["bash", "-lc", "command -v docker"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if docker.returncode != 0:
            self.skipTest("docker is not installed")

        for files in [
            ["docker-compose.yml", "docker-compose.secure.yml"],
            ["docker-compose.yml"],
        ]:
            args = ["docker", "compose"]
            for file_name in files:
                args.extend(["-f", str(ROOT / file_name)])
            args.extend(["config", "--quiet"])
            with self.subTest(files=files):
                subprocess.run(args, cwd=ROOT, check=True)

    def test_secure_kustomize_if_kubectl_available(self):
        kubectl = subprocess.run(
            ["bash", "-lc", "command -v kubectl"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if kubectl.returncode != 0:
            self.skipTest("kubectl is not installed")

        subprocess.run(
            ["kubectl", "kustomize", str(ROOT / "k8s/overlays/secure")],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

