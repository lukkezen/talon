# Talon Home Assistant add-on

This folder packages [Talon](https://github.com/ivo-toby/talon) as a Home Assistant OS add-on.

The add-on intentionally keeps the Talon application itself upstream-compatible. It uses the published `ghcr.io/ivo-toby/talond:latest` image and adds only a small Home Assistant startup wrapper.

## Current scope

- amd64 only (intended for the Intel NUC running Home Assistant OS)
- persistent Talon state under `/data/talon`
- OpenAI-compatible provider using the OpenAI API
- optional Telegram channel
- no Docker sandbox inside Talon
- no bundled Codex runner
- MCP servers can be added in a later iteration

See `DOCS.md` for installation and configuration.
