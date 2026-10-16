# Authority and persistence repairs

Version: 0.14.0. Baseline: audited 0.13.0, commit f615148. The nine audit
reproductions informed the regressions; original audit evidence is historical.
All results below are offline Lua 5.1 host evidence, not PZ runtime evidence.

| Finding | Resulting behavior | Focused regression |
| --- | --- | --- |
| Client query mutation | All queries use a non-mutating legacy-key fallback; validated authority writes alone move keys | test_query_authority.lua |
| Stale journal exhaustion | Claim and recovery planning check persistent successor/exhaustion; missing or malformed stores fail closed | test_journal_exhaustion.lua |
| Repeated acquisition conflicts | Built-in adapters retain original acquisition time; direct grant bindings remain strict | test_acquisition_replay.lua |
| Blank username fallback | Reject empty/nil/failed/invalid raw identifiers before prefixing; skip Steam 0 and negative online IDs | test_acquisition_replay.lua |
| Nested malformed claims | Validate collections, records, indexes, numeric values and cycles before dereference | test_saved_state_validation.lua |
| Destructive history attachment | Only genuinely fresh stores initialize; malformed existing stores remain untouched | test_saved_state_validation.lua |
| Missing next in Kahlua | Legacy claim-store import uses pairs, validates before merging, preserves successor conflicts and monotonic exhaustion | test_kahlua_claim_migration.lua |
| Unbounded source history | Bounded cursor cleanup expires inactive counters and preserves active/quarantined state | test_source_retention.lua |
| Realm export differences | Shared, client and server loaders include origin/media APIs | test_realm_load_graph.lua |

Saved schema remains 1. Existing storage keys, provider IDs, built-in claim IDs,
owners, full replay bindings, and old saved item types remain unchanged. The
frozen original-source 0.12.2 fixture still passes forward-upgrade tests. No
historical validation is promoted to current proof.

Queries never migrate, even on authority. Write-side migration happens only after
the stored object passes validation. `hasRead`, `snapshot`, progression snapshots
and journal snapshots can read supported legacy data without modifying it.
Unsupported/corrupt data is returned as an error rather than reset or repaired.
Operators should preserve the original save and obtain explicit review for any
manual recovery; this change provides no destructive repair or downgrade tool.
Old records already written under an empty/sentinel subject are preserved, not
silently rebound to a different identity; those need explicit native review.

`Claims.grantAcquisition` is restricted to the built-in fact adapters. It reuses
the original acquisition timestamp and still delegates all source, scope,
confidence and subject validation to strict `grant`. Revoked facts are not
silently reactivated. External direct requests keep exact full-binding conflict
behavior; do not expose either API as an unvalidated client network command.

`SurvivorJournals.recoveryPlan(item, successorId, currentXP, fraction, context)`
now requires authority plus an existing matching persistent claim. The optional
fifth argument forwards context to a registered store provider. Item-local flags
cannot override a consumed global payload. A missing/malformed store blocks the
plan. The server recovery setting caps the requested fraction; the plan is a
non-additive target and does not apply native XP. Native timed actions and exact
XP restoration remain unfinished and gated.

Source retention uses an optional schema-1 `sourceOrder` and `sourceCursor` index,
constructed once on an authority write for legacy data. Normal cleanup examines
at most 32 entries per processing attempt. Expired unquarantined
counters may be removed; active counters and unresolved awards are preserved.
Unknown legacy provider windows are retained conservatively. At 4,096 retained
sources a new source is rejected before native XP is attempted; later attempts
advance bounded cleanup. Existing larger legacy ledgers are not silently trimmed.
Committed/resolved transaction diagnostics are capped at 64; uncertain records
are not evicted. These are technical safety/work limits, not gameplay settings.

`SavedState.lua` checks nested domain shapes, dense indexes and references, finite
numbers, cycles and supported values before using persisted data. A tree depth
limit of 12 and node limit of 262,144 bound validation work. They protect technical
deserialization and remain internal. This is not a world/inventory scan or a
per-tick callback. Pending/uncertain transaction consistency fails closed instead
of inventing a successful XP award after an interrupted save.

See [configuration](CONFIGURATION.md) for gameplay candidates and existing-save
defaults. Server/SP authority reads the sandbox; a normal client cannot choose
shared rates or compute recovery/semantic award plans. No new networking or
automatic gameplay exposure was added. Existing native sync calls remain subject
to dedicated verification; a successful pcall is not replication evidence.

Public source: [GitHub](https://github.com/B47ANCE/B47ANCEDKnowledgeAndWisdom),
repair branch `fix/authority-persistence-0.14.0`. Main records the 0.13.0 baseline;
merging the repair PR is separate from committing/pushing the iteration. The
offline workflow has read-only contents permission, pins official action SHAs,
and has no deploy/publish/server/SFTP steps or credentials. Branch protection is
not implied by having a workflow. No release tag is created.

G7 dedicated MP: BLOCKED / NOT TESTED. Stable G8: BLOCKED. The user supplies
native results using [the runtime procedure](RUNTIME_VALIDATION_0_14_0.md).
