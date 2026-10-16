# B47ANCED Knowledge & Wisdom Master Roadmap

Canonical version: 0.14.1. This file consolidates current feature status; detailed
contracts and evidence remain in the other documents in this directory.

## Implemented

- Provider-owned Project Archive registry with tiers, categories, references,
  prerequisites, spawn metadata, canonical/redacted rendering, and bounded loot.
- Server-authoritative per-character document and knowledge ledger, idempotent
  unlocks, protected queries, ownership provenance, and future-save quarantine.
- Build 42 read-completion adapter and vanilla research viewer/read model.
- Namespaced knowledge definitions and composable ALL/ANY/NOT requirements.
- Semantic-action progression registry with weighted skills, meaningful-commit
  validation, bounded failure XP, diminishing returns, native XP, and quarantine.
- Survivor Journal persistence core: fixed capture targets, progressive writing,
  discrete entries, physical persistence, claims, clone rejection, recovery
  plans, and exhausted keepsakes.
- Canonical `B47ANCEDKnowledgeAndWisdom` identity and one-way legacy-state migration.
- In-game test fixtures, commands, save/reload gates, history, and report export.
- Versioned literature/media/journal/recovery/geography/history claim registry
  and per-character ledger with bounded provenance, explicit revocation,
  complete-request replay binding, registered geographic scope, and document-read
  production. Legacy operation evidence without a binding fails closed.
- Provider-validated persistent survivor-history records with author, subject,
  evidence, bounded content, visibility, timestamps, replay history, and
  permission-checked tombstone removal. Create and removal operation IDs bind
  the complete semantic request, and replay callers are re-authenticated.
- Bounded read-only recorded-media projection over stable media/line identity
  and native known-line state, with explicit spoiler/title policy and no reward
  execution or parallel completion database.
- Bounded explicit origin-provider observations and authority-owned conversion
  into replay-bound registered-locality hometown claims.

## Still to add

- Additional first-party restricted science, military, and government archives.
- Recipe and contextual-action knowledge consumers.
- uiWorks knowledge inspection/presentation adapters.
- Survivor Journal native timed writing/recovery UI and exact raw-XP application
  after an engine-safe policy is proven.
- EXT-25 uiWorks media-badge presentation and native media/journal/recovery validation.
- EXT-26 verified native origin mapping and approved first-party region catalog;
  arbitrary map/world-state discovery remains prohibited.
- EXT-32 optional first-party world presentation and MORTIS/Nightfall provenance
  consumers over the implemented neutral history-record core.

## Validation and release gates

- Verify native meta-recipe, auto-learning, exact-XP, and replication behavior.
- Validate dossier visuals, localization, keyboard/controller interaction,
  character death, late join, save migration, hosted, and dedicated servers.

## Excluded

- The misspelled `experianceWorks` identity is migration input only, never a
  parallel public API or mod.

## 0.14.0 repair status

Authority/query separation, persistent exhaustion, replay identity, nested save
validation, Kahlua-compatible legacy claims, bounded source retention, complete
realm exports and server sandbox controls have offline regressions. Public
source onboarding/CI is separate from native evidence. Follow
REPAIRS_0_14_0.md and RUNTIME_VALIDATION_0_14_0.md. Native journal action/restoration,
server synchronization and dedicated validation remain gated; G7/G8 BLOCKED.
