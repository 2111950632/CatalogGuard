// A fixed workload with independently known findings; elapsed time is recorded,
// not used as a machine-dependent CI pass threshold.
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import assert from 'node:assert/strict';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const version = JSON.parse(readFileSync(resolve(root, 'package.json'), 'utf8')).version;
const header = 'msgid ""\nmsgstr "Language: zh_CN\\nContent-Type: text/plain; charset=UTF-8\\nPlural-Forms: nplurals=4; plural=(n%4);\\n"\n\n';
function catalog(first) {
  let text = header;
  for (let index = 0; index < 250; index++) {
    text += 'msgid ' + JSON.stringify('key ' + index) + '\nmsgid_plural ' + JSON.stringify('keys ' + index) + '\n';
    for (let slot = 0; slot < 4; slot++) text += `msgstr[${slot}] ` + JSON.stringify(first ? 'a'.repeat(4096) : 'short') + '\n';
    text += '\n';
  }
  return text;
}
const files = Array.from({ length: 31 }, (_, index) => ({ path: `${index}.po`, text: catalog(index === 0), template: false }));
const inputBytes = files.reduce((sum, file) => sum + Buffer.byteLength(file.text), 0);
assert.ok(inputBytes <= 32 * 1024 * 1024);
globalThis.__szsRequest = JSON.stringify({ files, quality: { consistency: { enabled: true } } });
const started = performance.now();
await import(pathToFileURL(resolve(root, '_build/js/release/build/cmd/main/main.js')).href);
const elapsed = Math.round(performance.now() - started);
const response = JSON.parse(globalThis.__szsResponse);
assert.equal(response.exit_code, 0); // Review warnings remain nonfatal by default.
const findings = response.data.project_findings;
assert.equal(findings.length, 7500);
for (const finding of findings) {
  assert.equal(finding.diagnostic.code, 'X002');
  assert.equal(finding.related.file, '0.po');
  assert.notEqual(finding.diagnostic.file, finding.related.file);
}
const result = { schema_version: 1, version, files: 31, entries_per_file: 250, plural_slots: 4,
  original_chars_per_slot: 4096, input_bytes: inputBytes, findings: findings.length,
  expected_findings: 7500, correctness_passed: true, milliseconds: elapsed,
  rss_after_response_bytes: process.memoryUsage().rss,
  note: 'One deterministic workload, not a general performance guarantee or a peak-memory measurement.' };
const output = resolve(root, process.argv[2] || 'evidence/local/project-performance.json');
mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result));
