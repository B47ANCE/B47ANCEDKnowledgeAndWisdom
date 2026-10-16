# B47ANCED Knowledge & Wisdom Roadmap

> Consolidated status: [MASTER_ROADMAP.md](MASTER_ROADMAP.md).

## Implemented

- provider-owned Project Archive document registry;
- canonical/redacted rendering;
- tiers, categories, references, prerequisites, and spawn-category metadata;
- server-authoritative per-character document and knowledge ledger;
- idempotent unlocks and public knowledge queries.
- Build 42 literature read-completion adapter;
- bounded, idempotent restricted-loot-pool injection.
- read-only knowledge queries and fail-closed preservation of malformed/future save ledgers;
- reading-hook regression tests covering cancellation, delayed loading and callback isolation.
- read-only, redacted research view model and sandbox-controlled vanilla inventory viewer (host-tested; visual validation pending).
- namespaced, provider-owned knowledge-definition registry with protected queries;
- composable ALL/ANY/NOT document and knowledge requirements, with legacy
  prerequisite lists normalized through the same evaluator;
- first-party definition ownership for Project Nightfall, Project M.O.R.T.I.S.,
  and medWorks knowledge grants, including owner provenance in new ledger entries.
- provider-owned semantic-action registry and authoritative processing with
  normalized weighted skills, committed/meaningful validation, bounded failure
  XP, source-aware diminishing returns, native XP routing, and quarantine.
- Survivor Journal core with fixed capture targets, deterministic bounded work
  queues, progressive raw-XP interpolation, all-or-none discrete entries,
  physical-item persistence, authority checks, persistent single-successor
  claims, clone rejection, non-additive recovery plans, and exhausted keepsakes.
- first-stage in-game validation harness with deterministic non-distributed
  research/journal fixtures, feature-specific commands, one-shot semantic-XP
  evidence, save/reload gating, bounded command history, and automatic report
  export to the normal Project Zomboid user-data area.
- bounded recorded-media knowledge projection using native stable media/line
  identity, per-character known-line state, and explicit title-reveal policy;
  it does not inspect reward codes, grant XP, or create parallel completion state.
- bounded explicit origin-provider observations that can grant only registered
  locality claims through the canonical authoritative claim ledger.

## Next

- [Repository ownership and migration audit](REPOSITORY_AUDIT.md) inventories
  existing modules and separates public branding from compatibility identifiers.
  [Recipe audit](RECIPES_AUDIT.md) records installed learned-state semantics;
  native meta-recipe, auto-learning and replication verification remains open.
- [x] Complete the coordinated 0.7.0 identity migration: canonical
  `B47ANCEDKnowledgeAndWisdom` Mod ID, source/Lua/sandbox namespaces and public global,
  plus one-way import of pre-0.7.0 persisted state.
- [Survivor Journal runtime audit](SURVIVOR_JOURNAL_RUNTIME_AUDIT.md) verified
  that Build 42.20's multiplier-disabled `AddXP` overload still applies
  Strength nutrition modifiers and can reject Fitness XP, while
  `setXPToLevel` cannot preserve arbitrary raw XP. Native recovery timed-action
  and UI commit adapters therefore remain blocked on an exact-XP policy or a
  verified engine surface; the core deliberately fails closed instead of
  guessing this API.

- in-game dossier visual/controller validation and localization;
- additional restricted science, military, and government providers;
- recipe and contextual-action knowledge consumers;
- knowledge inspection UI through uiWorks;
- hosted and dedicated multiplayer validation;
- character-death and late-join policy validation.
