(function(root){
  const escape=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const icon=name=>`<svg viewBox="0 0 24 24" aria-hidden="true">${root.PantheonIcons?.[name]||''}</svg>`;
  const key=value=>{const aliases={' ':'Space',Esc:'Escape',Ctrl:'Control',ArrowUp:'Up',ArrowDown:'Down',ArrowLeft:'Left',ArrowRight:'Right',PageUp:'PgUp',PageDown:'PgDn'};value=aliases[value]||value.replace(/^key-/,'');if(/^[a-z0-9]$/i.test(value))return value.toUpperCase();if(/^(F(?:[1-9]|1\d|2[0-4])|Space|Tab|Enter|Escape|Up|Down|Left|Right|Shift|Control|Backspace|Delete|Insert|Home|End|PgUp|PgDn)$/.test(value))return value;throw Error('Use one letter, number, function key or navigation key.');};
  let recording=null,pendingRelease=null;
  const release=()=>{if(pendingRelease!==null){pendingRelease=null;root.PantheonKeyCapture.onState?.(false);}};
  const stop=(hold=false)=>{if(!recording){if(!hold)release();return;}const {button,text}=recording;recording=null;button.classList.remove('recording');button.innerHTML=text;if(!hold){release();root.PantheonKeyCapture.onState?.(false);}};
  root.PantheonKeyCapture={key,icon,escape,onState:null,button:(value,attrs='')=>`<button type="button" class="button key-button single-key" ${attrs}>${icon('keyboard')}<span>${escape(value)}</span></button>`,start(button,done,error){stop();recording={button,done,error,text:button.innerHTML};button.classList.add('recording');button.innerHTML=icon('keyboard')+'<span>Press a key…</span>';this.onState?.(true);},cancel:stop};
  const commit=(value,released=false)=>{const done=recording.done;stop(!released);if(!released)pendingRelease=value;done(value);};
  document.addEventListener('keydown',e=>{if(!recording)return;e.preventDefault();e.stopImmediatePropagation();if(e.repeat)return;if(e.key==='Escape'){stop();return;}try{if((e.ctrlKey&&e.key!=='Control')||(e.shiftKey&&e.key!=='Shift')||e.altKey||e.metaKey){recording.pending=null;throw Error('Use a single key without modifiers.');}const value=key(e.key);if(value==='Control'||value==='Shift'){recording.pending=value;return;}commit(value);}catch(err){recording?.error?.(err.message);}},true);
  document.addEventListener('keyup',e=>{try{if(pendingRelease===key(e.key))release();}catch{}if(!recording)return;e.preventDefault();e.stopImmediatePropagation();if(recording.pending===e.key)commit(recording.pending,true);},true);
  document.addEventListener('pointerdown',e=>{if(recording&&!recording.button.contains(e.target))stop();},true);
  window.addEventListener('blur',()=>stop());
  root.PantheonSort={bind(host,{handle,item,list,onDrop}){host.addEventListener('click',e=>{if(e.target.closest(handle)){e.preventDefault();e.stopPropagation();}},true);host.addEventListener('pointerdown',e=>{
    const grip=e.target.closest(handle),row=grip?.closest(item);if(!row||e.button!==0)return;const parent=row.closest(list);if(!parent)return;e.preventDefault();e.stopPropagation();const original=[...parent.children],rect=row.getBoundingClientRect(),anchor=e.clientY;let active=false,slot,ended=false;
    const siblings=()=>[...parent.children].filter(el=>el!==row&&el!==slot&&el.matches(item));
    const cleanup=()=>{document.removeEventListener('pointermove',move,true);document.removeEventListener('pointerup',finish,true);document.removeEventListener('pointercancel',cancel,true);document.removeEventListener('keydown',escape);window.removeEventListener('blur',cancel);if(grip.hasPointerCapture(e.pointerId))grip.releasePointerCapture(e.pointerId);};
    const move=ev=>{if(ev.pointerId!==e.pointerId)return;if(Math.abs(ev.clientY-anchor)<4&&!active)return;if(!active){active=true;slot=document.createElement('div');slot.className='step-drop-slot';slot.style.height=rect.height+'px';row.before(slot);Object.assign(row.style,{position:'fixed',left:rect.left+'px',width:rect.width+'px',height:rect.height+'px',zIndex:1000,pointerEvents:'none',margin:'0'});row.classList.add('step-dragging');}row.style.top=(rect.top+ev.clientY-anchor)+'px';const next=siblings().find(el=>ev.clientY<el.getBoundingClientRect().top+el.offsetHeight/2);if(next)parent.insertBefore(slot,next);else parent.append(slot);if(ev.clientY<80)window.scrollBy(0,-12);if(ev.clientY>innerHeight-60)window.scrollBy(0,12);};
    const cancel=(ev)=>{if(ev?.pointerId!==undefined&&ev.pointerId!==e.pointerId)return;if(ended)return;ended=true;cleanup();if(active){slot.remove();original.forEach(el=>parent.append(el));row.removeAttribute('style');row.classList.remove('step-dragging');}};
    const finish=ev=>{if(ev.pointerId!==e.pointerId||ended)return;ended=true;cleanup();if(active){slot.replaceWith(row);row.removeAttribute('style');row.classList.remove('step-dragging');onDrop(parent,[...parent.children].filter(el=>el.matches(item)));}};
    const escape=ev=>{if(ev.key==='Escape'){ev.preventDefault();cancel();}};
    grip.setPointerCapture(e.pointerId);document.addEventListener('pointermove',move,true);document.addEventListener('pointerup',finish,true);document.addEventListener('pointercancel',cancel,true);document.addEventListener('keydown',escape);window.addEventListener('blur',cancel);
  },true);}};
  root.PantheonEditorView={capture(host){
    const scroll=document.scrollingElement,x=scroll.scrollLeft,y=scroll.scrollTop,active=document.activeElement;
    let selector='',start=null,end=null;
    if(host.contains(active)){
      const step=active.closest('[data-step-path]'),setting=active.closest('[data-author-setting]'),option=active.closest('[data-setting-option]');
      const attrs=['data-step-field','data-condition-path','data-condition-field','data-parameter','data-walk-key','data-setting-field','data-option-field','data-default-option'];
      const keys=attrs.filter(k=>active.hasAttribute(k));
      if(keys.length){selector=(step?'[data-step-path="'+CSS.escape(step.dataset.stepPath)+'"] ':setting?'[data-author-setting="'+CSS.escape(setting.dataset.authorSetting)+'"] ':'')+(option?'[data-setting-option="'+option.dataset.settingOption+'"] ':'')+keys.map(k=>'['+k+'="'+CSS.escape(active.getAttribute(k))+'"]').join('');start=active.selectionStart;end=active.selectionEnd;}
    }
    return ()=>{if(selector){const el=host.querySelector(selector);if(el){el.focus({preventScroll:true});if(start!==null&&typeof el.setSelectionRange==='function')try{el.setSelectionRange(start,end);}catch{}}}scroll.scrollLeft=x;scroll.scrollTop=y;};
  }};
})(globalThis);
