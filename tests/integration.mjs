import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync, rmSync, mkdirSync, copyFileSync, utimesSync } from 'node:fs';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const temp = mkdtempSync(join(root, '.szs-test-'));
after(() => {
  const target = resolve(temp);
  assert.equal(dirname(target), root);
  assert.ok(target.startsWith(join(root, '.szs-test-')));
  rmSync(target, { recursive: true, force: true });
});

function run(args, options = {}) {
  const result = spawnSync(process.execPath, [join(root, 'cli.mjs'), ...args], {
    cwd: root, encoding: 'utf8', timeout: 15000, ...options,
  });
  assert.equal(result.error, undefined, result.error?.message);
  return result;
}
function data(result) { return JSON.parse(result.stdout); }
function input(name, content) {
  const path = join(temp, name);
  writeFileSync(path, content);
  return path;
}

const qualityHeader = readFileSync(join(root,'examples/zh_CN.po'),'utf8').replaceAll('\r\n','\n').split('\n\n')[0]+'\n\n';
function qualityInput(name, source, target, context) {
  return input(name, qualityHeader+(context === undefined ? '' : 'msgctxt '+JSON.stringify(context)+'\n')+'msgid '+JSON.stringify(source)+'\nmsgstr '+JSON.stringify(target)+'\n');
}

test('markup is opt-in and HTML/XML void semantics differ', () => {
  const path=qualityInput('markup-void.po','<br>','<br/>');
  assert.equal(run([path,'--markup','html','--json']).status,0);
  const xml=run([path,'--markup','xml','--json']);
  assert.equal(xml.status,1);
  assert.ok(data(xml).files[0].diagnostics.some(d=>d.code==='M001'));
  const broken=qualityInput('markup-opt-in.po','<b>x</b>','plain');
  assert.equal(run([broken,'--json']).status,0);
  assert.equal(run([broken,'--markup','html','--json']).status,1);
});

test('markup accepts translation reorder but protects attribute associations', () => {
  const good=qualityInput('markup-reorder.po','<b>One</b><a href="/help" title="Help">Two</a>','<a title="帮助" href="/help">二</a><b>一</b>');
  assert.equal(run([good,'--markup','html','--strict','--json']).status,0);
  const bad=qualityInput('markup-href.po','<a href="/help">Help</a>','<a href="/pay">帮助</a>');
  const result=run([bad,'--markup','html','--json']);
  assert.equal(result.status,1);
  assert.ok(data(result).files[0].diagnostics.some(d=>d.code==='M003' && d.related && d.span.start.line>1));
});

test('cross-file findings preserve both locations and strict failure policy', () => {
  const first=qualityInput('conflict-first.po','Save','保存');
  const second=qualityInput('conflict-second.po','Save','存储');
  const normal=run([first,second,'--consistency','--json']);
  assert.equal(normal.status,0);
  const finding=data(normal).project_findings[0];
  assert.equal(finding.diagnostic.code,'X002');
  assert.equal(finding.diagnostic.file,second);
  assert.equal(finding.related.file,first);
  assert.ok(finding.related.span.start.line>0);
  assert.equal(run([first,second,'--consistency','--strict','--json']).status,1);
});

test('contexts and locale variants avoid spurious cross-file conflicts', () => {
  const first=qualityInput('context-first.po','Open','打开','verb');
  const second=qualityInput('context-second.po','Open','开放','adjective');
  assert.deepEqual(data(run([first,second,'--consistency','--json'])).project_findings,[]);
  assert.equal(data(run([first,second,'--ignore-context','--json'])).project_findings[0].diagnostic.code,'X002');
  const other=input('other-locale.po',readFileSync(second,'utf8').replace('zh_CN','zh_TW'));
  assert.deepEqual(data(run([first,other,'--ignore-context','--json'])).project_findings,[]);
});

test('quality configuration enables checks and CLI flags override it', () => {
  const path=qualityInput('quality-config.po','<b>x</b>','plain');
  const config=input('quality.json',JSON.stringify({schema_version:1,quality:{markup:{mode:'html'}}}));
  assert.equal(run([path,'--config',config,'--json']).status,1);
  assert.equal(run([path,'--config',config,'--markup','off','--json']).status,0);
});

test('recursive input is deterministic and ignores noncatalogs and POT conflicts', () => {
  const folder=join(temp,'project-tree'); mkdirSync(join(folder,'nested'),{recursive:true});
  writeFileSync(join(folder,'a.po'),qualityHeader+'msgid "Save"\nmsgstr "保存"\n');
  writeFileSync(join(folder,'nested','b.po'),qualityHeader+'msgid "Save"\nmsgstr "存储"\n');
  writeFileSync(join(folder,'ignore.txt'),'not a catalog');
  writeFileSync(join(folder,'template.pot'),'msgid "Save"\nmsgstr ""\n');
  const result=run([folder,'--recursive','--consistency','--json']);
  assert.equal(result.status,0,result.stdout+result.stderr);
  assert.equal(data(result).files.length,3);
  assert.deepEqual(data(result).project_findings.map(f=>f.diagnostic.code),['X002']);
  assert.match(data(result).project_findings[0].related.file,/a\.po$/);
});

test('invalid quality options reject the invocation', () => {
  const path=qualityInput('quality-invalid.po','x','X');
  for(const quality of [{markup:{mode:'auto'}},{markup:{max_depth:129}},{consistency:{enabled:'yes'}},{markup:{translatable_attributes:[1]}},{markup:{typo:true}}]){
    const config=input('invalid-quality.json',JSON.stringify({quality}));
    assert.equal(run([path,'--config',config,'--json']).status,2);
  }
  assert.equal(run([path,'--markup','auto','--json']).status,2);
});

test('project limits report a failure instead of partial success', () => {
  const first=qualityInput('limit-first.po','Save','保存');
  const second=qualityInput('limit-second.po','Save','存储');
  const config=input('limit-quality.json',JSON.stringify({quality:{consistency:{enabled:true,max_entries:1}}}));
  const result=run([first,second,'--config',config,'--json']);
  assert.equal(result.status,1);
  assert.equal(data(result).project_findings[0].diagnostic.code,'X009');
  assert.equal(data(result).project_findings[0].diagnostic.entry,null);
});

test('inverse consistency is an explicit review operation', () => {
  const first=qualityInput('inverse-first.po','Cancel','取消');
  const second=qualityInput('inverse-second.po','Delete','取消');
  assert.deepEqual(data(run([first,second,'--consistency','--json'])).project_findings,[]);
  assert.equal(data(run([first,second,'--inverse-consistency','--json'])).project_findings[0].diagnostic.code,'X005');
});

test('duplicate input paths are rejected before double counting', () => {
  const path=qualityInput('duplicate-project.po','Save','保存');
  assert.equal(run([path,path,'--consistency','--json']).status,2);
});

test('Chinese PO and POT pass strict template comparison', () => {
  const result = run(['check', 'examples/zh_CN.po', '--template', 'examples/messages.pot', '--strict', '--json']);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.equal(data(result).files[0].statistics.translated, 3);
  assert.equal(data(result).files[0].plural_checked_through, 1000);
});

test('broken translations return specific errors and source positions', () => {
  const result = run(['examples/broken.po', '--json']);
  assert.equal(result.status, 1);
  const diagnostics = data(result).files[0].diagnostics;
  for (const code of ['L003', 'F003', 'F004', 'F005', 'C006', 'C007']) {
    assert.ok(diagnostics.some(d => d.code === code), code);
  }
  assert.ok(diagnostics.every(d => d.file === 'examples/broken.po' && d.span.start.line > 0));
});

test('POT mode does not report its intentionally empty translations', () => {
  const result = run(['examples/messages.pot', '--strict', '--json']);
  assert.equal(result.status, 0, result.stdout);
  assert.equal(data(result).files[0].diagnostics.length, 0);
});

test('multi-file requests aggregate failure status', () => {
  const result = run(['examples/zh_CN.po', 'examples/broken.po', '--json']);
  assert.equal(result.status, 1);
  assert.equal(data(result).files.length, 2);
});

test('inspect retains contextual source and plural values', () => {
  const result = run(['inspect', 'examples/zh_CN.po', '--json']);
  assert.equal(result.status, 0);
  const entries = data(result).files[0].entries;
  assert.ok(entries.some(e => e.context === 'menu' && e.translations[0].value === '打开'));
  assert.ok(entries.some(e => e.plural === '%d files'));
});

test('normalize round trip is idempotent and does not overwrite input', () => {
  const before = readFileSync(join(root, 'examples/zh_CN.po'));
  const first = run(['normalize', 'examples/zh_CN.po']);
  assert.equal(first.status, 0, first.stderr);
  const path = input('normalized.po', first.stdout);
  const second = run(['normalize', path]);
  assert.equal(second.status, 0);
  assert.equal(second.stdout, first.stdout);
  assert.deepEqual(readFileSync(join(root, 'examples/zh_CN.po')), before);
});

test('normalize refuses syntax errors and unassociated trailing comments', () => {
  for (const text of ['msgid bad\n', 'msgid "a"\nmsgstr "A"\n# trailing\n']) {
    assert.equal(run(['normalize', input('malformed.po', text)]).status, 2);
  }
});

test('invocation errors use exit 2 and valid JSON when requested', () => {
  for (const args of [
    ['missing-file.po'], ['--plural-max', '-1', 'examples/zh_CN.po'],
    ['--empty-severity', 'typo', 'examples/zh_CN.po'],
    ['--not-an-option'], ['normalize', 'examples/zh_CN.po', 'examples/broken.po'],
  ]) {
    const result = run([...args, '--json']);
    assert.equal(result.status, 2, args.join(' '));
    assert.equal(data(result).exit_code, 2);
  }
});

test('stdin UTF-8 BOM CRLF and Unicode paths work', () => {
  const text = '\uFEFFmsgid "你好"\r\nmsgstr "Hello"\r\n';
  const result = run(['inspect', '-', '--json'], { input: text });
  assert.equal(result.status, 0);
  assert.equal(data(result).files[0].entries[0].id, '你好');
  assert.equal(run(['inspect', input('中文.po', text), '--json']).status, 0);
});

test('invalid raw UTF-8 is rejected before replacement decoding', () => {
  const path = input('invalid.po', Buffer.from([0xc0, 0xaf]));
  const result = run([path, '--json']);
  assert.equal(result.status, 2);
  assert.ok(data(result).error);
});

test('policy configuration promotes review warnings and rejects typos', () => {
  const result = run(['examples/broken.po', '--config', 'examples/strict.json', '--json']);
  assert.equal(result.status, 1);
  assert.ok(data(result).files[0].diagnostics.some(d => d.code === 'C007' && d.severity === 'error'));
  assert.equal(run(['examples/zh_CN.po', '--config', input('bad.json', '{"options":{"typo":true}}')]).status, 2);
});

test('explicit flags select checking and unsupported flags are visible', () => {
  const path = input('unsupported.po', '#, java-format\nmsgid "x"\nmsgstr "X"\n');
  const result = run([path, '--json']);
  assert.ok(data(result).files[0].diagnostics.some(d => d.code === 'F007'));
  const plain = input('plain.po', 'msgid "100% ready"\nmsgstr "100% 完成"\n');
  assert.ok(!data(run([plain, '--json'])).files[0].diagnostics.some(d => d.code.startsWith('F')));
});

test('plural command reports finite coverage and division errors', () => {
  assert.equal(run(['plural', 'nplurals=1; plural=0;', '--json']).status, 0);
  const result = run(['plural', 'nplurals=2; plural=n==0?0:1/(n-1);', '--json']);
  assert.equal(result.status, 1);
  assert.ok(data(result).failures.length);
  assert.equal(data(result).checked_through, 1);
  assert.equal(run(['plural', 'nplurals=2; plural=process.exit();']).status, 2);
});

test('stats reports context workload and source references', () => {
  const result = run(['stats', 'examples/zh_CN.po', '--json']);
  assert.equal(result.status, 0);
  const summary = data(result).files[0].summary;
  assert.equal(summary.language, 'zh_CN');
  assert.ok(summary.contexts.some(c => c.context === 'menu' && c.translated === 1));
  assert.ok(summary.references.some(r => r.path === 'demo.mbt' && r.entries === 2));
});

test('output files are exclusive and original data is preserved', () => {
  const path = join(temp, 'report.json');
  assert.equal(run(['examples/zh_CN.po', '--json', '--output', path]).status, 0);
  const before = readFileSync(path);
  assert.equal(run(['examples/zh_CN.po', '--json', '--output', path]).status, 2);
  assert.deepEqual(readFileSync(path), before);
});

test('rules help and version work without catalog inputs', () => {
  const rules = data(run(['rules', '--json'])).rules;
  assert.ok(rules.some(r => r.code === 'P011'));
  assert.ok(rules.some(r => r.code === 'F008'));
  assert.equal(run(['--help']).status, 0);
  assert.equal(run(['--version']).stdout.trim(), 'szs 0.2.0');
});

test('duplicate stdin and excessive input are bounded IO failures', () => {
  assert.equal(run(['inspect', '-', '-', '--json'], { input: 'msgid "x"\nmsgstr "X"\n' }).status, 2);
  const path = input('oversized.po', Buffer.alloc(32 * 1024 * 1024 + 1, 32));
  const result = run(['inspect', path, '--json']);
  assert.equal(result.status, 2);
  assert.match(data(result).error, /32 MiB/);
});

test('end of options permits files named help and version', () => {
  for (const name of ['--help', '--version']) {
    input(name, 'msgid "x"\nmsgstr "X"\n');
    const result = run(['inspect', '--json', '--', name], { cwd: temp });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(data(result).files[0].entries[0].id, 'x');
  }
});

test('most recent local build wins and packaged core is a fallback', () => {
  const isolated = join(temp, 'loader');
  mkdirSync(isolated);
  copyFileSync(join(root, 'cli.mjs'), join(isolated, 'cli.mjs'));
  writeFileSync(join(isolated, 'package.json'), '{"type":"module"}');
  function core(relative, marker, time) {
    const path = join(isolated, relative);
    mkdirSync(dirname(path), { recursive: true });
    const response = { exit_code: 0, text: marker + '\n', data: { origin: marker } };
    writeFileSync(path, 'globalThis.__szsResponse = ' + JSON.stringify(JSON.stringify(response)) + ';');
    utimesSync(path, time, time);
  }
  function invoke() {
    const result = spawnSync(process.execPath, [join(isolated, 'cli.mjs'), 'rules', '--json'], { cwd: isolated, encoding: 'utf8', timeout: 15000 });
    assert.equal(result.status, 0, result.stderr);
    return data(result).origin;
  }
  core('dist/szs-core.js', 'packaged', 2000);
  assert.equal(invoke(), 'packaged');
  core('_build/js/release/build/cmd/main/main.js', 'release', 1000);
  assert.equal(invoke(), 'release');
  core('_build/js/debug/build/cmd/main/main.js', 'debug', 1500);
  assert.equal(invoke(), 'debug');
});
