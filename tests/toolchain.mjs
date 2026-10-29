import test from 'node:test';
import assert from 'node:assert/strict';
import { checkMooncVersion } from '../scripts/check-toolchain.mjs';

test('accepts the required compiler and later releases with real output shapes', () => {
  for (const version of ['0.10.16', '0.10.17', '0.11.0', '1.0.0']) {
    const output = `moon 0.1.20261021 (a4f8933) /path/moon\r\nmoonc v${version}+093cb8f9c (2026-10-21) /path/moonc\r\nmoonrun 0.1.20261021\r\n`;
    assert.equal(checkMooncVersion(output), version);
  }
  assert.equal(checkMooncVersion('moonc 0.10.16'), '0.10.16');
});

test('rejects older compilers even when the moon CLI date is newer', () => {
  for (const version of ['0.10.15', '0.9.99', '0.1.20261029']) {
    assert.throws(() => checkMooncVersion(`moon 0.1.20261029\nmoonc v${version}+abc123\n`), /below the required 0\.10\.16/);
  }
});

test('fails closed for absent, ambiguous, malformed and prerelease versions', () => {
  for (const output of ['', 'moon 0.1.20261021\nmoonrun 0.1.20261021', 'warning: moonc v0.10.17',
    'moonc v0.10.17-nightly', 'moonc v0.10', 'moonc v0.10.16.1', 'moonc v0.10.17\nmoonc v0.10.15',
    'moonc v999999999999999999999999.0.0']) {
    assert.throws(() => checkMooncVersion(output), /Cannot identify|Invalid moonc/);
  }
});
