# Talon CLI Home Assistant add-on

This add-on exposes Talon's original CLI in a Home Assistant Ingress terminal.

It uses the same upstream `ghcr.io/ivo-toby/talond:latest` image as the daemon add-on. The only additions are a browser terminal (`ttyd`) and a thin `talonctl` launcher that executes Talon's bundled CLI directly.

The shared Talon workspace is:

`/share/talon`

Examples:

```sh
talonctl list-personas
talonctl list-skills
talonctl add-skill --name postgram --persona assistant --format skillmd
talonctl add-mcp --skill postgram --name postgram --transport http --url https://example/mcp
talonctl reload
```
