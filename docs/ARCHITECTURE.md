# B47ANCED Knowledge & Wisdom Architecture

B47ANCEDKnowledgeAndWisdom owns reusable lore and survivor-knowledge infrastructure. It
does not own Project M.O.R.T.I.S. infected science, Project Nightfall secrets,
medWorks medical content, or the effects those providers unlock.

The knowledge subsystem and progression expansion are specified in
[PROGRESSION_AND_JOURNALS.md](PROGRESSION_AND_JOURNALS.md). Version 0.13.0 uses
`B47ANCEDKnowledgeAndWisdom` as the sole public Mod ID, Lua namespace, sandbox namespace,
and global. A private compatibility module keeps established storage keys and
claim replay identities, imports older misspelled storage, and recognizes saved
item types without retaining a duplicate public Lua runtime. This document
describes the implemented archive and host-tested journal
and semantic-XP cores; native journal actions and raw-XP restoration remain gated.

The Project Archive stores canonical unredacted content as ordered segments.
Segments explicitly marked redacted render as a supplied short marker unless a
developer view requests canonical text. Redactions therefore conceal known
information rather than decorative random bars.

SP-oriented knowledge is stored in character ModData. Learning is prerequisite-
aware and idempotent. No whole-character ModData broadcasts are made. Native
player ModData is client-replaceable and cannot authorize server gameplay; native
GlobalModData is request-readable and cannot store private history. In 0.16.0,
affected MP APIs fail closed rather than trust those transports. A private server
backend, character-lifetime identity and reviewed migration are required before
MP gameplay can be enabled. Duplicate SP files do not grant progression again.

Tier-four black files declare no procedural spawn categories. Content providers
may curate their placement later. Registered physical files use Build 42's
`base:literature` item type. The read-completion wrapper delegates to vanilla
first, then grants knowledge only on canonical authority. Restricted procedural
distribution injection touches only provider-declared pools and is idempotent.

## Save/query contract (0.1.1)

`hasRead`, `hasKnowledge`, `canLearn`, and `snapshot` never initialize or repair
the stored ledger. Missing ledgers behave as empty knowledge; only a successful
authoritative `learn` persists a new ledger. Malformed roots/collections or an
unknown schema version fail closed and remain untouched. `snapshot` returns
`nil, error` for unreadable data rather than hiding corruption behind an empty
snapshot. Callers must handle that result.

The read hook excludes `forceStopped` actions even when vanilla returns true.
It preserves vanilla's result and isolates both provider and diagnostic errors.
Host tests exercise delayed class availability at OnGameBoot, repeated hook
installation, cancellation, ordinary books, client authority and callback errors.
These mocks do not establish dedicated-server load order or replication.

Version 0.6.1 made that wrapper part of the canonical production load contract.
`B47ANCEDKnowledgeAndWisdom/Load` initializes progression, Survivor Journals, and read
completion through one cached module lifecycle. A production-entry regression prevents a directly tested
feature from being omitted by the public bootstrap.
The realm-specific compatibility loaders request the same three components; they
cannot silently expose a smaller API when realm path precedence differs from the
host-test search order. The client loader additionally owns presentation startup
for the research viewer; the server loader owns restricted-document distribution.

## Research presentation (0.2.0)

`getDocumentView(character, item)` returns display metadata, redacted text and
knowledge/prerequisite status without canonical hidden segments. It performs no
learning. Presentation providers such as uiWorks may consume this model without
owning knowledge state.

The client `ResearchViewer` supplies a standalone vanilla `ISModalRichText`
fallback. Select one registered physical document and choose **Inspect Research
File**. Text is escaped before passing it to PZ's rich-text renderer. Unknown
items and malformed selections do not break the inventory menu. The sandbox
setting `B47ANCEDKnowledgeAndWisdom.EnableResearchViewer` defaults on; disabling it removes
the inspection option without affecting normal reading or existing knowledge.

The normal timed Read action remains the only reading-based unlock path.
Inspection is not a shortcut for learning or a canonical-text developer view.
Host tests cover redaction, markup escaping, selection isolation, read-only
behavior and window creation/replacement using UI stubs. In-game fonts, scaling,
scrolling, split-screen and controller focus still require visual validation.

## Progressive validation harness (0.8.0)

The client-only harness registers non-distributed test fixtures on explicit
command use, records its session in character ModData, and writes a bounded
human-readable report through `getFileWriter`. Deterministic checks may record
their own results; rendering, sandbox presentation, old-save migration, and
multiplayer remain human-confirmed. A runtime token prevents the journal command
from claiming a save/reload PASS in the same Lua session.

## Knowledge and requirement contract (0.3.0)

Knowledge is declared before use with `registerKnowledge`. Each definition has
a namespaced ID, an explicit content owner, and a player-facing title. Document
registration rejects unknown prerequisite or granted knowledge, turning typos
and undeclared cross-mod coupling into load-time diagnostics. Registry queries
return copies so consumers cannot mutate canonical definitions.

New document definitions may provide a recursive `requirements` expression with
exactly one operator per node: `all`, `any`, `not`, `knowledge`, or `document`.
ALL and ANY require non-empty arrays. The legacy `prerequisiteDocuments` and
`prerequisiteKnowledge` arrays remain supported and are normalized as ALL
conditions alongside any new expression. `validateRequirement` and
`evaluateRequirement` expose the same fail-closed contract to contextual-action
consumers. New knowledge ledger records retain the definition owner as
provenance; the schema remains version 1 and older records stay valid.

## Semantic progression contract (0.4.0)

`registerSemanticAction` accepts a namespaced provider-owned action, finite base
XP, weighted skills, bounded outcome multipliers, and a repeat policy. Weights
are normalized centrally. Processing rejects clients, unknown perks,
no-op/uncommitted reports, invalid outcomes, and unavailable native award
surfaces. Difficulty is clamped to 0.25–4, quality to 0–1 with a restrained
0.75–1.25 factor, and failure credit to at most 10% before those factors.

Awards use the verified global `addXp(character, perk, amount)` route so vanilla
owns skill state, routing, and multipliers exactly once; no parallel XP total is
stored. Multi-skill awards are preflighted. If a later award throws, the source
is quarantined against retries and authority may close the ambiguity with
`resolveSemanticTransaction(..., "accept-uncertain")` without guessing or
rolling back XP. Committed transaction history is capped at 64; unresolved
records remain available for diagnosis.

## Survivor Journal core (0.5.0)

`SurvivorJournals.lua` stores canonical journal state on the physical item's
ModData. Starting an update freezes a serializable target and builds a bounded,
deterministically ordered queue. Raw perk XP is written first and interpolated
after every work increment; discrete document, recipe, map, media, knowledge,
and research entries become recoverable only when their individual work entry
finishes. Cancellation discards only unwritten targets and preserves all work
already committed to the item.

Payload claims use a persistent server-owned claim store keyed by stable payload
ID. This prevents two successors—or duplicated item payloads—from sharing one
recovery. Recovery planning uses `max(currentXP, documentedXP * fraction)` and
therefore cannot add XP or lower an existing skill. Completing recovery exhausts
the payload but leaves the journal as a keepsake.

The module exposes no guessed raw-XP mutation. A native timed-action/UI adapter
and multiplier-free XP setter remain in-game verification gates. Until they are
verified, the core can safely persist and calculate recovery but will not claim
that character XP has been restored.

## Claim replay integrity (0.10.1)

Claim and revocation operation history binds the complete normalized request,
including source, scope, acquisition, confidence, completeness, timestamp, and
revocation reason. Reusing an operation ID with any changed fact is rejected.
Duplicate claim IDs must match every immutable claim fact. Saved operation
records from earlier builds that lack a complete binding cannot safely prove a
replay and therefore fail closed with `OPERATION_REPLAY_UNVERIFIABLE`; existing
claims remain readable and are not discarded or rewritten.

## History replay integrity (0.10.2)

Survivor-history create and removal operations use the same fail-closed replay
boundary. An operation ID is bound to the complete normalized semantic request,
including record, actor, subject, provider and evidence identity, content,
visibility, group and removal policy, reason, region, and timestamp. A replay is
returned only after the current actor is authenticated through the record's
provider. Changed payloads are rejected with `OPERATION_ID_CONFLICT`; legacy
operation entries without a binding return `OPERATION_REPLAY_UNVERIFIABLE`.

## Origin knowledge boundary (0.12.0)

Origin providers return an explicit stable origin ID, registered locality,
evidence ID, and bounded confidence. Priority ordering is deterministic and
provider callbacks are isolated. Authority converts that evidence into the
canonical replay-bound Hometown claim. No vanilla provider or first-party region
catalog is registered until native character-origin evidence is verified;
current position, spawn square, profession, and map exploration are never used
as substitutes.

## Current authority and persistence contract (0.17.0)

SP/client presentation queries read supported legacy state without modifying it.
Server document/knowledge queries use private storage; other guarded ledgers still refuse untrusted native player state.
Validated SP writes retain migration. Dedicated document/knowledge uses private storage; other MP mutations remain blocked. Persistent journal successor and
exhaustion records govern plans as well as claims; stale item flags cannot
reopen a payload. Plans are SP-oriented while MP is blocked and are capped by sandbox policy.
Built-in acquisitions preserve original fact time; direct requests keep strict
full bindings. Malformed nested saved data fails closed without destructive
initialization. Bounded source cleanup preserves active/uncertain anti-repeat
state. Realm exports include both media and origin interfaces.

See [repairs](REPAIRS_0_14_0.md), [configuration](CONFIGURATION.md) and
[native validation](RUNTIME_VALIDATION_0_14_0.md). Existing engine replication
assumptions remain unverified: optional transmit calls are not dedicated proof.
0.17.0 adds the bounded own-projection protocol documented in DEDICATED_KNOWLEDGE.md; no client owns gameplay state.

Journal inspection uses a projection of existing physical-item state and only
renders local counts/status/progress. It reads no persistent claim store and
adds no network route. Local item flags are not authoritative recovery eligibility.
It omits account/payload identifiers, explicit entry IDs and unwritten targets.
Window state is per player and shared by research/journal inspection. Journal
beginWriting prepares a schema-valid candidate before committing in place; all
journal item-key migrations follow validation. Requirements preflight every
reference before boolean evaluation, so unknown facts cannot be inverted by NOT.

## Current dedicated knowledge contract

0.17.0 implements document/knowledge only using private server storage, life generations and owning-client projections. See [DEDICATED_KNOWLEDGE.md](DEDICATED_KNOWLEDGE.md). The earlier blanket refusal is historical for that subsystem; progression, claims, journals/recovery, XP and history retain independent guards. Existing-world private migration is not implemented; no untrusted native table is imported. First native tests use fresh disposable dedicated worlds/two clients. SP is optional, never a prerequisite. Native G7 and stable G8 remain BLOCKED. CAT integration is dropped; old item declarations/aliases remain inert saved-item compatibility only.
