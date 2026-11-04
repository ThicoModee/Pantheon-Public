'use strict';

const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');

const {actions,step,normalize,stageTemplate}=require('../Lib/ui/framework-editor.js');

const definition=JSON.parse(fs.readFileSync(path.join(__dirname,'data/flow-fixture.json'),'utf8'));

test('editor offers only typed input and control-flow actions',()=>{

  assert.deepEqual(actions,['click-point','click','click-setting','move','walk','scroll','wait','delay','press','key','call','repeat','for-setting','if','retry','until','stop','camera','placements','outcome','click-wait','scroll-option','dismiss','setting-call']);

  for(const action of actions){const s=step(action,definition,'new-step');assert.equal(s.action,action);assert.equal(s.id,'new-step');assert.equal(s.path,undefined);}

  assert.throws(()=>step('run',definition,'bad'));

});

test('stage-entry template groups the exact retry, diagonal walk, scroll and load-check sequence',()=>{

  const d=structuredClone(definition),images=stageTemplate(d,'enter-stage'),steps=d.workflows['enter-stage'].steps;

  assert.deepEqual(steps.map(s=>s.action),['retry','move','scroll','click-point','click-point','wait']);

  assert.deepEqual(steps[0].steps.map(s=>s.action),['click-point','click-point','walk']);

  assert.deepEqual(steps[0].steps[2].keys,['W','D']);assert.equal(steps[0].condition.checks[0].target,images.chamber);

  assert.equal(steps.at(-1).condition.checks[0].target,images.loaded);

  assert.equal(d.targets[images.chamber].pattern,'');assert.equal(d.targets[images.loaded].pattern,'');

  assert.equal(definition.workflows['enter-stage'],undefined);

});
