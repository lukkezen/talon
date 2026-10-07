# Talon add-on documentation

## Install

1. In Home Assistant, open **Settings → Add-ons → Add-on Store**.
2. Add the repository:
   `https://github.com/lukkezen/talon`
3. Install **Talon**.
4. Optionally install **Talon CLI** from the same repository.

## Home Assistant bootstrap options

For a fresh installation, configure at least:

- `openai_api_key`
- `openai_model`

For Telegram:

- `telegram_bot_token`
- `telegram_chat_id`

These options bootstrap the initial Talon configuration. After that, `/share/talon/talond.yaml` is the source of truth.

## Shared upstream-style workspace

Managed Talon files live in:

`/share/talon`

Layout:

```text
/share/talon/
├── talond.yaml
├── personas/
├── skills/
├── subagents/
├── userdata/
└── data/
    └── ipc/
        └── daemon/
```

The SQLite database and other daemon runtime state remain private under:

`/data/talon/state`

This keeps the database private to the daemon while allowing the separate Talon CLI add-on to manage configuration using upstream Talon commands.

## Upgrade from 0.3.x

On the first 0.4.0 start, if `/share/talon/talond.yaml` does not exist but the old `/data/talon/config/talond.yaml` does, the add-on:

1. copies the existing config to `/share/talon/talond.yaml`;
2. copies personas, skills, subagents and userdata to the shared workspace;
3. updates known absolute paths to the shared locations;
4. moves the IPC path to `/share/talon/data/ipc/daemon`.

The old files under `/data/talon` are deliberately left in place as a fallback copy.

## Managing Talon

Use the **Talon CLI** add-on. It opens a Home Assistant Ingress terminal in `/share/talon`.

Examples:

```sh
talonctl list-personas
talonctl list-skills
talonctl add-skill --name postgram --persona assistant --format skillmd
talonctl reload
```

This keeps Talon itself unmodified: the daemon and CLI both come from the upstream Talon image.

## Security

No Docker socket is exposed to Talon. The CLI add-on receives read/write access only to Home Assistant's shared `/share` mount.
