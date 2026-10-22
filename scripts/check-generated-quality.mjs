// Generated inputs are checked through the same public host bridge as the CLI.
// The small reference uses all earlier files; production uses bounded indexes.
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const version=JSON.parse(readFileSync(resolve(root,'package.json'),'utf8')).version;
const compiled=new vm.Script(readFileSync(resolve(root,'_build/js/release/build/cmd/main/main.js'),'utf8'));
function check(request){
  const context=vm.createContext({TextDecoder,TextEncoder,__szsRequest:JSON.stringify(request)});
  compiled.runInContext(context,{timeout:10000});
  assert.equal(typeof context.__szsResponse,'string');
  return JSON.parse(context.__szsResponse);
}
const output=resolve(root,process.argv[2]||'evidence/local/generated-quality.json');
mkdirSync(dirname(output),{recursive:true});
let seed=0x22102026;
function pick(n){seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return (seed>>>0)%n;}
const header=(language='zh_CN')=>'msgid ""\nmsgstr '+JSON.stringify(`Project-Id-Version: Review 1.0\nMIME-Version: 1.0\nContent-Type: text/plain; charset=UTF-8\nContent-Transfer-Encoding: 8bit\nLanguage: ${language}\nPlural-Forms: nplurals=2; plural=(n!=1);\n`)+'\n\n';
let serial=0;
function tree(depth=0){return {tag:['b','i','a','em','span'][pick(5)],key:String(serial++),children:depth>=3?[]:Array.from({length:pick(3)},()=>tree(depth+1))};}
function render(node,mode,reorder=false,mutated=false){
  const tag=mode==='html'&&reorder?node.tag.toUpperCase():node.tag;
  const protectedValue=node.key+(mutated?'changed':'');
  const attrs=reorder?`title="译文" data-k="${protectedValue}"`:`data-k="${protectedValue}" title="Source"`;
  const children=reorder?[...node.children].reverse():node.children;
  return `<${tag} ${attrs}>text`+children.map(child=>render(child,mode,reorder)).join('')+`</${tag}>`;
}
const markupResults=[];
for(const mode of ['html','xml']){
  const files=[],expected=[];
  for(let index=0;index<120;index++){
    const nodes=Array.from({length:2+pick(3)},()=>tree());
    const source=`case ${index}: `+nodes.map(n=>render(n,mode)).join('');
    const variants=[
      [nodes.toReversed().map(n=>render(n,mode,true)).join(''),[],'reorder'],
      [nodes.map((n,i)=>render(n,mode,true,i===0)).join(''),['M003'],'protected-value'],
      [nodes.slice(1).map(n=>render(n,mode,true)).join(''),['M003'],'removed-subtree'],
      [nodes.map(n=>render(n,mode,true)).join('')+'</missing>',['M002'],'unexpected-close'],
    ];
    for(const [target,codes,kind] of variants){
      files.push({path:`${mode}-${index}-${kind}.po`,text:header()+`msgid ${JSON.stringify(source)}\nmsgstr ${JSON.stringify(target)}\n`});
      expected.push(codes);
    }
  }
  const response=check({files,quality:{markup:{mode}},options:{plural_max:2}});
  assert.equal(response.data.files.length,files.length);
  response.data.files.forEach((file,index)=>assert.deepEqual(file.diagnostics.filter(d=>d.code.startsWith('M')).map(d=>d.code),expected[index],files[index].path));
  markupResults.push({mode,inputs:files.length,passed:true});
}
const scenarios=[],failures=[];
for(let scenario=0;scenario<350;scenario++){
  const ignore=!!pick(2),inverse=!!pick(2),files=[],entries=[];
  for(let file=0;file<2+pick(4);file++){
    const locale=['zh_CN','ZH-cn','fr','zh_TW'][pick(4)];
    let text=header(locale);
    const used=new Set();
    for(let item=0;item<2+pick(6);item++){
      const id=['Save','Open','Cancel','Delete','Close'][pick(5)];
      const context=['menu','dialog',null][pick(3)];
      const key=JSON.stringify([id,context]);if(used.has(key))continue;used.add(key);
      const plural=pick(3)===0?id+' items':null;
      const translated=pick(7)!==0;
      const values=plural?[translated?'T'+pick(3):'','T'+pick(3)]:[translated?'T'+pick(3):''];
      const fuzzy=pick(8)===0;
      const flag=['c-format','no-c-format',''][pick(3)];
      const entry={file,entry:used.size,id,context,plural,values,fuzzy,locale:locale.toLowerCase().replaceAll('_','-'),flag};
      entries.push(entry);
      text+=(fuzzy||flag?'#, '+[fuzzy?'fuzzy':'',flag].filter(Boolean).join(', ')+'\n':'');
      if(context!==null)text+=`msgctxt ${JSON.stringify(context)}\n`;
      text+=`msgid ${JSON.stringify(id)}\n`;
      if(plural)text+=`msgid_plural ${JSON.stringify(plural)}\n`;
      values.forEach((value,slot)=>{text+=`msgstr${plural?'['+slot+']':''} ${JSON.stringify(value)}\n`;});
      text+='\n';
    }
    files.push({path:`${scenario}-${file}.po`,text});
  }
  const response=check({files,quality:{consistency:{enabled:true,ignore_context:ignore,inverse}},options:{plural_max:2}});
  const active=entries.filter(e=>!e.fuzzy&&e.values.every(v=>v!==''));
  const sourceKey=e=>JSON.stringify([e.locale,ignore?null:e.context,e.id]);
  const targetKey=e=>JSON.stringify([e.locale,ignore?null:e.context,e.values]);
  const event=(entry,code)=>`${entry.file}:${entry.entry}:${code}`;
  const expected=new Set();
  for(const a of active)for(const b of active){
    if(b.file>=a.file)continue;
    if(sourceKey(a)===sourceKey(b)){
      if(a.plural!==b.plural)expected.add(event(a,'X003'));
      if(a.plural===b.plural&&JSON.stringify(a.values)!==JSON.stringify(b.values))expected.add(event(a,'X002'));
      if(a.flag!==b.flag)expected.add(event(a,'X004'));
    }
    if(inverse&&a.id!==b.id&&targetKey(a)===targetKey(b))expected.add(event(a,'X005'));
  }
  const actual=new Set();
  for(const finding of response.data.project_findings){
    const a=entries.find(e=>e.file===finding.file_index&&e.entry===finding.diagnostic.entry);
    const relatedIndex=files.findIndex(f=>f.path===finding.related?.file);
    const b=entries.find(e=>e.file===relatedIndex&&e.entry===finding.related?.entry);
    assert.ok(a&&b,'Finding must identify both entries');
    assert.ok(active.includes(a)&&active.includes(b),'Ignored entries must not become evidence');
    assert.notEqual(a.file,b.file);
    assert.equal(a.locale,b.locale);
    if(!ignore)assert.equal(a.context,b.context);
    const code=finding.diagnostic.code;
    if(code==='X005'){
      assert.ok(inverse);assert.notEqual(a.id,b.id);assert.equal(targetKey(a),targetKey(b));

    }else{
      assert.equal(sourceKey(a),sourceKey(b));
      if(code==='X003')assert.notEqual(a.plural,b.plural);
      else if(code==='X002')assert.notEqual(JSON.stringify(a.values),JSON.stringify(b.values));
      else if(code==='X004')assert.notEqual(a.flag,b.flag);
      else assert.fail('Unexpected project code '+code);

    }
    assert.ok(!actual.has(event(a,code)),'At most one finding per rule/current entry');
    actual.add(event(a,code));
  }
  for(const key of [...expected,...actual]){
    if(actual.has(key)!==expected.has(key)){
      if(failures.length===0)writeFileSync(resolve(dirname(output),'generated-quality-failure.json'),JSON.stringify({scenario,ignore,inverse,files,entries,expected:[...expected],actual:[...actual],response},null,2)+'\n');
      failures.push({scenario,ignore_context:ignore,inverse,event:key,expected:expected.has(key),actual:actual.has(key)});
    }
  }
  scenarios.push({id:scenario,files:files.length,findings:response.data.project_findings.length});
}
const summary={schema_version:1,client_date:process.env.SZS_VALIDATION_DATE||null,version,seed:'0x22102026',markup:markupResults,cross_file_projects:scenarios.length,cross_file_inputs:scenarios.reduce((s,p)=>s+p.files,0),failed_projects:new Set(failures.map(f=>f.scenario)).size,failures,passed:failures.length===0,note:'960 generated markup inputs and 350 multi-file projects, with per-entry/rule all-prior-files reference and witness checks. Separate from core test counts; finite checks do not establish full standards compatibility.'};
writeFileSync(output,JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify({...summary,failures:failures.slice(0,10)}));
process.exitCode=failures.length?1:0;
