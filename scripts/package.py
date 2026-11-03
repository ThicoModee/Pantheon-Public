from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json,re

root=Path(__file__).resolve().parents[1]
output=root/'dist/Pantheon.zip'
output.parent.mkdir(exist_ok=True)
files=[root/name for name in ['Pantheon.ahk','README.md','THIRD_PARTY.md']]
for folder in ['Lib','macros','docs']:
    files.extend(p for p in (root/folder).rglob('*') if p.is_file() and p.suffix.lower() not in {'.log','.tmp'} and '__pycache__' not in p.parts and p.name!='.gitkeep')
for file in (root/'macros').glob('*.json'):
    raw=json.loads(file.read_text(encoding='utf-8-sig'))
    if raw.get('format')!='pantheon-macro' or file.stem!=raw.get('id'): raise ValueError('Invalid supplied macro: '+file.name)
with ZipFile(output,'w',ZIP_DEFLATED) as archive:
    for file in sorted(files): archive.write(file,Path('Pantheon')/file.relative_to(root))
    archive.writestr('Pantheon/macros/','')
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert not any('/data/' in p or '/test-results/' in p or '/tests/' in p or '/scripts/' in p for p in archive.namelist())
    assert 'Pantheon/Lib/framework/Worker.ahk' in archive.namelist()
    for source in re.findall(r'<script defer src="([^"]+)"', (root/'Lib/ui/index.html').read_text(encoding='utf-8-sig')):
        assert 'Pantheon/Lib/ui/'+source in archive.namelist(), source
    assert [p for p in archive.namelist() if p.count('/')==1 and p.endswith('.ahk')]==['Pantheon/Pantheon.ahk']
print(f'{output}: {len(files)} files, {output.stat().st_size:,} bytes; integrity checked.')
