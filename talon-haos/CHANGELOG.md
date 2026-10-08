## 0.8.2

- Packages the fork-only OpenAI Responses MCP tool input-schema fix from commit 83a05ec.
- Preserves required file-export arguments and nested channel attachment schemas.
- Keeps the upstream image pinned and preserves existing private HA configuration.

# Changelog

## 0.8.1

- Packages the fork's attachment tool schema, download handler, and Telegram video uploader in the Home Assistant image.
- Pins the upstream image digest and verifies the three source modules during image build.
- Preserves private workspace configuration and existing capability defaults.

## 0.7.3

- Fixes embedded `talonctl status` and `talonctl reload` using the actual upstream IPC behavior.
- Upstream `talonctl` always uses `data/ipc/daemon` relative to the current workspace, while `talond` uses `<dataDir>/ipc/daemon`.
- Adds a private symlink from `/data/talon/workspaces/<instance>/data/ipc/daemon` to `/data/talon/state/ipc/daemon`.
- Removes the ineffective 0.7.2 YAML-only IPC rewrite.
- Keeps Home Assistant `/share` completely unmounted.

## 0.7.2

- Aligns migrated `ipc.daemonSocketDir` with `/data/talon/state/ipc/daemon`.
- Fixes embedded `talonctl status` and `talonctl reload` timing out while the daemon is running.
- Keeps `/share` completely unmounted.

## 0.7.1

- Removes the Home Assistant `/share` mount entirely after the 0.7.0 migration.
- Removes the old pre-0.7 IPC symlink into `/share` and recreates `/data/talon/state/ipc/daemon` as a local writable directory.
- Fixes `EROFS: read-only file system, chmod .../ipc/daemon/input` seen after upgrading from the shared-workspace wrapper.
- Keeps daemon and `talonctl` together in the same app/container.
- External Home Assistant files are now accessible to Talon only through explicitly configured MCP servers.

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
