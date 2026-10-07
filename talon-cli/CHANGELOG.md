# Changelog

## 0.3.2

- Forward-fix after the failed 0.3.0/0.3.1 app-config migration.
- Restores the last known-good CLI mapping with only `share:rw`.
- Removes `all_app_configs` and `/app_configs` discovery logic.
- Uses a version higher than 0.3.1 so Home Assistant can install this as a normal upgrade.

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
