(() => {

  'use strict';

  const {catalog,defaults:hubDefaults,mode,preferences,shortcut,keyLabel,setCustomMacros}=PantheonHub;

  const $=id=>document.getElementById(id);

  const native=!!window.chrome?.webview;

  const icons=window.PantheonIcons;

  const icon=name=>`<svg viewBox="0 0 24 24" aria-hidden="true">${icons[name]||icons.grid}</svg>`;

  const macroIcon=id=>`<img class="original-macro-icon" src="${mode(id).image}" alt="">`;

  const paintIcons=()=>document.querySelectorAll('[data-icon]').forEach(el=>{el.innerHTML=icon(el.dataset.icon);});

  const escapeHtml=v=>String(v).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

  const pending=new Map();
  PantheonKeyCapture.onState=active=>request('recordingKey',Number(active)).catch(e=>toast(e.message,true));

  let workspaceMode=null;

  const setText=(id,text)=>{const el=$(id);if(el.textContent!==String(text))el.textContent=text;};

  const setHTML=(id,html)=>{const el=$(id);if(el._html!==html){el.innerHTML=html;el._html=html;}};

  let config=hubDefaults(),snapshot=null,page='dashboard',filter='all',selected='',busy=false,toastTimer,recording=null,controls={},savedControls={},lastDirty=false,modalResolve=null,preferenceQueue=Promise.resolve();

  const runSettings=new RunSettingsPanel({request,toast,changed:trackDirty});

  const developer=new DeveloperPanel({request,toast});

  const authoredSettings=new MacroSettingsPanel({request,toast,changed:trackDirty});

  const editor=new PlacementEditor({request,icon,toast,changed:trackDirty,confirm:confirmAction});
  const framework=new FrameworkEditor({request,toast,changed:trackDirty,point:()=>developer.pickCoordinates(),catalogChanged:async()=>{await refreshSnapshot();if(workspaceMode)await authoredSettings.open(workspaceMode,true);},select:()=>developer.selectRegion(),capture:()=>({pattern:developer.code,region:{...developer.selection}})});

  const playEditor=new PlayEditor({framework,editor,request,toast,changed:trackDirty});
  const developerWorkspace=new DeveloperWorkspace();
  const controlInfo=[['resizeBind','Set up Roblox','Position and resize the game window.'],['startBind','Start / stop','Start or stop the selected macro.'],['pauseBind','Pause / resume','Temporarily pause or continue the macro.']];

  function toast(message,error=false) {clearTimeout(toastTimer);$('toast').textContent=message;$('toast').classList.toggle('error',error);$('toast').hidden=false;toastTimer=setTimeout(()=>{$('toast').hidden=true;},error?9000:4300);}

  function request(action,data,macro=selected) {

    if(!native) return previewRequest(action,data,macro);

    return new Promise((resolve,reject)=>{

      const id=crypto.randomUUID();

      const timeout=setTimeout(()=>{pending.delete(id);reject(Error('Pantheon did not respond.'));},['chooseFolder','importPlacementFrame','developerExport','developerSelect','developerPickPoint','placementPickPoint'].includes(action)?300000:['startEngine','testWebhook','developerTest'].includes(action)?30000:12000);

      pending.set(id,{resolve,reject,timeout});

      window.chrome.webview.postMessage(JSON.stringify({id,action,data,mode:macro}));

    });

  }

  if(native) window.chrome.webview.addEventListener('message',e=>{

    const r=e.data;if(r?.event==='error'){toast(r.message,true);return;}const p=pending.get(r?.id);if(!p)return;clearTimeout(p.timeout);pending.delete(r.id);r.ok?p.resolve(r.data):p.reject(Error(r.error||'The action could not be completed.'));

  });

  async function previewRequest(action,data,macro) {

    const store='pantheon.hub.';

    switch(action) {

      case 'snapshot': return {config:preferences(JSON.parse(localStorage.getItem(store+'preferences')||JSON.stringify(hubDefaults()))),macros:catalog.map(m=>({id:m.id,installed:0,opened:0,seconds:0})),roblox:0,controls:JSON.parse(localStorage.getItem(store+'controls')||'{"resizeBind":"F1","startBind":"F2","pauseBind":"F4"}'),history:[{time:'—',message:'Browser preview. Open Pantheon.ahk for the native launcher.'}]};

      case 'preferences': localStorage.setItem(store+'preferences',JSON.stringify(preferences(data)));return data;

      case 'dirty': return {};

      case 'loadRunSettings': {const fields=macro==='general'?PantheonRunSchema.general:PantheonRunSchema.modes[macro];return {values:JSON.parse(localStorage.getItem(store+'run.'+macro)||JSON.stringify(Object.fromEntries(fields.map(f=>[f.key,f.default])))),warnings:[]};}

      case 'saveRunSettings':localStorage.setItem(store+'run.'+macro,JSON.stringify(data));return {values:data};

      default: throw Error('Open Pantheon.ahk to use this desktop feature.');

    }

  }

  function confirmAction(title,description,label) {

    if(modalResolve) return Promise.resolve(false);

    hideMount();$('dialog-title').textContent=title;$('dialog-description').textContent=description;$('dialog-confirm').textContent=label;

    $('confirm-dialog').returnValue='cancel';$('confirm-dialog').showModal();

    return new Promise(resolve=>{modalResolve=resolve;});

  }

  $('confirm-dialog').addEventListener('close',()=>{const r=modalResolve;modalResolve=null;scheduleMount();r?.($('confirm-dialog').returnValue==='confirm');});

  function applyAppearance() {

    document.documentElement.dataset.theme=config.theme;document.documentElement.dataset.accent=config.accent;document.documentElement.dataset.scale=config.scale;

    document.body.classList.toggle('compact',!!config.compact);

    document.querySelectorAll('[data-theme-choice]').forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.themeChoice===config.theme)));document.querySelector('.swatches').closest('.setting-row').hidden=config.theme!=='default';$('compact-sidebar').checked=!!config.compact;$('interface-size').value=config.scale;

    developer.setEnabled(config.developer);$('developer-nav').hidden=!config.developer;

    document.querySelectorAll('.swatch').forEach(b=>{b.classList.toggle('selected',b.dataset.accent===config.accent);b.setAttribute('aria-pressed',String(b.dataset.accent===config.accent));});

    $('collapse').setAttribute('aria-label',config.compact?'Expand sidebar':'Collapse sidebar');

    $('collapse').title=config.compact?'Expand sidebar':'Collapse sidebar';

  }

  function persistPreferences() {

    const submitted=structuredClone(config);

    preferenceQueue=preferenceQueue.catch(()=>{}).then(()=>request('preferences',submitted)).catch(e=>{toast('Could not save preferences. '+e.message,true);});

    return preferenceQueue;

  }

  function setSelected(id) {mode(id);selected=id;config.selected=id;renderDashboard();persistPreferences();}

  function macroState(id) {return snapshot?.macros.find(m=>m.id===id)||{installed:0,opened:0,seconds:0};}

  function controlsDirty(){return controlInfo.some(([id])=>controls[id]!==savedControls[id]);}

  function trackDirty() {

    const any=editor.dirty()||playEditor.dirty()||controlsDirty()||runSettings.dirty()||framework.dirty()||authoredSettings.dirty();

    if(any!==lastDirty){lastDirty=any;if(native)window.chrome.webview.postMessage(JSON.stringify({id:crypto.randomUUID(),action:'dirty',data:Number(any)}));}

    return any;

  }

  function route(next) {
    PantheonKeyCapture.cancel();

    if(!['dashboard','loadout','controls','settings','developer'].includes(next))next='dashboard';

    if(next==='developer'&&!config.developer)next='dashboard';

    if(next!=='dashboard'&&['running','paused'].includes(snapshot?.engine?.state)) {

      if(location.hash!=='#dashboard')location.hash='dashboard';

      toast('Stop the macro before leaving its workspace.',true);return;

    }

    recording=null;page=next;

    document.querySelectorAll('.page').forEach(el=>{el.hidden=el.id!=='page-'+next;});

    document.querySelectorAll('nav>a').forEach(a=>{const active=a.dataset.page===next;a.classList.toggle('active',active);active?a.setAttribute('aria-current','page'):a.removeAttribute('aria-current');});

    $('breadcrumb').textContent=({dashboard:'Dashboard',loadout:'Placement setup',controls:'Controls',settings:'Settings',developer:'Developer tools'})[next];

    document.title='Pantheon · '+$('breadcrumb').textContent;

    window.scrollTo(0,0);

    if(next==='loadout'){if(!selected){toast('Select a macro first.',true);navigate('dashboard');return;}editor.open(selected);}
    if(next==='controls'){renderControls();playEditor.openControls();}

    if(next==='settings')runSettings.open('general');

    if(next==='developer')framework.open();

    renderDashboard();scheduleMount();

  }

  window.addEventListener('hashchange',()=>route(location.hash.slice(1)));

  const navigate=p=>{if(location.hash==='#'+p)route(p);else location.hash=p;};

  function renderDashboard() {

    const m=catalog.find(m=>m.id===selected)||{id:'',name:'Macro'},ms=macroState(selected),engine=snapshot?.engine||{state:'stopped',logs:[]};

    $('hub-selection').hidden=!!workspaceMode;$('macro-dashboard').hidden=!workspaceMode;

    setText('workspace-title',m.name||m.id);setHTML('workspace-icon',m.id?macroIcon(m.id):'');

    const active=['running','paused','initializing'].includes(engine.state);

    runSettings.locked=busy||active;runSettings.update();

    authoredSettings.setLocked(busy||active);

    $('configure-selected').hidden=false;

    $('start-engine').disabled=busy||!native||(!active&&(!ms.installed||!snapshot?.roblox));

    setText('start-label',active?'Stop macro':'Start macro');setHTML('start-icon',icon(active?'square':'play'));

    $('pause-engine').disabled=busy||!['running','paused'].includes(engine.state);

    $('back-to-hub').disabled=busy||active;

    setText('pause-label',engine.state==='paused'?'Resume':'Pause');

    const status=PantheonHub.statePresentation(engine.state,'',Object.fromEntries(Object.entries(controls).map(([k,v])=>[k,keyLabel(v)])));

    setText('sidebar-status',status.label);setText('hotkey-hint',status.hint);$('operation-dot').dataset.tone=status.tone;

    setText('phase-text',engine.state==='running'?'Macro running.':engine.state==='paused'?'Macro paused.':engine.state==='error'?'Run stopped with an error.':'Ready to run a saved setup.');

    const logs=engine.logs||[];setText('current-task','Current task: '+(active&&logs.length?logs.at(-1).replace(/^\d\d:\d\d:\d\d\s+/,''):'none'));

    const secs=engine.seconds||0;setText('runtime',[Math.floor(secs/3600),Math.floor(secs/60)%60,secs%60].map(n=>String(n).padStart(2,'0')).join(':'));

    setText('victories',engine.wins||0);setText('defeats',engine.losses||0);

    $('pin-roblox').checked=snapshot?.pinned!==0;$('pin-roblox').disabled=busy||!native||active;

    $('game-empty').hidden=!!snapshot?.mounted;

    setText('game-empty-title',snapshot?.roblox?'Roblox is ready to pin.':'Roblox is not open. It will pin here automatically.');

    const log=$('engine-log'),atEnd=log.scrollTop+log.clientHeight>=log.scrollHeight-12;setText('engine-log',logs.join('\n'));if(atEnd)log.scrollTop=log.scrollHeight;

    setText('macro-settings-title',(m.name||m.id)+' setup');

    setText('breadcrumb',page==='dashboard'?(workspaceMode?(m.name||m.id):'Dashboard'):({controls:'Controls',settings:'Settings',developer:'Developer tools'})[page]);

    scheduleMount();

  }

  function renderLibrary() {

    const search=$('macro-search').value.trim().toLowerCase();

    const matches=catalog.filter(m=>(filter!=='favorites'||config.favorites.includes(m.id))&&(m.name||m.id).toLowerCase().includes(search));

    $('macro-grid').innerHTML=matches.map(m=>{

      const favorite=config.favorites.includes(m.id);

      return `<article class="panel macro-card"><div class="macro-card-top"><span class="macro-emblem">${macroIcon(m.id)}</span><button class="icon-button favorite${favorite?' active':''}" data-favorite="${m.id}" aria-label="${favorite?'Remove':'Add'} ${escapeHtml(m.name||m.id)} ${favorite?'from':'to'} favourites" aria-pressed="${favorite}">${icon('star')}</button></div><h2>${escapeHtml(m.name||m.id)}</h2><div class="macro-card-actions"><button class="button" data-launch="${m.id}">${icon('arrow')}Select macro</button><button class="icon-button" data-configure="${m.id}" aria-label="${escapeHtml(m.name||m.id)} settings" title="Settings">${icon('settings')}</button></div></article>`;

    }).join('');

    $('hub-count').textContent=catalog.length;
    $('empty-macros').hidden=matches.length>0;

  }

  async function refreshSnapshot(initial=false) {

    try {

      const result=await request('snapshot');

      const custom=(result.macros||[]).filter(m=>m.custom),before=JSON.stringify(catalog.filter(m=>m.custom));setCustomMacros(custom);const catalogChanged=before!==JSON.stringify(catalog.filter(m=>m.custom));

      snapshot=result;

      if(!catalog.some(m=>m.id===selected)){selected='';workspaceMode=null;}

      if(initial){config=preferences(result.config);selected=config.selected;controls=result.controls;savedControls=structuredClone(controls);applyAppearance();}

      renderDashboard();if(initial||catalogChanged)renderLibrary();

      if(native){$('connection-banner').hidden=!result.warnings?.length;$('connection-banner').textContent=(result.warnings||[]).join(' ');}

    }catch(e){if(initial)throw e;toast(e.message,true);}

  }

  async function launch(id) {

    if(busy)return;

    try {

      if(native)await request('selectWorkspace',mode(id).id);

      workspaceMode=id;setSelected(id);navigate('dashboard');const custom=!!mode(id).custom;$('run-settings-fields').hidden=custom;$('save-run-settings').closest('.settings-save-row').hidden=custom;

      runSettings.mode=null;await authoredSettings.open(id,true);

    }catch(e){toast(e.message,true);}

  }

  function renderControls() {

    $('control-rows').innerHTML=controlInfo.map(([id,label,description])=>`<div class="control-row"><div><strong>${label}</strong><p>${description}</p></div><button class="button key-button${recording===id?' recording':''}" data-record="${id}" aria-label="Change ${label.toLowerCase()} shortcut">${icon('keyboard')}<span>${recording===id?'Press a shortcut…':escapeHtml(keyLabel(controls[id]||''))}</span></button></div>`).join('');

    $('apply-controls').disabled=!native||busy||!controlsDirty();

    trackDirty();

  }

  document.addEventListener('keydown',event=>{

    if(!recording)return;

    event.preventDefault();event.stopPropagation();

    if(event.key==='Escape'){recording=null;renderControls();return;}

    try{const key=shortcut(event);if(!key)return;controls[recording]=key;recording=null;renderControls();}

    catch(e){toast(e.message,true);}

  },true);

  $('reset-controls').addEventListener('click',()=>{controls={resizeBind:'F1',startBind:'F2',pauseBind:'F4'};recording=null;renderControls();});

  $('apply-controls').addEventListener('click',async()=>{

    if(!await confirmAction('Update macro shortcuts?','Update the shortcuts shared by your Pantheon workspaces.','Apply'))return;

    try{busy=true;renderControls();controls=await request('applyControls',controls);savedControls=structuredClone(controls);toast('Shortcuts updated.');await refreshSnapshot();}

    catch(e){toast(e.message,true);}finally{busy=false;renderControls();}

  });

  document.addEventListener('click',async event=>{

    const b=event.target.closest('[data-developer],[data-launch],[data-configure],[data-favorite],[data-filter],[data-select],[data-slot],[data-record],.swatch[data-accent],[data-route],[data-action]');if(!b)return;

    if(b.dataset.developer)navigate('developer');

    else if(b.dataset.launch)launch(b.dataset.launch);

    else if(b.dataset.configure){await launch(b.dataset.configure);requestAnimationFrame(()=>$('run-configuration').scrollIntoView({block:'start'}));}

    else if(b.dataset.favorite){const id=b.dataset.favorite;config.favorites=config.favorites.includes(id)?config.favorites.filter(value=>value!==id):[...config.favorites,id];persistPreferences();renderLibrary();}

    else if(b.dataset.filter){filter=b.dataset.filter;document.querySelectorAll('[data-filter]').forEach(button=>button.classList.toggle('active',button===b));renderLibrary();}

    else if(b.dataset.select)launch(b.dataset.select);



    else if(b.dataset.record){recording=b.dataset.record;renderControls();}

    else if(b.dataset.accent){config.accent=b.dataset.accent;applyAppearance();persistPreferences();}

    else if(b.dataset.route)navigate(b.dataset.route);

  });

  async function engineAction(action) {

    if(busy)return;

    if(action==='startEngine'&&(!await runSettings.prepareStart('general')||!await authoredSettings.prepareStart()||!await playEditor.prepareStart()))return;

    busy=true;renderDashboard();

    try {

      if(action==='startEngine')await sendMount();

      await request(action,selected);await refreshSnapshot();

    }catch(e){toast(e.message,true);}finally{busy=false;renderDashboard();}

  }

  $('start-engine').addEventListener('click',()=>engineAction(['running','paused','initializing'].includes(snapshot?.engine?.state)?'stopEngine':'startEngine'));

  $('pause-engine').addEventListener('click',()=>engineAction('pauseEngine'));

  $('pin-roblox').addEventListener('change',async e=>{

    try{await sendMount();await request(e.target.checked?'mount':'detach');await refreshSnapshot();}catch(err){toast(err.message,true);await refreshSnapshot();}

  });

  $('configure-selected').addEventListener('click',()=>navigate('loadout'));
  $('show-run-settings').addEventListener('click',()=>$('run-configuration').scrollIntoView({block:'start',behavior:'smooth'}));

  $('back-to-hub').addEventListener('click',()=>{workspaceMode=null;renderDashboard();scheduleMount();});

  $('refresh-library').addEventListener('click',async()=>{try{await request('macroCatalogRefresh');await refreshSnapshot();}catch(e){toast(e.message,true);}});

  $('macro-search').addEventListener('input',renderLibrary);

  $('join-discord').addEventListener('click',async()=>{try{await request('joinDiscord');}catch(e){toast(e.message,true);}});

  let reviewedImport='';

  $('import-macro').addEventListener('click',()=>{reviewedImport='';$('macro-import-text').value='';$('macro-import-review').textContent='';$('macro-import-install').disabled=true;hideMount();$('macro-import-dialog').showModal();});

  $('macro-import-cancel').addEventListener('click',()=>$('macro-import-dialog').close());

  $('macro-import-dialog').addEventListener('close',scheduleMount);

  $('macro-import-text').addEventListener('input',()=>{reviewedImport='';$('macro-import-install').disabled=true;$('macro-import-review').textContent='';});

  $('macro-import-preview').addEventListener('click',async()=>{const text=$('macro-import-text').value;try{const p=await request('macroImportPreview',text);if($('macro-import-text').value!==text)return;reviewedImport=text;$('macro-import-review').textContent=`${p.name}\nGame: ${p.game}\n${p.sequences} sequences · ${p.targets} images / points · ${p.settings} settings\nRuns: ${p.runMode==='repeat'?'Repeat main sequence':'Once'}\nActions: ${Object.entries(p.actions||{}).map(([id,count])=>(PantheonFlowActions.labels[id]||id)+' × '+count).join(', ')||'No input steps'}\nReview the sequences before running.${p.exists?'\nThis macro is already installed. Existing macros will not be overwritten.':''}`;$('macro-import-install').disabled=!!p.exists;}catch(e){reviewedImport='';$('macro-import-install').disabled=true;$('macro-import-review').textContent=e.message;}});

  $('macro-import-install').addEventListener('click',async()=>{if(!reviewedImport||reviewedImport!==$('macro-import-text').value)return;try{await request('macroInstall',reviewedImport);$('macro-import-dialog').close();await refreshSnapshot();workspaceMode=null;navigate('dashboard');toast('Macro added to the dashboard.');}catch(e){toast(e.message,true);}});

  $('collapse').addEventListener('click',()=>{config.compact=Number(!config.compact);applyAppearance();persistPreferences();});

  $('compact-sidebar').addEventListener('input',e=>{config.compact=Number(e.target.checked);applyAppearance();persistPreferences();});

  $('theme-options').addEventListener('click',e=>{const button=e.target.closest('[data-theme-choice]');if(!button)return;config.theme=button.dataset.themeChoice;applyAppearance();persistPreferences();});

  $('interface-size').addEventListener('input',e=>{config.scale=Number(e.target.value);applyAppearance();persistPreferences();});

  $('developer-mode').addEventListener('change',async e=>{config.developer=Number(e.target.checked);await persistPreferences();developer.setEnabled(config.developer);$('developer-nav').hidden=!config.developer;renderLibrary();});

  $('developer-back').addEventListener('click',()=>{workspaceMode=null;navigate('dashboard');});

  document.querySelectorAll('[data-window]').forEach(button=>button.addEventListener('click',async()=>{try{await request('window',button.dataset.window);}catch(e){toast(e.message,true);}}));

  $('resize-grip').addEventListener('pointerdown',e=>{if(e.button===0&&native){e.preventDefault();request('window','resize').catch(err=>toast(err.message,true));}});

  window.addEventListener('beforeunload',e=>{if(trackDirty()){e.preventDefault();e.returnValue='';}});

  let mountTimer,lastMount='';

  function mountBounds() {

    const r=$('game-mount').getBoundingClientRect(),d=window.devicePixelRatio||1;

    const visible=page==='dashboard'&&!!workspaceMode&&!$('confirm-dialog').open&&!$('macro-import-dialog').open&&r.top>=48&&r.bottom<=innerHeight&&r.width>0;

    return {x:Math.round(r.left*d),y:Math.round(r.top*d),width:Math.round(r.width*d),height:Math.round(r.height*d),visible:Number(visible)};

  }

  async function sendMount() {

    if(!native)return;

    const bounds=mountBounds();lastMount=JSON.stringify(bounds);

    await request('mountLayout',bounds);

  }

  function scheduleMount(){clearTimeout(mountTimer);mountTimer=setTimeout(()=>{

    if(native&&JSON.stringify(mountBounds())!==lastMount)sendMount().catch(e=>toast(e.message,true));

  },45);}

  function hideMount(){if(native){const b=mountBounds();b.visible=0;request('mountLayout',b).catch(()=>{});lastMount='';}}

  window.addEventListener('resize',scheduleMount);window.addEventListener('scroll',scheduleMount,{passive:true});

  new ResizeObserver(scheduleMount).observe($('game-mount'));

  const tooltip=$('app-tooltip');let tooltipTimer,tooltipTarget=null;

  function tooltipOff(){clearTimeout(tooltipTimer);tooltip.hidden=true;tooltipTarget=null;}

  function tooltipOn(target){

    if(tooltipTarget===target)return;

    if(target.hasAttribute('title')){target.dataset.tooltip=target.getAttribute('title');target.removeAttribute('title');}

    const text=target.dataset.tooltip||target.getAttribute('aria-label');if(!text)return;

    tooltipOff();tooltipTarget=target;tooltipTimer=setTimeout(()=>{

      tooltip.textContent=text;tooltip.hidden=false;

      const r=target.getBoundingClientRect();

      tooltip.style.left=Math.max(8,Math.min(r.left,innerWidth-tooltip.offsetWidth-8))+'px';

      tooltip.style.top=Math.min(r.bottom+8,innerHeight-tooltip.offsetHeight-8)+'px';

    },450);

  }

  document.addEventListener('pointerover',e=>{const t=e.target.closest('[title],[data-tooltip],button[aria-label]');if(t)tooltipOn(t);});

  document.addEventListener('pointerout',e=>{if(tooltipTarget&&!tooltipTarget.contains(e.relatedTarget))tooltipOff();});document.addEventListener('pointerdown',tooltipOff);

  document.addEventListener('focusin',e=>{if(e.target.matches('[data-tooltip],[title],button[aria-label]'))tooltipOn(e.target);});

  document.addEventListener('focusout',tooltipOff);

  document.addEventListener('contextmenu',e=>e.preventDefault());

  async function initialize(){

    document.body.classList.toggle('browser',!native);

    paintIcons();

    try {

      await refreshSnapshot(true);

      if(!native){$('connection-banner').hidden=false;$('connection-banner').textContent='Browser preview · Open Pantheon.ahk to launch macros and connect your saved settings.';}

      route(location.hash.slice(1)||'dashboard');

      setInterval(()=>{if(!document.hidden&&!busy)refreshSnapshot();},1200);

    }catch(e){$('connection-banner').hidden=false;$('connection-banner').textContent='Pantheon could not load: '+e.message;toast(e.message,true);}

  }

  initialize();

})();
