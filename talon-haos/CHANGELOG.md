# Changelog

## 0.2.0

- Adds WhatsApp via Talon's Baileys connector.
- Enables self-chat mode by default.
- Adds configurable `@Talon` trigger word.
- Runs first-time WhatsApp QR pairing from the Home Assistant add-on log.
- Persists WhatsApp credentials under `/data/talon/baileys-auth`.
- Keeps Telegram support available in parallel.

## 0.1.0

- Initial Home Assistant OS add-on wrapper.
- Uses the upstream Talon container image.
- Persists Talon data under `/data/talon`.
- Adds OpenAI API configuration.
- Adds optional Telegram channel configuration.
