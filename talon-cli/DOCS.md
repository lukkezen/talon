# Talon CLI add-on

Talon CLI 0.3.0 manages the isolated Talon daemon workspace.

The CLI intentionally keeps manual `share:rw` access and additionally mounts `all_app_configs:rw`. It locates the Talon daemon app config, exposes it locally as `/config`, and manages:

```text
/config/instances/default
/config/instances/<instance>
```

On first start, if a matching legacy workspace exists under `/share/talon` or `/share/talon-instances/<instance>`, it is copied into the isolated workspace. The legacy copy is retained.

After migration restart Talon, then normal upstream commands continue to work:

```sh
talonctl status
talonctl list-personas
talonctl list-skills --persona assistant
talonctl reload
```
