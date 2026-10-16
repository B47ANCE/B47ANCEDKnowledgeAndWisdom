"""Offline identity, Lua syntax, localization and Linux path-case checks."""
import json
import re
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'src/B47ANCEDKnowledgeAndWisdom/42'


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def main():
    metadata = dict(line.split('=', 1) for line in (SOURCE / 'mod.info').read_text(encoding='utf-8').splitlines() if '=' in line)
    require(metadata['name'] == 'B47ANCED Knowledge & Wisdom' and metadata['id'] == 'B47ANCEDKnowledgeAndWisdom', 'Wrong canonical identity')
    require((ROOT / 'WORKSHOP_ID.txt').read_text().strip() == '3792566496', 'Workshop item identity changed')
    files = [p for p in (ROOT / 'src').rglob('*') if p.is_file()]
    paths = [p.relative_to(ROOT / 'src').as_posix() for p in files]
    require(len({p.lower() for p in paths}) == len(paths), 'Case-colliding source paths')
    require(not any(p.suffix.lower() in {'.jar', '.java', '.class', '.dll', '.so'} for p in files), 'Non-Lua runtime dependency')
    require(not any('experienceWorks' in p for p in paths), 'Old active source filename')
    modules = {p.relative_to(SOURCE / 'media/lua' / realm).with_suffix('').as_posix()
               for realm in ('shared', 'client', 'server') for p in (SOURCE / 'media/lua' / realm).rglob('*.lua')}
    runtime = LuaRuntime(unpack_returned_tuples=True)
    parse = runtime.eval('function(source,name) local fn,err=loadstring(source,name);return fn~=nil,err end')
    lua_files = [p for p in files if p.suffix == '.lua'] + list((ROOT / 'tests').rglob('*.lua'))
    for path in lua_files:
        text = path.read_text(encoding='utf-8-sig')
        ok, error = parse(text, '@' + path.as_posix())
        require(ok, f'Lua syntax: {path}: {error}')
        if path.is_relative_to(SOURCE):
            if path.name != 'LegacyMigration.lua':
                require('experienceWorks' not in text and 'EXPERIENCE_WORKS' not in text, f'Old namespace outside private compatibility: {path}')
            for name in re.findall(r'\brequire\s*\(?\s*["\'](B47ANCEDKnowledgeAndWisdom/[^"\']+)["\']', text):
                require(name in modules, 'Missing or wrong-case import: ' + name)
    translations = SOURCE / 'media/lua/shared/Translate'
    english = {p.name: json.loads(p.read_text(encoding='utf-8')) for p in (translations / 'EN').glob('*.json')}
    localized = 0
    for path in translations.glob('*/*.json'):
        values = json.loads(path.read_text(encoding='utf-8'))
        require(path.name in english and set(values) == set(english[path.name]), f'Translation/fallback key mismatch: {path}')
        require(all(isinstance(v, str) and v for v in values.values()), f'Empty translation: {path}')
        require(all('experienceWorks' not in v for v in values.values()), f'Old display brand: {path}')
        localized += 1
    for path in files:
        if path.suffix == '.lua':
            for key in re.findall(r'["\'](ContextMenu_B47ANCEDKnowledgeAndWisdom_[^"\']+)["\']', path.read_text(encoding='utf-8')):
                require(key in english['ContextMenu.json'], 'Missing UI translation: ' + key)
    sandbox = (SOURCE / 'media/sandbox-options.txt').read_text(encoding='utf-8')
    require('option B47ANCEDKnowledgeAndWisdom.EnableResearchViewer' in sandbox and 'page = B47ANCEDKnowledgeAndWisdom' in sandbox, 'Sandbox identity mismatch')
    require(english['Sandbox.json']['Sandbox_B47ANCEDKnowledgeAndWisdom'] == 'B47ANCED Knowledge & Wisdom', 'Sandbox page display mismatch')
    items = []
    for path in (SOURCE / 'media/scripts').glob('*.txt'):
        text = path.read_text(encoding='utf-8')
        module = re.search(r'^module (\w+)', text, re.M).group(1)
        require(module == ('experienceWorks' if path.name.startswith('LegacySaved') else 'B47ANCEDKnowledgeAndWisdom'), 'Wrong item module')
        require(text.count('{') == text.count('}'), 'Unbalanced item script braces')
        items.extend(module + '.' + name for name in re.findall(r'\bitem\s+(\w+)\s*\{', text))
    require(len(items) == len(set(items)) == 38, 'Missing/duplicate canonical or legacy saved item types')
    require(set(items) == set(english['ItemName.json']), 'Item translation coverage mismatch')
    workshop = (ROOT / 'workshop.txt').read_text(encoding='utf-8').splitlines()
    for field, filename in [('description', 'WORKSHOP_DESCRIPTION.txt'), ('changenote', 'WORKSHOP_CHANGE_NOTE.txt')]:
        lines = [line[len(field)+1:] for line in workshop if line.startswith(field+'=')]
        require(lines == (ROOT / filename).read_text(encoding='utf-8').splitlines(), field + ' mirror/newline mismatch')
    require('title=B47ANCED Knowledge & Wisdom' in workshop, 'Workshop title mismatch')
    print(f'PASS: identity; {len(lua_files)} Lua 5.1 parses; exact-case imports; {localized} translation/fallback files; 38 item types; Workshop text mirrors; Lua-only source')
    print('STATIC ONLY: native PZ loading, Linux, SP and dedicated MP NOT TESTED.')


if __name__ == '__main__':
    main()
