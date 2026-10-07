# Changelog

## 0.3.1

- Fixes the Home Assistant `all_app_configs` mount path from `/addon_configs` to the current `/app_configs` path.
- Allows the CLI to find the Talon 0.6 daemon app config and complete the one-time workspace migration.

## 0.3.0

- Manages the Talon daemon isolated app config instead of the old shared workspace.
- Keeps manual CLI `share:rw` access.
- Adds `all_app_configs:rw` only to the CLI for daemon administration.
- Automatically migrates pre-0.6 `/share/talon*` workspaces on first start.
- Leaves the old share copy intact as a fallback.

## 0.2.0

- Adds optional `instance` configuration.
- Empty `instance` remains fully backwards-compatible with `/share/talon`.
- Named instances use `/share/talon-instances/<instance>`.
- Adds strict instance-name validation to prevent path traversal.
- Terminal banner shows the active instance and workspace.
- `talonctl` automatically uses the selected workspace.

## 0.1.0

- Initial Talon CLI Home Assistant add-on.
- Uses the original upstream Talon image.
- Adds a Home Assistant Ingress terminal with ttyd.
- Shares `/share/talon` with the Talon daemon.
- Provides a thin `talonctl` launcher for the bundled upstream CLI.
