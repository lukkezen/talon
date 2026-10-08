# Home Assistant startup regression (1.0.10)

## Problem and evidence

The reported 1.0.9 daemon and terminal are running, but Supervisor remains in
`startup` and does not expose the terminal UI. Both add-on Dockerfiles contain
`HEALTHCHECK NONE`. Docker serializes that as `Config.Healthcheck.Test=["NONE"]`.
Supervisor treats the nonempty healthcheck object as true when handling a
running container, so it waits for a health event that a disabled check cannot
produce. Daemon `READY` logging is not a Supervisor readiness signal.

Reference inspected: home-assistant/supervisor commit
`01b32d6d31125425260638f768980d35659c4874`,
`supervisor/apps/app.py` (`_derive_state`) and
`supervisor/docker/interface.py` (`healthcheck`). The deployed Supervisor
version/container metadata still need confirmation; do not equate source
analysis or Docker smoke tests with verification on the user's HA installation.

## Intended behavior and scope

Remove the explicit disabled Docker healthcheck from both node-based images.
The base image must have no inherited check (verify the built image, fail if
that assumption changes). Supervisor can then classify Docker `running` as
`started`; the recovery terminal remains available independently of daemon
configuration/provider authentication. Release add-on 1.0.10.

Preserve the gateway-only proxy on 7681, loopback-only ttyd on 7682, unprivileged
terminal/daemon, private storage and current start/stop behavior. Do not add
network privileges, publish terminal ports, admit other add-ons, or require an
OpenAI API key. No changes to main or upstream PRs #288–#291, no deployment,
no deletion/migration of existing configuration or databases.

## Acceptance criteria and verification plan

1. Reproduce the `NONE` metadata trap; the actual HA-context image has no
   `Config.Healthcheck`, and container `running` requires no health event.
2. Build `talon-haos/Dockerfile` with context `talon-haos/` for linux/amd64,
   inspect version 1.0.10 and run that exact image (not only Dockerfile.source).
3. A Docker ingress fixture with source IP 172.30.32.2 can fetch ttyd HTML and
   establish a tty WebSocket; another peer is denied, even with spoofed headers.
   These tests simulate ingress transport, not HA login/session validation.
4. Fresh empty options start the daemon without an API key; the generated YAML
   and a SQLite sentinel survive a restart of the same image. This checks restart
   persistence, not an upgrade of a user's pre-existing installation. Recovery terminal remains usable
   if the daemon cannot start. Relevant Codex CLI tests still pass.
5. Real HA validation requires read-only access to the target: record Supervisor
   version, add-on version/state, relevant container metadata and an authenticated
   ingress HTTP/WebSocket session. Never deploy automatically; if the fixed
   version is not installed by the operator, report this criterion unverified.

## Edge cases

Disabled versus missing healthchecks are distinct Docker configurations.
Listening sockets and log lines alone are not proof of an interactive terminal.
An unauthenticated Codex CLI may prevent AI requests, but must not prevent
management access. Proxy rejection must happen before reaching ttyd. Existing
workspaces and legacy state must remain authoritative across upgrades.

## Results

- Local regression: both Dockerfile assertions failed before the fix; all four
  add-on Node tests pass after it. Shell, JavaScript and Python syntax checks pass.
- Executed the pinned upstream Supervisor state method with stub model inputs:
  disabled metadata returns STARTUP; absent metadata returns STARTED.
- Independent GPT-6-sol review found an overbroad persistence claim; narrowed
  criterion 4 to the actual restart test. Upgrade preservation on user data is
  unverified. Runtime scripts and storage behavior are unchanged.
- Actual image build/transport tests and live HA validation are still pending.
