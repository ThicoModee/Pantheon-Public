(function(root){
  'use strict';
  const labels={'click-point':'Click coordinate',click:'Click image / saved point','click-setting':'Click selected setting option',move:'Move mouse',walk:'Walk',scroll:'Scroll',wait:'Wait for images',delay:'Delay',press:'Press a key',key:'Hold a key',call:'Run another sequence',repeat:'Repeat steps','for-setting':'For each selected item',if:'If conditions match',retry:'Retry sequence until conditions match',until:'Repeat until conditions match',stop:'Stop macro',camera:'Set bird’s-eye camera',placements:'Run placement setup',outcome:'Wait for match result'};
  const actions=Object.keys(labels);
  const condition=target=>({operator:'all',checks:[{target,state:'present'}]});
  function step(action,definition,id){
    const target=Object.keys(definition.targets)[0]||'',image=Object.keys(definition.targets).find(id=>definition.targets[id].kind==='pattern')||'',workflow=Object.keys(definition.workflows)[0]||'';
    const s={id,action};
    if(action==='outcome')return {...s,victory:Object.keys(definition.targets).find(k=>/victory/i.test(definition.targets[k].name))||image,defeat:Object.keys(definition.targets).find(k=>/defeat/i.test(definition.targets[k].name))||image,timeoutMs:1800000,thenSteps:[],elseSteps:[]};
    if(action==='stop')return s;
    if(action==='camera')return {...s,zoomIn:20,zoomOut:20,tilt:299};
    if(action==='placements')return {...s,route:'selected',fallback:'shared',setting:''};
    if(action==='click-point')Object.assign(s,{x:0,y:0,button:'Left'});
    else if(action==='move')Object.assign(s,{x:0,y:0});
    else if(action==='walk')Object.assign(s,{keys:['W'],sprint:0,sprintKey:'Shift',durationMs:1000});
    else if(action==='scroll')Object.assign(s,{direction:'Down',ticks:1,count:20,intervalMs:100});
    else if(action==='click')Object.assign(s,{target,button:'Left',timeoutMs:0,missing:'error'});
    else if(action==='click-setting')Object.assign(s,{setting:Object.keys(definition.settings||{}).find(id=>['select','priority','multiselect'].includes(definition.settings[id].type))||'',button:'Left',timeoutMs:0,missing:'error'});
    else if(action==='wait')Object.assign(s,{condition:condition(image),timeoutMs:30000,missing:'error'});
    else if(action==='delay')s.durationMs=500;
    else if(action==='key')Object.assign(s,{key:'W',durationMs:500});
    else if(action==='press')Object.assign(s,{key:'Space',count:1,intervalMs:100});
    else if(action==='call')s.workflow=workflow;
    else if(action==='repeat')Object.assign(s,{steps:[],count:2});
    else if(action==='for-setting')Object.assign(s,{setting:Object.keys(definition.settings||{}).find(id=>['priority','multiselect'].includes(definition.settings[id].type))||'',steps:[]});
    else if(action==='if')Object.assign(s,{condition:condition(image),thenSteps:[],elseSteps:[]});
    else if(action==='retry')Object.assign(s,{condition:condition(image),steps:[],attempts:3,timeoutMs:5000,intervalMs:500,failure:'error'});
    else if(action==='until')Object.assign(s,{condition:condition(image),steps:[],timeoutMs:1800000,intervalMs:1000,failure:'error'});
    else throw Error('Unknown action.');
    return s;
  }
  function normalize(raw){
    const d=structuredClone(raw);
    d.settings=d.settings||{};d.entry=d.entry||(d.workflows['enter-map']?'enter-map':Object.keys(d.workflows)[0]);d.runMode=d.runMode||'once';
    function visit(steps){for(const s of steps){
      if(s.action==='repeat'&&s.workflow){s.steps=[{id:'run-sequence',action:'call',workflow:s.workflow}];delete s.workflow;}
      if(s.action==='if'&&!s.condition&&d.targets[s.target]?.kind==='pattern'){
        s.condition=condition(s.target);s.thenSteps=s.then?[{id:'then-sequence',action:'call',workflow:s.then}]:[];s.elseSteps=s.otherwise?[{id:'else-sequence',action:'call',workflow:s.otherwise}]:[];delete s.target;delete s.then;delete s.otherwise;
      }
      for(const field of ['steps','thenSteps','elseSteps'])if(s[field])visit(s[field]);
    }}
    for(const flow of Object.values(d.workflows))visit(flow.steps);return d;
  }
  function stageTemplate(d,id){
    const unique=prefix=>{let n=1;while(d.targets[prefix+'-'+n])n++;return prefix+'-'+n;};
    const chamber=unique('stage-chamber'),loaded=unique('stage-loaded');
    for(const [target,name]of [[chamber,'Stage selection chamber'],[loaded,'Loaded in stage']])d.targets[target]={name,kind:'pattern',pattern:'',x:0,y:0,width:800,height:600,error1:0,error0:0,offsetX:0,offsetY:0};
    const click=id=>({id,action:'click-point',x:0,y:0,button:'Left'});
    d.workflows[id]={name:'Enter stage (template)',steps:[
      {id:'reach-chamber',action:'retry',steps:[click('open-menu'),click('enter-mode'),{id:'walk-diagonally',action:'walk',keys:['W','D'],sprint:0,sprintKey:'Shift',durationMs:1500}],condition:condition(chamber),attempts:3,timeoutMs:5000,intervalMs:500,failure:'error'},
      {id:'move-to-list',action:'move',x:0,y:0},{id:'scroll-to-bottom',action:'scroll',direction:'Down',ticks:1,count:30,intervalMs:100},click('choose-stage'),click('start-stage'),
      {id:'wait-for-load',action:'wait',condition:condition(loaded),timeoutMs:60000,missing:'error'}
    ]};return {chamber,loaded};
  }
  class FrameworkEditor{
    constructor({request,toast,capture,select,point,changed,catalogChanged}){
      Object.assign(this,{request,toast,capture,select,point,changed,catalogChanged,definition:null,saved:'',revision:0,flow:'',target:'',busy:false,package:'',collapsed:new Set(),groupActions:new Map()});
      this.$=id=>document.getElementById(id);this.escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
      this.$('framework-reload').addEventListener('click',()=>{if(this.dirty()){toast('Save or discard the draft before reloading.',true);return;}this.open(true);});
      this.$('framework-discard').addEventListener('click',()=>{if(!this.saved)return;this.definition=JSON.parse(this.saved);this.render();this.change();});
      this.$('framework-save').addEventListener('click',()=>this.save());
      this.settingsEditor=new root.FlowSettingsEditor({definition:()=>this.definition,point,toast,changed:()=>{this.renderChoices();this.renderFlow();this.change();}});
      this.$('framework-package').addEventListener('change',e=>{if(this.dirty()){e.target.value=this.package;toast('Save or discard the draft before switching macros.',true);return;}this.open(true,e.target.value);});
      this.$('framework-new-macro').addEventListener('click',async()=>{if(this.dirty()){toast('Save or discard the draft before creating a macro.',true);return;}try{const data=await request('frameworkNew');await this.open(true,data.package);await catalogChanged?.();}catch(e){toast(e.message,true);}});
      this.$('framework-export-macro').addEventListener('click',async()=>{try{await request('macroExport',{id:this.package,definition:this.definition});toast('Macro configuration copied. It contains definitions and defaults, not your saved settings.');}catch(e){toast(e.message,true);}});
      for(const [id,field]of [['framework-macro-name','name'],['framework-game-id','game'],['framework-entry','entry'],['framework-run-mode','runMode'],['framework-icon','icon']])this.$(id).addEventListener('change',e=>{let value=e.target.value;if(field==='game'){value=value.trim().toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,'').slice(0,48)||'roblox-td';if(!/^[a-z]/.test(value))value=('game-'+value).slice(0,48);e.target.value=value;}this.definition[field]=value;if(field==='icon')this.$('framework-icon-preview').src=root.PantheonHub.macroIcons[value].image;this.change();});
      this.$('framework-flow').addEventListener('change',e=>{this.flow=e.target.value;this.renderFlow();});
      this.$('framework-target').addEventListener('change',e=>{this.target=e.target.value;this.renderTarget();});
      this.$('framework-flow-name').addEventListener('change',e=>{this.definition.workflows[this.flow].name=e.target.value;this.renderChoices();this.change();});
      this.$('framework-new-action').innerHTML=this.actionOptions('click-point');
      this.$('framework-add-step').addEventListener('click',()=>this.addStep('',this.$('framework-new-action').value));
      this.$('framework-delete-flow').addEventListener('click',()=>this.deleteFlow());
      this.$('framework-add-flow').addEventListener('click',()=>{this.flow=this.id('sequence',Object.keys(this.definition.workflows));this.definition.workflows[this.flow]={name:'New sequence',steps:[]};this.render();this.change();});
      this.$('framework-stage-template').addEventListener('click',()=>{this.flow=this.id('enter-stage',Object.keys(this.definition.workflows));const targets=stageTemplate(this.definition,this.flow);this.target=targets.chamber;this.render();this.change();});
      this.$('framework-add-target').addEventListener('click',()=>{this.target=this.id('image',Object.keys(this.definition.targets));this.definition.targets[this.target]={name:'New image',kind:'pattern',pattern:'',x:0,y:0,width:800,height:600,error1:0,error0:0,offsetX:0,offsetY:0};this.render();this.change();});
      this.$('framework-capture-target').addEventListener('click',async()=>{const id=this.target,result=await select();if(!result||result.cancelled)return;const c=capture(),t=this.definition.targets[id];Object.assign(t,{x:0,y:0,width:800,height:600,kind:'pattern',pattern:c.pattern});this.renderTarget();this.renderFlow();this.change();});
      this.$('framework-target-fields').addEventListener('change',e=>{const f=e.target.dataset.targetField;if(!f)return;const t=this.definition.targets[this.target];t[f]=e.target.type==='number'?Number(e.target.value):e.target.value;if(f==='kind'&&t.kind==='point')Object.assign(t,{pattern:'',width:1,height:1,offsetX:0,offsetY:0});this.renderChoices();this.renderTarget();this.renderFlow();this.change();});
      this.$('framework-use-capture').addEventListener('click',()=>{const c=capture();if(!c.pattern){toast('Select a region in Roblox first.',true);return;}Object.assign(this.definition.targets[this.target],{x:0,y:0,width:800,height:600,kind:'pattern',pattern:c.pattern});this.renderTarget();this.renderFlow();this.change();});
      this.$('framework-use-point').addEventListener('click',()=>{const c=capture();if(!c.pattern){toast('Select a region in Roblox first.',true);return;}const r=c.region;Object.assign(this.definition.targets[this.target],{kind:'point',pattern:'',x:r.x+Math.floor(r.width/2),y:r.y+Math.floor(r.height/2),width:1,height:1,offsetX:0,offsetY:0});this.renderTarget();this.renderFlow();this.change();});
      this.$('framework-full-client').addEventListener('click',()=>{Object.assign(this.definition.targets[this.target],{x:0,y:0,width:800,height:600});this.renderTarget();this.change();});
      this.$('framework-steps').addEventListener('change',e=>this.editStep(e));
      this.$('framework-steps').addEventListener('click',e=>this.command(e));
      this.$('framework-steps').addEventListener('toggle',e=>{const key=e.target.dataset.foldKey;if(key)e.target.open?this.collapsed.delete(key):this.collapsed.add(key);},true);
      PantheonSort.bind(this.$('framework-steps'),{handle:'.sequence-grip',item:'.framework-step',list:'.flow-step-list',onDrop:(parent,rows)=>{const list=this.resolve(parent.dataset.listPath),byIndex=[...list];list.splice(0,list.length,...rows.map(row=>byIndex[Number(row.dataset.flowStep)]));this.renderFlow();this.change();}});

    }
    deleteFlow(){
      const d=this.definition,id=this.flow;
      if(Object.keys(d.workflows).length===1){this.toast('Keep at least one sequence.',true);return;}
      if(d.entry===id){this.toast('Choose a different starting sequence before deleting this one.',true);return;}
      const used=[];
      const visit=steps=>steps.some(s=>s.workflow===id||s.then===id||s.otherwise===id||['steps','thenSteps','elseSteps'].some(f=>s[f]&&visit(s[f])));
      for(const [key,flow] of Object.entries(d.workflows))if(key!==id&&visit(flow.steps))used.push(flow.name);
      if(used.length){this.toast('Sequence is used by: '+used.join(', ')+'. Remove those references first.',true);return;}
      delete d.workflows[id];this.flow=Object.keys(d.workflows)[0];this.render();this.change();
    }
    id(prefix,ids){let i=1;while(ids.includes(prefix+'-'+i))i++;return prefix+'-'+i;}
    dirty(){return !!this.definition&&JSON.stringify(this.definition)!==this.saved;}
    change(){const pending=this.definition?Object.values(this.definition.targets).filter(t=>t.kind==='pattern'&&!t.pattern).map(t=>t.name):[];this.$('framework-save').disabled=this.busy||!this.dirty()||!!pending.length;this.$('framework-discard').disabled=this.busy||!this.dirty();this.$('framework-export-macro').disabled=this.busy||!!pending.length;this.$('framework-state').textContent=pending.length?'Capture required: '+pending.join(', '):this.dirty()?'Unsaved sequence changes':'Saved · revision '+this.revision;this.changed?.();}
    async open(force=false,id=this.package){PantheonKeyCapture.cancel();if(this.definition&&!force)return;try{const packages=await this.request('frameworkCatalog');if(!packages.some(p=>p.id===id))id=packages[0]?.id||'';this.$('framework-package').innerHTML=this.options(Object.fromEntries(packages.map(p=>[p.id,p])),id);this.$('framework-empty').hidden=!!id;this.$('framework-content').hidden=!id;this.$('framework-editor').hidden=false;this.$('framework-export-macro').disabled=!id;if(!id){this.package='';this.definition=null;this.saved='';return;}const data=await this.request('frameworkLoad',id);this.package=id;this.definition=normalize(data.definition);this.revision=data.revision;this.saved=JSON.stringify(this.definition);this.render();this.change();}catch(e){this.toast(e.message,true);}}
    async save(){if(this.busy)return;this.busy=true;this.change();try{const data=await this.request('frameworkSave',{package:this.package,definition:this.definition,revision:this.revision});this.definition=normalize(data.definition);this.revision=data.revision;this.saved=JSON.stringify(this.definition);if(this.$('framework-package').selectedOptions[0])this.$('framework-package').selectedOptions[0].textContent=this.definition.name;this.toast(data.warnings?.length?data.warnings.join(' '):'Macro definition saved.');await this.catalogChanged?.();}catch(e){this.toast(e.message,true);}finally{this.busy=false;this.change();}}
    options(values,current,empty=false){return (empty?'<option value="">Continue with next step</option>':'')+(!empty&&!Object.hasOwn(values,current)?'<option value="">Select an option</option>':'')+Object.entries(values).map(([id,v])=>`<option value="${this.escape(id)}"${id===current?' selected':''}>${this.escape(v.name)}</option>`).join('');}
    actionOptions(current){return actions.map(a=>`<option value="${a}"${a===current?' selected':''}>${labels[a]}</option>`).join('');}
    renderChoices(){this.$('framework-flow').innerHTML=this.options(this.definition.workflows,this.flow);this.$('framework-target').innerHTML=this.options(this.definition.targets,this.target);this.$('framework-entry').innerHTML=this.options(this.definition.workflows,this.definition.entry);}
    render(){if(!this.definition.workflows[this.flow])this.flow=Object.keys(this.definition.workflows)[0];if(!this.definition.targets[this.target])this.target=Object.keys(this.definition.targets)[0];this.$('framework-macro-name').value=this.definition.name;this.$('framework-game-id').value=this.definition.game;this.$('framework-run-mode').value=this.definition.runMode;this.$('framework-icon').innerHTML=Object.entries(root.PantheonHub.macroIcons).map(([id,v])=>`<option value="${id}"${id===(this.definition.icon||'pantheon')?' selected':''}>${v.name}</option>`).join('');this.$('framework-icon-preview').src=root.PantheonHub.macroIcons[this.definition.icon||'pantheon'].image;this.renderChoices();this.renderFlow();this.renderTarget();this.settingsEditor.render();}
    resolve(path){let value=this.definition.workflows[this.flow].steps;for(const p of path.split('.').filter(Boolean))value=value[p];return value;}
    location(path){const parts=path.split('.'),index=Number(parts.pop());return {list:this.resolve(parts.join('.')),index};}
    addStep(path,action){const list=this.resolve(path);list.push(step(action,this.definition,this.id('step',list.map(s=>s.id))));this.renderFlow();this.change();}
    editStep(e){
      const el=e.target,path=el.closest('[data-step-path]')?.dataset.stepPath;if(path===undefined)return;const s=this.resolve(path);
      if(el.dataset.conditionField){const value=this.resolve(el.dataset.conditionPath),field=el.dataset.conditionField;if(field==='setting')Object.assign(value,this.settingCheck(el.value));else value[field]=el.dataset.conditionNumber?Math.round(Number(el.value)*(el.dataset.seconds?1000:1)):el.value;}
      else if(el.dataset.parameter){s[el.dataset.parameter]=el.value?{setting:el.value}:Number(el.dataset.parameterMin);}
      else if(el.dataset.walkKey){const k=el.dataset.walkKey,opposite={W:'S',S:'W',A:'D',D:'A'};s.keys=s.keys.filter(v=>v!==k&&(!el.checked||v!==opposite[k]));if(el.checked)s.keys.push(k);}
      else if(el.dataset.stepField){const f=el.dataset.stepField;if(f==='action'){const loc=this.location(path);loc.list[loc.index]={...step(el.value,this.definition,s.id),...(s.name?{name:s.name}:{})};}else if(f==='key'){const names={space:'Space',enter:'Enter',tab:'Tab',esc:'Escape',escape:'Escape',ctrl:'Control',control:'Control',shift:'Shift',up:'Up',down:'Down',left:'Left',right:'Right'};s[f]=/^[a-z]$/i.test(el.value)?el.value.toUpperCase():names[el.value.toLowerCase()]||el.value;}else s[f]=el.type==='checkbox'?Number(el.checked):el.type==='number'?Math.round(Number(el.value)*(el.dataset.seconds?1000:1)):el.value;}
      else return;
      this.renderFlow();this.change();
    }
    command(e){
      const b=e.target.closest('button');if(!b)return;e.preventDefault();
      if(b.dataset.addGroupStep!==undefined){const action=b.parentElement.querySelector('select').value;this.groupActions.set(this.flow+':'+b.dataset.addGroupStep,action);this.addStep(b.dataset.addGroupStep,action);return;}
      if(b.dataset.conditionCommand){const c=this.resolve(b.dataset.conditionPath),cmd=b.dataset.conditionCommand;if(cmd==='selected-image'){const id=Object.keys(this.definition.settings).find(id=>this.definition.settings[id].type==='select');c.checks.push({selectedImage:id||'',state:'present'});}else if(cmd==='remove')c.checks.splice(Number(b.dataset.checkIndex),1);else if(cmd==='setting'){const id=Object.keys(this.definition.settings)[0];c.checks.push(this.settingCheck(id));}else{const image=Object.keys(this.definition.targets).find(id=>this.definition.targets[id].kind==='pattern')||'';c.checks.push(cmd==='group'?condition(image):{target:image,state:'present'});}this.renderFlow();this.change();return;}
      if(!b.dataset.stepCommand)return;const path=b.closest('[data-step-path]').dataset.stepPath,{list,index}=this.location(path),cmd=b.dataset.stepCommand;
      if(cmd==='delete')list.splice(index,1);
      else if(cmd==='duplicate'){const clone=structuredClone(list[index]);clone.id=this.id('step',list.map(s=>s.id));list.splice(index+1,0,clone);}
      else if(cmd==='insert')list.splice(index+1,0,step('click-point',this.definition,this.id('step',list.map(s=>s.id))));
      else if(cmd==='point'){this.pickPoint(path,b);return;}
      else{const dest=index+(cmd==='up'?-1:1);if(dest>=0&&dest<list.length)[list[index],list[dest]]=[list[dest],list[index]];}
      this.renderFlow();this.change();
    }
    async pickPoint(path,button){button.disabled=true;button.textContent='Selecting coordinates…';try{const p=await this.point();if(!p||p.cancelled)return;const s=this.resolve(path);s.x=p.x;s.y=p.y;this.change();}finally{this.renderFlow();}}
    settingCheck(id){const s=this.definition.settings[id];return {setting:id,comparison:Array.isArray(s.default)?'contains':'equals',value:Array.isArray(s.default)?s.options[0]?.value||'':s.default};}
    settingConditionHTML(check,path){
      const spec=this.definition.settings[check.setting];if(!spec)return '<p>Choose a setting</p>';
      const list=Array.isArray(spec.default),operators=list?{contains:'Contains','not-contains':'Does not contain'}:{equals:'Equals','not-equals':'Does not equal',...(spec.type==='number'?{greater:'Greater than',less:'Less than'}:{})};
      let value='';const attrs=`data-condition-field="value" data-condition-path="${path}"`;
      if(spec.type==='key')value=`<input ${attrs} value="${this.escape(check.value)}" maxlength="12">`;else if(spec.type==='number')value=`<input type="number" ${attrs} data-condition-number="1" value="${check.value}" min="${spec.min}" max="${spec.max}">`;
      else{const options=spec.options||[{value:0,label:'Disabled'},{value:1,label:'Enabled'}];value=`<select ${attrs}${spec.options?'':' data-condition-number="1"'}>${options.map(o=>`<option value="${this.escape(o.value)}"${o.value===check.value?' selected':''}>${this.escape(o.label)}</option>`).join('')}</select>`;}
      return `<div class="flow-image-choice"><label>Setting<select data-condition-field="setting" data-condition-path="${path}">${this.options(Object.fromEntries(Object.entries(this.definition.settings).map(([id,s])=>[id,{name:s.label}])),check.setting)}</select></label><label>Comparison<select data-condition-field="comparison" data-condition-path="${path}">${Object.entries(operators).map(([id,label])=>`<option value="${id}"${id===check.comparison?' selected':''}>${label}</option>`).join('')}</select></label><label>Value${value}</label></div>`;
    }
    renderTarget(){
      const t=this.definition.targets[this.target];for(const id of ['framework-capture-target','framework-use-capture','framework-use-point'])this.$(id).disabled=!t;
      if(!t){this.$('framework-target-fields').innerHTML='<p>No images or saved points</p>';this.$('framework-references').textContent='';this.$('framework-full-client').hidden=true;return;}
      const input=(f,label,min,max)=>`<label>${label}<input data-target-field="${f}" type="number" min="${min}" max="${max}" value="${t[f]}"></label>`;
      this.$('framework-target-fields').innerHTML=`<label>Name<input data-target-field="name" maxlength="80" value="${this.escape(t.name)}"></label><label>Type<select data-target-field="kind"><option value="point"${t.kind==='point'?' selected':''}>Saved coordinate</option><option value="pattern"${t.kind==='pattern'?' selected':''}>FindText image</option></select></label><div class="framework-fields">${input('x',t.kind==='pattern'?'Search X':'X',0,799)}${input('y',t.kind==='pattern'?'Search Y':'Y',0,599)}${t.kind==='pattern'?input('width','Search width',1,800)+input('height','Search height',1,600):''}</div>${t.kind==='pattern'?`${this.preview(this.target)}<label>FindText capture<textarea data-target-field="pattern" rows="3" spellcheck="false">${this.escape(t.pattern)}</textarea></label><div class="framework-fields">${input('error1','Foreground mismatch (%)',0,20)}${input('error0','Background mismatch (%)',0,20)}${input('offsetX','Click offset X',-799,799)}${input('offsetY','Click offset Y',-599,599)}</div>`:''}`;
      this.$('framework-full-client').hidden=t.kind!=='pattern';
      const used=Object.values(this.definition.workflows).filter(f=>JSON.stringify(f.steps).includes('"'+this.target+'"')).map(f=>f.name);
      this.$('framework-references').textContent='Used by: '+(used.join(', ')||'No sequences');this.paintPreviews(this.$('framework-target-fields'));
    }
    preview(target){return `<div class="flow-image-preview" data-pattern-target="${this.escape(target)}"><canvas aria-label="FindText image preview"></canvas><small></small></div>`;}
    paintPreviews(host){for(const box of host.querySelectorAll('[data-pattern-target]')){
      const canvas=box.querySelector('canvas'),label=box.querySelector('small'),t=this.definition.targets[box.dataset.patternTarget];
      try{const variants=root.PantheonDeveloper.decodePattern(t?.pattern),p=variants[0];canvas.hidden=false;canvas.width=p.width;canvas.height=p.height;const ctx=canvas.getContext('2d'),image=ctx.createImageData(p.width,p.height);for(let i=0;i<p.bits.length;i++){const v=p.bits[i]==='1'?0:255;image.data.set([v,v,v,255],i*4);}ctx.putImageData(image,0,0);label.textContent=`${p.width} × ${p.height}${variants.length>1?' · '+variants.length+' variants':''}`;}catch{canvas.hidden=true;label.textContent='Capture an image';}
    }}
    selectedImageHTML(check,path){const settings=Object.fromEntries(Object.entries(this.definition.settings).filter(([,s])=>s.type==='select').map(([id,s])=>[id,{name:s.label}]));return `<div class="flow-image-choice"><label>Selected option image<select data-condition-field="selectedImage" data-condition-path="${path}">${this.options(settings,check.selectedImage)}</select></label><label>Check<select data-condition-field="state" data-condition-path="${path}"><option value="present"${check.state==='present'?' selected':''}>Is detected</option><option value="absent"${check.state==='absent'?' selected':''}>Is not detected</option></select></label></div>`;}
    conditionHTML(c,path,depth=0){
      const images=Object.fromEntries(Object.entries(this.definition.targets).filter(([,t])=>t.kind==='pattern'));
      return `<div class="flow-condition"><label>Match<select data-condition-field="operator" data-condition-path="${path}"><option value="all"${c.operator==='all'?' selected':''}>All conditions (AND)</option><option value="any"${c.operator==='any'?' selected':''}>Any condition (OR)</option></select></label>${c.checks.map((check,i)=>{
        const p=path+'.checks.'+i;
        return `<div class="flow-image-check">${check.operator?this.conditionHTML(check,p,depth+1):check.selectedImage!==undefined?this.selectedImageHTML(check,p):check.setting?this.settingConditionHTML(check,p):`<div class="flow-image-choice"><label>Image<select data-condition-field="target" data-condition-path="${p}">${this.options(images,check.target)}</select></label><label>Check<select data-condition-field="state" data-condition-path="${p}"><option value="present"${check.state==='present'?' selected':''}>Is detected</option><option value="absent"${check.state==='absent'?' selected':''}>Is not detected</option></select></label></div>${this.preview(check.target)}`}<button class="button" data-condition-command="remove" data-condition-path="${path}" data-check-index="${i}"${c.checks.length===1?' disabled':''}>Remove condition</button></div>`;
      }).join('')}<div class="developer-toolbar"><button class="button" data-condition-command="selected-image" data-condition-path="${path}"${c.checks.length>=8||!Object.values(this.definition.settings).some(s=>s.type==='select')?' disabled':''}>Add selected option image</button><button class="button" data-condition-command="image" data-condition-path="${path}"${c.checks.length>=8?' disabled':''}>Add image</button><button class="button" data-condition-command="setting" data-condition-path="${path}"${c.checks.length>=8||!Object.keys(this.definition.settings).length?' disabled':''}>Add setting / flag</button>${depth<3?`<button class="button" data-condition-command="group" data-condition-path="${path}"${c.checks.length>=8?' disabled':''}>Add AND / OR group</button>`:''}</div></div>`;
    }
    foldKey(path){let prefix='',ids=[];for(const part of path.split('.')){prefix+=(prefix?'.':'')+part;if(/^\d+$/.test(part))ids.push(this.resolve(prefix).id);}return this.flow+':'+ids.join('/');}
    groupHTML(steps,path,label){return `<section class="flow-step-group"><h4>${label}</h4>${this.stepsHTML(steps,path)}<div class="developer-toolbar"><select aria-label="Action to add">${this.actionOptions(this.groupActions.get(this.flow+':'+path)||'click-point')}</select><button class="button" data-add-group-step="${path}">Add step</button></div></section>`;}
    stepsHTML(steps,parent=''){
      return `<div class="flow-step-list" data-list-path="${parent}">`+steps.map((s,i)=>{
        const path=(parent?parent+'.':'')+i;
        const select=(f,title,values,empty=false)=>`<label>${title}<select data-step-field="${f}">${this.options(values,s[f],empty)}</select></label>`;
        const number=(f,title,min=0,max=60000)=>{const time=f.endsWith('Ms');title=title.replace(/\(ms\)/g,'(seconds)');const settings=Object.entries(this.definition.settings).filter(([,spec])=>spec.type==='number'?spec.min>=min&&spec.max<=max:['toggle','checkbox'].includes(spec.type)&&min===0&&max===1),ref=s[f]&&typeof s[f]==='object';return `<label>${title}${settings.length?`<select data-parameter="${f}" data-parameter-min="${min}"><option value="">Fixed value</option>${settings.map(([id,spec])=>`<option value="${this.escape(id)}"${ref&&s[f].setting===id?' selected':''}>Setting: ${this.escape(spec.label)}</option>`).join('')}</select>`:''}${ref?'':`<input type="number" data-step-field="${f}" min="${time?min/1000:min}" max="${time?max/1000:max}" step="${time?0.001:1}" ${time?'data-seconds="1"':''} value="${time?s[f]/1000:s[f]}">`}</label>`;};
        const choices=(f,title,values)=>`<label>${title}<select data-step-field="${f}">${Object.entries(values).map(([value,text])=>`<option value="${value}"${s[f]===value?' selected':''}>${text}</option>`).join('')}</select></label>`;
        let fields='',blocks='';
        if(s.action==='camera')fields=number('zoomIn','Zoom in ticks',1,50)+number('zoomOut','Zoom out ticks',1,50)+number('tilt','Look down movement',30,299);
        if(s.action==='placements')fields=select('route','Placement map',{selected:{name:"Player’s selected setup"},shared:{name:'Shared setup'},setting:{name:'Map from dropdown setting'},...(this.definition.maps||{})})+choices('fallback','If map has no placements',{shared:'Use Shared setup',error:'Stop with error'})+(s.route==='setting'?select('setting','Stage / map dropdown',Object.fromEntries(Object.entries(this.definition.settings).filter(([,v])=>v.type==='select').map(([id,v])=>[id,{name:v.label}]))):'');
        if(s.action==='click-point'||s.action==='move')fields=number('x','X',0,799)+number('y','Y',0,599)+(s.action==='click-point'?choices('button','Mouse button',{Left:'Left click',Right:'Right click'}):'')+'<button class="button primary" data-step-command="point">Select coordinates</button>';
        if(s.action==='click-setting'){const settings=Object.fromEntries(Object.entries(this.definition.settings).filter(([,s])=>['select','priority','multiselect'].includes(s.type)).map(([id,s])=>[id,{name:s.label}]));fields=select('setting','Use selected option from',settings)+number('timeoutMs','Wait up to (ms)')+choices('button','Mouse button',{Left:'Left click',Right:'Right click'})+choices('missing','If not detected',{error:'Stop with error',skip:'Continue to next step'});}
        if(s.action==='click'||(s.action==='wait'&&!s.condition))fields=select('target','Image / saved point',this.definition.targets)+number('timeoutMs','Wait up to (ms)',s.action==='wait'?100:0,s.action==='wait'?3600000:60000)+choices('missing','If not detected',{error:'Stop with error',skip:'Continue to next step'})+(s.action==='click'?choices('button','Mouse button',{Left:'Left click',Right:'Right click'}):'');
        if(s.action==='delay'||s.action==='key'||s.action==='walk')fields+=number('durationMs',s.action==='walk'?'Walk for (ms)':'Duration (ms)',s.action==='delay'?0:30,s.action==='walk'?30000:60000);
        if(s.action==='key'||s.action==='press')fields+=`<label>Key<input data-step-field="key" value="${this.escape(s.key)}" maxlength="12"></label>`;
        if(s.action==='press')fields+=number('count','Press count',1,20)+number('intervalMs','Delay between presses (ms)',0,5000);
        if(s.action==='walk')fields+=`<fieldset class="flow-walk"><legend>Hold directions together</legend>${['W','A','S','D'].map(k=>`<label><input type="checkbox" data-walk-key="${k}"${s.keys.includes(k)?' checked':''}>${k}</label>`).join('')}</fieldset><label class="flow-checkbox"><input type="checkbox" data-step-field="sprint"${s.sprint?' checked':''}>Sprint</label>`+choices('sprintKey','Sprint key',{Shift:'Shift',Control:'Control'});
        if(s.action==='scroll')fields=choices('direction','Direction',{Up:'Scroll up',Down:'Scroll down'})+number('ticks','Wheel ticks each time',1,10)+number('count','Repeat scroll',1,100)+number('intervalMs','Delay between scrolls (ms)',0,5000);
        if(s.action==='call')fields=select('workflow','Sequence',Object.fromEntries(Object.entries(this.definition.workflows).filter(([id])=>id!==this.flow)));
        if(s.action==='repeat'){fields=number('count','Repeat count',1,20);blocks=this.groupHTML(s.steps,path+'.steps','Repeat these steps');}
        if(s.action==='for-setting'){fields=select('setting','Selected list / priority',Object.fromEntries(Object.entries(this.definition.settings).filter(([,s])=>['priority','multiselect'].includes(s.type)).map(([id,s])=>[id,{name:s.label}])));blocks=this.groupHTML(s.steps,path+'.steps','For each selected item, in saved order');}
        if(s.action==='if'&&s.condition)blocks=this.conditionHTML(s.condition,path+'.condition')+this.groupHTML(s.thenSteps,path+'.thenSteps','Then')+this.groupHTML(s.elseSteps,path+'.elseSteps','Otherwise');
        if(s.action==='if'&&!s.condition)fields=select('target','Target',this.definition.targets)+select('then','Then run',this.definition.workflows,true)+select('otherwise','Otherwise run',this.definition.workflows,true);
        if(s.action==='outcome'){const images=Object.fromEntries(Object.entries(this.definition.targets).filter(([,t])=>t.kind==='pattern'));fields=select('victory','Victory image',images)+select('defeat','Defeat image',images)+number('timeoutMs','Wait up to (seconds)',100,3600000);blocks=this.groupHTML(s.thenSteps,path+'.thenSteps','On victory')+this.groupHTML(s.elseSteps,path+'.elseSteps','On defeat');}
        if(s.action==='wait'&&s.condition){fields=number('timeoutMs','Wait up to (ms)',100,3600000)+choices('missing','If time runs out',{error:'Stop with error',skip:'Continue to next step'});blocks=this.conditionHTML(s.condition,path+'.condition');}
        if(s.action==='retry'||s.action==='until'){
          fields=(s.action==='retry'?number('attempts','Maximum attempts',1,20):'')+number('timeoutMs',s.action==='retry'?'Wait for images after each attempt (ms)':'Stop checking after (ms)',100,s.action==='until'?3600000:60000)+number('intervalMs','Delay between attempts / checks (ms)',100,10000)+choices('failure','If unsuccessful',{error:'Stop with error',continue:'Continue to next step'});
          blocks=s.action==='retry'?this.groupHTML(s.steps,path+'.steps','Try these steps')+'<h4>Continue when</h4>'+this.conditionHTML(s.condition,path+'.condition'):this.conditionHTML(s.condition,path+'.condition')+this.groupHTML(s.steps,path+'.steps','Repeat while waiting');
        }
        const image=s.target&&this.definition.targets[s.target]?.kind==='pattern'?this.preview(s.target):'';
        const fold=this.foldKey(path),svg=PantheonKeyCapture.icon;
        return `<details class="framework-step" data-flow-step="${i}" data-step-path="${path}" data-fold-key="${this.escape(fold)}"${this.collapsed.has(fold)?'':' open'}><summary class="framework-step-top"><span class="fold-indicator">${svg('chevron-down')}</span><span class="sequence-grip" aria-label="Drag step">${svg('grip-vertical')}</span><span class="step-order">${i+1}</span><strong>${this.escape(s.name||labels[s.action])}</strong><span class="step-action-label">${s.name?labels[s.action]:''}</span><div class="flow-step-commands"><button type="button" class="icon-button" aria-label="Move step up" data-step-command="up"${i===0?' disabled':''}>${svg('arrow-up')}</button><button type="button" class="icon-button" aria-label="Move step down" data-step-command="down"${i===steps.length-1?' disabled':''}>${svg('arrow-down')}</button><button type="button" class="icon-button" aria-label="Remove step" data-step-command="delete">${svg('trash')}</button></div></summary><div class="sequence-step-body"><div class="framework-fields"><label>Step name<input data-step-field="name" maxlength="80" value="${this.escape(s.name||'')}" placeholder="${labels[s.action]}"></label><label>Action<select data-step-field="action" aria-label="Step action">${this.actionOptions(s.action)}</select></label></div><div class="developer-toolbar"><button class="button" data-step-command="insert">Insert below</button><button class="button" data-step-command="duplicate">Duplicate</button></div><div class="framework-step-fields">${fields}</div>${image}${blocks}</div></details>`;
      }).join('')+(steps.length?'':'<p class="flow-empty">No steps</p>')+'</div>';
    }
    renderFlow(){const f=this.definition.workflows[this.flow];this.$('framework-flow-name').value=f.name;this.$('framework-steps').innerHTML=this.stepsHTML(f.steps);this.paintPreviews(this.$('framework-steps'));}
  }
  root.FrameworkEditor=FrameworkEditor;root.PantheonFlowActions={actions,labels,step,normalize,stageTemplate};
  if(typeof module!=='undefined'&&module.exports)module.exports={actions,labels,step,normalize,stageTemplate};
})(globalThis);
