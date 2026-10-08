import { describe, expect, it } from 'vitest';
import { buildResponsesTools } from '../src/providers/openai-compatible/agent-cli/responses-api.js';

const schema = {
  type: 'object',
  properties: {
    source: { type: 'string', enum: ['Videoclipper', 'Transcripts'] },
    path: { type: 'string' },
    export_name: { type: 'string' },
  },
  required: ['source', 'path'],
};

describe('Mastra MCP JsonSchemaWrapper compatibility', () => {
  it('preserves required MCP tool arguments from Standard JSON Schema', () => {
    const wrapped = {
      '~standard': {
        version: 1,
        vendor: 'json-schema',
        jsonSchema: {
          input: ({ target }: { target: string }) => {
            expect(target).toBe('draft-07');
            return schema;
          },
        },
      },
    };
    const tools = buildResponsesTools({
      'ha-files_copy_to_export': {
        description: 'Export a file',
        inputSchema: wrapped,
      } as never,
    });
    expect(tools[0]?.parameters).toMatchObject(schema);
  });

  it('still supports plain JSON schemas', () => {
    const tools = buildResponsesTools({
      'ha-files_copy_to_export': {
        description: 'Export a file',
        inputSchema: schema,
      } as never,
    });
    expect(tools[0]?.parameters).toMatchObject(schema);
  });
});
