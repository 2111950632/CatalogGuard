import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(await readFile(join(root, 'tests', 'fixtures.json'), 'utf8'));
const destination = join(root, 'tests', 'external');
await mkdir(destination, { recursive: true });
for (const fixture of manifest.fixtures) {
  const path = join(destination, fixture.name);
  try {
    const cached = await readFile(path);
    if (createHash('sha256').update(cached).digest('hex') === fixture.sha256) {
      console.log(`Verified cached fixture: ${fixture.name}, ${cached.length} bytes`);
      continue;
    }
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
  const response = await fetch(fixture.url, { signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`${response.status}: ${fixture.url}`);
  const bytes = Buffer.from(await response.arrayBuffer());
  const digest = createHash('sha256').update(bytes).digest('hex');
  if (digest !== fixture.sha256) throw new Error(`Fixture checksum mismatch: ${fixture.name}`);
  await writeFile(path, bytes);
  console.log(`Verified fixture: ${fixture.name}, ${bytes.length} bytes`);
}
