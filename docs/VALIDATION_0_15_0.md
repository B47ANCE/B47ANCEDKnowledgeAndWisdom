# Audit and journal-inspection validation

Version: 0.15.0
Date: 2026-10-16. Offline Windows, Python/Lupa Lua 5.1 only.
Public repository: https://github.com/B47ANCE/B47ANCEDKnowledgeAndWisdom
Branch: fix/authority-persistence-0.14.0
Baseline: a8ba91c8454a0a4cac937392d227e1ba1aebcaa3

[TESTED: offline] Before implementation, the new requirement regression failed on
unknown knowledge under NOT, and the journal atomicity regression failed on an
oversized queue throwing after item initialization. Follow-up rejected-operation
migration and malformed legacy-store initialization regressions also failed before
their corresponding fixes. These observations are not PZ runtime reproductions.

Exact validation commands from the project root:

```powershell
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_versions.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/run_host_tests.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/validate_source.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_public_tree.py --staged
git diff --check
```

[TESTED: offline] 25/25 host test files PASS; 17 current version mirrors PASS;
47 Lua parses, 87 translation/fallback files, 38 item types, exact-case imports,
Workshop mirrors and Lua-only checks PASS. Current provenance/public inventory and
manual staged diff checks are required before commit. Remote SHA/CI are verified
after push in the PR/iteration report.
No new test claims reuse historical runtime observations. The current provenance
manifest binds canonical LF text/exact PNG bytes, including added tests/modules.
Historical named validation/manifests, packages/staging and selected artwork remain
unchanged. Manual public diff review accompanies the credential/artifact heuristic.

[VERIFIED: source] Steam build 25485521; full engine version UNKNOWN. The current
modal definition/update fingerprint is in API_INSPECTION_0_15_0.json. API audit
entry recorded in the unmanaged local library. No native implementation or raw game
source is copied into this repository; no vanilla or third-party files changed.

[RUNTIME GATE] Native UI, old-save loading, authoritative writing/XP restoration,
replication/privacy and SP/dedicated scenarios are NOT TESTED. See AUDIT_0_15_0.md,
JOURNAL_INSPECTION.md and the existing broader native procedure. G7 BLOCKED /
NOT TESTED; stable G8 BLOCKED. No build, deploy, publish, game/server launch or tag.
