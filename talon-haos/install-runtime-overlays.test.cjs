const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { install, modules } = require('./install-runtime-overlays.cjs');

test('install processes all four runtime modules', (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'talon-overlays-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const sourceRoot = path.join(root, 'src');
  const runtimeRoot = path.join(root, 'runtime');
  for (const name of modules) {
    fs.mkdirSync(path.dirname(path.join(sourceRoot, name + '.ts')), { recursive: true });
    fs.mkdirSync(path.dirname(path.join(runtimeRoot, name + '.js')), { recursive: true });
    fs.writeFileSync(path.join(sourceRoot, name + '.ts'), 'export const enabled: boolean = true;');
    fs.writeFileSync(path.join(runtimeRoot, name + '.js'), 'old');
  }
  install(sourceRoot, runtimeRoot);
  for (const name of modules) {
    assert.match(fs.readFileSync(path.join(runtimeRoot, name + '.js'), 'utf8'), /enabled/);
  }
});

test('invalid source leaves the existing runtime unchanged', (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'talon-overlay-reject-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const sourceRoot = path.join(root, 'src');
  const runtimeRoot = path.join(root, 'runtime');
  for (const name of modules) {
    fs.mkdirSync(path.dirname(path.join(sourceRoot, name + '.ts')), { recursive: true });
    fs.mkdirSync(path.dirname(path.join(runtimeRoot, name + '.js')), { recursive: true });
    fs.writeFileSync(path.join(sourceRoot, name + '.ts'), 'export const ok: boolean = true;');
    fs.writeFileSync(path.join(runtimeRoot, name + '.js'), 'original');
  }
  fs.unlinkSync(path.join(sourceRoot, modules.at(-1) + '.ts'));
  assert.throws(() => install(sourceRoot, runtimeRoot));
  for (const name of modules) {
    assert.equal(fs.readFileSync(path.join(runtimeRoot, name + '.js'), 'utf8'), 'original');
  }
});
