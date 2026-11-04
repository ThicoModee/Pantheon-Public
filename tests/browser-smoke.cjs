'use strict';

const fs=require('node:fs'),path=require('node:path'),{spawn}=require('node:child_process'),assert=require('node:assert/strict');
const {pathToFileURL}=require('node:url');
const root=path.resolve(__dirname,'..'),out=path.join(root,'test-results');fs.mkdirSync(out,{recursive:true});
const browserProfile=path.join(out,'isolated-browser-'+Date.now());
const browser=spawn('C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',['--headless','--disable-gpu','--no-first-run','--no-default-browser-check','--remote-debugging-port=0',`--user-data-dir=${browserProfile}`,'about:blank'],{windowsHide:true,stdio:['ignore','ignore','pipe']});
const timeout=setTimeout(()=>{browser.kill();process.exitCode=1;console.error('Browser test timed out.');},55000);
let ws;
(async()=>{
  const endpoint=await new Promise((resolve,reject)=>{
    let text='';
    const portFile=path.join(browserProfile,'DevToolsActivePort');
    const polling=setInterval(()=>{try{const [port,url]=fs.readFileSync(portFile,'utf8').trim().split(/\r?\n/);if(port&&url){clearInterval(polling);resolve(`ws://127.0.0.1:${port}${url}`);}}catch{}},50);
    browser.stderr.on('data',chunk=>{text+=chunk;const m=text.match(/DevTools listening on (ws:\/\/[^\s]+)/);if(m){clearInterval(polling);resolve(m[1]);}});
    browser.on('error',e=>{clearInterval(polling);reject(e);});
    browser.on('exit',code=>{if(code){clearInterval(polling);reject(Error('Browser exited '+code+' '+text));}});
  });
  ws=new WebSocket(endpoint);await new Promise((resolve,reject)=>{ws.addEventListener('open',resolve,{once:true});ws.addEventListener('error',reject,{once:true});});
  const waiting=new Map();let next=0,session;const errors=[];
  ws.addEventListener('message',event=>{const m=JSON.parse(event.data);if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails.text+' '+(m.params.exceptionDetails.exception?.description||''));if(m.id&&waiting.has(m.id)){const p=waiting.get(m.id);waiting.delete(m.id);m.error?p.reject(Error(m.error.message)):p.resolve(m.result);}});
  const call=(method,params={},sid=session)=>new Promise((resolve,reject)=>{const id=++next;waiting.set(id,{resolve,reject});ws.send(JSON.stringify({id,method,params,...(sid?{sessionId:sid}:{})}));});
  const target=await call('Target.createTarget',{url:'about:blank'},null);session=(await call('Target.attachToTarget',{targetId:target.targetId,flatten:true},null)).sessionId;
  await call('Runtime.enable');await call('Page.enable');await call('Emulation.setDeviceMetricsOverride',{width:1380,height:900,deviceScaleFactor:1,mobile:false});

  const config=require('../Lib/ui/model.js').defaults(),schemas=require('../Lib/ui/run-settings-schema.js');
  const fixture={config,macros:[],roblox:1,pinned:1,mounted:0,engine:{state:'stopped',active:0,logs:[]},controls:{resizeBind:'F1',startBind:'F2',pauseBind:'F4'}};
  const mock=(state,schemas)=>{
    const handlers=[],packages={},values={},messages=[],placementPlans={};window.__host={state,packages,values,messages};
    const entry=id=>({id,name:packages[id].definition.name,icon:packages[id].definition.icon||'pantheon',custom:1,installed:1});
    window.chrome=window.chrome||{};
    window.chrome.webview={addEventListener:(name,fn)=>handlers.push(fn),postMessage:text=>{
      const m=JSON.parse(text);messages.push(m);let data={};
      switch(m.action){
        case 'playControlsLoad':data={'slot-1':'1','slot-2':'2','slot-3':'3','slot-4':'4','slot-5':'5','slot-6':'6',upgrade:'R',sell:'X',cancel:'Q',targeting:'T','auto-upgrade':'K'};break;
        case 'playControlsSave':data=m.data;break;
        case 'loadPlacements':{const p=placementPlans[m.mode]||PantheonPlacements.defaults();for(const [id,map]of Object.entries(packages[m.mode].definition.maps||{}))if(!p.routes.some(r=>r.id===id))p.routes.push({...PantheonPlacements.route(id,map.name),parent:map.parent||''});placementPlans[m.mode]=p;data={profile:structuredClone(p),frames:{},playback:packages[m.mode].definition.playback||{}};break;}
        case 'savePlacements':placementPlans[m.mode]=m.data;data={saved:1};break;
        case 'capturePlacement':case 'importPlacementFrame':case 'developerSelect':{const c=document.createElement('canvas');c.width=800;c.height=600;const x=c.getContext('2d');x.fillStyle='#263c32';x.fillRect(0,0,800,600);data={image:c.toDataURL(),region:{x:150,y:390,width:100,height:5}};break;}
        case 'placementPickPoint':data={x:350,y:100};break;
        case 'snapshot':state.macros=Object.keys(packages).map(entry);data=structuredClone(state);break;
        case 'selectWorkspace':state.config.selected=m.data;data={selected:m.data};break;
        case 'preferences':state.config=m.data;data=m.data;break;
        case 'loadRunSettings':data={values:values.general||Object.fromEntries(schemas.general.map(f=>[f.key,f.default])),warnings:[]};break;
        case 'saveRunSettings':values.general=m.data;data={values:m.data};break;
        case 'frameworkCatalog':case 'macroCatalogRefresh':data=Object.keys(packages).map(entry);break;
        case 'frameworkLoad':data=structuredClone(packages[m.data]);break;
        case 'frameworkNew':{const id='macro-created-test';packages[id]={package:id,revision:1,definition:{version:1,name:'New macro',game:'roblox-td',mode:'custom',entry:'main',runMode:'once',icon:'pantheon',client:{width:800,height:600},settings:{},targets:{},workflows:{main:{name:'Main sequence',steps:[]}}}};data=structuredClone(packages[id]);break;}
        case 'frameworkSave':{const id=m.data.package;packages[id]={package:id,revision:packages[id].revision+1,definition:structuredClone(m.data.definition)};data=structuredClone(packages[id]);break;}
        case 'developerPickPoint':data={x:321,y:234};break;
        case 'macroSettingsLoad':{const specs=packages[m.data].definition.settings;data={specs,values:values[m.data]||Object.fromEntries(Object.entries(specs).map(([id,s])=>[id,structuredClone(s.default)]))};break;}
        case 'macroSettingsSave':values[m.mode]=m.data;data=structuredClone(m.data);break;
        case 'macroExport':window.__host.exported=JSON.stringify({format:'pantheon-macro',version:1,id:m.data.id,definition:m.data.definition});data={copied:1};break;
        case 'macroImportPreview':{const p=JSON.parse(m.data),d=p.definition;data={id:p.id,name:d.name,game:d.game,icon:d.icon,sequences:Object.keys(d.workflows).length,targets:Object.keys(d.targets).length,settings:Object.keys(d.settings).length,entry:d.entry,runMode:d.runMode,exists:!!packages[p.id],actions:{}};break;}
        case 'macroInstall':{const p=JSON.parse(m.data);packages[p.id]={package:p.id,revision:1,definition:p.definition};data=packages[p.id];break;}
        case 'startEngine':state.engine={state:'running',active:1,logs:['Running']};break;
        case 'pauseEngine':state.engine.state=state.engine.state==='running'?'paused':'running';break;
        case 'stopEngine':state.engine={state:'stopped',active:0,logs:[]};break;
      }
      setTimeout(()=>handlers.forEach(fn=>fn({data:{id:m.id,ok:1,data}})),0);
    }};
  };
  await call('Page.addScriptToEvaluateOnNewDocument',{source:`(${mock.toString()})(${JSON.stringify(fixture)},${JSON.stringify(schemas)})`});
  const evaluate=async expression=>{const r=await call('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.exception?.description||r.exceptionDetails.text);return r.result.value;};
  const until=async expr=>{const start=Date.now();while(!await evaluate(expr)){if(Date.now()-start>7000)throw Error('UI condition timed out: '+expr);await new Promise(r=>setTimeout(r,50));}};
  const activate=selector=>evaluate(`(()=>{const panel=document.querySelector(${JSON.stringify(selector)})?.closest('[data-developer-panel]');if(panel?.hidden)document.querySelector('[data-developer-tab="'+panel.dataset.developerPanel+'"]').click();})()`);
  const click=async selector=>{await activate(selector);return evaluate(`document.querySelector(${JSON.stringify(selector)}).click()`);};
  const change=async(selector,value)=>{await activate(selector);return evaluate(`(()=>{const el=document.querySelector(${JSON.stringify(selector)});el.value=${JSON.stringify(value)};el.dispatchEvent(new Event('change',{bubbles:true}));})()`);};
  const shot=async name=>{const r=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});fs.writeFileSync(path.join(out,name),Buffer.from(r.data,'base64'));};
  await call('Page.navigate',{url:pathToFileURL(path.join(root,'Lib/ui/index.html')).href});
  await until("!document.querySelector('#page-dashboard').hidden");
  assert.equal(await evaluate("document.querySelectorAll('.macro-card').length"),0);
  assert.equal(await evaluate("document.querySelector('#empty-macros').hidden"),false);
  assert.equal(await evaluate("document.querySelector('#import-macro').parentElement===document.querySelector('#refresh-library').parentElement"),true);
  await click('#refresh-library');
  await shot('release-empty-dashboard.png');
  assert.equal(await evaluate("Math.abs(document.querySelector('#refresh-library').getBoundingClientRect().right-document.querySelector('#hub-selection .page-heading').getBoundingClientRect().right)<2"),true);
  assert.equal(await evaluate("document.querySelector('#macro-search').placeholder"),'Search macros…');
  assert.equal(await evaluate("document.querySelector('.about-panel p').textContent.includes('Â')"),false);

  await click('[data-page=settings]');await click('#developer-mode');await click('[data-page=dashboard]');
  await until("!document.querySelector('#developer-nav').hidden");await click('#developer-nav');
  await until("!document.querySelector('#framework-empty').hidden");
  assert.equal(await evaluate("document.querySelector('#framework-content').hidden"),true);
  await click('#framework-new-macro');await until("!document.querySelector('#framework-content').hidden");
  assert.equal(await evaluate("document.querySelectorAll('[data-step-path]').length"),0);
  assert.equal(await evaluate("Object.keys(window.__host.packages['macro-created-test'].definition.targets).length"),0);
  await change('#framework-macro-name','Community TD');await change('#framework-icon','raids');
  assert.ok((await evaluate("document.querySelector('#framework-icon-preview').src")).endsWith('/assets/macros/Raids.png'));
  await change('#framework-setting-type','toggle');await click('#framework-add-setting');
  await click('#framework-add-step');
  await click('[data-step-command=\"point\"]');
  await until("document.querySelector('[data-step-field=x]').value==='321'");
  await change('[data-step-field=action]','press');await change('[data-step-field=key]','space');
  await click('#play-auto-upgrade');
  assert.equal(await evaluate("(()=>{const t=document.querySelector('#play-auto-upgrade').getBoundingClientRect(),r=document.querySelector('#play-auto-upgrade').closest('label').getBoundingClientRect();return Math.abs((t.top+t.bottom)/2-(r.top+r.bottom)/2)<2;})()"),true);
  assert.ok(await evaluate("parseFloat(getComputedStyle(document.querySelector('#play-auto-upgrade').closest('label')).gap)>=24"));

  await change('#play-map-name','Test map');await click('#play-add-map');
  await click('[data-child-map=test-map]');await change('#play-map-name','Act 1');await click('#play-add-map');
  await change('#play-map-name','Infinite');await click('#play-add-map');
  await change('#framework-setting-type','key');await click('#framework-add-setting');
  await change('[data-author-setting=setting-2] [data-setting-field=control]','upgrade');
  await change('[data-author-setting=setting-2] [data-setting-field=label]','Upgrade key');
  await click('[data-author-setting=setting-2] [data-author-key]');
  await evaluate("document.dispatchEvent(new KeyboardEvent('keydown',{key:'T',code:'KeyT',bubbles:true}));document.dispatchEvent(new KeyboardEvent('keyup',{key:'T',code:'KeyT',bubbles:true}))");
  assert.equal(await evaluate("document.querySelector('[data-author-setting=setting-2] [data-author-key]').textContent.trim()"),'T');
  await evaluate("document.querySelector('[data-author-setting=setting-1]').open=false");
  await evaluate("new Promise(r=>setTimeout(r,50))");
  await change('[data-author-setting=setting-2] [data-setting-field=label]','Upgrade key');
  assert.equal(await evaluate("document.querySelector('[data-author-setting=setting-1]').open"),false);
  assert.equal(await evaluate("document.querySelector('#framework-setting-fields').nextElementSibling.contains(document.querySelector('#framework-add-setting'))"),true);
  await change('[data-step-field=name]','Open stage menu');
  await change('#framework-new-action','camera');await click('#framework-add-step');
  await change('#framework-new-action','placements');await click('#framework-add-step');
  await evaluate("[...document.querySelectorAll('.framework-step')].forEach(d=>d.open=false)");
  await evaluate("new Promise(r=>setTimeout(r,70))");
  const drag=async(from,to,cancel=false)=>{
    await evaluate(`document.querySelector(${JSON.stringify(from)}).scrollIntoView({block:'center'})`);
    await evaluate("new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))");
    const coords=await evaluate(`(()=>{const a=document.querySelector(${JSON.stringify(from)}).getBoundingClientRect(),b=document.querySelector(${JSON.stringify(to)}).getBoundingClientRect();return {x:a.left+a.width/2,y:a.top+a.height/2,tx:b.left+b.width/2,ty:b.top+2};})()`);
    await call('Input.dispatchMouseEvent',{type:'mouseMoved',x:coords.x,y:coords.y});
    await call('Input.dispatchMouseEvent',{type:'mousePressed',x:coords.x,y:coords.y,button:'left',buttons:1,clickCount:1});
    await call('Input.dispatchMouseEvent',{type:'mouseMoved',x:coords.x+35,y:coords.ty,buttons:1});
    await until("!!document.querySelector('.step-dragging')");
    const left=await evaluate("document.querySelector('.step-dragging').getBoundingClientRect().left");
    await call('Input.dispatchMouseEvent',{type:'mouseMoved',x:coords.x+100,y:coords.ty+1,buttons:1});
    assert.equal(await evaluate("document.querySelector('.step-dragging').getBoundingClientRect().left"),left);
    assert.equal(await evaluate("document.querySelectorAll('.step-drop-slot').length"),1);
    if(cancel){await call('Input.dispatchKeyEvent',{type:'keyDown',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});await call('Input.dispatchKeyEvent',{type:'keyUp',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});}
    await call('Input.dispatchMouseEvent',{type:'mouseReleased',x:coords.x+100,y:coords.ty+1,button:'left',buttons:0,clickCount:1});
    await until("!document.querySelector('.step-dragging,.step-drop-slot')");
  };
  await drag('[data-step-path=\"2\"] .sequence-grip','[data-step-path=\"0\"] summary',true);
  assert.equal(await evaluate("document.querySelector('[data-step-path=\"0\"] [data-step-field=action]').value"),'press');
  await drag('[data-step-path=\"2\"] .sequence-grip','[data-step-path=\"0\"] summary');
  assert.equal(await evaluate("document.querySelector('[data-step-path=\"0\"] [data-step-field=action]').value"),'placements');
  await click('[data-step-path=\"1\"] [data-step-command=up]');
  assert.equal(await evaluate("document.querySelector('[data-step-path=\"0\"] [data-step-field=name]').value"),'Open stage menu');
  assert.equal(await evaluate("document.querySelector('[data-step-path=\"0\"]').open"),false);
  await change('#framework-new-action','repeat');await click('#framework-add-step');
  await evaluate("document.querySelector('[data-add-group-step=\"3.steps\"]').parentElement.querySelector('select').value='delay'");
  await click('[data-add-group-step=\"3.steps\"]');await click('[data-add-group-step=\"3.steps\"]');
  await change('[data-step-path=\"3.steps.0\"] [data-step-field=name]','First wait');await change('[data-step-path=\"3.steps.1\"] [data-step-field=name]','Second wait');
  await evaluate("[...document.querySelectorAll('[data-step-path^=\"3.steps.\"]')].forEach(d=>d.open=false)");
  await evaluate("new Promise(r=>setTimeout(r,50))");
  await drag('[data-step-path=\"3.steps.1\"] .sequence-grip','[data-step-path=\"3.steps.0\"] summary');
  assert.equal(await evaluate("document.querySelector('[data-step-path=\"3.steps.0\"] [data-step-field=name]').value"),'Second wait');
  assert.equal(await evaluate("document.querySelector('[data-list-path=\"\"]').children.length"),4);
  await evaluate("document.querySelector('#framework-steps').scrollIntoView({block:'start'})");await shot('sequence-folds.png');
  assert.equal(await evaluate("getComputedStyle(document.querySelector('.flow-setting-card')).backgroundColor===getComputedStyle(document.querySelector('.framework-step')).backgroundColor"),true);
  await change('#framework-setting-type','select');await click('#framework-add-setting');
  assert.ok(await evaluate("parseFloat(getComputedStyle(document.querySelector('[data-author-setting=setting-3] .setting-option-add')).marginTop)>=14"));
  assert.ok(await evaluate("parseFloat(getComputedStyle(document.querySelector('[data-author-setting=setting-3] .setting-remove')).marginTop)>=20"));
  await click('[data-author-setting=setting-3] [data-author-command=delete]');
  await click('#framework-save');await until("document.querySelector('#framework-save').disabled");
  await click('#framework-export-macro');await until("!!window.__host.exported");
  const exported=await evaluate('JSON.parse(window.__host.exported)');
  assert.equal(exported.definition.maps['test-map'].name,'Test map');assert.equal(exported.definition.maps['test-map-act-1'].parent,'test-map');assert.equal(exported.definition.settings['setting-2'].type,'key');assert.equal(exported.definition.settings['setting-2'].control,'upgrade');assert.equal(exported.definition.settings['setting-2'].default,'T');assert.ok(exported.definition.workflows.main.steps.some(s=>s.action==='placements'));assert.equal(exported.definition.workflows.main.steps[0].name,'Open stage menu');
  assert.equal(exported.definition.icon,'raids');assert.equal(exported.definition.workflows.main.steps[0].action,'press');
  await evaluate("document.querySelector('#framework-icon').scrollIntoView({block:'center'})");await shot('release-icon-editor.png');
  await click('#developer-back');await until("!!document.querySelector('[data-launch]')");
  assert.ok((await evaluate("document.querySelector('[data-launch]').closest('article').querySelector('img').src")).endsWith('/assets/macros/Raids.png'));
  await click('[data-launch]');await until("!document.querySelector('#macro-dashboard').hidden");
  await click('[data-macro-key=setting-2]');await evaluate("document.dispatchEvent(new KeyboardEvent('keydown',{key:'G',code:'KeyG',bubbles:true}));document.dispatchEvent(new KeyboardEvent('keyup',{key:'G',code:'KeyG',bubbles:true}))");await click('#save-authored-settings');
  assert.equal(await evaluate("window.__host.values['macro-created-test']['setting-2']"),'G');
  await click('[data-page=loadout]');await until("document.querySelectorAll('[data-route-id]').length===4");
  await click('[data-route-id=test-map-act-1]');assert.equal(await evaluate("document.querySelectorAll('.map-route-group').length"),1);await click('#import-spawn');await until("!document.querySelector('#spawn-image').hidden");
  await evaluate("(()=>{const el=document.querySelector('#placement-surface'),r=el.getBoundingClientRect();el.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,button:0,clientX:r.left+120,clientY:r.top+230}));})()");
  await until("document.querySelectorAll('[data-step]').length===2");
  await evaluate("(()=>{const el=document.querySelector('#placement-surface'),r=el.getBoundingClientRect();el.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,button:0,clientX:r.left+180,clientY:r.top+250}));})()");
  await click('[data-unit=\"2\"]');
  await evaluate("(()=>{const el=document.querySelector('#placement-surface'),r=el.getBoundingClientRect();el.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,button:0,clientX:r.left+240,clientY:r.top+280}));})()");
  assert.deepEqual(await evaluate("[...document.querySelectorAll('[data-unit-count]')].map(m=>[m.dataset.unitSlot,m.dataset.unitCount])"),[['1','1'],['1','2'],['2','1']]);
  assert.equal(await evaluate("getComputedStyle(document.querySelectorAll('[data-unit-slot]')[0]).getPropertyValue('--unit-colour')!==getComputedStyle(document.querySelectorAll('[data-unit-slot]')[2]).getPropertyValue('--unit-colour')"),true);
  await click('#add-step');await until("document.querySelector('#step-dialog').open");
  await click('[data-match-kind=upgrade]');await evaluate("(()=>{const s=document.querySelector('#step-placement');s.value=[...s.options].find(o=>o.textContent.includes('Unit 2')).value;})()");
  assert.equal(await evaluate("document.querySelector('#step-position-fields').hidden"),true);
  await shot('match-action-dialog.png');await click('#step-form button[value=save]');await until("!document.querySelector('#step-dialog').open");
  assert.equal(await evaluate("document.querySelectorAll('[data-unit-count]').length"),3);
  await evaluate("(()=>{const el=document.querySelector('#placement-surface'),r=el.getBoundingClientRect();el.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,button:0,clientX:r.left+300,clientY:r.top+300}));})()");
  assert.equal(await evaluate("document.querySelectorAll('[data-unit-count]').length"),4);
  assert.equal(await evaluate("document.querySelector('[data-step]:last-child').classList.contains('kind-place')"),true);
  assert.equal(await evaluate("[...document.querySelectorAll('#slot-buttons button')].map(b=>b.textContent).join(',')"),'1,2,3,4,5,6');
  assert.equal(await evaluate("document.querySelector('#slot-buttons small')"),null);
  const linkedId=await evaluate("document.querySelectorAll('[data-unit-slot]')[2].dataset.marker");
  await click(`[data-step="${linkedId}"] [data-step-action=edit]`);await change('#step-x','63');await change('#step-y','334');
  await change('#step-auto-upgrade','2');await change('#step-targeting','2');
  assert.equal(await evaluate("document.querySelector('#step-pick').getBoundingClientRect().top-document.querySelector('#step-position-fields').getBoundingClientRect().bottom>=12"),true);
  await shot('place-instance-dialog.png');await click('#step-form button[value=save]');
  assert.ok((await evaluate("document.querySelector('.kind-upgrade .step-title').textContent")).includes('63, 334'));
  await click('.kind-upgrade [data-step-action=edit]');
  assert.ok((await evaluate("document.querySelector('#step-placement').selectedOptions[0].textContent")).includes('2a · Unit 2 at (63, 334)'));
  await click('#match-action-close');
  await click('#add-step');await click('[data-match-kind=reconfigure]');
  await evaluate("(()=>{const s=document.querySelector('#step-placement');s.value=s.options[1].value;})()");
  await click('#step-change-targeting');assert.equal(await evaluate("document.querySelector('#step-targeting').disabled"),true);
  assert.equal(await evaluate("document.querySelector('#step-auto-upgrade').value"),'-1');
  await shot('reconfigure-instance-dialog.png');await click('#step-form button[value=save]');await until("!document.querySelector('#step-dialog').open");
  await click('#add-step');await click('[data-match-kind=sell]');
  await evaluate("(()=>{const s=document.querySelector('#step-placement');s.value=[...s.options].find(o=>o.textContent.includes('Unit 2 at (63, 334)')).value;})()");
  assert.equal(await evaluate("document.querySelector('#step-repeat-label').hidden"),true);
  await shot('sell-instance-dialog.png');await click('#step-form button[value=save]');await until("!document.querySelector('#step-dialog').open");

  assert.equal(await evaluate("(()=>{const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');svg.innerHTML=window.PantheonIcons.trash;return document.querySelector('[data-step-action=remove] svg').innerHTML===svg.innerHTML;})()"),true);
  assert.equal(await evaluate("document.querySelector('.kind-start .step-title small').textContent"),'Required');
  await click('[data-start-enabled]');assert.equal(await evaluate("document.querySelector('[data-start-enabled]').checked"),false);
  await click('[data-step-action=edit]');assert.equal(await evaluate("document.querySelector('#step-enabled').checked"),false);await click('#step-enabled');await click('#step-pick');await until("document.querySelector('#step-x').value==='350'");
  await click('#step-form button[value=save]');await until("!document.querySelector('#step-dialog').open");
  await click('#placement-use-shared');await click('#save-placement');await until("document.querySelector('#save-placement').disabled");
  await evaluate("document.querySelector('#page-loadout').scrollIntoView({block:'start'})");await shot('shared-placement-editor.png');
  await click('[data-page=controls]');await until("document.querySelectorAll('[data-play-key]').length===11");
  assert.ok(await evaluate("parseFloat(getComputedStyle(document.querySelector('#save-play-controls')).marginBottom)>0"));
  await click('[data-play-key=upgrade]');await evaluate("document.dispatchEvent(new KeyboardEvent('keydown',{key:'F8',code:'F8',bubbles:true}));document.dispatchEvent(new KeyboardEvent('keyup',{key:'F8',code:'F8',bubbles:true}))");await click('#save-play-controls');
  assert.equal(await evaluate("window.__host.messages.filter(m=>m.action==='playControlsSave').at(-1).data.upgrade"),'F8');
  await click('[data-play-key=upgrade]');
  await evaluate("document.dispatchEvent(new KeyboardEvent('keydown',{key:'Control',ctrlKey:true,bubbles:true}));document.dispatchEvent(new KeyboardEvent('keydown',{key:'R',ctrlKey:true,bubbles:true}));document.dispatchEvent(new KeyboardEvent('keyup',{key:'Control',bubbles:true}))");
  assert.ok((await evaluate("document.querySelector('[data-play-key=upgrade]').textContent")).includes('Press a key'));
  await evaluate("document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}))");
  assert.equal(await evaluate("document.querySelector('[data-play-key=upgrade]').textContent.trim()"),'F8');

  await click('[data-page=dashboard]');
  await click('#start-engine');await until("document.querySelector('#start-label').textContent==='Stop macro'");
  await click('#pause-engine');await until("document.querySelector('#pause-label').textContent==='Resume'");
  await click('#pause-engine');await until("document.querySelector('#pause-label').textContent==='Pause'&&!document.querySelector('#start-engine').disabled");await click('#start-engine');await until("document.querySelector('#start-label').textContent==='Start macro'");
  await click('#back-to-hub');await click('#import-macro');
  exported.id='macro-imported-test';exported.definition.name='Imported TD';exported.definition.playback.autoUpgrade=0;
  await evaluate(`document.querySelector('#macro-import-text').value=${JSON.stringify(JSON.stringify(exported))};document.querySelector('#macro-import-text').dispatchEvent(new Event('input',{bubbles:true}));`);
  await click('#macro-import-preview');await until("!document.querySelector('#macro-import-install').disabled");await click('#macro-import-install');
  await until("document.querySelectorAll('[data-launch]').length===2");
  assert.ok((await evaluate("document.querySelector('[data-launch=macro-imported-test]').closest('article').querySelector('img').src")).endsWith('/assets/macros/Raids.png'));
  await shot('release-dashboard.png');
  await click('[data-launch=macro-imported-test]');await click('[data-page=loadout]');await until("!document.querySelector('.placement-content').inert");
  await click('#add-step');assert.equal(await evaluate("document.querySelector('#step-auto-fields').hidden"),true);
  assert.equal(await evaluate("!!document.querySelector('[data-match-kind=upgrade]')"),true);await click('#match-action-close');

  await evaluate(`window.__host.packages['macro-imported-test'].definition.targets=${JSON.stringify(JSON.parse(fs.readFileSync(path.join(root,'tests/data/flow-fixture.json'),'utf8')).targets)}`);
  await click('[data-page=developer]');await click('#framework-reload');await until("!!document.querySelector('#framework-package option[value=macro-imported-test]')");await change('#framework-package','macro-imported-test');await until("document.querySelector('#framework-macro-name').value==='Imported TD'");
  await click('[data-managed-enable]');
  assert.equal(await evaluate("document.querySelector('[data-managed=settleMs]').value"),'0.25');
  assert.equal(await evaluate("document.querySelector('[data-managed=settleMs]').checkValidity()"),true);
  for(const [field,target] of [['panel','popup-close'],['affordable','close-a'],['max','close-b']])await change('[data-managed='+field+']',target);
  await click('[data-managed-pick=close]');await until("document.querySelector('#play-managed-upgrades').textContent.includes('(321, 234)')");
  await click('[data-managed-pick=progress]');await until("document.querySelector('#play-managed-upgrades').textContent.includes('100 × 5')");
  await click('[data-feedback-command=add]');
  for(const [field,target] of [['panel','popup-close'],['money','close-a'],['limit','close-b']])await change('[data-feedback='+field+']',target);
  await change('[data-managed=intervalMs]','1.5');await click('#framework-save');await until("document.querySelector('#framework-state').textContent.startsWith('Saved')");
  assert.equal(await evaluate("window.__host.packages['macro-imported-test'].definition.playback.managedUpgrade.intervalMs"),1500);
  await click('[data-page=loadout]');await until("!document.querySelector('.placement-content').inert");await click('#add-step');
  assert.equal(await evaluate("document.querySelector('#step-managed-fields').hidden"),false);
  assert.equal(await evaluate("document.querySelector('#step-timeout-label').hidden"),false);
  await change('#step-timeout','90');
  await change('#step-managed-priority','2');await change('#step-managed-limit','3');await click('#step-form button[value=save]');await click('#save-placement');
  assert.equal(await evaluate("window.__host.messages.filter(m=>m.action==='savePlacements').at(-1).data.routes.flatMap(r=>r.teams.flatMap(t=>t.steps)).some(s=>s.kind==='place'&&s.managedPriority===2&&s.managedLimit===3)"),true);
  await shot('managed-upgrade-editor.png');

  await click('[data-page=developer]');await change('#framework-new-action','delay');await click('#framework-add-step');await click('#framework-add-step');
  const stability=await evaluate(`(()=>{
    const list=document.querySelector('#framework-steps>.flow-step-list'),cards=[...list.children].filter(el=>el.matches('details'));
    const previous=cards.at(-2),card=cards.at(-1),input=card.querySelector('[data-step-field=name]'),duration=card.querySelector('[data-step-field=durationMs]');
    previous.open=false;input.scrollIntoView({block:'center'});input.focus({preventScroll:true});const top=window.scrollY;
    input.value='Upgrade wait';input.dispatchEvent(new Event('change',{bubbles:true}));
    const sameName=input.isConnected&&document.activeElement===input;duration.value='1.25';duration.dispatchEvent(new Event('change',{bubbles:true}));
    const unchanged=duration.isConnected&&!previous.open&&Math.abs(window.scrollY-top)<2;
    card.querySelector('[data-step-field=action]').value='repeat';card.querySelector('[data-step-field=action]').dispatchEvent(new Event('change',{bubbles:true}));
    const after=[...document.querySelector('#framework-steps>.flow-step-list').children].filter(el=>el.matches('details'));
    return {sameName,unchanged,stillClosed:!after.at(-2).open,stillOpen:after.at(-1).open};
  })()`);
  assert.deepEqual(stability,{sameName:true,unchanged:true,stillClosed:true,stillOpen:true});
  await evaluate('new Promise(resolve=>setTimeout(resolve,50))');
  assert.equal(await evaluate("[...document.querySelector('#framework-steps>.flow-step-list').children].filter(el=>el.matches('details')).at(-2).open"),false);
  for(const position of ['top','bottom']){
    await evaluate(position==='top'?'window.scrollTo(0,0)':'window.scrollTo(0,document.body.scrollHeight)');
    assert.equal(await evaluate("getComputedStyle(document.querySelector('#framework-savebar')).position"),'fixed');
    assert.equal(await evaluate("Math.round(document.querySelector('#framework-savebar').getBoundingClientRect().bottom)===innerHeight"),true);
  }
  await shot('anchored-editor-savebar.png');

  await click('#framework-add-target');
  const freshTarget=await evaluate("document.querySelector('#framework-target').value");
  assert.equal(await evaluate(`!!document.querySelector('[data-managed=panel] option[value="${freshTarget}"]')`),true);
  assert.equal(await evaluate(`!!document.querySelector('[data-feedback=money] option[value="${freshTarget}"]')`),true);
  await change('[data-managed=panel]',freshTarget);
  await activate('#framework-target-fields [data-target-field=name]');
  const renameStatus=await evaluate(`(()=>{const el=document.querySelector('#framework-target-fields [data-target-field=name]');el.focus({preventScroll:true});el.value='Selected unit panel';el.dispatchEvent(new Event('input',{bubbles:true}));const menu=document.querySelector('[data-managed=panel]');return {selected:menu.value,name:menu.selectedOptions[0].textContent,sameInput:el===document.activeElement&&el.isConnected};})()`);
  assert.deepEqual(renameStatus,{selected:freshTarget,name:'Selected unit panel',sameInput:true});
  assert.equal(await evaluate(`document.querySelector('#framework-target option[value="${freshTarget}"]').textContent`),'Selected unit panel');

  await click('#framework-capture-bounds');
  assert.equal(await evaluate("document.querySelector('[data-target-field=x]').value"),'150');
  assert.equal(await evaluate("document.querySelector('[data-target-field=width]').value"),'100');
  assert.equal(await evaluate("document.querySelectorAll('[data-developer-tab]').length"),6);
  for(const tab of ['macro','sequences','images','placement','capture','guide']){
    await click('[data-developer-tab='+tab+']');
    assert.equal(await evaluate("[...document.querySelectorAll('[data-developer-panel]')].filter(p=>!p.hidden).length"),1);
    assert.equal(await evaluate(`document.querySelector('[data-developer-panel=${tab}]').hidden`),false);
    assert.equal(await evaluate(`document.querySelector('[data-developer-tab=${tab}]').getAttribute('aria-selected')`),'true');
  }
  await evaluate("document.querySelector('#component-guide-search').value='reward';document.querySelector('#component-guide-search').dispatchEvent(new Event('input',{bubbles:true}))");
  assert.equal(await evaluate("!!document.querySelector('#component-guide-dismiss')"),true);
  await click('[data-developer-tab=sequences]');
  for(const action of ['click-wait','scroll-option','dismiss','setting-call']){
    await change('#framework-new-action',action);await click('#framework-add-step');
    assert.equal(await evaluate(`document.querySelector('#framework-steps>.flow-step-list>details:last-child [data-step-field=action]').value`),action);
  }
  await click('#framework-steps>.flow-step-list>details:last-child [data-component-help]');
  assert.equal(await evaluate("document.querySelector('[data-developer-tab=guide]').getAttribute('aria-selected')"),'true');
  assert.equal(await evaluate("!!document.querySelector('#component-guide-setting-call')"),true);
  await shot('developer-component-guide.png');
  await click('[data-developer-tab=sequences]');await shot('developer-sequences-tab.png');

  await click('[data-page=settings]');
  const themeSurfaces=[];
  for(const theme of ['christmas','midnight','rose','ember','default']){
    await click('[data-theme-choice='+theme+']');
    await until(`window.__host.state.config.theme==='${theme}'`);
    assert.equal(await evaluate('document.documentElement.dataset.theme'),theme);
    themeSurfaces.push(await evaluate("[getComputedStyle(document.documentElement).getPropertyValue('--panel').trim(),getComputedStyle(document.documentElement).getPropertyValue('--bg').trim()].join('|')"));
    if(theme!=='default'){
      const consistent=await evaluate(`(()=>{const rgb=token=>{const el=document.createElement('span');el.style.color='var('+token+')';document.body.append(el);const c=getComputedStyle(el).color;el.remove();return c;};return {status:getComputedStyle(document.querySelector('.sidebar-state')).backgroundColor===rgb('--panel'),filter:getComputedStyle(document.querySelector('.segments')).backgroundColor===rgb('--input'),selected:getComputedStyle(document.querySelector('.segments>button.active')).backgroundColor===rgb('--accent-soft'),search:getComputedStyle(document.querySelector('.search-field input')).backgroundColor==='rgba(0, 0, 0, 0)',labels:getComputedStyle(document.querySelector('.nav-section')).color===getComputedStyle(document.querySelector('.sidebar-title')).color,border:getComputedStyle(document.querySelector('.app-header')).borderBottomColor===rgb('--line')};})()`);
      assert.ok(Object.values(consistent).every(Boolean),theme+' '+JSON.stringify(consistent));
    }
    if(theme==='christmas'){
      assert.equal(await evaluate("document.querySelectorAll('.theme-swatch').length"),5);
      assert.equal(await evaluate("document.querySelector('[data-theme-choice=christmas]').getAttribute('aria-pressed')"),'true');
      assert.ok((await evaluate("getComputedStyle(document.querySelector('[data-theme-choice=christmas]')).backgroundImage")).includes('linear-gradient'));
      await evaluate("document.querySelector('#theme-options').scrollIntoView({block:'center'})");await shot('christmas-theme-picker.png');
      await click('[data-page=loadout]');await until("!document.querySelector('.placement-content').inert");
      const placementStyle=await evaluate(`(()=>{const rgb=token=>{const el=document.createElement('span');el.style.color='var('+token+')';document.body.append(el);const c=getComputedStyle(el).color;el.remove();return c;};const row=document.querySelector('.match-step');return {row:getComputedStyle(row).backgroundColor===rgb('--input'),rail:getComputedStyle(document.querySelector('.route-rail')).backgroundColor===rgb('--sidebar'),stripe:getComputedStyle(row).borderLeftWidth==='1px',nav:getComputedStyle(document.querySelector('nav>a.active')).boxShadow==='none'};})()`);
      assert.ok(Object.values(placementStyle).every(Boolean),JSON.stringify(placementStyle));
      await evaluate("document.querySelector('#match-step-list').scrollIntoView({block:'center'})");await shot('christmas-placement-theme.png');await click('[data-page=settings]');
    }

  }
  assert.equal(new Set(themeSurfaces).size,5);
  assert.equal(await evaluate("document.querySelector('.swatches').closest('.setting-row').hidden"),false);

  await click('[data-theme-choice=midnight]');await click('[data-page=dashboard]');await click('#back-to-hub');await shot('midnight-theme-consistency.png');

  assert.deepEqual(errors,[]);
  console.log('PASS: linked instance selection/moved coordinates, Reconfigure and optional auto upgrade, compact slots, corrected text/padding, key recording and modifier rejection, collapsible named steps/settings, root/nested drag/drop and cancellation, slot colours/counters, match dialog, map groups, sidebar developer tools, creator maps/key overrides, player screenshot/points/start setup, global controls, empty release, generic developer workspace, blank creation, bundled icon selection/export/import, settings/coordinate/key editing, dashboard controls and run lifecycle; no browser errors.');
  await call('Browser.close',{},null).catch(()=>{});
})().catch(error=>{console.error(error.stack||error.message||String(error));process.exitCode=1;}).finally(()=>{clearTimeout(timeout);ws?.close();if(!browser.killed)browser.kill();});
