'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const {makeSetting,fields,types}=require('../Lib/ui/macro-settings.js');
const {setCustomMacros,catalog,preferences,defaults}=require('../Lib/ui/model.js');
test('settings authoring uses typed defaults and never creates executable fields',()=>{
  for(const type of Object.keys(types)){const s=makeSetting(type,'Example');assert.equal(s.type,type);assert.equal(s.label,'Example');assert.equal(s.script,undefined);assert.equal(s.path,undefined);}
  assert.equal(makeSetting('select').default,'option-1');assert.deepEqual(makeSetting('priority').default,['option-1']);
});
test('dashboard settings preserve choice IDs, priority order, and escaped labels',()=>{
  const specs={stage:makeSetting('select','<img src=x>'),portal:makeSetting('toggle','Farm portals'),shop:makeSetting('priority','Shop')};
  specs.shop.options.push({value:'option-2',label:'Second',target:''});
  const html=fields(specs,{stage:'option-1',portal:1,shop:['option-2','option-1']});
  assert.ok(html.includes('&lt;img src=x&gt;'));assert.ok(!html.includes('<img src=x>'));
  assert.ok(html.indexOf('>Second</label>')<html.indexOf('>Option 1</label>'));
  assert.ok(html.includes('data-macro-value="portal" checked'));
});
test('authored macro catalogue accepts safe IDs without restoring removed legacy macros',()=>{
  try{setCustomMacros([{id:'macro-community',name:'Community TD'},{id:'Raids',name:'Spoof'},{id:'../bad',name:'Bad'}]);assert.equal(catalog.length,1);assert.equal(preferences({...defaults(),selected:'macro-community'}).selected,'macro-community');assert.equal(catalog.find(m=>m.id==='Raids'),undefined);}
  finally{setCustomMacros([]);}
});
