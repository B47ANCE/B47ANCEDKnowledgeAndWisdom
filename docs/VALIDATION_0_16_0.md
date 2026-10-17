# Audit follow-through validation

Version: 0.16.0
Date: 2026-10-16. Offline Windows / Lupa Lua 5.1 only.
Baseline: ca5b724c63d49ab224f96b2daea3e17ad7498e44.
Branch: fix/authority-persistence-0.14.0
Public repository: https://github.com/B47ANCE/B47ANCEDKnowledgeAndWisdom

New regression cases failed before their corresponding fixes: MP player-store
acceptance, silent native XP refusal, malformed learned timestamps, empty claim
acquisition, truncated media identity, inconsistent journal totals and missing
shared reading dependency. Unsupported history evidence was reproduced against the
exact baseline Git module in an isolated VM. Current tests cover additional
boundary/reentrancy/replay/queue/probe cases without claiming each one was separately
run on baseline. Existing SP core fixtures now explicitly use SP role; MP refusal
is a separate case, never relabeled as dedicated gameplay success.

Exact commands from repository root:

```powershell
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_versions.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/run_host_tests.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/validate_source.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_public_tree.py --staged
git diff --check
```

Before the version bump, 0.15.0's 17 current mirrors passed.
[TESTED: offline] Current 17 mirrors PASS; 34/34 host test files PASS; 58 Lua parses,
87 translation/fallback files, 38 item types, exact-case imports and Workshop text
checks PASS. The source gate also rejects whole-table transports in private core
modules/harness. Staged provenance/public inventory and manual diff results are
verified before commit; remote SHA/CI results are recorded with the pushed head/PR. No old runtime report is promoted.
Source manifests use canonical LF text and exact supplied PNG bytes. Native hashes
and observations are separately in NATIVE_EVIDENCE_0_16_0.json; they are not runtime
behavior proofs. Selected engine inputs were read only; no engine/mod classes ran.
CFR was tooling outside the repository, not a mod or CI dependency.

Current gates: affected MP gameplay IMPLEMENTATION BLOCKED, native SP NOT TESTED,
G7 BLOCKED / NOT TESTED, stable G8 BLOCKED. Existing GlobalModData records are not
sanitized by refusing new writes; private migration is a separate unresolved P1.
The probe is read-only and never declares PASS for gameplay or privacy. No package,
deploy, game/server launch, Workshop upload, merge, stable tag or actual save change.
