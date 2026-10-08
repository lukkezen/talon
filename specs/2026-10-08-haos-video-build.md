# Home Assistant video delivery build

## Problem
The Home Assistant wrapper uses the upstream image, which lacks this fork's existing attachment implementations. A local deployment fix would be overwritten by a source sync.

## Behavior and scope
Package the three attachment modules from the already-tested fork revision 8ad2cdeb997a3978aff2389839175ab3158cdb65 into the Home Assistant image. Pin the upstream base image digest as well as the overlay revision. Use pinned, hash-verified source and Node 24's TypeScript transform. Keep the upstream dependencies and other modules. Preserve existing private configuration and capability defaults; document the opt-in channel.send permission and delivery workflow. Release wrapper 0.8.1.

## Acceptance and verification
1. A build installs the channel.send handler, MCP attachment schema and Telegram video connector. Check transformed output and syntax against current repository sources.
2. Missing or changed source fails before modifying runtime files. Test hash mismatch and missing-file cases in a temporary directory.
3. Existing private workspaces and permissions are not migrated or broadened. Review run.sh remains unchanged; document channel-specific permission.
4. Build fix is committed on main, making it available to source sync. Verify remote commit after push.

## Edge cases and non-goals
Build requires access to pinned GitHub raw source. Fail closed on unavailable downloads or hash mismatch. Future changes to these modules require deliberately updating the revision and hashes. Do not upload deployment credentials or private persona data. Do not change the core daemon or other connectors. Actual Telegram delivery remains a separate user-chat verification; technical runtime and mock upload tests already passed on the local deployment.

## Verification result
`node --test talon-haos/install-video-support.test.cjs` passes all three tests: complete installation with JS syntax checks, modified-source rejection and missing-source rejection without runtime writes. `git diff --check` passes. `run.sh` is unchanged, preserving private configuration and permission defaults. The equivalent three-module overlay was previously rebuilt and started successfully on D66; this revised Docker download step has not been rebuilt on the live instance. Remote main verification is performed after committing and pushing.
