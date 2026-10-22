#!/usr/bin/env node
import { writeFile, stat, readdir } from 'node:fs/promises';
import { createReadStream } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const help = `CatalogGuard 0.2.2 — MoonBit PO/POT checker

Usage: node cli.mjs [check|inspect|normalize|stats] FILE... [options]
       node cli.mjs plural 'nplurals=2; plural=(n!=1);' [options]
       node cli.mjs rules [--json]

Options:
  --json                  Print schema-versioned JSON
  --strict                Fail when warnings are present
  --template FILE.pot     Compare exact keys against a POT template
  --pot                   Treat all inputs as templates
  --config FILE.json      Read options and review-rule policies
  --markup MODE           Check balanced markup fragments: html, xml, or off
  --consistency           Compare translations across files in the same locale
  --ignore-context        Include different contexts in consistency groups
  --inverse-consistency   Review different sources sharing one translation
  --recursive             Read PO/POT files from input directories recursively
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
const request = { command: 'check', files: [], options: {}, quality: {} };
const inputPaths = [];
const optionEnd = args.indexOf('--');
const optionArgs = args.slice(0, optionEnd < 0 ? args.length : optionEnd);
let json = optionArgs.includes('--json');
let pot = false;
let templatePath;
let configPath;
let outputPath;
let endOptions = false;
let recursive = false;
const maxBytes = 32 * 1024 * 1024;
let totalBytes = 0;

function takeValue(index, option) {
  if (index + 1 >= args.length) throw new Error(`${option} requires a value`);
  return args[index + 1];
}

async function readUtf8(path) {
  const stream = path === '-' ? process.stdin : createReadStream(resolve(path));
  const chunks = [];
  for await (const chunk of stream) {
    totalBytes += chunk.length;
    if (totalBytes > maxBytes) throw new Error('Input total exceeds 32 MiB');
    chunks.push(chunk);
  }
  const bytes = Buffer.concat(chunks);
  return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
}

async function expandInput(path, depth = 0) {
  if (path === '-') return [path];
  if (depth > 32) throw new Error('Directory traversal exceeds depth 32');
  const info = await stat(resolve(path));
  if (!info.isDirectory()) return [path];
  if (!recursive) throw new Error('Directory input requires --recursive');
  const entries = (await readdir(resolve(path), { withFileTypes: true })).sort((a,b) => a.name < b.name ? -1 : a.name > b.name ? 1 : 0);
  const files = [];
  for (const entry of entries) {
    if (entry.isSymbolicLink() || ['.git','node_modules','_build','.mooncakes'].includes(entry.name)) continue;
    if (entry.isDirectory()) files.push(...await expandInput(join(path,entry.name), depth+1));
    else if (entry.isFile() && /\.pot?$/i.test(entry.name)) files.push(join(path,entry.name));
    if (files.length > 1000) throw new Error('A request supports at most 1000 files');
  }
  return files;
}

try {
  if (optionArgs.includes('--help') || optionArgs.includes('-h') || args.length === 0) {
    process.stdout.write(help);
    process.exit(0);
  }
  if (optionArgs.includes('--version')) {
    process.stdout.write('szs 0.2.2\n');
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
      if (arg === '--recursive') { recursive = true; continue; }
      if (arg === '--consistency') { request.quality.consistency = { ...request.quality.consistency, enabled: true }; continue; }
      if (arg === '--ignore-context' || arg === '--inverse-consistency') {
        request.quality.consistency = { ...request.quality.consistency, enabled: true, [arg === '--ignore-context' ? 'ignore_context' : 'inverse']: true }; continue;
      }
      const value = takeValue(i, arg);
      if (arg === '--template') templatePath = value;
      else if (arg === '--config') configPath = value;
      else if (arg === '--output') outputPath = value;
      else if (arg === '--markup') request.quality.markup = { mode: value };
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
    if (inputPaths.filter(path => path === '-').length > 1) throw new Error('stdin may be read only once');
    const expanded = [];
    for (const path of inputPaths) {
      expanded.push(...await expandInput(path));
      if (expanded.length > 1000) throw new Error('A request supports at most 1000 files');
    }
    const seen = new Set();
    for (const path of expanded) {
      const identity = path === '-' ? '-' : resolve(path);
      if (seen.has(identity)) throw new Error('Duplicate input path: ' + path);
      seen.add(identity);
      request.files.push({ path, text: await readUtf8(path), template: pot || /\.pot$/i.test(path) });
    }
  }
  if (templatePath) request.reference = { path: templatePath, text: await readUtf8(templatePath) };
  if (configPath) request.config = await readUtf8(configPath);

  const root = dirname(fileURLToPath(import.meta.url));
  const candidates = [
    join(root, '_build', 'js', 'release', 'build', 'cmd', 'main', 'main.js'),
    join(root, '_build', 'js', 'debug', 'build', 'cmd', 'main', 'main.js'),
    join(root, 'dist', 'szs-core.js'),
  ];
  const builds = [];
  for (const candidate of candidates.slice(0, 2)) {
    try {
      const info = await stat(candidate);
      if (info.isFile()) builds.push({ path: candidate, modified: info.mtimeMs });
    } catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  builds.sort((a, b) => b.modified - a.modified);
  let corePath = builds[0]?.path;
  if (!corePath) {
    try { if ((await stat(candidates[2])).isFile()) corePath = candidates[2]; }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  if (!corePath) throw new Error('MoonBit core is not built. Run: moon build --target js --release');
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
