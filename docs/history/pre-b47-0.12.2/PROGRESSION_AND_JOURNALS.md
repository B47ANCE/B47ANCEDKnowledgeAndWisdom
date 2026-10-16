# experienceWorks / homeWorks requirements

Current approved design, 2026-08-26. This is a development specification, not an
implemented-feature claim. Canonical project name is **experienceWorks**.
Version 0.7.0 completed the coordinated canonical identity migration. New code
uses only the `experienceWorks` Mod ID, Lua namespace, global, sandbox page, and
saved keys. A private one-way importer preserves pre-0.7.0 persisted state.

## Ownership

- Domain mods report semantic actions and own their content and requirements.
- experienceWorks owns progression policy, semantic XP routing, anti-farming,
  diagnostics and integration with vanilla/custom perks.
- homeWorks is an internal subsystem, NOT a separate mod. It owns knowledge,
  literature, research, persistent study, provenance and Survivor Journals.
- Vanilla remains authoritative for ordinary skill XP and known recipes. No
  parallel skill totals, per-domain skills, mandatory rebalance or level-cap change.
- Knowledge and practical skill are separate requirements. Knowledge acquisition
  may be background, literature, practical or world discovery, per definition;
  classified research must not appear merely from a generic skill threshold.

## Framework requirements

Namespaced knowledge and semantic-action registries; composable ALL/ANY
requirements for knowledge, skills, recipes, documents, backgrounds and registered
capabilities. Recipe grants must use verified vanilla recipe ownership. Knowledge
provenance records source and time, without exposing hidden metadata by default.

Semantic action processing supports outcome, difficulty, restrained quality
adjustment, source category, weighted primary/secondary skills, meaningful
diminishing returns and bounded failure XP. Invalid/no-op attempts earn nothing.
Vanilla multipliers must apply exactly once. No arbitrary scattered AddXP calls.
Server validates committed actions; clients cannot submit authoritative XP totals.
Diagnostics explain applied policy without inventing unverified multiplier math.

## Physical Survivor Journal invariants

1. Journal is a physical item, not a save backup. Lost/inaccessible/destroyed
   journal means inaccessible recovery; death never auto-updates it.
2. Record supported raw perk XP including partial levels, recipes, read documents,
   media and knowledge. Never serialize the whole character, active book
   multipliers, buffs or arbitrary runtime state.
3. Recovery is target-based: `max(currentXP, documentedXP * recoveryFraction)`.
   Never additive, never lower current XP, never apply ordinary gain multipliers.
   Exact raw-XP restoration and level recalculation require native verification.
4. Default recovery is 90%, configurable 0–100%. Completed discrete knowledge is
   recovered whole, not proportionally. Media recovery must prevent double XP.
5. Explicit map-reading knowledge is distinct from explored fog-of-war. Do not
   automatically copy exploration.
6. One successor claims each recovery payload at first study. Persist the claim
   across interruptions, restarts and transfers; reject other successors and
   duplicated item payloads. Completed payload is permanently exhausted, while
   the item remains as a recovered keepsake.
7. Writing captures a fixed target and serializable deterministic work queue.
   New XP while writing belongs to the next delta, not a moving current target.
8. Every increment of writing persists on the JOURNAL, including unfinished
   updates. If 47/180 minutes were written before death, corresponding written
   information survives; never revert to the previous complete snapshot.
9. Raw XP is documented first and interpolates progressively. A 2,000→3,000 XP
   delta half written records 2,500, recoverable as 2,250 at 90%.
10. Discrete entries unlock only when completely documented, but incomplete work
    remains stored. Order after XP: magazine/flier/map/read knowledge, other
    knowledge, watched media, homeWorks knowledge, Works research.
11. Recovery study is resumable and preferably transfers information progressively.
    One-successor claiming must prevent sharing partial recovery among characters.
12. Time scales with undocumented work using bounded/level-aware/logarithmic
    costs, not fixed sessions or naive linear raw-XP costs. Daily updates should
    be shorter than catch-up documentation. No arbitrary ink/page simulation.
13. Successors may write their own new journals: 10,000→9,000→8,100 XP without
    new practice is valid generational degradation, not an exploit.

Defaults: journals enabled, recovery 90%, writing instrument required, single-use
recovery, normal write/read speed and work multiplier 1.0. Expose useful sandbox
controls without overwhelming low-level tuning. Single-successor/exhaustion
invariants are mandatory in the normal configuration.

UX: author, last update, recorded progress, knowledge count; undocumented changes
visible only to original author. Start/update/continue writing, study, and
recovered-keepsake states. Preserve the normal Project Zomboid interface.

## Audit gate and implementation order

Before new framework implementation, inspect current repositories and installed
XP overloads, perks/curves, boosts/multipliers, recipes/auto-learning, literature
partial reading, watched media, map state, timed actions, persistence and network
authority. Compare available current progression mods as compatibility evidence,
never source to copy. Javadoc or Workshop descriptions alone do not prove runtime.

Then: canonical registries/persistence → semantic XP → homeWorks knowledge →
persistent study/write → journal snapshot/delta → progressive physical writing →
one-successor recovery → authority/diagnostics/sandbox → interruption/compatibility
validation. Existing archive API remains supported during migration.

## Required test gates

- Empty, experienced, high-XP and large-knowledge authors; no-op/tiny/mixed deltas.
- New magazine, recipe, map, VHS, research and multi-day updates.
- Minute/halfway/movement/zombie/sleep/logout/restart/crash/death interruption.
- Exact 47/180 survival, interpolated XP and incomplete discrete entries.
- Recovery below/equal/above target; custom percentage; no multipliers; levels.
- Successor claim contention, resume/restart, exhaustion, cloned items,
  transfer/drop/container/ownership/serialization duplication.
- Watched-media rewatch prevention; A→B→C generations; no additive restoration.
- Server-owned snapshots, rejected malicious client totals, late join and reconnect.

No current journal or semantic-XP runtime is claimed by this specification.
