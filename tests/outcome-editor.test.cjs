const {test}=require('node:test');
const assert=require('node:assert/strict');
require('../Lib/ui/framework-editor.js');
const proto=globalThis.FrameworkEditor.prototype;
const editor=()=>Object.assign(Object.create(proto),{definition:{entry:'main',settings:{},targets:{win:{kind:'pattern',name:'Victory'},lose:{kind:'pattern',name:'Defeat'}},workflows:{main:{name:'Main',steps:[]},unused:{name:'Unused',steps:[]}}},flow:'unused',toast(message){this.message=message;},render(){},renderFlow(){},change(){},escape:String,collapsed:new Set(),groupActions:new Map()});
test('sequence deletion preserves the entry and recursively referenced sequences',()=>{
 let e=editor();e.deleteFlow();assert.equal(e.definition.workflows.unused,undefined);
 e=editor();e.flow='main';e.deleteFlow();assert.ok(e.definition.workflows.main);
 e=editor();e.definition.workflows.main.steps=[{action:'outcome',thenSteps:[{action:'call',workflow:'unused'}],elseSteps:[]}];e.deleteFlow();assert.ok(e.definition.workflows.unused);assert.match(e.message,/used by/);
});
test('seconds input keeps millisecond definitions and fractional precision',()=>{
 const e=editor();e.definition.workflows.unused.steps=[{id:'wait',action:'wait',timeoutMs:30000}];
 e.editStep({target:{dataset:{stepField:'timeoutMs',seconds:'1'},type:'number',value:'90.125',closest:()=>({dataset:{stepPath:'0'}})}});
 assert.equal(e.definition.workflows.unused.steps[0].timeoutMs,90125);
});
