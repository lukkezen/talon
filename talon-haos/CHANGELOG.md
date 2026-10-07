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
