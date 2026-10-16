# Server sandbox configuration

All options use the stable `B47ANCEDKnowledgeAndWisdom` page and namespace.
Gameplay options are integers with step 1, grouped on the same mod page. Names
and tooltips have English/fallback entries in the project's 29 language folders;
this is fallback coverage, not a claim of 29 human translations. Native UI
rendering and server configuration transport remain runtime gates.

| Identifier | Default | Bounds | Interpretation |
| --- | --- | --- | --- |
| EnableResearchViewer | true | boolean | Existing local read-only research presentation |
| SemanticXPPercent | 100 | 0–1000 | Percent of provider semantic XP; 0 disables awards |
| RepeatWindowPercent | 100 | 25–400 | Percent of each provider's repeat window |
| RepeatDecayPercent | 100 | 0–400 | Percent of provider decay; 0 removes the penalty |
| RepeatFloorPercent | 100 | 0–400 | Percent of provider minimum credit, capped at full credit |
| JournalRecoveryPercent | 90 | 0–100 | Maximum percent of documented raw XP in a recovery target |
| JournalWritingSpeedPercent | 100 | 10–1000 | Percent of server-validated writing work per elapsed minute |
| FailureXPCapPercent | 10 | 0–10 | Failure-credit cap as a percent of provider base XP, before bounded modifiers |

`Config.gameplay()` reads only on authority. Missing fields on old worlds use
the defaults above. Non-numeric, NaN and infinite settings fall back to defaults;
numeric settings clamp to declared bounds and floor to an integer. A normal
client receives a non-authority error, not a client-chosen gameplay snapshot.
No user-edited Lua table or client preference substitutes for server settings.

Defaults retain provider semantic/repeat rates and existing writing speed. The
old implicit journal recovery default remains 90%, now a server maximum: an
explicit caller fraction above it is capped; a provider can request less.
Changing settings does not reset saved XP, knowledge, claims or histories. New
calculations use the current server policy. Removed expired counters cannot be
reconstructed if a window is lengthened later. Active/uncertain history remains
protected; old unknown-provider windows are retained conservatively.

The viewer's legacy false fallback remains local presentation policy: a saved
false under either historical namespace prevents a new default true from
re-enabling it. See [migration](IDENTITY_MIGRATION.md) before intentionally
re-enabling a migrated world.

Configuration candidates were assessed explicitly. Global rates, repeat policy,
failure credit and journal recovery/writing affect meaningful server gameplay
and are exposed. Provider definitions still own content-specific base XP, skill
weights and outcomes. Difficulty/quality clamps, queue capacity, validation
limits, retention capacity/work budget, protocol keys and UI coordinates are
technical/internal constraints, not separate sandbox micro-settings.

These controls configure existing server APIs. They do not implement unfinished
native journal actions or XP restoration, nor prove remote synchronization.
G7/G8 remain BLOCKED pending the required evidence.
