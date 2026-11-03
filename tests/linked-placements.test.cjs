'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const {start,defaults,validate,instances,config}=require('../Lib/ui/placements.js');
const place=(id,slot,x=63,y=334)=>({...start(),id,kind:'place',slot,x,y});
test('instance labels use first-placed slot groups and letter suffixes for multiple placements',()=>{
  assert.equal(instances([place('a',3)])[0].label,'1');
  const list=instances([place('a',3),place('b',2),place('c',3),place('d',3)]);
  assert.deepEqual(list.map(p=>p.label),['1a','2','1b','1c']);
  assert.equal(instances(Array.from({length:27},(_,i)=>place('p'+i,1))).at(-1).label,'1aa');
});
test('linked actions follow coordinates and strict validation rejects missing/sold/unplaced units',()=>{
  const p=defaults(),steps=p.routes[0].teams[0].steps;
  steps.push(place('a',3),{...start(),id:'up',kind:'upgrade',placement:'a',slot:3});
  steps[1].x=220;
  assert.equal(validate(p,true).routes[0].teams[0].steps[2].x,220);
  steps[2].placement='missing';assert.throws(()=>validate(p,true));
  steps[2].placement='a';steps.push({...steps[2],id:'sell',kind:'sell'},{...steps[2],id:'after'});assert.throws(()=>validate(p,true));
});
test('auto upgrade is an explicit game capability and manual upgrades work without it',()=>{
  const p=defaults();p.routes[0].teams[0].steps.push({...place('a',1),autoUpgrade:2});
  assert.throws(()=>validate(p,true,config({autoUpgrade:0})));
  assert.doesNotThrow(()=>validate(p,true,config({autoUpgrade:1})));
  p.routes[0].teams[0].steps[1].autoUpgrade=0;
  p.routes[0].teams[0].steps.push({...start(),id:'up',kind:'upgrade',placement:'a'});
  assert.doesNotThrow(()=>validate(p,true,config({autoUpgrade:0})));
});
