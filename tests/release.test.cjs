'use strict';
const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
test('release keeps supplied data macros separate from personal data',()=>{
  const hub=require('../Lib/ui/model.js');hub.setCustomMacros([]);
  assert.equal(hub.catalog.length,0);assert.equal(hub.defaults().selected,'');assert.deepEqual(hub.defaults().favorites,[]);
  for(const name of fs.readdirSync(path.join(root,'macros')).filter(p=>p.endsWith('.json'))){const p=JSON.parse(read('macros/'+name));assert.equal(p.format,'pantheon-macro');assert.match(p.minPantheonVersion,/^1\.0-beta\.[1-9][0-9]*$/);assert.equal(name,p.id+'.json');}assert.ok(!fs.readdirSync(path.join(root,'macros')).some(p=>p.endsWith('.ahk')));
  for(const p of ['Lib/framework/Store.ahk','Lib/framework/definitions','macros/Anime Adventures','Lib/ui/bundled-framework.js','Lib/ui/route-catalog.json'])assert.ok(!fs.existsSync(path.join(root,p)),p);
});
test('developer UI is generic and import is grouped immediately before refresh',()=>{
  const html=read('Lib/ui/index.html');
  assert.ok(html.includes('class="action-group hub-actions"><button class="button" id="import-macro">Import macro</button><button class="button" id="refresh-library"'));
  for(const s of ['raids-pilot','framework-raids-enabled','framework-link-raids'])assert.ok(!html.includes(s));
  assert.ok(html.includes('id="framework-icon"'));assert.ok(html.includes('id="framework-empty"'));
});
test('launcher and worker only use the internal engine and retain input/source guards',()=>{
  assert.ok(read('Lib/framework/Worker.ahk').includes('EngineBridge.ahk'));
  const bridge=read('Lib/EngineBridge.ahk');
  assert.ok(bridge.includes('sender != this.Parent'));assert.ok(bridge.includes('parts[1] != this.Token'));
  assert.ok(read('Lib/Pantheon.ahk').includes('Untrusted page source.'));
  assert.ok(!bridge.includes('ManualSetup'));assert.ok(!read('Lib/Desktop.ahk').includes('FlowStore'));
});
