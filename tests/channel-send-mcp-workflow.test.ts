import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

// Guard the HA runtime's tool instructions against regressions in the
// export-to-Telegram workflow. The host MCP server is deployed as an overlay.
const toolSource = readFileSync(
  new URL('../src/tools/host-tools-mcp-server.ts', import.meta.url),
  'utf8',
);

describe('channel_send attachment workflow instructions', () => {
  it('targets the current Telegram thread without requiring a chat ID', () => {
    expect(toolSource).toContain('OMIT externalChatId');
    expect(toolSource).toContain('current conversation thread chat ID');
    expect(toolSource).toContain('Never call channel_list or channel_broadcast to reply to a single chat');
  });
  it('uses a fresh export URL rather than a list_exports path', () => {
    expect(toolSource).toContain('first call copy_to_export');
    expect(toolSource).toContain('list_exports only lists paths');
    expect(toolSource).toContain('Do not expose signed URLs in chat');
  });
});
