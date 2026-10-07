# Talon add-on documentation

## Install

1. In Home Assistant, open **Settings → Add-ons → Add-on Store**.
2. Open the repository menu and add:
   `https://github.com/lukkezen/talon`
3. Refresh the add-on store.
4. Install **Talon**.

## Configuration

At minimum, set:

- `openai_api_key`: an OpenAI API key.
- `openai_model`: defaults to `gpt-5.4`.

To use Telegram, also set:

- `telegram_bot_token`: token from BotFather.
- `telegram_chat_id`: the Telegram chat ID allowed to talk to Talon.

If Telegram is left empty, the daemon still starts but has no chat channel.

## Persistent data

All local Talon data is stored below:

`/data/talon`

This includes SQLite state, the generated Talon configuration, persona prompts, skills, sub-agents and user data.

## Notes

This first Home Assistant build deliberately does not expose Docker to Talon. Home Assistant OS manages containers itself, and giving Talon access to the Docker socket would substantially increase privileges.

The next logical step is to add MCP configuration for Postgram and the user's Todo service while preserving least-privilege access.
