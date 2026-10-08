# Changelog

## 1.0.3

- Respect `CODEX_HOME` when locating Codex CLI authentication for provider sessions and provider tests.
- Increase the Codex provider smoke-test timeout from 30 to 120 seconds.
- Add regression tests for Codex authentication handling.

## 1.0.2

- Keep Codex CLI authentication in the add-on's persistent storage across restarts by setting `CODEX_HOME` for the daemon and terminal.

## 1.0.1

- Restore the `instance` workspace selector in Home Assistant add-on settings.
- Document how to reopen existing named workspaces without moving data.

## 1.0.0

Initial public release of the Talon Home Assistant add-on.

- Single Talon daemon with an integrated management terminal.
- Private persistent workspace, database, and configuration.
- Configurable private storage location.
- Optional Telegram configuration and MCP integrations.
