const test=require('node:test'),assert=require('node:assert/strict');
require('../Lib/ui/component-guide.js');
const {actions}=require('../Lib/ui/framework-editor.js');
test('every authoring component has a guide description, example and behaviour note',()=>{
 for(const id of actions){const entry=globalThis.PantheonComponentGuide[id];assert.ok(entry,id);for(const key of ['name','description','example','note'])assert.ok(typeof entry[key]==='string'&&entry[key].length>(key==='name'?0:5),id+' '+key);}
});
