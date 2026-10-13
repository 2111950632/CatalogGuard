import { copyFile, mkdir, readFile } from 'node:fs/promises';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const source = join(root, '_build', 'js', 'release', 'build', 'cmd', 'main', 'main.js');
const bytes = await readFile(source);
await mkdir(join(root, 'dist'), { recursive: true });
await copyFile(source, join(root, 'dist', 'szs-core.js'));
console.log(JSON.stringify({ artifact: 'dist/szs-core.js', bytes: bytes.length,
  sha256: createHash('sha256').update(bytes).digest('hex') }, null, 2));
