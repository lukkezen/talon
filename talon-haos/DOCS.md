# Talon Home Assistant app

## Talon 0.7: daemon and CLI together

Talon 0.7 runs the upstream Talon daemon and upstream Talon CLI in one Home Assistant app/container. The persistent workspace lives in app-private storage:

```text
/data/talon/workspaces/default
/data/talon/workspaces/<instance>
```

Open the Talon app Web UI for the management terminal. Normal commands work there:

```sh
talonctl status
talonctl list-personas
talonctl list-skills --persona assistant
talonctl reload
```

The separate Talon CLI app is no longer needed once this setup has been verified.

## 0.7.0 migration bridge

Version 0.7.0 temporarily mounts Home Assistant `/share` **read-only**. If an old workspace exists at `/share/talon` or `/share/talon-instances/<instance>`, it is copied once into private `/data`. The old workspace is never modified or deleted.

After migration is confirmed, upgrade to 0.7.1. That version will remove `/share` entirely. External files such as transcripts must then be accessed through explicitly configured MCP servers.

No upstream Talon source code is modified.
