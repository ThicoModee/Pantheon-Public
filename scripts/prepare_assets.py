from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
DATA=json.loads((ROOT/'Lib/vendor/lucide/icons.json').read_text(encoding='utf-8-sig'))
ALIASES={'grid':'layout-dashboard','help':'circle-help','panel':'panel-left','arrow':'arrow-right','external':'external-link','refresh':'refresh-cw','scroll':'scroll-text','snow':'snowflake','pin':'map-pin','dps':'swords','ground':'shield','hill':'mountain','buff':'sparkles','farm':'sprout','stop':'stop-circle'}
icons={}
for name,item in DATA['icons'].items():icons[name]=item['body']
for name,item in DATA.get('aliases',{}).items():icons[name]=icons[item['parent']]
for name,target in ALIASES.items():icons[name]=icons[target]
(ROOT/'Lib/ui/icons.js').write_text('window.PantheonIcons='+json.dumps(icons,ensure_ascii=False)+';\n',encoding='utf-8')
print('Prepared bundled Lucide icons.')
