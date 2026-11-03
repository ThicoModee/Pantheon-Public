'use strict';
const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'..');
test('every UI icon body is an unmodified Lucide asset from the Iconify response',()=>{
  const source=JSON.parse(fs.readFileSync(path.join(root,'Lib/vendor/lucide/icons.json'),'utf8'));
  const allowed=new Set(Object.values(source.icons).map(i=>i.body));
  const context={window:{}};vm.runInNewContext(fs.readFileSync(path.join(root,'Lib/ui/icons.js'),'utf8'),context);
  assert.ok(Object.keys(context.window.PantheonIcons).length>30);
  for(const [name,body]of Object.entries(context.window.PantheonIcons))assert.ok(allowed.has(body),name+' must come from Lucide');
  for(const file of ['Lib/ui/app.js','Lib/ui/index.html'])assert.equal(fs.readFileSync(path.join(root,file),'utf8').includes('<path d='),false,'no hand-drawn path definitions in '+file);
});
test('every bundled macro icon exists and unknown identifiers fall back to Pantheon',()=>{
  const hub=require('../Lib/ui/model.js');
  for(const icon of Object.values(hub.macroIcons))assert.ok(fs.existsSync(path.join(root,'Lib/ui',icon.image)));
  hub.setCustomMacros([{id:'macro-icon-test',name:'Icon test',icon:'raids'},{id:'macro-bad-icon',name:'Fallback',icon:'../escape.png'}]);
  assert.equal(hub.mode('macro-icon-test').image,'assets/macros/Raids.png');
  assert.equal(hub.mode('macro-bad-icon').image,'assets/pantheon.png');
  hub.setCustomMacros([]);
});
