# Talon Home Assistant add-on

This folder packages [Talon](https://github.com/ivo-toby/talon) as a Home Assistant OS add-on without modifying Talon's application source.

## Current scope

- uses the upstream `ghcr.io/ivo-toby/talond:latest` image
- amd64, intended for the Intel NUC running Home Assistant OS
- OpenAI-compatible provider using the OpenAI API
- optional Telegram channel
- upstream-style shared workspace at `/share/talon`
- private SQLite/runtime state under `/data/talon/state`
- compatible with the separate **Talon CLI** add-on in this repository
- no Docker socket
- no bundled Codex runner

Home Assistant options bootstrap a fresh install. Afterwards, `/share/talon/talond.yaml` and the normal Talon skill/persona files are authoritative.

See `DOCS.md` for installation and migration details.
