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

Version 0.7.1 removes `/share` entirely. It also cleans up the old pre-0.7 IPC symlink that pointed from `/data/talon/state/ipc/daemon` into `/share`, recreating the IPC directory locally and writable. External files such as transcripts must now be accessed through explicitly configured MCP servers.

## Video delivery (0.8.1)

The wrapper overlays three attachment modules from this fork onto the upstream
runtime at build time. The upstream base image is pinned by digest as well; update
it deliberately together with compatibility verification. Downloads are pinned to a commit and hash-checked; a failed
download or changed source aborts the build. The local app build context is sufficient.
When updating these modules, update the pinned revision and installer hashes together.

Existing private configurations are preserved. To enable requested file delivery,
add `channel.send:personal-telegram` to the assistant persona's `capabilities.allow`
list in its private `talond.yaml` (substitute your configured channel name). Keep
existing entries and reload with `talonctl reload`. The capability also exposes
channel discovery and broadcast tools; instruct the persona to use only the current
chat unless another recipient is explicitly requested. This is not a per-chat ACL.

For an explicit file request, obtain a short-lived HTTP(S) download URL from a
trusted file tool, then call `channel_send` with `attachments: [{url, filename,
mimeType: "video/mp4"}]`. Omit `externalChatId` for the current chat. Exporting alone
is not sending. Confirm delivery only after the tool succeeds. Test with one small
clip; the attachment handler accepts at most 50 MiB per file.
