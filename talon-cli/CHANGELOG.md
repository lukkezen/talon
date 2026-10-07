# Changelog

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
