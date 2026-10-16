"""Bounded credential/artifact checks on the public Git inventory, without values."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKERS = [
    re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    re.compile(rb'github_pat_[A-Za-z0-9_]{30,}'),
    re.compile(rb'gh[pousr]_[A-Za-z0-9]{30,}'),
    re.compile(rb'AKIA[A-Z0-9]{16}'),
]
PRIVATE = {'.agents', '.codex', 'dist', 'contents', '__pycache__', 'node_modules'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--staged', action='store_true')
    args = parser.parse_args()
    names = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    issues = []
    for name in filter(None, names):
        path = Path(name)
        if PRIVATE.intersection(p.lower() for p in path.parts) or path.name.lower() in {'console.txt', 'server-console.txt', 'local.settings.json', 'id_rsa', 'id_ed25519'} or path.suffix.lower() in {'.log', '.jar', '.class', '.java', '.pem', '.pfx', '.ppk', '.key', '.p12', '.zip'}:
            issues.append(name + ': private/generated/non-Lua artifact')
            continue
        if (ROOT / path).is_symlink() or not (ROOT / path).resolve().is_relative_to(ROOT.resolve()):
            issues.append(name + ': linked/outside-workspace public file')
            continue
        data = (subprocess.check_output(['git', 'show', ':' + name], cwd=ROOT) if args.staged else (ROOT / path).read_bytes())
        if any(pattern.search(data) for pattern in MARKERS):
            issues.append(name + ': credential marker (value suppressed)')
    if issues:
        raise SystemExit('\n'.join(issues))
    version = (ROOT / 'VERSION').read_text().strip()
    manifest_path = ROOT / 'docs' / ('SOURCE_PROVENANCE_' + version.replace('.', '_') + '.json')
    if manifest_path.exists():
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
        for name, expected in manifest['files_sha256'].items():
            path = Path(name)
            if path.is_absolute() or '..' in path.parts or ':' in name or '\\' in name or not (ROOT / path).resolve().is_relative_to(ROOT.resolve()):
                issues.append(name + ': unsafe provenance path')
                continue
            data = (subprocess.check_output(['git', 'show', ':' + name], cwd=ROOT) if args.staged else (ROOT / name).read_bytes())
            if Path(name).suffix.lower() != '.png':
                data = data.replace(b'\r\n', b'\n')
            if hashlib.sha256(data).hexdigest() != expected:
                issues.append(name + ': current source provenance mismatch')
        if issues:
            raise SystemExit('\n'.join(issues))
        print(f'PASS: {len(manifest["files_sha256"])} current provenance hashes (canonical LF text / exact PNG bytes)')
    print(f'PASS: {len(list(filter(None, names)))} public files; credential/artifact heuristic. Manual diff review still required.')


if __name__ == '__main__':
    main()
