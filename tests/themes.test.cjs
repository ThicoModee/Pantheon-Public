const test=require('node:test'),assert=require('node:assert/strict');
const {defaults,preferences}=require('../Lib/ui/model.js');
test('themes migrate old preferences and persist supported choices',()=>{
 const old=defaults();delete old.theme;assert.equal(preferences(old).theme,'default');
 for(const theme of ['default','christmas','midnight','rose','ember'])assert.equal(preferences({...defaults(),theme}).theme,theme);
 assert.throws(()=>preferences({...defaults(),theme:'unknown'}));
});
