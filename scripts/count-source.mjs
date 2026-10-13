import { readdir, readFile } from 'node:fs/promises';
import { resolve, join, relative, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const ignored = new Set(['.git', '_build', '.mooncakes', 'node_modules', 'dist', 'external', 'work', 'evidence']);
const files = [];
async function walk(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory() && !ignored.has(entry.name)) await walk(path);
    else if (entry.isFile() && entry.name.endsWith('.mbt')) files.push(path);
  }
}
await walk(root);
const groups = { production: [], tests: [] };
for (const path of files.sort()) {
  const lines = (await readFile(path, 'utf8')).split(/\r?\n/);
  if (lines.at(-1) === '') lines.pop();
  const category = /(?:_test|_wbtest)\.mbt$/.test(path) ? 'tests' : 'production';
  groups[category].push({ file: relative(root, path).replaceAll('\\', '/'), total: lines.length,
    nonblank_noncomment: lines.filter(line => line.trim() && !line.trimStart().startsWith('//')).length });
}
const totals = Object.fromEntries(Object.entries(groups).map(([name, values]) => [name, {
  files: values.length, total: values.reduce((n, f) => n + f.total, 0),
  nonblank_noncomment: values.reduce((n, f) => n + f.nonblank_noncomment, 0),
}]));
console.log(JSON.stringify({ method: 'Nonempty lines excluding whole-line // comments; includes structural syntax. Not an organizer-certified effective-line count. Tests, generated interfaces, external fixtures and host JS are separate.', totals, files: groups }, null, 2));
