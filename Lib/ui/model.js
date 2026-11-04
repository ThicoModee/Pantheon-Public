(function(root) {
  'use strict';
  const catalog = [];
  const macroIcons={pantheon:{name:'Pantheon',image:'assets/pantheon.png'},dungeons:{name:'Dungeons',image:'assets/macros/Dungeon.png'},progressive:{name:'Progressive',image:'assets/macros/Progressive.png'},raids:{name:'Raids',image:'assets/macros/Raids.png'},challenges:{name:'Challenges',image:'assets/macros/Challenge.png'},winter:{name:'Winter',image:'assets/macros/Winter.png'}};
  const defaults = () => ({root:'',accent:'violet',theme:'default',compact:0,scale:100,selected:'',favorites:[],developer:0});
  function mode(id) { const m=catalog.find(m=>m.id===id); if(!m) throw Error('Unknown macro.'); return m; }
  function preferences(raw) {
    const theme=raw.theme??'default';
    if(!['default','christmas','midnight','rose','ember'].includes(theme))throw Error('Unknown theme.');
    const selected=catalog.some(m=>m.id===raw.selected)?raw.selected:'';
    if(!['violet','neutral','gold'].includes(raw.accent) || ![90,100,110].includes(raw.scale) || ![0,1].includes(raw.compact)) throw Error('Invalid appearance preferences.');
    if(!Array.isArray(raw.favorites) || raw.favorites.length>64) throw Error('Invalid favourites.');
    const favorites=raw.favorites.filter(id=>catalog.some(m=>m.id===id));
    const developer=raw.developer??0;
    if(![0,1].includes(developer))throw Error('Invalid developer mode preference.');
    return {root:typeof raw.root==='string'?raw.root:'',accent:raw.accent,theme,compact:raw.compact,scale:raw.scale,selected,favorites:[...new Set(favorites)],developer};
  }
  function shortcut(event) {
    if(['Control','Alt','Shift','Meta'].includes(event.key)) return null;
    const aliases = {' ':'Space',ArrowUp:'Up',ArrowDown:'Down',ArrowLeft:'Left',ArrowRight:'Right',PageUp:'PgUp',PageDown:'PgDn'};
    let key=aliases[event.key] || event.key;
    if(/^[a-z]$/i.test(key)) key=key.toUpperCase();
    if(!/^(F([1-9]|1\d|2[0-4])|[A-Z0-9]|Space|Home|End|Insert|Delete|PgUp|PgDn|Up|Down|Left|Right)$/.test(key)) throw Error('Use a function key, letter, number, or navigation key.');
    return `${event.ctrlKey?'^':''}${event.altKey?'!':''}${event.shiftKey?'+':''}${event.metaKey?'#':''}${key}`;
  }

  function keyLabel(key) {
    let prefix='',i=0;
    const names={'^':'Ctrl','!':'Alt','+':'Shift','#':'Win'};
    while(names[key[i]]) prefix+=names[key[i++]]+' + ';
    return prefix+key.slice(i);
  }
  function setCustomMacros(entries){const seen=new Set();const custom=entries.filter(m=>/^macro-[a-z0-9][a-z0-9-]{0,40}$/.test(m.id)&&typeof m.name==='string'&&!seen.has(m.id)&&(seen.add(m.id),true)).slice(0,64);catalog.splice(0,catalog.length,...catalog.filter(m=>!m.custom),...custom.map(m=>({id:m.id,name:m.name,custom:true,modern:false,icon:Object.hasOwn(macroIcons,m.icon)?m.icon:'pantheon',image:macroIcons[Object.hasOwn(macroIcons,m.icon)?m.icon:'pantheon'].image})));}

  function statePresentation(state,description,controls={startBind:'F2'}){
    const map={stopped:['Ready','idle'],ready:['Ready','idle'],initializing:['Preparing','warning'],reconnecting:['Reconnecting','warning'],running:[description||'Running','running'],paused:['Paused','warning'],stopping:['Stopping','warning'],error:['Error','error']};
    const [label,tone]=map[state]||map.stopped;
    const a=controls.startBind||'F2';
    return {label,tone,hint:`${a} start / stop`};
  }
  const api={catalog,defaults,mode,preferences,shortcut,keyLabel,setCustomMacros,macroIcons,statePresentation};
  root.PantheonHub=api;
  if(typeof module!=='undefined'&&module.exports) module.exports=api;
})(globalThis);
