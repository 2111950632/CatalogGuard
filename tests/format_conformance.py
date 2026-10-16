"""Independent, executable format-contract matrix. No PO parser dependencies."""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
HEADER = ('msgid ""\nmsgstr ""\n'
          '"Project-Id-Version: CatalogGuard conformance 1\\n"\n'
          '"Content-Type: text/plain; charset=UTF-8\\n"\n'
          '"Content-Transfer-Encoding: 8bit\\n"\n'
          '"Language: en\\n"\n'
          '"Plural-Forms: nplurals=2; plural=(n!=1);\\n"\n\n')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--msgfmt', default=os.environ.get('SZS_MSGFMT'))
    parser.add_argument('--output', type=Path, default=ROOT/'evidence'/'local'/'format-conformance.json')
    args = parser.parse_args()
    if sys.version_info[:2] != (3,12):
        raise RuntimeError('This profile uses the CPython 3.12 oracle; run with Python 3.12')
    msgfmt = args.msgfmt or shutil.which('msgfmt')
    if not msgfmt:
        raise RuntimeError('GNU msgfmt is required; set SZS_MSGFMT or --msgfmt')
    gnu_version = subprocess.run([msgfmt,'--version'], capture_output=True,text=True,check=True).stdout.splitlines()[0]
    matrix = json.loads((ROOT/'tests'/'format-cases.json').read_text(encoding='utf8'))
    results = []
    with tempfile.TemporaryDirectory(prefix='.szs-format-contract-',dir=ROOT) as raw:
        temporary = Path(raw).resolve()
        assert temporary.parent == ROOT.resolve()
        for case in matrix['cases']:
            source = HEADER + '#, '+case['style']+'\nmsgid '+json.dumps(case['source'],ensure_ascii=False)+'\nmsgstr '+json.dumps(case['target'],ensure_ascii=False)+'\n'
            path = temporary/(case['id']+'.po')
            path.write_text(source,encoding='utf8')
            run = subprocess.run(['node',str(ROOT/'cli.mjs'),'check',str(path),'--json'],capture_output=True,text=True,encoding='utf8',timeout=30)
            if run.returncode not in (0,1): raise RuntimeError(run.stderr or run.stdout)
            data = json.loads(run.stdout)
            findings = data['files'][0]['diagnostics']
            codes = sorted(set(x['code'] for x in findings if x['code'].startswith('F')))
            errors = [x for x in findings if x['severity']=='error' and not x['code'].startswith('F')]
            assert not errors, (case['id'],errors)
            result = dict(id=case['id'], style=case['style'], category=case['category'],
                          expected_codes=case['expected_codes'], actual_codes=codes,
                          catalogguard_pass=codes==sorted(case['expected_codes']))
            oracle = subprocess.run([msgfmt,'--check-format','--use-fuzzy','-o',os.devnull,str(path)],capture_output=True,text=True,encoding='utf8',errors='replace',timeout=30)
            result['gnu_accepts'] = oracle.returncode==0
            result['gnu_expected_1_0'] = case['gnu']
            # GNU is an additional reference, not the Python language definition.
            # Only assert version-pinned results; record other tool versions as observations.
            result['gnu_pass'] = None if case['gnu'] is None or gnu_version.rsplit(' ',1)[-1] != '1.0' else result['gnu_accepts']==case['gnu']
            if case.get('gnu_difference'): result['gnu_difference'] = case['gnu_difference']
            result['gnu_diagnostic'] = oracle.stderr.replace(str(temporary),'$CASES').strip()
            probe = case['python']
            if probe:
                render = (lambda text: text % (tuple(probe['values']) if isinstance(probe['values'],list) else probe['values'])) if probe['mode']=='percent' else (lambda text: text.format(*probe['args'],**probe['kwargs']))
                outputs = []
                for label,text in [('source',case['source']),('target',case['target'])]:
                    try: outputs.append(dict(side=label,valid=True,output=render(text)))
                    except (ValueError,TypeError,KeyError,IndexError,AttributeError) as error:
                        outputs.append(dict(side=label,valid=False,error=type(error).__name__+': '+str(error)))
                result['python'] = outputs
                result['python_pass'] = outputs[0]['valid'] and outputs[1]['valid']==probe['target_valid']
            results.append(result)
            if not result['catalogguard_pass'] or result['gnu_pass'] is False or result.get('python_pass') is False:
                print(json.dumps(result,ensure_ascii=False))
    failed = [x['id'] for x in results if not x['catalogguard_pass'] or x['gnu_pass'] is False or x.get('python_pass') is False]
    evidence = dict(schema_version=1,profile=matrix['profile'],python_version=platform.python_version(),gnu_version=gnu_version,
                    cases=len(results),styles=dict(Counter(x['style'] for x in results)),
                    gnu_compared=sum(x['gnu_pass'] is not None for x in results),
                    python_probes=sum('python_pass' in x for x in results),failed=failed,results=results)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in evidence.items() if k!='results'},ensure_ascii=False))
    return bool(failed)

if __name__=='__main__':
    sys.exit(main())
