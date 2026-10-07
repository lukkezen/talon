# Talon CLI Home Assistant add-on

This add-on exposes Talon's original CLI in a Home Assistant Ingress terminal.

It uses the same upstream `ghcr.io/ivo-toby/talond:latest` image as the daemon add-on. The only additions are a browser terminal (`ttyd`) and a thin `talonctl` launcher that executes Talon's bundled CLI directly.

## Optional instance selection

By default the CLI manages:

`/share/talon`

Set the Home Assistant add-on option `instance` to, for example, `d66` and it instead manages:

`/share/talon-instances/d66`

This makes one generic Talon CLI add-on usable with multiple Talon workspaces without changing upstream Talon.

Examples:

```sh
talonctl list-personas
talonctl list-skills
talonctl add-skill --name postgram --persona assistant --format skillmd
talonctl add-mcp --skill postgram --name postgram --transport http --url https://example/mcp
talonctl reload
```
