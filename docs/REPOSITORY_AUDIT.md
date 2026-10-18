# B47ANCED Knowledge & Wisdom repository audit

2026-10-16. Current version: 0.17.0. Source inspection and offline tests only.
The original 2026-08-26 audit remains under `history/pre-b47-0.12.2/` and is
historical evidence; its identifiers/test claims are not renamed proof.

| Surface | Current identity or ownership |
| --- | --- |
| Display name | B47ANCED Knowledge & Wisdom |
| Mod ID / Lua global / imports / sandbox page | B47ANCEDKnowledgeAndWisdom |
| Authoritative runtime | src/B47ANCEDKnowledgeAndWisdom/42 |
| Canonical project version | Root VERSION, checked by scripts/check_versions.py |
| Existing Workshop item | 3792566496, unchanged; no upload performed |
| Historical package/staging roots | Contents/ and dist/, preserved byte-for-byte |
| Saved storage and built-in claim replay identity | Immutable historical keys isolated in LegacyMigration.lua |
| Saved inventory | Nineteen old item types retained beside nineteen canonical types |
| Git | Public B47ANCE/B47ANCEDKnowledgeAndWisdom; repair branch fix/authority-persistence-0.14.0; main baseline f615148 |

The shared API owns registries and character ledgers. ReadCompletion delegates
vanilla reading and rejects ordinary client learning. Progression routes XP to
vanilla; SurvivorJournals owns item documentation and GlobalModData successor
locks; Claims owns bounded character claims and replay checks. HistoryRecords
and server HistoryServer retain provider validation, actor reauthentication,
visibility rules, world persistence and operation replay. ResearchViewer is
local read-only presentation. These boundaries were preserved during renaming.
No new networking or gameplay tuning was introduced. Provider content remains
provider-owned; dependent repositories were not modified.

The nine source/host defects from the prior audit are addressed by the current
[repair contract](REPAIRS_0_14_0.md) and focused regressions. This does not upgrade
any native/runtime claim. Server rates are described in [configuration](CONFIGURATION.md).

See [upgrade contract](IDENTITY_MIGRATION.md), [version/package inventory](VERSION_POLICY.md),
and [current offline evidence and runtime blockers](VALIDATION_0_16_0.md).
Inherited acquisition-policy and mutable-public-registry concerns remain design
limitations; the rename makes no new security or native synchronization claims.
Native journal timed actions/raw-XP restoration, old-save selection, join/rejoin,
replication and dedicated restart persistence remain [RUNTIME GATE]. G7 dedicated
multiplayer is BLOCKED / NOT TESTED; stable G8 is BLOCKED.

The current 0.15.0 follow-up is in AUDIT_0_15_0.md: prerequisite validation and
journal write safety fixes plus local journal presentation. The preceding
ownership inventory does not establish native privacy/replication or authorize
provider content changes. The 0.14.x validation/manifests retain their old hashes.

The current audit conclusion supersedes earlier native-authority assumptions:
see AUDIT_CLOSURE_0_16_0.md and NATIVE_AUDIT_0_16_0.md. Player ModData broadcasts and
replacement, GlobalModData disclosure and silent native XP refusals are concrete
source findings. Affected MP APIs now fail closed; no private-backend capability
is inferred from server-side execution. SP-oriented cores retain regression coverage.

## Current dedicated knowledge contract

0.17.0 implements document/knowledge only using private server storage, life generations and owning-client projections. See [DEDICATED_KNOWLEDGE.md](DEDICATED_KNOWLEDGE.md). The earlier blanket refusal is historical for that subsystem; progression, claims, journals/recovery, XP and history retain independent guards. Existing-world private migration is not implemented; no untrusted native table is imported. First native tests use fresh disposable dedicated worlds/two clients. SP is optional, never a prerequisite. Native G7 and stable G8 remain BLOCKED. CAT integration is dropped; old item declarations/aliases remain inert saved-item compatibility only.
