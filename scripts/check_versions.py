"""Check current source mirrors; historical packages never prove this version."""
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release', action='store_true')
    args = parser.parse_args()
    version = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?', version):
        raise SystemExit('Invalid canonical SemVer')
    mods = list((ROOT / 'src').glob('*/42/mod.info'))
    if len(mods) != 1:
        raise SystemExit('Expected exactly one authoritative mod.info')
    source = mods[0].parent.parent
    mirrors = {
        mods[0]: r'^modversion=(.+)$',
        source / 'info.txt': r'^Version: (.+)$',
        ROOT / 'README.md': r'Status: version `([^`]+)`',
        ROOT / 'WORKSHOP_DESCRIPTION.txt': r'\[b\]Mod Version: (.+?)\[/b\]',
        ROOT / 'workshop.txt': r'description=\[b\]Mod Version: (.+?)\[/b\]',
        ROOT / 'WORKSHOP_CHANGE_NOTE.txt': r'^\[b\]Version (.+?)\[/b\]',
        ROOT / 'docs/MASTER_ROADMAP.md': r'^Canonical version: ([^ .]+\.[^ .]+\.[^ .]+)\.',
        ROOT / 'tests/test_identity_migration.lua': r'API.VERSION=="([^"]+)"',
        ROOT / 'AGENTS.md': r'^B47ANCED Knowledge & Wisdom ([^ ]+) uses',
        ROOT / 'docs/IN_GAME_TESTING.md': r'^Current version: ([^ ]+)\.',
        ROOT / 'docs/IDENTITY_MIGRATION.md': r'^Current version: ([^ ]+)\.',
        ROOT / 'docs/REPOSITORY_AUDIT.md': r'Current version: ([^ ]+)\.',
        ROOT / 'docs/TESTING.md': r'^Current ([^ ]+) offline results',
        ROOT / 'docs/ARCHITECTURE.md': r'^## Current authority and persistence contract \(([^)]+)\)',
        ROOT / 'docs' / ('VALIDATION_' + version.replace('.', '_') + '.md'): r'^Version: (.+)$',
    }
    apis = list(source.glob('42/media/lua/shared/*/API.lua'))
    if len(apis) != 1:
        raise SystemExit('Expected exactly one canonical API')
    mirrors[apis[0]] = r'\.VERSION="([^"]+)"'
    changelog = ROOT / 'CHANGELOG.md'
    if changelog.exists():
        mirrors[changelog] = r'^## ([^ ]+) '
    errors = []
    for path, pattern in mirrors.items():
        match = re.search(pattern, path.read_text(encoding='utf-8-sig'), re.M)
        if not match or match.group(1) != version:
            errors.append(str(path.relative_to(ROOT)))
    if errors:
        raise SystemExit('Version mismatch/missing mirror: ' + ', '.join(errors))
    print(f'PASS: VERSION {version}; {len(mirrors)} current mirrors')
    if args.release:
        raise SystemExit('G8 BLOCKED: private MP authority/storage and migration are unimplemented; native runtime evidence and current release artifacts are missing. Historical dist/ and Contents/ are excluded.')


if __name__ == '__main__':
    main()
