import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { canonicalInterface, compareInterfaces, checkInterfaces } from '../scripts/check-interfaces.mjs';

const sample = 'pub fn f(Int, budget? : Int) -> Result[Array[Int], String]\n'
  + 'pub(all) struct Limits {\n  count : Int\n  other : Int?\n}\n'
  + 'pub(all) enum Value {\n  Constant(Int)\n}\n';

test('accepts builtin Int/Int32 only, including fields, arrays and optional types', () => {
  assert.equal(canonicalInterface(sample), sample.replaceAll(/\bInt\b/g, 'Int32'));
  assert.equal(canonicalInterface(sample.replaceAll('\n', '\r\n')), canonicalInterface(sample));
  assert.equal(canonicalInterface('pub fn f() -> Int\n'), 'pub fn f() -> Int32\n');
  assert.equal(canonicalInterface('pub fn f() -> Int'), 'pub fn f() -> Int32');
});

test('accepts the exact Linux CI spelling change in the actual committed API', () => {
  const actual = readFileSync(new URL('../pkg.generated.mbti', import.meta.url), 'utf8');
  const oldSpelling = actual.replaceAll(/\bInt32\b/g, 'Int');
  assert.match(oldSpelling, /\bInt\b/);
  assert.equal(canonicalInterface(oldSpelling), canonicalInterface(oldSpelling.replaceAll(/\bInt\b/g, 'Int32')));
});

test('rejects changed widths, removed fields, changed signatures and added exports', () => {
  for (const changed of [sample.replace('count : Int', 'count : Int64'), sample.replace('  count : Int\n', ''),
    sample.replace('budget?', 'limit?'), sample + 'pub fn extra() -> Bool\n']) {
    assert.notEqual(canonicalInterface(sample), canonicalInterface(changed));
  }
});

test('does not rewrite strings, comments, identifiers or qualified types', () => {
  for (const text of ['// Int\npub fn f() -> String\n', '/* Int */\n',
    'package "Int"\n', 'pub const value : String = "Int \\\" test"\n',
    'pub fn Int() -> Bool\n', 'pub fn f(@other.Int) -> @other.Int\n',
    'pub fn Int::f() -> Bool\n', 'pub(all) struct X {\n  Int : String\n}\n']) {
    assert.equal(canonicalInterface(text), text);
    assert.notEqual(canonicalInterface(text), canonicalInterface(text.replaceAll(/\bInt\b/g, 'Int32')));
  }
});

test('fails closed for custom types, generic binders and using declarations', () => {
  for (const text of ['pub type Int\npub fn f(Int) -> Int\n',
    'pub typealias Int32 = Int64\npub fn f(Int) -> Int\n',
    'pub fn[Int] f(Int) -> Int\n', 'pub impl[Int] Trait for X with f(Int) -> Int\n',
    'pub fn f[Int](Int) -> Int\n', 'pub fn X::f[Int](Int) -> Int\n',
    'pub struct X[Int] { value : Int }\n', 'pub using @other { type Int }\n']) {
    assert.equal(canonicalInterface(text), text);
    assert.notEqual(canonicalInterface(text), canonicalInterface(text.replaceAll(/\bInt\b/g, 'Int32')));
  }
});

test('detects missing and added interface files', () => {
  const before = new Map([['a.mbti', sample]]);
  assert.deepEqual(compareInterfaces(before, new Map()), ['a.mbti']);
  assert.deepEqual(compareInterfaces(before, new Map([...before, ['b.mbti', '']])), ['b.mbti']);
});

test('checks HEAD, staged and untracked files, paths with spaces, and missing files', () => {
  const root = mkdtempSync(join(tmpdir(), 'catalogguard-interface-'));
  const git = process.env.SZS_GIT || 'git';
  const run = args => execFileSync(git, args, { cwd: root, stdio: 'pipe' });
  try {
    run(['init', '--quiet']);
    mkdirSync(join(root, 'path with spaces'));
    const path = join(root, 'path with spaces', 'pkg.generated.mbti');
    writeFileSync(path, sample);
    run(['add', '.']);
    run(['-c', 'user.name=Interface Test', '-c', 'user.email=test@example.invalid', 'commit', '--quiet', '-m', 'fixture']);
    writeFileSync(path, sample.replaceAll(/\bInt\b/g, 'Int32'));
    assert.equal(checkInterfaces(root, git), 1);
    writeFileSync(path, sample.replace('count : Int', 'count : Int64'));
    run(['add', '.']);
    assert.throws(() => checkInterfaces(root, git), /interfaces differ/);
    writeFileSync(path, sample);
    const extra = join(root, 'extra.mbti');
    writeFileSync(extra, '');
    assert.throws(() => checkInterfaces(root, git), /extra.mbti/);
    rmSync(extra);
    rmSync(path);
    assert.throws(() => checkInterfaces(root, git), /path with spaces/);
  } finally { rmSync(root, { recursive: true, force: true }); }
});
