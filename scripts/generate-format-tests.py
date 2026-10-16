"""Generate MoonBit regression cases from the normative JSON fixture."""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
cases = json.loads((root/'tests'/'format-cases.json').read_text(encoding='utf8'))['cases']
lines = ['// Cases generated from tests/format-cases.json; edit the fixture and regenerate.']
for item in cases:
    source = '#, '+item['style']+'\nmsgid '+json.dumps(item['source'],ensure_ascii=False)+'\nmsgstr '+json.dumps(item['target'],ensure_ascii=False)+'\n'
    lines += ['','///|',f'test "CGFC-1 {item["id"]} {item["category"]}" {{',
              '  let report = check_text(test_header() + '+json.dumps(source,ensure_ascii=False)+')',
              '  let codes = report.diagnostics.filter(d => d.code.has_prefix("F")).map(d => d.code)',
              '  let unique : Array[String] = []',
              '  for code in codes { if !unique.contains(code) { unique.push(code) } }',
              '  unique.sort()',
              '  assert_eq(unique, '+json.dumps(sorted(item['expected_codes']))+')',
              '}']
(root/'format_conformance_wbtest.mbt').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'Generated {len(cases)} CGFC-1 cases; run moon fmt next.')
