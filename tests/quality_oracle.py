"""Executable markup/project cases with independent XML and Toolkit references."""
import argparse
import hashlib
import json
from importlib.metadata import version
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
import polib
from translate.filters import checks

ROOT=Path(__file__).resolve().parents[1]
# Version-pinned reference outcomes, separate from normative CGM-1 outcomes.
TOOLKIT_EXPECTED={'H01':True,'H02':True,'H03':False,'H04':False,'H05':False,
                  'H06':False,'H07':False,'H10':False,'H13':True,'H16':True,
                  'H17':True,'H21':True,'H28':True,'X01':True,'X09':True,'X11':True}
HEADER=('msgid ""\nmsgstr ""\n"Project-Id-Version: quality 1\\n"\n'
        '"MIME-Version: 1.0\\n"\n"Content-Type: text/plain; charset=UTF-8\\n"\n'
        '"Content-Transfer-Encoding: 8bit\\n"\n"Language: zh_CN\\n"\n'
        '"Plural-Forms: nplurals=2; plural=(n!=1);\\n"\n\n')

def entry(source,target,context=None):
    return ('' if context is None else 'msgctxt '+json.dumps(context,ensure_ascii=False)+'\n')+'msgid '+json.dumps(source,ensure_ascii=False)+'\nmsgstr '+json.dumps(target,ensure_ascii=False)+'\n'

def cli(args):
    result=subprocess.run(['node',str(ROOT/'cli.mjs'),*map(str,args),'--json'],capture_output=True,text=True,encoding='utf8',timeout=30,cwd=ROOT)
    assert result.returncode in (0,1),(result.returncode,result.stdout,result.stderr)
    return json.loads(result.stdout)

class AttributeProbe(HTMLParser):
    def __init__(self,text):
        super().__init__(convert_charrefs=True)
        self.elements=[]
        self.feed(text)
        self.close()

    def handle_starttag(self,tag,attrs):
        self.elements.append((tag,sorted(attrs)))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',type=Path,default=ROOT/'evidence'/'local'/'quality-conformance.json')
    args=parser.parse_args()
    assert version('translate-toolkit')=='3.20.0','Use the pinned independent reference version'
    fixture=ROOT/'tests'/'markup-cases.json'
    cases=json.loads(fixture.read_text(encoding='utf8'))['cases']
    results=[]
    project_results=[]
    checker=checks.StandardChecker()
    with tempfile.TemporaryDirectory(prefix='.szs-test-quality-',dir=ROOT) as raw:
        folder=Path(raw)
        for case in cases:
            path=folder/(case['id']+'.po')
            path.write_text(HEADER+entry(case['source'],case['target']),encoding='utf8')
            response=cli([path,'--markup',case['mode']])
            codes=sorted(d['code'] for d in response['files'][0]['diagnostics'] if d['code'].startswith('M'))
            assert codes==case['expected_codes'],(case['id'],codes,case['expected_codes'])
            row=dict(id=case['id'],mode=case['mode'],catalogguard_codes=codes,catalogguard_pass=True)
            if case['xml_target_valid'] is not None:
                try: ET.fromstring('<cg-root>'+case['target']+'</cg-root>'); valid=True
                except ET.ParseError: valid=False
                assert valid==case['xml_target_valid'],(case['id'],'XML independent parser',valid)
                row['xml_target_valid']=valid
                row['xml_probe_pass']=True
            if 'xml_attribute_equal' in case:
                equal=ET.fromstring(case['source']).attrib==ET.fromstring(case['target']).attrib
                assert equal==case['xml_attribute_equal'],(case['id'],'Independent XML attribute normalization',equal)
                row['xml_attribute_equal']=equal
                row['xml_attribute_probe_pass']=True
            if 'html_attribute_equal' in case:
                equal=AttributeProbe(case['source']).elements==AttributeProbe(case['target']).elements
                assert equal==case['html_attribute_equal'],(case['id'],'Independent HTML attribute normalization',equal)
                row['html_attribute_equal']=equal
                row['html_attribute_probe_pass']=True
            try: row['toolkit_xmltags_accepts']=bool(checker.xmltags(case['source'],case['target']))
            except checks.FilterFailure as error:
                row['toolkit_xmltags_accepts']=False
                row['toolkit_message']=str(error)
            # This is a recorded behavior, not a claim of Toolkit compatibility.
            if case['id'] in TOOLKIT_EXPECTED:
                row['toolkit_expected']=TOOLKIT_EXPECTED[case['id']]
                assert row['toolkit_xmltags_accepts']==row['toolkit_expected'],(case['id'],'Pinned Toolkit behavior changed',row)
                row['toolkit_probe_pass']=True
            results.append(row)
        scenarios=[
            ('same-source-conflict',[('Save','保存','zh_CN'),('Save','存储','zh_CN')],False,['X002'],True),
            ('same-source-consistent',[('Save','保存','zh_CN'),('Save','保存','zh_CN')],False,[],False),
            ('inverse-collision',[('Delete','取消','zh_CN'),('Cancel','取消','zh_CN')],True,['X005'],True),
            ('different-sources',[('Delete','删除','zh_CN'),('Cancel','取消','zh_CN')],False,[],False),
            ('different-locales',[('Save','保存','zh_CN'),('Save','Sauver','fr')],False,[],True),
        ]
        for name,rows,inverse,expected_codes,toolkit_conflict in scenarios:
            inputs=folder/name/'inputs'; inputs.mkdir(parents=True)
            files=[]
            for index,(source,target,locale) in enumerate(rows):
                path=inputs/(str(index)+'.po')
                path.write_text(HEADER.replace('zh_CN',locale)+entry(source,target),encoding='utf8')
                files.append(path)
            got=cli([*files,'--inverse-consistency' if inverse else '--consistency'])
            codes=[f['diagnostic']['code'] for f in got['project_findings']]
            assert codes==expected_codes,(name,codes)
            output=folder/name/'toolkit-output'
            command=[sys.executable,'-c','from translate.tools.poconflicts import main; main()', '-i',str(inputs),'-o',str(output)]
            if inverse: command.append('-v')
            run=subprocess.run(command,capture_output=True,text=True,encoding='utf8',errors='replace',timeout=60)
            assert run.returncode==0,(name,run.stdout,run.stderr)
            emitted=sum(len(polib.pofile(str(path),encoding='utf8')) for path in output.rglob('*.po'))
            assert bool(emitted)==toolkit_conflict,(name,emitted,run.stdout,run.stderr)
            project_results.append(dict(id=name,catalogguard_codes=codes,catalogguard_pass=True,
                                        toolkit_conflict=bool(emitted),toolkit_expected=toolkit_conflict,toolkit_pass=True,
                                        difference='CatalogGuard separates Language groups; poconflicts input must be locale-scoped by its caller.' if name=='different-locales' else None))
    evidence=dict(schema_version=1,client_date=os.environ.get('SZS_VALIDATION_DATE'),profile='CGM-1 / CGP-1',
                  python=platform.python_version(),toolkit=version('translate-toolkit'),lxml=version('lxml'),
                  fixture_sha256=hashlib.sha256(fixture.read_bytes()).hexdigest(),
                  markup_cases=len(results),xml_probes=sum('xml_probe_pass'in r for r in results),
                  xml_attribute_probes=sum('xml_attribute_probe_pass'in r for r in results),
                  html_attribute_probes=sum('html_attribute_probe_pass'in r for r in results),
                  toolkit_markup_observations=len(results),project_scenarios=len(project_results),
                  toolkit_markup_assertions=sum('toolkit_probe_pass' in r for r in results),
                  toolkit_project_assertions=len(project_results),failed=[],markup_results=results,project_results=project_results)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in evidence.items() if not k.endswith('_results')},ensure_ascii=False))

if __name__=='__main__': main()
