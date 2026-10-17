# Remaining audit dispositions — 0.16.0

Baseline: ca5b724c63d49ab224f96b2daea3e17ad7498e44. Date: 2026-10-16.
The selected source/offline audit is complete. That means each area below has a
source-backed conclusion or an explicit implementation/runtime blocker. It does
not mean the feature roadmap, private migration, SP/dedicated validation or release
is complete. Native results remain NOT TESTED.

| Area | Source/offline disposition | Current action / remaining gate |
| --- | --- | --- |
| Character authority/privacy | Player ModData is broadcast to relative clients and can be replaced through the inspected object packet route | P1: broadcasts removed; server character-ledger reads/writes refuse. Private backend and verified identity required. |
| Global history/claim storage | GlobalModData.receiveRequest returns named tables without provider visibility filtering | P1: affected MP store initialization/CRUD blocked. Existing native stores are preserved and remain exposed by the engine until a reviewed private migration; the guard does not sanitize them. |
| Physical journal authority | InventoryItem lacks the assumed transmitter; syncItemModData sends full payload to relative clients, including unwritten targets | MP mutation/recovery plans blocked. Need private target/payload anchor and documented-data projection; read-only inspection is not authenticity proof. |
| Lifetime/reconnect identity | Username/SteamID identify accounts, online ID identifies sessions; none is established as a verified life identifier | Claims.subjectId compatibility is retained. Do not use it as a new journal lifetime key. No automatic identity migration. |
| Native XP and levels | Full AddXP can silently refuse or apply passive-skill adjustments; threshold setter loses fractional progress | Exact restoration remains disabled. SP semantic awards require observed XP increase; partial/silent refusal is quarantined without automatic replay. |
| Semantic transaction callbacks | Native callbacks could observe an invalid pending graph/reenter the same source; extreme weight sums could become zero weights | Pending source quarantine now precedes native calls; overflow/sentinels/unobservable XP rejected; planned and observed XP are distinct. |
| Saved knowledge/registries | Invalid timestamps, source types, missing grants, sparse lists or infinite loot weights could poison state or omit requirements | Schema-valid candidate committed only after validation; malformed input returns failure without initialization. Read-completion context is copied. |
| Claims/history requests | Empty acquisition, unbounded bound fields or unsupported evidence could poison subsequent ledger reads | Bounded finite/scalar validation before mutation; prior data preserved. Direct replay bindings remain strict. |
| Media identity/ownership | Truncated GUIDs could query a different known line; native membership and save/load differ from reward/grant logic | Exact bounded IDs retained or rejected; no media rewards/restore path added. |
| Recipe/meta/auto-learning | Explicit learned list differs from visibility/debug/craftability; meta and skill-derived expansion are distinct | Source audit completed. Native recipe restoration and transport remain implementation/runtime gates; no recipe enumeration is treated as earned knowledge. |
| Reading/timed actions | Shared native reading dependency is now explicitly required; engine calls serverStart/serverStop/complete and uses server time | Dependency regression fixed. Client update is not incremental authority work. No writing action invented from raw duration; headless execution still needs runtime proof. |
| Journal consistency | Queue totals/duplicate identities/targets were not cross-validated; malformed recovery IDs/XP inputs could poison or mis-plan | Reject inconsistent saved state without repair; strict recovery IDs/context/current-XP checks. Old source fixture remains covered. |
| UI, localization and loader | Client-only inspector remains read-only; relevant loader exports and English fallback keys checked | Visual/controller/scale/native old-save tests remain required. No UI test is called an MP pass. |
| Content and provider integrations | Framework owns neutral APIs; native origin mapping/approved region catalog and external consumer contracts are absent | Explicit feature dependencies, not guessed APIs or copied lore. No third-party or consumer source was changed. |
| Current source/version/security/CI | Lua-only source, exact-case imports, text mirrors, source hashes and public inventory checked | No current release package. Offline CI cannot clear runtime or authority gates. |

Regression evidence: requirement/queue issues from 0.15.0 remain fixed. New MP
storage, silent-XP, invalid knowledge/acquisition/media identity, journal-work and
native reading-dependency tests failed before their fixes. The history evidence
case was reproduced with the exact old Git module in an isolated Lua VM, then
passes against current source. Other boundary assertions broaden those cases;
not every assertion is claimed as an independently observed baseline failure.

SP-oriented core tests now explicitly use an SP role; dedicated refusal is a
separate test. No old server/mock result has been relabeled as dedicated success.
The original 0.12.2 fixture and immutable storage/replay keys are retained.

NATIVE_EVIDENCE_0_16_0.json fingerprints 27 selected classes and 13 observations.
Packaged Core reports 42.21; the Steam manifest says build 25485521. Differing
loose character classes and changed JAR hashes invalidate blind reuse of older
native reports. Effective running version/class selection is UNKNOWN. No game
classes were executed; raw decompiler output/tooling stays outside the repository.

Unresolved P1 implementation work is in MP_AUTHORITY_PLAN.md. The guard stops new
unsafe operations; it is not the private backend and cannot conceal old native
GlobalModData tables. This source is not a functional MP test build. G7 BLOCKED
(implementation + runtime); stable G8 BLOCKED. No package, deploy, upload, launch,
merge or tag. No audit artifact authorizes any of those actions.

Technical limits are not gameplay tuning: new definition IDs/registration lists
are bounded, semantic actions cap their skill fan-out at 64, and claim scope arrays
must be dense. Old stored keys are preserved under their existing schema bounds.
Co-installed trusted Lua providers can still mutate public registries; this is
not an isolation sandbox against server-installed code. API grant validation
prevents missing/malformed grant definitions from silently poisoning saved data.

Missing, failing or non-boolean realm functions now yield REALM_UNAVAILABLE;
they never imply SP authority. Host tests explicitly initialize SP role stubs
before individual tests select server/client roles. No result is a native role check.

The development harness is explicitly SP-gated before session creation/reset/item
grants. Its whole-character broadcast was removed too. Debug mode is not authority
and does not create an MP bypass. The dedicated opt-in probe remains read-only.
