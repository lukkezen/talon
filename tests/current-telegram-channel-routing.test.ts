import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const channelSend = readFileSync(new URL('../src/tools/host-tools/channel-send.ts', import.meta.url), 'utf8');

describe('current Telegram channel routing', () => {
  it('accepts the model Telegram alias only for the current registered Telegram conversation', () => {
    expect(channelSend).toContain("channelId === 'telegram' && !args.externalChatId");
    expect(channelSend).toContain("!origin.value.external_id.startsWith('schedule:')");
    expect(channelSend).toContain("currentChannel.value?.type === 'telegram'");
    expect(channelSend).toContain('channelId = currentChannel.value.name;');
  });
  it('retains the existing explicit recipient and scheduled origin rules', () => {
    expect(channelSend).toContain('args.externalChatId ?? originExternalId');
    expect(channelSend).toContain('channel.send: no recipient chat id');
  });
});
