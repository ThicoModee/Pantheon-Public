const test=require('node:test'),assert=require('node:assert/strict');
const placements=require('../Lib/ui/placements.js');
test('managed placement preferences and creator configuration survive round trips',()=>{
 const c={panel:'panel',affordable:'green',max:'max',closeX:280,closeY:230,progress:{x:150,y:390,width:100,height:5},intervalMs:1000,settleMs:250,confirmMs:2000,policy:'affordable'};
 assert.deepEqual(placements.config({managedUpgrade:c}).managedUpgrade,c);
 const plan=placements.defaults();plan.routes[0].teams[0].steps.push({...placements.start(),id:'unit',kind:'place',x:200,y:300,managedPriority:2,managedLimit:4});
 const saved=placements.validate(plan,true);assert.equal(saved.routes[0].teams[0].steps[1].managedPriority,2);assert.equal(saved.routes[0].teams[0].steps[1].managedLimit,4);
 plan.routes[0].teams[0].steps[1].managedPriority=11;assert.throws(()=>placements.validate(plan,true));
});
