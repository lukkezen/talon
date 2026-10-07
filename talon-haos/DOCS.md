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

### WhatsApp

WhatsApp is enabled by default in self-chat mode:

- `whatsapp_enabled: true`
- `whatsapp_self_chat: true`
- `whatsapp_trigger_word: "@Talon"`

On the first start, the add-on prints a WhatsApp QR code in the Home Assistant add-on log. Scan it using:

**WhatsApp → Settings → Linked devices → Link a device**

Authentication is stored persistently under:

`/data/talon/baileys-auth`

After successful pairing, restart the add-on. Future starts reuse the stored WhatsApp session and do not require another QR scan.

With the default self-chat setting, Talon only listens in your own **Message Yourself** chat. Start messages with `@Talon`, for example:

`@Talon wat staat er nog open?`

Set `whatsapp_trigger_word` to an empty string if you do not want a trigger word.

### Telegram

Telegram remains optional. To enable it, also set:

- `telegram_bot_token`
- `telegram_chat_id`

Telegram and WhatsApp can be enabled at the same time.

## Persistent data

All local Talon data is stored below:

`/data/talon`

This includes SQLite state, the generated Talon configuration, WhatsApp credentials, persona prompts, skills, sub-agents and user data.

## Security

This Home Assistant build deliberately does not expose Docker to Talon. Home Assistant OS manages containers itself, and giving Talon access to the Docker socket would substantially increase privileges.

WhatsApp uses the upstream Talon Baileys/WhatsApp Web connector. It does not require a Meta Business account, but it is still an unofficial WhatsApp Web integration rather than the official WhatsApp Business Cloud API.
