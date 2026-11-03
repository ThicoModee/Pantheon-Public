(function(root){
  'use strict';
  const alphabet='0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  function region(a,b){
    const x=Math.max(0,Math.min(799,Math.min(a.x,b.x))),y=Math.max(0,Math.min(599,Math.min(a.y,b.y)));
    return {x,y,width:Math.max(1,Math.min(800-x,Math.abs(a.x-b.x)+1)),height:Math.max(1,Math.min(600-y,Math.abs(a.y-b.y)+1))};
  }
  function pattern(pixels,width,height,threshold){
    if(!Number.isInteger(width)||width<1||width>800||!Number.isInteger(height)||height<1||height>600||pixels.length!==width*height*4||!Number.isInteger(threshold)||threshold<0||threshold>255)throw Error('Invalid FindText image or threshold.');
    let bits='',encoded='';
    for(let i=0;i<pixels.length;i+=4)bits+=((pixels[i]*38+pixels[i+1]*75+pixels[i+2]*15)>>7)<=threshold?'1':'0';
    const source=bits;
    bits+='100000'.slice(0,6-bits.length%6);
    for(let i=0;i<bits.length;i+=6)encoded+=alphabet[parseInt(bits.slice(i,i+6),2)];
    return {text:`|<>*${threshold}$${width}.${encoded}`,bits:source};
  }
  function decodePattern(text){
    if(typeof text!=='string'||text.length>100000)throw Error('Invalid FindText capture.');
    const parts=text.split('|').filter(Boolean);if(!parts.length||parts.length>8)throw Error('Invalid capture variants.');
    return parts.map(part=>{
      const m=part.match(/^<[^<>]{0,64}>\*(\d{1,3})\$(\d{1,3})\.([0-9+/A-Za-z]+)$/);
      if(!m||Number(m[1])>255)throw Error('Unsupported FindText capture.');
      const width=Number(m[2]);let bits='';
      for(const c of m[3])bits+=alphabet.indexOf(c).toString(2).padStart(6,'0');
      if(!/10*$/.test(bits))throw Error('Invalid capture padding.');bits=bits.replace(/10*$/,'');
      const height=bits.length/width;if(width<1||width>800||!Number.isInteger(height)||height<1||height>600)throw Error('Invalid capture dimensions.');
      return {width,height,bits};
    });
  }
  class DeveloperPanel{
    constructor({request,toast}){
      this.request=request;this.toast=toast;this.enabled=false;this.busy=false;this.frame=null;this.selection={x:0,y:0,width:800,height:600};this.anchor=null;this.pointer=null;this.code='';
      this.$=id=>document.getElementById(id);
      this.canvas=this.$('developer-canvas');this.context=this.canvas.getContext('2d');
      this.source=document.createElement('canvas');this.source.width=800;this.source.height=600;this.sourceContext=this.source.getContext('2d',{willReadFrequently:true});
      this.$('developer-coordinates').addEventListener('change',async e=>{try{await request('developerCoordinates',Number(e.target.checked));}catch(err){e.target.checked=false;toast(err.message,true);}});
      for(const [id,action]of [['developer-capture','developerCapture'],['developer-select','developerSelect']])this.$(id).addEventListener('click',()=>this.perform(()=>this.captureFrame(action)));
      this.$('developer-export').addEventListener('click',()=>this.perform(async()=>{const r=await request('developerExport',this.selection);if(!r.cancelled)toast('PNG region saved.');}));
      this.$('developer-copy-area').addEventListener('click',()=>this.perform(async()=>{await request('developerCopy',this.selection);toast('Client coordinates copied.');}));
      this.$('developer-copy-pattern').addEventListener('click',()=>this.perform(async()=>{await request('developerCopyPattern',this.code);toast('FindText pattern copied.');}));
      this.$('developer-test').addEventListener('click',()=>this.perform(async()=>{
        const r=await request('developerTest',{pattern:this.code,tolerance:Number(this.$('developer-tolerance').value)});
        this.$('developer-result').textContent=r.matches.length?`${r.matches.length} match${r.matches.length===1?'':'es'} · client centres: ${r.matches.map(m=>`${m.x}, ${m.y}`).join(' · ')}`:'No match in the current Roblox client area.';
      }));
      for(const name of ['x','y','width','height'])this.$('developer-'+name).addEventListener('change',()=>{
        const r=Object.fromEntries(['x','y','width','height'].map(key=>[key,Math.trunc(Number(this.$('developer-'+key).value))]));
        r.x=Math.max(0,Math.min(799,r.x||0));r.y=Math.max(0,Math.min(599,r.y||0));r.width=Math.max(1,Math.min(800-r.x,r.width||1));r.height=Math.max(1,Math.min(600-r.y,r.height||1));this.selection=r;this.sync();
      });
      this.$('developer-threshold').addEventListener('input',()=>this.renderPattern());
      this.$('developer-zoom').addEventListener('change',()=>{this.canvas.style.width=800*Number(this.$('developer-zoom').value)+'px';});
      const position=e=>{const r=this.canvas.getBoundingClientRect();return {x:Math.max(0,Math.min(799,Math.floor((e.clientX-r.left)*800/r.width))),y:Math.max(0,Math.min(599,Math.floor((e.clientY-r.top)*600/r.height)))};};
      this.canvas.addEventListener('pointerdown',e=>{if(!this.frame||this.busy||e.button!==0)return;e.preventDefault();this.pointer=e.pointerId;this.anchor=position(e);this.canvas.setPointerCapture(e.pointerId);this.selection=region(this.anchor,this.anchor);this.sync();});
      this.canvas.addEventListener('pointermove',e=>{
        if(!this.frame||this.busy)return;const p=position(e),pixel=this.sourceContext.getImageData(p.x,p.y,1,1).data;
        this.$('developer-pixel').textContent=`Client: ${p.x}, ${p.y} · RGB: #${[...pixel].slice(0,3).map(c=>c.toString(16).padStart(2,'0')).join('').toUpperCase()}`;
        if(this.anchor&&this.pointer===e.pointerId){this.selection=region(this.anchor,p);this.sync(false);}
      });
      const end=e=>{if(this.pointer!==e.pointerId)return;this.anchor=null;this.pointer=null;this.renderPattern();};
      this.canvas.addEventListener('pointerup',end);this.canvas.addEventListener('pointercancel',end);this.canvas.addEventListener('lostpointercapture',end);
    }
    setEnabled(enabled){this.enabled=!!enabled;this.$('developer-tools').hidden=!enabled;this.$('developer-mode').checked=!!enabled;if(!enabled){this.$('developer-coordinates').checked=false;this.$('developer-pattern').value='';this.code='';this.frame=null;this.$('developer-image-tools').hidden=true;}}
    async captureFrame(action){
      const result=await this.request(action);if(result.cancelled)return result;const image=new Image();image.src=result.image;await image.decode();
      this.sourceContext.drawImage(image,0,0);this.frame=true;this.selection=result.region||{x:0,y:0,width:800,height:600};this.$('developer-image-tools').hidden=false;this.sync();
      this.$('developer-result').textContent=result.region?'Region selected. Adjust the threshold, then copy the FindText pattern.':'Captured Roblox client area: 800 × 600';return result;
    }
    selectRegion(){return this.perform(()=>this.captureFrame('developerSelect'));}
    pickCoordinates(){return this.perform(()=>this.request('developerPickPoint'));}
    async perform(fn){if(this.busy||!this.enabled)return;this.busy=true;const buttons=[...this.$('developer-tools').querySelectorAll('button')].filter(b=>!b.closest('#framework-editor'));buttons.forEach(b=>b.disabled=true);try{return await fn();}catch(e){this.toast(e.message,true);}finally{this.busy=false;buttons.forEach(b=>b.disabled=false);}}
    sync(convert=true){
      const r=this.selection;for(const key of ['x','y','width','height'])this.$('developer-'+key).value=r[key];
      this.context.drawImage(this.source,0,0);this.context.fillStyle='rgba(0,0,0,.45)';this.context.fillRect(0,0,800,600);this.context.drawImage(this.source,r.x,r.y,r.width,r.height,r.x,r.y,r.width,r.height);this.context.strokeStyle='#a99bff';this.context.lineWidth=1;this.context.strokeRect(r.x+.5,r.y+.5,r.width-1,r.height-1);
      if(convert)this.renderPattern();
    }
    renderPattern(){
      if(!this.frame)return;const r=this.selection,threshold=Number(this.$('developer-threshold').value),pixels=this.sourceContext.getImageData(r.x,r.y,r.width,r.height).data;
      const result=pattern(pixels,r.width,r.height,threshold);this.code=result.text;this.$('developer-pattern').value=this.code;this.$('developer-threshold-value').textContent=threshold;
      const canvas=this.$('developer-binary');canvas.width=r.width;canvas.height=r.height;const ctx=canvas.getContext('2d'),image=ctx.createImageData(r.width,r.height);
      for(let i=0;i<result.bits.length;i++){const value=result.bits[i]==='1'?0:255;image.data.set([value,value,value,255],i*4);}ctx.putImageData(image,0,0);
      this.$('developer-pattern-size').textContent=`${r.width} × ${r.height} · ${this.code.length.toLocaleString()} characters`;
    }
  }
  root.DeveloperPanel=DeveloperPanel;root.PantheonDeveloper={region,pattern,decodePattern};
  if(typeof module!=='undefined'&&module.exports)module.exports={region,pattern,decodePattern};
})(globalThis);
