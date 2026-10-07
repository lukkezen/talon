# Talon Home Assistant add-on

This wrapper runs the unmodified upstream Talon image on Home Assistant OS.

## Instance-aware workspace

The optional Home Assistant setting `instance` selects the workspace:

- empty: `/share/talon`
- `d66`: `/share/talon-instances/d66`
- `group`: `/share/talon-instances/group`

Use the same instance value in the Talon CLI add-on. This lets the same wrapper code be reused for multiple isolated Home Assistant add-on installations without changing upstream Talon.

Named instances bootstrap independently and never copy the default Talon workspace.
