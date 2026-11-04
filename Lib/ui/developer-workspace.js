(function(root){
  'use strict';
  class DeveloperWorkspace {
    constructor(){
      const $=id=>document.getElementById(id),tools=$('developer-tools'),content=$('framework-content'),framework=$('framework-editor');
      const captures=[...tools.children].filter(el=>el!==framework),layout=content.querySelector('.framework-layout');
      this.panels={},this.positions={},this.active='macro';
      const tabs=[['macro','Macro'],['sequences','Sequences'],['images','Images'],['placement','Placement'],['capture','Capture'],['guide','Guide']];
      this.nav=document.createElement('div');this.nav.className='developer-tabs';this.nav.setAttribute('role','tablist');this.nav.setAttribute('aria-label','Developer tools sections');
      for(const [id,label] of tabs){const button=document.createElement('button');button.className='developer-tab';button.type='button';button.dataset.developerTab=id;button.id='developer-tab-'+id;button.textContent=label;button.setAttribute('role','tab');button.setAttribute('aria-controls','developer-panel-'+id);this.nav.append(button);const panel=document.createElement('section');panel.id='developer-panel-'+id;panel.dataset.developerPanel=id;panel.className='developer-tab-panel';panel.setAttribute('role','tabpanel');panel.setAttribute('aria-labelledby',button.id);this.panels[id]=panel;(id==='capture'||id==='guide'?tools:content).append(panel);}
      tools.insertBefore(this.nav,framework);
      this.panels.macro.append($('framework-macro-name').closest('.framework-fields'),content.querySelector('.flow-settings-author'));
      this.panels.images.append($('framework-target').closest('section'));
      this.panels.sequences.append($('framework-reload').closest('.panel-top'),$('framework-flow').closest('section'));
      for(const id of ['play-maps','play-target-order','play-managed-upgrades','play-placement-feedback'])this.panels.placement.append($(id).closest('section'));
      this.panels.capture.append(...captures);layout.remove();content.append($('framework-savebar'));
      this.panels.guide.innerHTML='<div class="guide-heading"><h2>Component guide</h2><label>Find a component<input id="component-guide-search" type="search" placeholder="Search components and examples"></label></div><div class="guide-workflow"><h3>Typical match flow</h3><p>Enter the stage → wait for stage readiness → set the camera → run placements → wait for the match result → dismiss rewards → run the selected result sequence.</p><p>Images and saved points are created in Images. Player controls are created in Macro. Game detection, maps, money feedback and managed upgrades are configured in Placement. Fixed timing fields display seconds.</p></div><div id="component-guide-list"></div>';
      this.search=$('component-guide-search');this.search.addEventListener('input',()=>this.renderGuide());this.renderGuide();
      this.nav.addEventListener('click',e=>{const button=e.target.closest('[data-developer-tab]');if(button)this.select(button.dataset.developerTab);});
      this.nav.addEventListener('keydown',e=>{const buttons=[...this.nav.children],i=buttons.indexOf(document.activeElement);if(i<0)return;let n;if(e.key==='ArrowRight')n=(i+1)%buttons.length;else if(e.key==='ArrowLeft')n=(i+buttons.length-1)%buttons.length;else if(e.key==='Home')n=0;else if(e.key==='End')n=buttons.length-1;else return;e.preventDefault();this.select(buttons[n].dataset.developerTab);buttons[n].focus();});
      tools.addEventListener('click',e=>{const b=e.target.closest('[data-component-help]');if(!b)return;this.search.value='';this.renderGuide();this.select('guide');document.getElementById('component-guide-'+b.dataset.componentHelp)?.scrollIntoView({block:'center'});});
      this.select('macro');
    }
    select(id){
      if(!this.panels[id])return;
      this.positions[this.active]=window.scrollY;this.active=id;
      for(const [key,panel]of Object.entries(this.panels)){panel.hidden=key!==id;const tab=document.getElementById('developer-tab-'+key);tab.setAttribute('aria-selected',String(key===id));tab.tabIndex=key===id?0:-1;}
      window.scrollTo(0,this.positions[id]||0);
    }
    renderGuide(){
      const escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),q=this.search.value.trim().toLowerCase();
      const entries=Object.entries(root.PantheonComponentGuide).filter(([,c])=>Object.values(c).join(' ').toLowerCase().includes(q));
      document.getElementById('component-guide-list').innerHTML=entries.map(([id,c])=>`<article class="component-guide-card" id="component-guide-${id}"><h3>${escape(c.name)}</h3><p>${escape(c.description)}</p><p><strong>Example</strong> ${escape(c.example)}</p><p class="component-guide-note">${escape(c.note)}</p></article>`).join('')||'<p>No matching components.</p>';
    }
  }
  root.DeveloperWorkspace=DeveloperWorkspace;
})(globalThis);
