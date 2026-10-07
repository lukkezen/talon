# Talon add-on documentation

## Optional instance

The Home Assistant option `instance` selects the Talon workspace.

Default/backwards-compatible:

```yaml
instance: ""
```

uses `/share/talon`.

A named instance such as:

```yaml
instance: d66
```

uses `/share/talon-instances/d66`.

Use the same `instance` value in **Talon CLI** to manage that daemon.

Named instances do not copy or migrate the default Talon workspace. If their workspace does not exist, they bootstrap a fresh `talond.yaml` using that add-on installation's own Home Assistant options.

Instance names may contain letters, numbers, dots, underscores and dashes. `..` and path traversal are rejected.

## Install

1. Install or deploy **Talon**.
2. Configure the optional `instance` plus OpenAI and Telegram settings.
3. Install **Talon CLI** and set the same `instance` when you want to manage this Talon.

## Workspace layout

Default:

```text
/share/talon/
```

Named:

```text
/share/talon-instances/<instance>/
```

Each workspace contains `talond.yaml`, personas, skills, subagents, userdata and the daemon IPC directory.

The daemon SQLite/runtime state remains under its add-on-private `/data/talon/state`. Separate Home Assistant add-on installations therefore keep separate state even when they use the same wrapper code.

## Managing Talon

Set the same instance in Talon CLI, restart the CLI add-on, then use normal upstream commands:

```sh
talonctl list-personas
talonctl list-skills
talonctl add-skill --name postgram --persona assistant --format skillmd
talonctl reload
```

Talon upstream itself is not modified.
