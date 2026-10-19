"""Generate markup regression tests from independently specified JSON cases."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
cases=json.loads((root/'tests'/'markup-cases.json').read_text(encoding='utf8'))['cases']
lines=['// Generated from tests/markup-cases.json. Edit the fixture, then regenerate.']
for item in cases:
    po='msgid '+json.dumps(item['source'],ensure_ascii=False)+'\nmsgstr '+json.dumps(item['target'],ensure_ascii=False)+'\n'
    lines+=['','///|',f'test "CGM-1 {item["id"]} {item["category"]}" {{',
            '  let catalog = parse_catalog(test_header() + '+json.dumps(po,ensure_ascii=False)+')',
            '  let result = check_markup_catalog(catalog, options={ ..default_markup_options(), mode: '+json.dumps(item['mode'])+' })',
            '  let codes = result.map(d => d.code)', '  codes.sort()',
            '  assert_eq(codes, '+json.dumps(item['expected_codes'])+')', '}']
(root/'markup_conformance_wbtest.mbt').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'Generated {len(cases)} CGM-1 cases; run moon fmt next.')
