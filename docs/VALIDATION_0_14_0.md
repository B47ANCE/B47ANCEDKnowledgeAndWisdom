# Repair validation

Version: 0.14.0
Date: 2026-10-16. Offline Windows Lua 5.1 host evidence only.
Public repository: https://github.com/B47ANCE/B47ANCEDKnowledgeAndWisdom
Branch: `fix/authority-persistence-0.14.0`. Baseline commit: `f615148`.

The two P1 regressions were run against the baseline first and both FAILED:
client query moved saved keys; a stale clone yielded an exhausted recovery plan.
They PASS after repair. Subsequent replay, saved-state, Kahlua, retention and
realm regressions also failed before their corresponding repairs and now pass.
All changes are independent Lua-only implementation in the authoritative source.

[TESTED: offline] Final suite: 22/22 test files PASS. Includes the frozen original
0.12.2 upgrade fixture; non-mutating client/authority queries; validated writes;
stale copies, missing stores and reloads; original acquisition preservation and
strict direct replay conflicts; identity fallbacks; malformed collections,
cycles and future schemas; migration with next/table.unpack absent; 1,500 expired
sources; active capacity rejection before XP; quarantine retention; sandbox
bounds/defaults/client refusal; reading, viewer, claims, history and load graphs.

[TESTED: offline] 42 current/test Lua files parse under Lua 5.1. Exact-case local
imports, collision checks, Lua-only current source, 87 translation/fallback JSON
files, all 38 current/legacy item types, Workshop paragraph/text mirrors and the
seven declared sandbox/server bound sets pass. Native Linux/server execution is
not implied by path-case checks or Linux CI. Version mirrors are checked by the
current script; named 0.13.0 reports/manifests are historical baseline evidence.

Exact validation commands from the project root:

```powershell
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_versions.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/run_host_tests.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/validate_source.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/check_public_tree.py --staged
git diff --check
```

The host runner accepts `--test <filename>` for targeted reproduction. GitHub CI
installs pinned `lupa==2.6` on Python 3.12 and runs the same offline gates using
pinned official action SHAs and read-only contents permission. CI result and
exact pushed SHA are verified with the iteration's PR; this source document
does not turn an unobserved workflow into a PASS or bind its own commit hash.
`check_versions.py --release` remains an explicit G8 blocker: no current release
package/provenance or dedicated evidence has been provided. No packaging runs.

[VERIFIED: bounded installed-source inspection] Steam build 25485521; full engine
version UNKNOWN. `versionMin=42.20.3` is metadata, not detected runtime version.
Vanilla shared `Sandbox/SandboxVars.lua` invokes sandbox initialization; SHA-256
`9c79a0d000afd347c34fdd4be84ed85f0abb0069959ef0735be731c211681ec0`.
Packaged CustomSandboxOptions metadata includes integer/type/boolean tokens;
class SHA-256 `80d7d66b1bd7dda3877fa2edca2b136442208c4edc9f178e210130feaf0c4166`.
Metadata/source inspection does not prove native parser, UI or network behavior.
No Java class was loaded/executed and no Java runtime dependency was introduced.

Public-tree checks are a credential/artifact heuristic plus manual staged diff
review, not a universal secret guarantee. Historical package/staging/artwork
protection is rechecked separately; generated archives and raw diagnostics are
not staged. Existing release packages are neither rebuilt nor relabeled.
SOURCE_PROVENANCE_0_14_0.json uses canonical LF text (per .gitattributes) and exact
PNG bytes so Windows/CI checkouts can verify the same content. The public-tree
gate validates those hashes. Earlier 0.13.0 host byte fingerprints remain
historical and are not relabeled as normalized checkout hashes.

[RUNTIME GATE] SP NOT TESTED. Dedicated G7 BLOCKED / NOT TESTED. Stable G8 BLOCKED.
The user will supply observations using RUNTIME_VALIDATION_0_14_0.md. Native
journal timed actions/raw-XP restoration and a reviewed dedicated authority-side
driver remain unavailable. Server-ledger replication, privacy, late join,
reconnect, restart and native old-save behavior are not proven by these tests.
No game/server launch, deployment, Workshop publication or release tag.
