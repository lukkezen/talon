# Talon add-on documentation

## Isolated Home Assistant storage

Talon 0.6.0 no longer mounts Home Assistant’s general `/share` directory.

The daemon uses its dedicated Home Assistant app config mounted as `/config`, with one workspace per instance:

```text
/config/instances/default/
/config/instances/D66/
```

The autonomous daemon therefore cannot directly read `/share/video-transcriber`, `/share/downloadclipper`, or other Home Assistant shares. Access to those files should go through explicitly configured MCP servers such as Read-only Files MCP.

The SQLite database and host-tools socket remain private under `/data/talon/state`.

## Migration from pre-0.6

1. Update/start Talon 0.6.0 once so Home Assistant creates its app config.
2. Update/start Talon CLI 0.3.0 once. The CLI migrates the matching old `/share/talon*` workspace automatically.
3. Restart Talon.
4. Verify with `talonctl status` and `talonctl list-skills --persona assistant`.

The old `/share` copy is left intact as a fallback.

## CLI control IPC

Only the transient daemon IPC directory is shared through the isolated workspace so `talonctl status` and `talonctl reload` continue to work. Talon upstream itself is not modified.
