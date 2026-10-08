// Install compatibility modules from immutable, Dockerfile-pinned Talon source revisions.
const fs = require('node:fs');
const path = require('node:path');
const { stripTypeScriptTypes } = require('node:module');
const modules = [
  'tools/host-tools/channel-send',
  'tools/host-tools-mcp-server',
  'channels/connectors/telegram/telegram-connector',
  'providers/openai-compatible/agent-cli/responses-api',
  'providers/codex-cli-provider',
  'cli/commands/test-provider',
];
function install(sourceRoot, runtimeRoot) {
  // Transform all modules before touching the runtime.
  const outputs = modules.map((name) => {
    const src = fs.readFileSync(path.join(sourceRoot, name + '.ts'), 'utf8');
    const destination = path.join(runtimeRoot, name + '.js');
    if (!fs.statSync(destination).isFile()) throw new Error('Missing runtime module: ' + destination);
    return [destination, stripTypeScriptTypes(src, { mode: 'transform' })];
  });
  for (const [destination, code] of outputs) fs.writeFileSync(destination, code);
}
module.exports = { install, modules };
if (require.main === module) install(process.argv[2], process.argv[3]);
