# Talon CLI

Open **Talon CLI** from the Home Assistant add-on page and click **Open Web UI**.

The terminal starts in `/share/talon`, which is the same workspace used by the Talon daemon.

## Common commands

```sh
talonctl config-show
talonctl list-channels
talonctl list-personas
talonctl list-skills
talonctl list-providers
talonctl list-capabilities
```

Add a skill:

```sh
talonctl add-skill --name postgram --persona assistant --format skillmd
```

Add an MCP server:

```sh
talonctl add-mcp \
  --skill postgram \
  --name postgram \
  --transport http \
  --url https://example.com/mcp
```

After changing config/personas/channels, use:

```sh
talonctl reload
```

The Talon daemon keeps its SQLite database under its private `/data`; configuration, personas, skills and the IPC control socket are shared through `/share/talon`.
