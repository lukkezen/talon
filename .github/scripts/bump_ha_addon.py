#!/usr/bin/env python3
"""Bump the Home Assistant add-on version and pin the Talon source commit.

Called on a code push to main. The generated release metadata commit is NOT
used as its own build source (which would create a circular Git reference).
"""
from __future__ import annotations

import argparse
import pathlib
import re


def bump(config_text: str, docker_text: str, source_sha: str) -> tuple[str, str, str]:
    if not re.fullmatch(r"[0-9a-f]{40}", source_sha):
        raise ValueError("Source commit must be a full lowercase SHA-1")

    version_pattern = r'(?m)^version: "(\d+)\.(\d+)\.(\d+)"$'
    matches = list(re.finditer(version_pattern, config_text))
    if len(matches) != 1:
        raise ValueError("Expected exactly one numeric add-on version in config.yaml")
    major, minor, patch = (int(part) for part in matches[0].groups())
    version = f"{major}.{minor}.{patch + 1}"
    config_text = re.sub(version_pattern, f'version: "{version}"', config_text, count=1)

    source_pattern = r"(?m)^ARG TALON_GIT_REF=[0-9a-f]{40}$"
    build_pattern = r"(?m)^ARG BUILD_VERSION=\d+\.\d+\.\d+$"
    if len(re.findall(source_pattern, docker_text)) != 1:
        raise ValueError("Dockerfile must have exactly one pinned TALON_GIT_REF")
    if len(re.findall(build_pattern, docker_text)) != 1:
        raise ValueError("Dockerfile must have exactly one numeric BUILD_VERSION")
    docker_text = re.sub(source_pattern, f"ARG TALON_GIT_REF={source_sha}", docker_text)
    docker_text = re.sub(build_pattern, f"ARG BUILD_VERSION={version}", docker_text)
    return config_text, docker_text, version


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--root", default=".")
    args = parser.parse_args()
    root = pathlib.Path(args.root)
    config_path = root / "talon-haos/config.yaml"
    docker_path = root / "talon-haos/Dockerfile"
    config, docker, version = bump(
        config_path.read_text(encoding="utf-8"),
        docker_path.read_text(encoding="utf-8"),
        args.source_sha,
    )
    config_path.write_text(config, encoding="utf-8")
    docker_path.write_text(docker, encoding="utf-8")
    print(f"Prepared Talon HA add-on {version} from source {args.source_sha}")


if __name__ == "__main__":
    main()
