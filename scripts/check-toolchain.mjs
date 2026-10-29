import { execFileSync } from 'node:child_process';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const minimumMoonc = '0.10.16';

export function moonExecutable() {
  return process.env.SZS_MOON || (process.env.MOON_HOME
    ? join(process.env.MOON_HOME, 'bin', process.platform === 'win32' ? 'moon.exe' : 'moon') : 'moon');
}

// Inspect moonc reported by the selected moon, not the unrelated moon CLI version.
// Unknown or prerelease spellings require explicit review rather than passing silently.
export function checkMooncVersion(output) {
  const matches = [...output.matchAll(/^moonc\s+v?(\d+)\.(\d+)\.(\d+)(?:\+[0-9A-Za-z.-]+)?(?=\s|$)/gm)];
  if (matches.length !== 1) throw new Error('Cannot identify one stable moonc version from moon version --all.');
  const version = matches[0].slice(1).map(Number);
  if (!version.every(Number.isSafeInteger)) throw new Error('Invalid moonc version number.');
  const minimum = minimumMoonc.split('.').map(Number);
  const firstDifference = version.findIndex((part, index) => part !== minimum[index]);
  if (firstDifference !== -1 && version[firstDifference] < minimum[firstDifference]) {
    throw new Error(`moonc ${version.join('.')} is below the required ${minimumMoonc}; update the MoonBit toolchain.`);
  }
  return version.join('.');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const output = execFileSync(moonExecutable(), ['version', '--all'], { encoding: 'utf8', timeout: 15000 });
    const version = checkMooncVersion(output);
    process.stdout.write(output);
    console.log(`Compiler requirement passed: moonc ${version} >= ${minimumMoonc}.`);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
