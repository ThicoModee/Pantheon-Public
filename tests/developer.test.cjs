'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const {region,pattern,decodePattern}=require('../Lib/ui/developer-tools.js');
const {preferences,defaults}=require('../Lib/ui/model.js');
const alphabet='0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const decode=text=>text.split('.').at(-1).split('').map(c=>alphabet.indexOf(c).toString(2).padStart(6,'0')).join('').replace(/10*$/,'');
test('FindText encoding preserves pixels, row order, weighted grayscale, and sentinel padding',()=>{
  for(const width of [1,2,5,6,7,134]){
    const data=Uint8ClampedArray.from({length:width*3*4},(_,i)=>i%4===3?255:i%256);
    const result=pattern(data,width,3,99),expected=[];
    for(let i=0;i<data.length;i+=4)expected.push(((data[i]*38+data[i+1]*75+data[i+2]*15)>>7)<=99?'1':'0');
    assert.equal(decode(result.text),expected.join(''));assert.equal(result.bits,expected.join(''));
    assert.ok(result.text.startsWith(`|<>*99$${width}.`));
  }
  assert.equal(pattern(Uint8ClampedArray.from([0,0,0,255,255,255,255,255]),2,1,99).text,'|<>*99$2.c');
  assert.throws(()=>pattern(new Uint8Array(8),2,2,99));assert.throws(()=>pattern(new Uint8Array(4),1,1,256));
});
test('selection stays within client pixels and supports reverse dragging',()=>{
  assert.deepEqual(region({x:20,y:30},{x:10,y:10}),{x:10,y:10,width:11,height:21});
  assert.deepEqual(region({x:799,y:599},{x:799,y:599}),{x:799,y:599,width:1,height:1});
});
test('FindText preview decodes the encoded pixels and named variants',()=>{
  const p=pattern(Uint8ClampedArray.from([0,0,0,255,255,255,255,255]),2,1,99);
  assert.deepEqual(decodePattern(p.text),[{width:2,height:1,bits:'10'}]);
  assert.equal(decodePattern(p.text.replace('<>','<settings>')+p.text).length,2);
  assert.throws(()=>decodePattern('|<>*99$800.0'));assert.throws(()=>decodePattern('<script>'));
});
test('developer mode is disabled by default and old preferences migrate without enabling it',()=>{
  assert.equal(defaults().developer,0);const old=defaults();delete old.developer;
  assert.equal(preferences(old).developer,0);assert.equal(preferences({...old,developer:1}).developer,1);
  assert.throws(()=>preferences({...old,developer:2}));
});
