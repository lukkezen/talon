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

### Telegram

To use Telegram, set:

- `telegram_bot_token`: token from BotFather.
- `telegram_chat_id`: the Telegram chat ID allowed to talk to Talon.

If Telegram is left empty, the daemon still starts but has no chat channel.

## Persistent data

All local Talon data is stored below:

`/data/talon`

This includes SQLite state, the Talon configuration, persona prompts, skills, sub-agents and user data.\n\n## Upstream-style Talon configuration\n\nHome Assistant options are now used only to bootstrap `talond.yaml` when `/data/talon/config/talond.yaml` does not exist yet. Once created, the file is persistent and is not regenerated on add-on restart.\n\nThis keeps the add-on close to upstream Talon: `talond.yaml`, personas, skills and MCP definitions are the source of truth. The upstream CLI is available in the image as `node /opt/talond/dist/cli/index.js`. Run CLI commands from `/data/talon/config`, or pass `--config /data/talon/config/talond.yaml`. For skill/MCP commands, use `--skills-dir /data/talon/skills` where applicable.\n\nAfter changing configuration with the CLI, upstream Talon supports hot reload through `talonctl reload`/the equivalent CLI command using the daemon IPC directory `/data/talon/state/ipc/daemon`.

## Security

This Home Assistant build deliberately does not expose Docker to Talon. Home Assistant OS manages containers itself, and giving Talon access to the Docker socket would substantially increase privileges.
