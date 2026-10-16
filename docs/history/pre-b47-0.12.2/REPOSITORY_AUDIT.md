# experienceWorks repository and migration audit

2026-08-26. Source inspection, not in-game validation. This is one part of the
handoff's prerequisite audit; it does not clear the full implementation gate.

## Existing module ownership

| Source module (under the existing experienceWorks namespace) | Current responsibility | Expansion boundary |
| --- | --- | --- |
| shared/API.lua | Document/item indexes, redaction, prerequisite checks, character ledger, knowledge grants, distribution data application | Keep one canonical registry/ledger; no parallel XP totals |
| shared/ReadCompletion.lua | Delegates ISReadABook.complete, grants discrete knowledge after successful non-forced completion on authority | Preserve vanilla reading and multipliers; not persistent journal writing |
| server/Distribution.lua | OnPreDistributionMerge installs provider-declared loot entries | Providers own content/pools; no broad loot replacement |
| client/ResearchViewer.lua | Read-only redacted vanilla modal and inventory option | Presentation only; no learning or XP mutation |
| shared, client, server Load.lua | Require the canonical API and realm-owned adapters | Keep loading idempotent; never load duplicate registries/hooks |

All current Lua source files are covered by structural and focused load checks.
The first-stage test harness adds deterministic command-driven evidence and a
human-readable result export, but host mocks still do not prove native
persistence, packet routing, server execution, or UI rendering.

## Current gaps and trust boundaries

- Knowledge IDs now use an independently validated, provider-owned definition
  registry. Acquisition-policy enforcement beyond document grants remains open.
- Document/knowledge prerequisites now support composable ALL/ANY/NOT semantics;
  native skills, recipes, backgrounds and registered capabilities remain open.
- `learn` is a trusted authoritative Lua integration API. `completeRead` maps an
  item to a document; it does not independently prove pages, ownership or elapsed
  reading. The vanilla action is the current validation boundary. Neither method
  is suitable for direct exposure as an unvalidated client command.
- Learning rejects ordinary clients. Optional protected `transmitModData` is
  not evidence of verified remote/late-join synchronization.
- Provenance records document and optional time/item type; general acquisition
  provenance and server-derived timestamps need an explicit contract.
- Registry tables remain publicly mutable; registration asserts malformed input.
  Finite-number validation and nested saved-record validation need hardening.
- The semantic-action XP engine now validates committed meaningful outcomes,
  weights skills, bounds failure XP, applies diminishing returns and routes
  awards through vanilla. There is still no native recipe-grant adapter, generic
  study queue, journal item, recovery claim registry or duplication protection.

## Naming migration result (0.7.0)

| Surface | Canonical identifier | Compatibility treatment |
| --- | --- | --- |
| Public documentation | experienceWorks | Corrected everywhere |
| Repository/source roots and package filenames | experienceWorks | Corrected atomically with build tooling |
| Mod ID and consumer `require=` fields | experienceWorks | Corrected across the dependency closure |
| Lua require paths/global | experienceWorks/API, experienceWorks | One canonical registry and hook lifecycle |
| Persisted character ledger | EXPERIENCE_WORKS_KNOWLEDGE_V1 | Imports the pre-0.7.0 key once, then removes it |
| Sandbox option/page/translation keys | experienceWorks.* | Canonical key with read-only fallback for existing worlds |
| Reading wrapper marker | __experienceWorksWrapped | One canonical marker |
| Release/staging/verification/test tools | experienceWorks root and ID | Corrected and package-verified |

Source consumers include Project M.O.R.T.I.S., Project Nightfall, medWorks, and
junkWorks. Version 0.7.0 updates each consumer, rebuilds repository staging and
packages, and leaves the former identifiers only inside the private migration
module and its regression test. No separate homeWorks mod is needed.

Host tests verify the one registry/read hook and persisted-state migration.
Remaining runtime gates are migration against a real pre-0.7.0 save, saved
sandbox fallback, dependency selection, and absence of simultaneously installed
old/new packages.

## Remaining prerequisite audit

Complete perk/custom-curve and background boosts, exact raw-XP restoration,
recipe/meta-recipe/auto-learning, media enumeration and anti-repeat policy,
document-derived map knowledge, server replication and item claim persistence.
See NATIVE_XP_AUDIT.md, READING_MEDIA_AUDIT.md and RECIPES_AUDIT.md. Workshop
compatibility claims require source/runtime checks before being advertised.
