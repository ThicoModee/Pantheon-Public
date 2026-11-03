class RunSettingsPanel {
  constructor({request,toast,changed}) {
    Object.assign(this,{request,toast,changed});this.schema=PantheonRunSchema;this.cache=new Map();this.saved=new Map();this.loading=new Set();this.mode=null;this.locked=false;
    document.getElementById('save-run-settings').addEventListener('click',()=>this.save(this.mode));
    document.getElementById('save-general-settings').addEventListener('click',()=>this.save('general'));
    for(const [id,key]of [['run-settings-fields',()=>this.mode],['general-settings-fields',()=> 'general']]) {
      document.getElementById(id).addEventListener('input',e=>{
        const field=e.target.closest('[data-setting]');if(!field)return;const scope=key();if(!this.cache.has(scope)||this.loading.has(scope))return;const spec=this.fields(scope).find(f=>f.key===field.dataset.setting);if(!spec)return;
        this.cache.get(scope)[spec.key]=spec.type==='toggle'?(field.checked?(spec.on??1):(spec.off??0)):spec.type==='select'?Number(field.value):field.value;
        if(spec.image){const image=field.closest('[data-field]').querySelector('img');image.src=field.checked?spec.image:spec.disabledImage;}
        this.visibility(scope);this.update();
      });
    }
    document.getElementById('test-webhook').addEventListener('click',()=>this.test('testWebhook'));
  }
  fields(scope){return scope==='general'?this.schema.general:this.schema.modes[scope];}
  dirty(){return [...this.cache].some(([scope,values])=>JSON.stringify(values)!==JSON.stringify(this.saved.get(scope)));}
  dirtyScope(scope){return this.cache.has(scope)&&JSON.stringify(this.cache.get(scope))!==JSON.stringify(this.saved.get(scope));}
  async open(scope){
    if(scope!=='general')this.mode=scope;
    this.loading.add(scope);
    const host=document.getElementById(scope==='general'?'general-settings-fields':'run-settings-fields');host.inert=true;
    try {
      if(!this.cache.has(scope)){
        const result=await this.request('loadRunSettings',null,scope);this.cache.set(scope,result.values);this.saved.set(scope,result.warnings?.length?null:structuredClone(result.values));
        if(result.warnings?.length)this.toast(result.warnings.join(' '),true);
      }
      if(scope!=='general'&&this.mode!==scope)return;
      this.render(scope);this.update();
    }catch(e){this.toast(e.message,true);}finally{this.loading.delete(scope);this.update();}
  }
  render(scope){
    const host=document.getElementById(scope==='general'?'general-settings-fields':'run-settings-fields');host.replaceChildren();const groups=new Map();
    for(const spec of this.fields(scope)){
      const section=spec.section||'Run options';let group=groups.get(section);
      if(!group){const block=document.createElement(scope!=='general'&&section!=='Run options'?'details':'section');block.className='run-settings-section';
        if(section!=='Run options'){const heading=document.createElement(block.tagName==='DETAILS'?'summary':'h3');heading.textContent=section;block.append(heading);}
        group=document.createElement('div');group.className='run-settings-grid';block.append(group);host.append(block);groups.set(section,group);}
      const label=document.createElement('label');label.className='run-setting'+(spec.type==='toggle'?' run-toggle':'');label.dataset.field=spec.key;
      const text=document.createElement('span');text.textContent=spec.label;
      const input=document.createElement(spec.type==='select'?'select':'input');input.dataset.setting=spec.key;input.id='setting-'+scope+'-'+spec.key;input.autocomplete='off';
      if(spec.type==='select'){spec.options.forEach((value,i)=>{const o=document.createElement('option');o.value=i+1;o.textContent=value;input.append(o);});input.value=this.cache.get(scope)[spec.key];}
      else if(spec.type==='toggle'){input.type='checkbox';input.className='switch';input.setAttribute('role','switch');input.checked=this.cache.get(scope)[spec.key]===(spec.on??1);}
      else {input.type=spec.secret?'password':'text';input.value=this.cache.get(scope)[spec.key];input.maxLength=spec.maxLength||2048;if(['waves','userId'].includes(spec.format))input.inputMode='numeric';}
      if(spec.image){const image=document.createElement('img');image.className='shop-item-image';image.alt='';image.src=input.checked?spec.image:spec.disabledImage;label.prepend(image);label.classList.add('shop-item');}
      label.append(text,input);
      if(spec.event){
        let matrix=group.querySelector('.event-matrix');if(!matrix){matrix=document.createElement('div');matrix.className='event-matrix';const header=document.createElement('div');header.className='event-row event-header';for(const value of ['Event','Webhook','Ping']){const cell=document.createElement('span');cell.textContent=value;header.append(cell);}matrix.append(header);group.append(matrix);}
        let row=matrix.querySelector('[data-event="'+spec.event+'"]');if(!row){row=document.createElement('div');row.className='event-row';row.dataset.event=spec.event;const name=document.createElement('span');name.textContent=spec.label;row.append(name);matrix.append(row);}
        text.className='sr-only';input.setAttribute('aria-label',spec.label+' '+spec.eventType);row.append(label);
      }else group.append(label);
    }
    this.visibility(scope);
  }
  visibility(scope){
    const host=document.getElementById(scope==='general'?'general-settings-fields':'run-settings-fields');
    for(const f of this.fields(scope))host.querySelector(`[data-field="${f.key}"]`).hidden=!!f.when&&!Object.entries(f.when).every(([k,v])=>this.cache.get(scope)[k]===v);
  }
  update(){
    for(const [scope,id]of [[this.mode,'run'],['general','general']]){
      const dirty=this.dirtyScope(scope),button=document.getElementById('save-'+id+'-settings');button.disabled=this.locked||!dirty;
      document.getElementById(id+'-settings-state').textContent=dirty?'Unsaved changes':'Saved';
    }
    document.getElementById('run-settings-fields').inert=this.locked||this.loading.has(this.mode)||!this.cache.has(this.mode);document.getElementById('general-settings-fields').inert=this.locked||this.loading.has('general')||!this.cache.has('general');
    for(const id of ['test-webhook'])document.getElementById(id).disabled=this.locked||this.dirtyScope('general');
    this.changed();
  }
  async save(scope){
    if(!scope||this.locked)return false;
    try{const result=await this.request('saveRunSettings',structuredClone(this.cache.get(scope)),scope);this.saved.set(scope,structuredClone(result.values));this.update();this.toast('Settings saved.');return true;}
    catch(e){this.toast(e.message,true);return false;}
  }
  async prepareStart(scope){
    for(const key of ['general',scope])if(this.dirtyScope(key)&&!await this.save(key))return false;
    return true;
  }
  async test(action){
    const button=document.getElementById('test-webhook');button.disabled=true;
    try{const result=await this.request(action,null);this.toast(result.message);}
    catch(e){this.toast(e.message,true);}finally{button.disabled=this.locked||this.dirtyScope('general');}
  }
}
