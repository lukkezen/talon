const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { install, hashes } = require('./install-video-support.cjs');

function fixture(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'talon-video-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  for (const name of Object.keys(hashes)) {
    const source = path.join(dir, 'src', name);
    const target = path.join(dir, 'dist', name.replace(/\.ts$/, '.js'));
    fs.mkdirSync(path.dirname(source), { recursive: true });
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(path.join(__dirname, '..', 'src', name), source);
    fs.writeFileSync(target, 'original');
  }
  // Tell Node's syntax checker these generated .js files are ESM.
  fs.writeFileSync(path.join(dir, 'package.json'), '{"type":"module"}');
  return dir;
}

test('installs all pinned attachment modules with valid JS syntax', t => {
  const dir = fixture(t);
  install(path.join(dir, 'src'), path.join(dir, 'dist'));
  for (const name of Object.keys(hashes)) {
    const file = path.join(dir, 'dist', name.replace(/\.ts$/, '.js'));
    execFileSync(process.execPath, ['--check', file]);
    assert.match(fs.readFileSync(file, 'utf8'), /attachments/);
  }
  assert.match(fs.readFileSync(path.join(dir, 'dist/channels/connectors/telegram/telegram-connector.js'), 'utf8'), /sendVideo/);
});

for (const failure of ['modified source', 'missing source']) {
  test(`${failure} leaves every runtime module unchanged`, t => {
    const dir = fixture(t);
    const last = Object.keys(hashes).at(-1);
    const file = path.join(dir, 'src', last);
    if (failure === 'modified source') fs.appendFileSync(file, '\n// changed\n');
    else fs.unlinkSync(file);
    assert.throws(() => install(path.join(dir, 'src'), path.join(dir, 'dist')));
    for (const name of Object.keys(hashes)) {
      assert.equal(fs.readFileSync(path.join(dir, 'dist', name.replace(/\.ts$/, '.js')), 'utf8'), 'original');
    }
  });
}
