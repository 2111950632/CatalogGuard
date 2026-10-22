import {spawnSync} from 'node:child_process';
import {writeFileSync,mkdirSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const cases=[
  ['valid',['examples/project-quality/valid','--recursive','--markup','html','--consistency','--strict'],0,[]],
  ['broken',['examples/project-quality/broken','--recursive','--markup','html','--consistency','--strict'],1,['M002','M003','X002']],
  ['xml-good',['examples/project-quality/xml-good.po','--markup','xml','--strict'],0,[]],
  ['xml-broken',['examples/project-quality/xml-broken.po','--markup','xml','--strict'],1,['M002','M003']],
  ['configured',['examples/project-quality/valid','--recursive','--config','examples/project-quality/ci.json'],0,[]],
];
const results=[];
for(const [name,args,expected,codes]of cases){
  const run=spawnSync(process.execPath,['cli.mjs',...args,'--json'],{cwd:root,encoding:'utf8',timeout:30000});
  assert.equal(run.status,expected,name+': '+run.stdout+run.stderr);
  const report=JSON.parse(run.stdout);
  const actual=[...new Set(report.files.flatMap(f=>f.diagnostics.map(d=>d.code)))].sort();
  for(const code of codes)assert.ok(actual.includes(code),name+': missing '+code);
  if(expected===0)assert.deepEqual(actual,[],name);
  results.push({name,args,exit_code:run.status,diagnostic_codes:actual,report});
}
const output=resolve(root,process.argv[2]||'evidence/local/project-demo.json');
mkdirSync(dirname(output),{recursive:true});
writeFileSync(output,JSON.stringify({schema_version:1,client_date:process.env.SZS_VALIDATION_DATE||null,cases:results.length,passed:results.length,results},null,2)+'\n');
console.log('Project quality demo: 5/5 command runs passed; four primary examples exit 0,1,0,1.');
