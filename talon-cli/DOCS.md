# Talon CLI

Open **Talon CLI** from the Home Assistant add-on page and click **Open Web UI**.

## Selecting a Talon instance

The optional `instance` setting controls which Talon workspace the CLI manages.

Leave it empty for the existing/default Talon:

```yaml
instance: ""
```

This uses:

```text
/share/talon
```

Set an instance name, for example:

```yaml
instance: d66
```

This uses:

```text
/share/talon-instances/d66
```

The same CLI add-on can therefore be pointed at another Talon instance simply by changing this setting and restarting the CLI add-on.

Instance names may contain letters, numbers, dots, underscores and dashes. Path traversal such as `..` is rejected.

> The selected Talon daemon must itself use the same workspace. The CLI does not create or redirect a daemon; it only selects which workspace `talonctl` manages.

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

After changing config/personas/channels:

```sh
talonctl reload
```

The terminal banner shows the selected instance and workspace so it is immediately visible which Talon you are managing.
