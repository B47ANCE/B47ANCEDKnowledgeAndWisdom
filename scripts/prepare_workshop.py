"""Prepare/verify an isolated Knowledge MP-test package. Never upload or run a game."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import zipfile
from check_versions import ROOT


NOTICE = 'MP testing build - dedicated multiplayer NOT TESTED'
ITEM = '3792566496'
COMMON = 'Contents/mods/B47ANCEDKnowledgeAndWisdom/common/.keep'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(root):
    root = Path(root)
    if (root/'WORKSHOP_ID.txt').read_text().strip() != ITEM:
        raise ValueError('wrong existing Workshop identity')
    description = (root/'WORKSHOP_DESCRIPTION.txt').read_text(encoding='utf-8').strip()
    note = (root/'WORKSHOP_CHANGE_NOTE.txt').read_text(encoding='utf-8').split('[b]Earlier development notes (historical)[/b]')[0].strip()
    for text in (description, note):
        if NOTICE not in text or '\\n' in text or any(marker in text for marker in ('TODO', '<placeholder>', '\x00')):
            raise ValueError('invalid MP-test text')
    if len(description.encode('utf-8')) >= 8000:
        raise ValueError('description exceeds reviewed Steamworks byte budget')
    if '[url=https://github.com/B47ANCE/B47ANCEDKnowledgeAndWisdom]' not in description:
        raise ValueError('missing verified source link')
    projected = '\n'.join(line[len('description='):] for line in (root/'workshop.txt').read_text(encoding='utf-8').splitlines() if line.startswith('description=')).strip()
    if projected != description:
        raise ValueError('workshop description differs from canonical text')
    return description, note


def payload(root):
    root = Path(root)
    source = root/'src/B47ANCEDKnowledgeAndWisdom/42'
    files = {}
    for path in sorted(source.rglob('*')):
        if path.is_symlink() or getattr(path, 'is_junction', lambda: False)():
            raise ValueError('linked runtime input')
        if path.is_file():
            if path.suffix.lower() in {'.java', '.jar', '.class', '.dll', '.so', '.exe'}:
                raise ValueError('non-Lua runtime component')
            files['Contents/mods/B47ANCEDKnowledgeAndWisdom/42/'+path.relative_to(source).as_posix()] = path.read_bytes()
    for target, name in [('Contents/mods/B47ANCEDKnowledgeAndWisdom/info.txt', 'src/B47ANCEDKnowledgeAndWisdom/info.txt'),
                         ('Contents/mods/B47ANCEDKnowledgeAndWisdom/thumbnail.png', 'src/B47ANCEDKnowledgeAndWisdom/thumbnail.png'),
                         ('preview.png', 'preview.png'), ('workshop.txt', 'workshop.txt')]:
        files[target] = (root/name).read_bytes()
    files[COMMON] = b''  # Packaging-only empty common layer; no runtime code.
    if len(files) != len({name.casefold() for name in files}):
        raise ValueError('case collision')
    return files


def validate_zip(path, expected):
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if len(names) != len({name.casefold() for name in names}):
            raise ValueError('duplicate/case-colliding archive member')
        if any(name.startswith('/') or '\\' in name or ':' in name or any(p in ('', '.', '..') for p in name.split('/')) for name in names):
            raise ValueError('unsafe archive member')
        if set(names) != set(expected) or archive.testzip():
            raise ValueError('archive inventory/CRC differs')
        for name, raw in expected.items():
            if archive.read(name) != raw:
                raise ValueError('archive source bytes differ')


def escape(text):
    return text.replace('\\', '\\\\').replace('"', '\\"').replace('\r\n', '\n').replace('\r', '\n')


def verify(output, root=ROOT):
    output, root = Path(output).resolve(), Path(root).resolve()
    expected = payload(root)
    manifest = json.loads((output/'provenance.json').read_text(encoding='utf-8'))
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
    version = (root/'VERSION').read_text().strip()
    archive = output/('B47ANCEDKnowledgeAndWisdom-'+version+'-mp-test.zip')
    validate_zip(archive, expected)
    actual = {p.relative_to(output/'stage').as_posix(): p for p in (output/'stage').rglob('*') if p.is_file()}
    if set(actual) != set(expected) or any(actual[n].is_symlink() or actual[n].read_bytes() != raw for n, raw in expected.items()):
        raise ValueError('staging bytes/inventory differ')
    hashes = {name: sha(raw) for name, raw in expected.items()}
    if manifest.get('commit') != commit or manifest.get('version') != version or manifest.get('workshop_id') != ITEM or manifest.get('mod_id') != 'B47ANCEDKnowledgeAndWisdom' or manifest.get('appid') != 108600 or manifest.get('files') != hashes or manifest.get('package_sha256') != sha(archive.read_bytes()):
        raise ValueError('provenance differs')
    description, note = canonical(root)
    expected_vdf = vdf(output, description, note)
    if (output/'upload.vdf').read_text(encoding='utf-8') != expected_vdf:
        raise ValueError('upload VDF differs')
    if (output/'description.bbcode').read_text(encoding='utf-8') != description or (output/'changenote.txt').read_text(encoding='utf-8') != note:
        raise ValueError('generated publication text differs')
    return manifest


def vdf(output, description, note):
    # Omit title, visibility and tags: preserve the existing item's values.
    fields = {'appid': '108600', 'publishedfileid': ITEM,
              'contentfolder': (output/'stage/Contents').as_posix(),
              'previewfile': (output/'stage/preview.png').as_posix(),
              'description': description, 'changenote': note}
    return '"workshopitem"\n{\n'+''.join('    "'+k+'" "'+escape(value)+'"\n' for k, value in fields.items())+'}\n'


def prepare(output):
    subprocess.run([sys.executable, str(ROOT/'scripts/check_versions.py')], cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT/'scripts/check_public_tree.py')], cwd=ROOT, check=True)
    description, note = canonical(ROOT)
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    if subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT):
        raise ValueError('commit intended publication inputs first')
    version = (ROOT/'VERSION').read_text().strip()
    output = Path(output).absolute()
    if not output.resolve().is_relative_to((ROOT/'dist').resolve()):
        raise ValueError('output must stay inside this checkout dist directory')
    for parent in [output, *output.parents]:
        if parent.is_symlink() or getattr(parent, 'is_junction', lambda: False)():
            raise ValueError('linked output path')
    if output.exists() or output.is_symlink(): raise ValueError('output already exists; verify rather than overwrite')
    # No deletion, deployment, old package synchronization or Steam operation.
    output.mkdir(parents=True)
    files = payload(ROOT)
    for name, raw in files.items():
        target = output/'stage'/name; target.parent.mkdir(parents=True, exist_ok=True); target.write_bytes(raw)
    archive = output/('B47ANCEDKnowledgeAndWisdom-'+version+'-mp-test.zip')
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as target:
        for name, raw in sorted(files.items()):
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0)); info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16; target.writestr(info, raw)
    record = {'version': version, 'commit': commit, 'appid': 108600, 'workshop_id': ITEM,
              'mod_id': 'B47ANCEDKnowledgeAndWisdom', 'package_sha256': sha(archive.read_bytes()),
              'files': {name: sha(raw) for name, raw in files.items()},
              'generated_common_marker': COMMON, 'target_min_game': '42.20.3',
              'source_evidence_steam_build': '25485521', 'executed_build': 'NOT TESTED',
              'validation': 'Offline host/source checks; see owning commit docs/WORKSHOP_0.17.0.md',
              'G7': 'BLOCKED / NOT TESTED', 'G8': 'BLOCKED', 'upload_verified': False,
              'identity_access': 'Fixed existing repository item identity. Verify current access and upload outcome separately for each attempt; omit visibility changes.'}
    for name, text in [('provenance.json', json.dumps(record, indent=2)+'\n'),
                       ('description.bbcode', description), ('changenote.txt', note), ('upload.vdf', vdf(output, description, note))]:
        (output/name).write_bytes(text.encode('utf-8'))
    return verify(output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--verify', action='store_true')
    args = parser.parse_args()
    try:
        record = verify(args.output) if args.verify else prepare(args.output)
        print(json.dumps({'status': 'PASS', 'files': len(record['files']), 'version': record['version'],
                          'commit': record['commit'], 'package_sha256': record['package_sha256'],
                          'upload_verified': False, 'G7': record['G7'], 'G8': record['G8']}, indent=2))
    except (OSError, ValueError, zipfile.BadZipFile, KeyError, subprocess.CalledProcessError) as error:
        print('FAIL: '+type(error).__name__+'; package/upload not certified'); sys.exit(1)
