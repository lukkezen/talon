# Changelog

## 0.7.0

- Combines the Talon daemon and management CLI in one Home Assistant app.
- Adds an Ingress terminal with upstream `talonctl`.
- Moves the active workspace to private `/data/talon/workspaces/<instance>`.
- Migrates the existing `/share/talon*` workspace once using a temporary read-only `/share` mount.
- Leaves the legacy workspace untouched as a fallback.
- Prepares 0.7.1, which will remove `/share` completely after migration.
- Does not modify upstream Talon.

## 0.6.1

- Forward-fix after the failed 0.6.0 app-config migration.
- Restores the last known-good Home Assistant mapping with `share:rw`.
- Removes dependency on `app_config` / `all_app_configs` for Talon and Talon CLI.
- Uses a version higher than 0.6.0 so Home Assistant can install this as a normal upgrade.

## 0.5.1

- Fixes `talonctl status` and `talonctl reload` from the separate Talon CLI add-on.
- Keeps Talon `dataDir`, SQLite state, and host-tools socket private.
- Redirects only upstream Talon's transient `<dataDir>/ipc/daemon` directory to the matching shared instance workspace.
- Does not modify upstream Talon.

## 0.5.0

- Adds optional `instance` configuration to the Talon daemon wrapper.
- Empty instance stays backwards-compatible with `/share/talon`.
- Named instances use `/share/talon-instances/<instance>`.
- Named instances bootstrap independently and do not inherit the default workspace.
- Adds path-traversal validation for instance names.
- Logs active instance and workspace at startup.
- Designed to pair with Talon CLI 0.2.0 using the same instance value.

# Changelog

## 0.4.0

- Adds shared upstream-style Talon workspace at `/share/talon`.
- Migrates existing 0.3.x configuration and managed files automatically on first start.
- Keeps SQLite/runtime state private under `/data/talon/state`.
- Moves daemon IPC to `/share/talon/data/ipc/daemon` so the separate Talon CLI add-on can use upstream `status`, `reload`, and queue commands.
- Leaves the pre-0.4 private configuration in place as a fallback copy.
- Designed to work with the new Talon CLI Home Assistant add-on.

## 0.3.0

- Preserves Talon configuration instead of regenerating it on each restart.

## 0.2.1

- Removes the Home Assistant WhatsApp/Baileys self-chat integration.
- Keeps Telegram as the optional chat channel.

## 0.2.0

- Added WhatsApp/Baileys support; removed again in 0.2.1.

## 0.1.0

- Initial Home Assistant OS add-on wrapper.
- Uses the upstream Talon container image.
- Adds OpenAI API and optional Telegram bootstrap configuration.
