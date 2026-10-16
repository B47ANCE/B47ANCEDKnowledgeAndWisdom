# B47ANCED Knowledge & Wisdom Testing

Current 0.15.0 offline results and native gates: [validation](VALIDATION_0_15_0.md).
The version-specific descriptions below are inherited test history; original
pre-rename records remain under `history/pre-b47-0.12.2/`.

Version 0.8.0 host tests cover archive/knowledge persistence, semantic
progression, reading completion, the redacted viewer, Survivor Journals, and the
canonical production load graph. The load regression verifies that the canonical
API owns one hook lifecycle and that normal startup installs the registered-
document completion hook. The identity regression verifies one-way migration of
pre-0.7.0 saved ledgers and journal state.
The realm load-graph regression separately executes the client and server entry
files with isolated module stubs. This prevents shared-first host resolution
from concealing a missing client/server initialization edge and asserts the
client-only research viewer and server-only distribution injector separately.
Run `python scripts/run_host_tests.py`, `python scripts/check_versions.py`, and
`python scripts/validate_source.py`. The earlier workspace Works tools are not
present in this checkout and are not current validation entry points.

The client test harness is covered for deterministic fixture registration,
idempotent item grants, knowledge/prerequisite transitions, one-shot native XP
observation, partial physical-journal state, runtime-reload evidence, bounded
command history, and `getFileWriter` report output. See [IN_GAME_TESTING.md](IN_GAME_TESTING.md)
for the human gate; mocked execution is not an in-game PASS.

The Survivor Journal host test verifies fixed targets, deterministic bounded
queues, exact partial-XP interpolation, delayed discrete entries, item-state
survival across module reload, authority rejection, non-additive recovery,
single-successor contention, cloned payload rejection, and exhaustion.

In game, still verify item ModData across inventory/container/drop/save/reload,
GlobalModData claim persistence, late join and reconnect. Do not expose recovery
as working gameplay until a multiplier-free raw-XP setter and correct vanilla
level recalculation are proven. Timed-action cancellation, death during writing,
controller UI, and hosted/dedicated authority remain release gates.

Version 0.10.1 adds regressions for operation-ID collisions across source,
scope, confidence, and revocation reason; immutable duplicate-claim conflicts;
and fail-closed handling of legacy replay records without a full request binding.

Version 0.10.2 extends that boundary to survivor-history create and removal
operations. Tests cover normalized-content and removal-reason collisions,
re-authentication of replay callers, and fail-closed legacy history operations.

Version 0.11.0 verifies recorded-media identity, unseen/partial/complete
projection, explicit title visibility, line-count bounds, duplicate-GUID
rejection, and zero mutation of native known-media state. Installed Build
42.20.3 Lua/JAR inspection confirms the invoked methods; live media playback,
localization, save/reload, and multiplayer visibility remain native gates.

Version 0.12.0 verifies deterministic origin-provider selection, registered
locality enforcement, bounded confidence, canonical source ownership, and
authority-owned hometown claim construction. No native origin mapping or region
catalog is claimed.

For 0.14.0 authority, stale-copy, reconnect/restart and sandbox checks, use
[the native test procedure](RUNTIME_VALIDATION_0_14_0.md). Do not use old session results as current proof.

0.15.0 adds test_requirement_safety.lua, test_journal_write_atomicity.lua and
test_journal_viewer.lua. These cover invalid references under negation, malformed
requirement graphs, atomic rejection/migration, bound active writing captures,
client projection privacy, corrupt items, localization escaping and a modeled
split-screen/controller modal lifecycle. They are offline simulations.
