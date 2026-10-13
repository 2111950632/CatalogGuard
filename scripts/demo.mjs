import { spawnSync } from 'node:child_process';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const cases = [
  ['1. 正常中文翻译与模板对照，预期通过', ['check', 'examples/zh_CN.po', '--template', 'examples/messages.pot', '--strict'], 0],
  ['2. 故意出错的译文，预期指出问题', ['check', 'examples/broken.po'], 1],
  ['3. 查看开发工具可读取的 JSON 报告', ['check', 'examples/zh_CN.po', '--json'], 0],
  ['4. 查看复数表达式的有限检查范围', ['plural', 'nplurals=2; plural=(n!=1);'], 0],
];
for (const [title, args, expected] of cases) {
  process.stdout.write('\n' + title + '\n');
  const result = spawnSync(process.execPath, [join(root, 'cli.mjs'), ...args], { cwd: root, stdio: 'inherit', timeout: 30000 });
  if (result.error || result.status !== expected) {
    process.stderr.write('演示结果与预期不符：' + (result.error?.message || result.status) + '\n');
    process.exit(2);
  }
}
process.stdout.write('\n演示完成，四项结果符合预期。\n');
