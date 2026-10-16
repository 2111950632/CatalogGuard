"""Pin a public baseline and test its API without modifying its source."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BASELINE = '7ef95764ed37b47d4b8fabe1a6ed12c719850437'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--moon',default=os.environ.get('SZS_MOON','moon'))
    parser.add_argument('--source',type=Path,help='Existing, unmodified baseline checkout')
    parser.add_argument('--output',type=Path,default=ROOT/'evidence'/'local'/'moongettext-baseline.json')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='.szs-test-baseline-',dir=ROOT) as raw:
        temporary = Path(raw).resolve()
        assert temporary.parent == ROOT.resolve()
        baseline = args.source.resolve() if args.source else temporary/'moongettext'
        def run(command,cwd):
            result = subprocess.run(command,cwd=cwd,capture_output=True,text=True,encoding='utf8',errors='replace',timeout=180)
            if result.returncode: raise RuntimeError(result.stdout+'\n'+result.stderr)
            return result.stdout+result.stderr
        if not args.source:
            run(['git','clone','--quiet','https://github.com/YanFangNie/moongettext',str(baseline)],ROOT)
            run(['git','checkout','--quiet','--detach',BASELINE],baseline)
        actual = run(['git','rev-parse','HEAD'],baseline).strip()
        assert actual==BASELINE, (actual,BASELINE)
        # Ignore untracked build/dependency caches; tracked sources must be exact.
        assert not run(['git','diff','--name-only','HEAD'],baseline).strip()
        consumer = temporary/'consumer'
        consumer.mkdir()
        (temporary/'moon.work').write_text('members = '+json.dumps([str(baseline).replace('\\','/'),'consumer'])+'\n',encoding='utf8')
        (consumer/'moon.mod').write_text('name = "catalogguard-review/baseline"\nversion = "0.1.0"\nimport { "YanFangNie/moongettext@0.1.1" }\n',encoding='utf8')
        (consumer/'moon.pkg').write_text('import { "YanFangNie/moongettext" }\n',encoding='utf8')
        (consumer/'consumer.mbt').write_text('pub fn has_errors(source : String) -> Bool { let po = try! @moongettext.parse_po(source); @moongettext.validation_has_errors(@moongettext.validate_po(po)[:]) }\n',encoding='utf8')
        tests = []
        rows = [('c-format','%d','%s'),('python-format','%(n)d','%(n)s'),('python-brace-format','{n:d}','{n:s}')]
        for style,source,target in rows:
            po = '#, '+style+'\nmsgid '+json.dumps(source)+'\nmsgstr '+json.dumps(target)+'\n'
            tests.append('test '+json.dumps(style+' mismatch is outside baseline validator scope')+' { assert_true(!has_errors('+json.dumps(po)+')) }')
        duplicate='msgid "x"\nmsgstr "a"\n\nmsgid "x"\nmsgstr "b"\n'
        tests.append('test "duplicate control confirms validation is active" { assert_true(has_errors('+json.dumps(duplicate)+')) }')
        (consumer/'consumer_wbtest.mbt').write_text('\n'.join(tests)+'\n',encoding='utf8')
        # Warning 79 concerns old derived-method promotion under this newer compiler.
        # Only the baseline build suppresses it. No baseline code or checks are changed.
        log=run([args.moon,'test','--target','js','--warn-list','-79','-p','catalogguard-review/baseline'],consumer)
        assert 'Total tests: 4, passed: 4, failed: 0.' in log,log
        evidence=dict(schema_version=1,baseline_repository='https://github.com/YanFangNie/moongettext',
                      baseline_commit=BASELINE,source_modified=False,cases=4,passed=4,
                      format_mismatch_errors_detected={'c-format':False,'python-format':False,'python-brace-format':False},
                      duplicate_control_detected=True,warning_79_suppressed_for_baseline_only=True,log=log)
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
        print('Pinned moongettext comparison: 4/4 probes passed; 3 format mismatches are outside its validator scope.')

if __name__=='__main__': main()
