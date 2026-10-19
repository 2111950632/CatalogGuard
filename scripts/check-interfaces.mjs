import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// MoonBit documents Int as an accepted alias of Int32. Only this spelling
// difference in unqualified type positions is accepted; everything else stays
// byte-for-byte significant (apart from CRLF). This is a repository gate, not
// a general MoonBit parser or an API compatibility checker.
// https://docs.moonbitlang.com/en/latest/language/fundamentals.html
export function canonicalInterface(source) {
  const text = source.replace(/\r\n/g, '\n');
  const tokens = [...text.matchAll(/\/\/[^\n]*|\/\*[\s\S]*?\*\/|"(?:\\[\s\S]|[^"\\])*"|'(?:\\[\s\S]|[^'\\])*'|[\p{L}_][\p{L}\p{N}_]*|\s+|::|->|[^]/gu)]
    .map(match => match[0]);
  const significant = tokens.map((value, index) => ({ value, index }))
    .filter(({ value }) => !/^\s+$|^\/\/|^\/\*/.test(value));
  const code = significant.map(({ value }) => value).join(' ');
  // Fail closed if future exports could shadow the builtin type names. Exact
  // interfaces still compare equal; alias-only acceptance then needs review.
  const ambiguous = /\busing\b/.test(code)
    || /\b(?:type|typealias|struct|enum|trait)\s+(?:Int|Int32)\b/.test(code)
    || /\b(?:fn|impl|type|typealias|struct|enum|trait)\s*\[/.test(code)
    || /\b(?:fn|type|typealias|struct|enum|trait)\s+[\p{L}_][\p{L}\p{N}_]*(?:\s*::\s*[\p{L}_][\p{L}\p{N}_]*)?\s*\[/u.test(code);
  if (ambiguous) return text;
  for (let i = 0; i < significant.length; i++) {
    const token = significant[i];
    if (token.value !== 'Int') continue;
    const before = significant[i - 1]?.value;
    const after = significant[i + 1]?.value;
    const next = significant[i + 1];
    const endsLine = !next || tokens.slice(token.index + 1, next.index).some(t => t.includes('\n'));
    if ([':', '(', ',', '[', '->', '&'].includes(before)
      && ([',', ')', ']', '?', '}', '=', '&'].includes(after)
        || (endsLine && after !== '::' && after !== '.'))) {
      tokens[token.index] = 'Int32';
    }
  }
  return tokens.join('');
}

export function compareInterfaces(expected, actual) {
  const paths = [...new Set([...expected.keys(), ...actual.keys()])].sort();
  return paths.filter(path => !expected.has(path) || !actual.has(path)
    || canonicalInterface(expected.get(path)) !== canonicalInterface(actual.get(path)));
}

export function checkInterfaces(root, git = 'git') {
  const run = args => execFileSync(git, args, { cwd: root, encoding: 'utf8' });
  const paths = run(['ls-tree', '-r', '--name-only', '-z', 'HEAD']).split('\0').filter(path => path.endsWith('.mbti'));
  if (!paths.length) throw new Error('HEAD contains no committed interfaces.');
  const expected = new Map(paths.map(path => [path, run(['show', `HEAD:${path}`])]));
  const actual = new Map();
  // Include newly generated untracked files; keep deleted paths absent.
  const working = run(['ls-files', '--cached', '--others', '--exclude-standard', '-z', '--', '*.mbti']).split('\0').filter(Boolean);
  for (const path of working) {
    try { actual.set(path, readFileSync(resolve(root, path), 'utf8')); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  const changed = compareInterfaces(expected, actual);
  if (changed.length) {
    throw new Error(`Generated public interfaces differ: ${changed.join(', ')}.\nRun moon info and review/commit the API changes. Only builtin Int/Int32 spelling is equivalent.`);
  }
  return paths.length;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const count = checkInterfaces(resolve(dirname(fileURLToPath(import.meta.url)), '..'), process.env.SZS_GIT || 'git');
    console.log(`Public interface check passed (${count} files; builtin Int/Int32 aliases accepted).`);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
