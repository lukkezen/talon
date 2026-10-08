# Talon fork integration plan

Status: work-in-progress. This file is deliberately on `integration/custom`, not on production `main`.

## Immutable upstream baseline (2026-10-08)
- Upstream: `ivo-toby/talon` / `main`, commit `32fbf4507a9e85a324f1ec8bce02804471f9142e`.
- `integration/upstream` holds this source baseline; refresh only after reviewing new upstream changes.
- `integration/custom` started as a snapshot of the existing fork `main`. It is **not yet** a rebuilt clean patch stack.

## Protected external pull requests (DO NOT change their heads automatically)
- #288 MCP Standard JSON Schema: `92e6bc9bf27a2f16699ea71186254ec3bd2d873b` (`upstream/fix-mcp-standard-json-schema`)
- #289 outbound attachments: `b1ba1c9c62eb7742ac00d15693a6393c243e54cd` (`upstream/feat-channel-send-attachments`)
- #290 Telegram aliases: `5e142efb9af2502b829ed322dba43b41938ce41a` (`upstream/fix-telegram-channel-routing`)
- #291 HAOS add-on: `affaba9a921b56c2c0919da8544d2652beed6c4b` (`upstream/feat-home-assistant-addon`)

Keep all four PR source branches, SHAs, commits and PR metadata unchanged. Never force push, rebase, squash or auto-merge these branches. Integrate via copies/cherry-picks into disposable integration branches, not by editing originals. If a PR gets merged upstream, remove only its duplicate local application at the **next** integration rebuild.

## Desired layer order
1. Fresh upstream `main`, pinned to a reviewed commit.
2. PR #288 (MCP), #289 (attachments), #290 (Telegram), #291 (HAOS). Apply independently and check for overlapping changes.
3. Unsubmitted local functionality: Codex `CODEX_HOME`, process environment isolation, Codex test timeout and stdin EOF, plus required tests; any HAOS-only improvements are kept separate.
4. Private deployment config: workspace, personas, bot tokens and `auth.json` remain outside Git. Do not include credentials in commits, PRs, logs or documentation.

## Outstanding technical blockers
- Existing HAOS Dockerfile uses a moving `ghcr.io/ivo-toby/talond:latest` plus TS overlays from older pinned commits; the resulting runtime does not necessarily match the assembled source tree.
- `talon-haos/run.sh` requires `openai_api_key` even for Codex CLI-only use.
- Existing long Telegram responses can exceed platform length limits; automatic chunking with safe retries is not implemented.
- Validate fork-specific provider fixes before submitting a fifth PR upstream.

## Integration acceptance criteria
- No direct edits to upstream PR branches or `main` until explicit review.
- Capture exact upstream commit, fork patches, build image digest and integration commit.
- Run unit tests for #288, #289, #290 and Codex. Confirm add-on builds, persistence, Telegram routing, attachment delivery and Codex login survive restart.
- Use immutable source/image pins, no floating `latest` for deployed artifacts.
- Manual release/merge after tests; never overwrite production workspace.
