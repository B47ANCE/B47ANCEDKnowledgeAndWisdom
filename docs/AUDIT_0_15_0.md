# Source and roadmap audit — 0.15.0

2026-10-16. Baseline a8ba91c8454a0a4cac937392d227e1ba1aebcaa3 (0.14.1).
Scope: authoritative Lua/API/load paths, requirements, physical journal lifecycle,
claim-store initialization, native UI source, configuration/version mirrors and
existing offline regression coverage. This is a bounded source/offline audit,
not native gameplay, third-party compatibility or a release certification.

| Finding | Priority | Resolution / evidence |
| --- | --- | --- |
| Unknown knowledge/document beneath NOT could become allowed; ANY could hide unknown references | P1 | Preflight every reference before evaluation; invalid input fails closed. Baseline regression failed, repaired regression passes. |
| Journal capture could create/change item state before an oversized queue assertion; unsupported identifiers could be persisted | P1 | Prepare complete candidate/queue, validate schema, then commit in place. Clean false result preserves blank/existing/legacy data. Baseline queue regression failed. |
| Rejected advance/cancel/claim/exhaust requests could migrate legacy item keys | P2 | Migration follows validation. Added regression failed before this fix and passes afterward. |
| Malformed legacy claim table could initialize an empty canonical store before refusal | P2 | Validate old table before getOrCreate. Regression failed before fix. |
| Active journal operation ID accepted a different capture | P2 | Active duplicate must match the normalized fixed target. No change to completed-operation history or schema. |
| Native modal auto-height uses full screen rather than player viewport | P2 | Shared client inspection window bounds its own instance, including scroll/button layout; modeled split-screen regression passes. Native visual/input proof pending. |
| Five current-document headings escaped version checks and had stale versions | P2 | Synchronize current headings and expand the existing checker to 17 mirrors. Historical named reports remain unchanged. |

[VERIFIED: installed source] Steam appmanifest build 25485521. Full engine
version UNKNOWN. ISModalRichText constructor/update inspected; portable fingerprint
and observed signature are in API_INSPECTION_0_15_0.json and the local API draft.
ISInventoryPane.getActualItems is a Lua table projection in current client source.
ISReadABook.complete has shared server-aware completion logic; its hook delegates
vanilla work and rejects ordinary client writes. These observations do not prove
native hook order, recipients or reconnect behavior.

[TESTED: offline] Requirement validation also rejects sparse arrays, unknown
fields, cycles, depth >16 and >512 nodes. These technical input bounds are internal,
not sandbox settings. Removed-provider references now deny rather than becoming
false facts that negation could invert. Public validateRequirement normalizes
structure; evaluateRequirement/canLearn additionally preflight registered references.
Document registration still permits forward document references; evaluation denies
until their definitions exist.

[TESTED: offline] Journal projection does not access the authority claim store,
initialize/migrate ModData, grant XP/knowledge, claim or exhaust. It returns counts,
local status and progress, excluding account/payload identifiers, entry IDs and
unwritten target details. A local claimed/exhausted flag is not authoritative
recovery eligibility. Missing/corrupt/unsupported journals receive no menu action.
Only recorded payloads are inspected; no new physical item or loot pool is added.
Existing test journals are debug fixtures, not normal production distribution.

Open dependency gates:

- [RUNTIME GATE] Character/item ModData replication, recipient privacy, server
  completion hook order, late join/reconnect/restart and old native saves remain
  unverified. No client mutation or invented networking substitutes for proof.
- [RUNTIME GATE] Exact raw-XP restoration remains blocked by the historical
  Strength/Fitness findings. Current native exposure/policy must be established;
  this iteration does not re-audit or implement an XP setter.
- [UNKNOWN] Native authoritative capture/writing actions, instrument ownership,
  elapsed-time validation and interruption/death/logout contracts need a bounded
  API/authority slice. Recipe/meta-recipe/media restoration remain separate gates.
- [UNKNOWN] Provider-owned archive/region content and external uiWorks/history
  consumers require their own contracts; no unrelated repository was changed.
- [RUNTIME GATE] Native journal/research visuals, scrolling, UI scale, keyboard and
  controller operation require user observations. English fallback coverage is
  not human translation validation.
- Existing mutable public registries and acquisition-policy trust are provider
  contracts, not permission to expose client-selected rewards or facts.

See MASTER_ROADMAP.md for dependency order and JOURNAL_INSPECTION.md for tests.
G7 dedicated BLOCKED / NOT TESTED. Stable G8 BLOCKED. No package, deployment,
publication, game/server launch or stable tag.
