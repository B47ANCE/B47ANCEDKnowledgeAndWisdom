# B47ANCED Knowledge & Wisdom 0.13.0 validation

2026-10-16. Offline Windows source/host evidence only. Display name:
**B47ANCED Knowledge & Wisdom**. Mod ID: `B47ANCEDKnowledgeAndWisdom`.

Working directory for all commands:
`C:\Users\willi\Desktop\Work\Project Zomboid\Mod Repositories\B47ANCEDKnowledgeAndWisdom`

Exact final validation commands:

```powershell
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_versions.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/run_host_tests.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/validate_source.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_versions.py --release
```

- [TESTED: offline] Version check PASS, canonical 0.13.0 and 10 current mirrors.
  The user-approved 0.12.2 baseline passed its 9 then-existing mirrors before
  implementation. Historical records were excluded from current-version checks.
- [TESTED: offline Lua 5.1 host mocks] 15/15 test files PASS. Before changes,
  all 14 existing host test files passed under the available default Lupa runtime.
  The final runner explicitly uses Lua 5.1 and adds a frozen original-source
  upgrade fixture. No human runtime observation is inferred from harness output.
- [TESTED: offline] All 33 current/test Lua files parse under Lua 5.1. Exact-case
  local imports, source path case collisions and Lua-only runtime files pass.
- [TESTED: offline] 87 translation/fallback JSON files have matching English key
  coverage and nonempty values; current display values use the final branding.
  All 19 canonical and 19 saved-legacy script item types have ItemName coverage.
  This does not prove native loading or professional translation of all locales.
- [TESTED: offline] Workshop title, canonical text mirrors and paragraph-line
  reconstruction pass. Existing Workshop ID 3792566496 remains unchanged.
- [VERIFIED: local SHA-256] All 788 protected historical package/staging/metadata
  files match the pre-edit inventory; both source artwork PNGs match exactly.
  Retention summary: `RENAME_RETENTION_0_13_0.json`. No cleanup was performed.
- [VERIFIED: source comparison] Non-identity production changes are restricted to
  private storage constants, known old-item lookup and stable claim scope,
  and disabled historical sandbox fallback. Original redaction and rich-text
  escaping glyphs are retained. No gameplay tuning or new authority is introduced.
- [VERIFIED: gate behavior] `--release` exits nonzero as expected: no current
  release artifacts/provenance and no dedicated MP evidence. No packaging ran.

The synthetic fixture was generated from the original version's Lua source;
`tests/fixtures/PROVENANCE.json` records its source hashes. It contains no real
player data. Upgrade coverage retains knowledge, committed progression and
diminishing returns, literature/journal replay bindings, successor contention,
history storage and actor reauthentication, repeated canonical loads, saved item
lookup and sandbox false retention. Source/host checks are not native save proof.
Final source, test, tooling and metadata hashes are recorded in
`SOURCE_PROVENANCE_0_13_0.json`; this is local iteration provenance, not a release
package manifest or a substitute for a verified Git commit/push.

The top-level folder, source, tests, current docs, Workshop metadata and local
workspace project pointers use the final name. The dated repository catalog's
link was repaired while retaining its original 2026-10-12 version observations.
Other projects' consumer dependencies/imports were not changed. Original docs,
packages, cleanup/setup snapshots and private saved identifiers retain their
historical names deliberately.

[UNKNOWN] The startup freshness helper reported not a Git repository. The user
explicitly authorized this local legacy migration, canonical version baseline
and target iteration. Git branch, HEAD, upstream, public visibility, commit and
push are unavailable. **NOT BACKED UP TO GITHUB.** No remote was guessed.

[RUNTIME GATE] SP: NOT TESTED. Native scripts/translation UI, old-save mod-list
selection, old inventory items, sandbox persistence and one reading hook still
need a disposable-save check. Dedicated G7: BLOCKED / NOT TESTED. Verify server
startup, remote reading/XP authority, late join/rejoin, claim duplication/replay,
privacy, journal persistence and server restart. Stable-release G8: BLOCKED.
Historical runtime claims are not current proof. No game/server was launched;
no local deployment or Workshop publication was performed.
