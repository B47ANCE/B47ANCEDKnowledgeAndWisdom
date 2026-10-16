# Thumbnail iteration validation

Version: 0.14.1
Date: 2026-10-16. Offline Windows checks only.
Public repository: https://github.com/B47ANCE/B47ANCEDKnowledgeAndWisdom
Branch: `fix/authority-persistence-0.14.0`. Baseline: `45cd856adeef45811d2c79b919494fd6f4754d29`.

PATCH scope: supplied artwork, documentation and synchronized project-version
mirrors. No gameplay behavior, schema, Mod ID, sandbox setting or icon change.
Older validation and source manifests remain historical evidence.

[TESTED: offline] Pillow PNG verify/load, dimensions/mode and SHA-256 equality
against the supplied attachment for both thumbnail copies: PASS. See ARTWORK.md.
Git diff confirms no historical package or staging changes.

Exact commands from the repository root (Python runtime shown explicitly):

```powershell
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_versions.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/validate_source.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/run_host_tests.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_public_tree.py --staged
git diff --check
```

[TESTED: offline] Version mirrors: 12 PASS. Source validation: 42 Lua parses,
87 translation/fallback files, case/import/item and Workshop text checks PASS.
Lua 5.1 host regressions: 22/22 files PASS. The
source provenance manifest uses canonical LF text and exact PNG bytes. Public
inventory scanning and manual staged diff review exclude private/generated
files; this is a bounded audit, not a universal secret guarantee. GitHub CI and
the remote commit SHA are checked after pushing; this record does not assume an
unobserved workflow result.

[RUNTIME GATE] Native thumbnail display and Workshop acceptance NOT TESTED.
SP NOT TESTED. Dedicated G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. The existing
RUNTIME_VALIDATION_0_14_0.md procedure still applies to the unchanged gameplay;
its results must identify the actual tested version and commit. No packaging,
game/server launch, deployment, Workshop publication or stable release tag.
