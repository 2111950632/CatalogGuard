import { spawnSync } from 'node:child_process';
import { writeFileSync, mkdirSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const moon = process.env.SZS_MOON || (process.env.MOON_HOME
  ? join(process.env.MOON_HOME, 'bin', process.platform === 'win32' ? 'moon.exe' : 'moon') : 'moon');
const python = process.env.SZS_PYTHON || (process.platform === 'win32' ? 'python' : 'python3');
const independent = process.argv.includes('--independent');
const steps = [
  [moon, ['check', '--target', 'all', '--deny-warn']],
  [moon, ['test', '--target', 'js', '--deny-warn']],
  [moon, ['test', '--target', 'wasm-gc', '--deny-warn']],
  [moon, ['fmt', '--check']],
  [moon, ['info']],
  [process.execPath, ['--test', 'tests/interfaces.mjs']],
  [process.execPath, ['scripts/check-interfaces.mjs']],
  [moon, ['build', '--target', 'js', '--release', '--deny-warn']],
  [process.execPath, ['--test', 'tests/integration.mjs']],
  [process.execPath, ['scripts/check-generated-quality.mjs']],
  [moon, ['package']],
  [python, ['scripts/check-consumer.py', '--moon', moon]],
];
if (independent) {
  steps.push([process.execPath, ['scripts/fetch-fixtures.mjs']]);
  steps.push([python, ['tests/oracle.py', 'tests/external/moonbit-docs-0.po', 'tests/external/moonbit-docs-1.po', '--gnu']]);
  steps.push([python, ['tests/format_conformance.py']]);
  steps.push([python, ['tests/quality_oracle.py']]);
  steps.push([process.execPath, ['scripts/benchmark-project.mjs']]);
}
const results = [];
for (const [program, args] of steps) {
  process.stdout.write(`\nChecking: ${args.join(' ')}\n`);
  const started = Date.now();
  const result = spawnSync(program, args, { cwd: root, stdio: 'inherit', timeout: 180000 });
  results.push({ command: [program, ...args], exit_code: result.status, milliseconds: Date.now() - started });
  if (result.error || result.status !== 0) {
    process.stderr.write((result.error?.message || 'Verification stopped at the failing step.') + '\n');
    process.exit(result.status || 2);
  }
}
mkdirSync(join(root, 'evidence', 'local'), { recursive: true });
writeFileSync(join(root, 'evidence', 'local', 'verification.json'), JSON.stringify({ schema_version: 1, completed_at: new Date().toISOString(), independent, steps: results }, null, 2) + '\n');
process.stdout.write('\nAll selected verification steps passed.\n');
