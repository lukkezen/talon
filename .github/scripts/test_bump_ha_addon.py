import importlib.util
import pathlib
import unittest

module_path = pathlib.Path(__file__).with_name("bump_ha_addon.py")
spec = importlib.util.spec_from_file_location("bump_ha_addon", module_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

SHA = "a" * 40
CONFIG = 'name: Talon\nversion: "1.0.11"\noptions:\n  instance: ""\n'
DOCKER = (
    "# Pinned by the HA release workflow\n"
    "ARG TALON_GIT_REF=" + "b" * 40 + "\n"
    "ARG BUILD_VERSION=1.0.11\n"
)


class BumpAddonTests(unittest.TestCase):
    def test_increments_version_and_pins_same_source(self):
        config, docker, version = module.bump(CONFIG, DOCKER, SHA)
        self.assertEqual(version, "1.0.12")
        self.assertIn('version: "1.0.12"', config)
        self.assertIn("ARG BUILD_VERSION=1.0.12", docker)
        self.assertIn("ARG TALON_GIT_REF=" + SHA, docker)
        self.assertIn('instance: ""', config)

    def test_version_is_monotonic_over_multiple_releases(self):
        config, docker, _ = module.bump(CONFIG, DOCKER, SHA)
        config, docker, version = module.bump(config, docker, "c" * 40)
        self.assertEqual(version, "1.0.13")
        self.assertIn("ARG TALON_GIT_REF=" + "c" * 40, docker)

    def test_invalid_source_commit_is_rejected(self):
        with self.assertRaises(ValueError):
            module.bump(CONFIG, DOCKER, "main")

    def test_unpinned_or_ambiguous_dockerfile_is_rejected(self):
        with self.assertRaises(ValueError):
            module.bump(CONFIG, DOCKER.replace("b" * 40, "main"), SHA)
        with self.assertRaises(ValueError):
            module.bump(CONFIG, DOCKER + "ARG BUILD_VERSION=1.0.11\n", SHA)


if __name__ == "__main__":
    unittest.main()
