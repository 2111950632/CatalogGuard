#!/usr/bin/env node
import { readFile, writeFile, access } from 'node:fs/promises';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const help = `SZS CatalogGuard 0.1.0 — MoonBit PO/POT checker

Usage: node cli.mjs [check|inspect|normalize|stats] FILE... [options]
       node cli.mjs plural 'nplurals=2; plural=(n!=1);' [options]
       node cli.mjs rules [--json]

Options:
  --json                  Print schema-versioned JSON
  --strict                Fail when warnings are present
  --template FILE.pot     Compare exact keys against a POT template
  --pot                   Treat all inputs as templates
  --config FILE.json      Read options and review-rule policies
  --plural-max N          Test plural counts from 0 through N (default 1000)
  --empty-severity LEVEL  error, warning, or info (default warning)
  --fuzzy-severity LEVEL  error, warning, or info (default warning)
  --output FILE           Write output to a new file; refuses to overwrite
  --                      End options; '-' reads UTF-8 from stdin
  --help, --version       Show help or version

Exit: 0 accepted by policy, 1 findings failed policy, 2 invocation/IO error.
Only UTF-8 catalogs are supported. Format flags select format checking.
`;

const commands = new Set(['check', 'inspect', 'normalize', 'stats', 'plural', 'rules']);
const args = process.argv.slice(2);
const request = { command: 'check', files: [], options: {} };
const inputPaths = [];
let json = false;
let pot = false;
let templatePath;
let configPath;
let outputPath;
let endOptions = false;
const maxBytes = 32 * 1024 * 1024;
let totalBytes = 0;

function takeValue(index, option) {
  if (index + 1 >= args.length) throw new Error(`${option} requires a value`);
  return args[index + 1];
}

async function readUtf8(path) {
  const bytes = await readFile(path === '-' ? 0 : resolve(path));
  totalBytes += bytes.length;
  if (totalBytes > maxBytes) throw new Error('Input total exceeds 32 MiB');
  return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
}

try {
  if (args.includes('--help') || args.includes('-h') || args.length === 0) {
    process.stdout.write(help);
    process.exit(0);
  }
  if (args.includes('--version')) {
    process.stdout.write('szs 0.1.0\n');
    process.exit(0);
  }
  if (commands.has(args[0])) request.command = args.shift();
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (!endOptions && arg === '--') { endOptions = true; continue; }
    if (!endOptions && arg.startsWith('--')) {
      if (arg === '--json') { json = true; continue; }
      if (arg === '--strict') { request.options.strict = true; continue; }
      if (arg === '--pot') { pot = true; continue; }
      const value = takeValue(i, arg);
      if (arg === '--template') templatePath = value;
      else if (arg === '--config') configPath = value;
      else if (arg === '--output') outputPath = value;
      else if (arg === '--plural-max') {
        if (!/^\d+$/.test(value)) throw new Error('--plural-max requires an integer');
        request.options.plural_max = Number(value);
      } else if (arg === '--empty-severity') request.options.empty_severity = value;
      else if (arg === '--fuzzy-severity') request.options.fuzzy_severity = value;
      else throw new Error(`Unknown option: ${arg}`);
      i++;
    } else inputPaths.push(arg);
  }
  if (request.command === 'plural') {
    if (inputPaths.length !== 1) throw new Error('plural requires one quoted rule');
    request.rule = inputPaths[0];
  } else if (request.command === 'rules') {
    if (inputPaths.length) throw new Error('rules accepts no input files');
  } else {
    for (const path of inputPaths) {
      request.files.push({ path, text: await readUtf8(path), template: pot || /\.pot$/i.test(path) });
    }
  }
  if (templatePath) request.reference = { path: templatePath, text: await readUtf8(templatePath) };
  if (configPath) request.config = await readUtf8(configPath);

  const root = dirname(fileURLToPath(import.meta.url));
  let corePath = join(root, 'dist', 'szs-core.js');
  try { await access(corePath); } catch {
    corePath = join(root, '_build', 'js', 'release', 'build', 'cmd', 'main', 'main.js');
    try { await access(corePath); } catch {
      corePath = join(root, '_build', 'js', 'debug', 'build', 'cmd', 'main', 'main.js');
      try { await access(corePath); } catch {
        throw new Error('MoonBit core is not built. Run: moon build --target js --release');
      }
    }
  }
  globalThis.__szsRequest = JSON.stringify(request);
  await import(pathToFileURL(corePath).href);
  if (typeof globalThis.__szsResponse !== 'string') throw new Error('MoonBit core returned no response');
  const response = JSON.parse(globalThis.__szsResponse);
  const output = json ? JSON.stringify(response.data, null, 2) + '\n' : response.text;
  if (outputPath && response.exit_code !== 2) await writeFile(resolve(outputPath), output, { flag: 'wx', encoding: 'utf8' });
  else process.stdout.write(output);
  process.exitCode = response.exit_code;
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  if (json) process.stdout.write(JSON.stringify({ schema_version: 1, exit_code: 2, error: message }, null, 2) + '\n');
  else process.stderr.write(`szs: ${message}\n`);
  process.exitCode = 2;
}
