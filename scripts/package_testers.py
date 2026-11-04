from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json, re

root = Path(__file__).resolve().parents[1]
version = re.search(r'Current := "([^"]+)"', (root/'Lib/Version.ahk').read_text(encoding='utf-8-sig')).group(1)
output = root/'dist'/f'Pantheon-{version}.zip'
output.parent.mkdir(exist_ok=True)
readme = f'''# Pantheon {version}

Install AutoHotkey v2 (64-bit) and Microsoft Edge WebView2 Runtime.
Extract the complete folder, then run Pantheon.ahk.

Raids is included. Configure your settings and placements before starting.
To update, extract into a new folder and copy your existing data folder if you want to retain your preferences and placements. Local edits to a bundled macro take priority over its supplied version; back up/export those edits before replacing them to use an updated supplied macro.

Developer tools: enable Developer mode at the bottom of Settings. The Guide tab explains components and shows examples. Additional guides are in Lib/help.
Themes are under Settings > Appearance.

Macro exports require the exporting Pantheon version or newer. Review community macro actions before running them.
Personal settings, screenshots, authored macros and logs are created in data. Do not share your entire data folder.
'''
files = [(root/'Pantheon.ahk', 'Pantheon/Pantheon.ahk'), (root/'THIRD_PARTY.md', 'Pantheon/Lib/THIRD_PARTY.md')]
files += [(p, 'Pantheon/'+p.relative_to(root).as_posix()) for p in (root/'Lib').rglob('*') if p.is_file() and p.suffix.lower() not in {'.tmp', '.log'} and '__pycache__' not in p.parts]
files += [(root/'docs'/name, 'Pantheon/Lib/help/'+name) for name in ['MACRO_AUTHORING.md', 'EDITOR_CONTROLS.md', 'SHARED_PLACEMENTS.md', 'PLACED_UNIT_ACTIONS.md']]
for p in (root/'macros').glob('*.json'):
    package = json.loads(p.read_text(encoding='utf-8-sig'))
    assert package['format']=='pantheon-macro' and package['id']+'.json'==p.name
    files.append((p, 'Pantheon/macros/'+p.name))
with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
    archive.writestr('Pantheon/README.md', readme)
    for p, name in sorted(files):
        archive.write(p, name)
with ZipFile(output) as archive:
    assert archive.testzip() is None
    names = archive.namelist()
    assert not any('/'+part+'/' in name for name in names for part in ['data', 'tests', 'test-results', 'scripts', '.git'])
    assert [n for n in names if n.count('/')==1 and n.endswith('.ahk')]==['Pantheon/Pantheon.ahk']
    assert 'Pantheon/Lib/framework/Worker.ahk' in names
    for script in re.findall(r'<script defer src="([^"]+)"', (root/'Lib/ui/index.html').read_text(encoding='utf-8-sig')):
        assert 'Pantheon/Lib/ui/'+script in names
print(f'{output}: {len(names)} entries, {output.stat().st_size:,} bytes; integrity and contents checked.')
