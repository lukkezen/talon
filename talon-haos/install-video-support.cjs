// Pinned fork overlay for the upstream runtime used by the HA build.
const fs = require('node:fs');
const path = require('node:path');
const { createHash } = require('node:crypto');
const { stripTypeScriptTypes } = require('node:module');
const hashes = {
  "tools/host-tools/channel-send.ts": "b05d03609152831058aa712368e3a19ef751ab16dd56876e006e9447a09e4e5a",
  "tools/host-tools-mcp-server.ts": "e6c651076c077678412791cdd437adc9a41efca83a20af818c45a9c7045a10b2",
  "channels/connectors/telegram/telegram-connector.ts": "dd557ae49bf0601104f02d8458ba518a953c05b8afbb934970b212a292b5883d"
};
function install(sourceRoot, runtimeRoot) {
  // Validate and transform every file before touching runtime files.
  const outputs = Object.entries(hashes).map(([name, expected]) => {
    const source = fs.readFileSync(path.join(sourceRoot, name), 'utf8').replace(/\r\n/g, '\n');
    const actual = createHash('sha256').update(source).digest('hex');
    if (actual !== expected) throw new Error(`Video source hash mismatch: ${name}`);
    const target = path.join(runtimeRoot, name.replace(/\.ts$/, '.js'));
    if (!fs.statSync(target).isFile()) throw new Error(`Missing runtime module: ${target}`);
    return [target, stripTypeScriptTypes(source, { mode: 'transform' })];
  });
  for (const [target, code] of outputs) fs.writeFileSync(target, code);
}
module.exports = { install, hashes };
if (require.main === module) install(process.argv[2], process.argv[3]);
