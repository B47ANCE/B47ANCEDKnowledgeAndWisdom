<!-- CURRENT_GW_CANDIDATE -->
Current groundWorks integration candidate uses `src/experienceWorks/42` as its authoritative source. The older `Contents/mods` tree is preserved for history and is not the candidate source. Build this three-mod candidate with `tools/Build-GroundWorksCandidate.ps1`; see [candidate changes and acceptance checks](../groundWorks/docs/RELEASE_CANDIDATE_0_16_0.md).

# experienceWorks

experienceWorks is the canonical lore, research, survivor-knowledge, and
experience-progression infrastructure project for theWorks ecosystem.

- Status: version `0.12.2` Project Archive, registered knowledge definitions,
  composable prerequisites, semantic-action progression, vanilla research viewer,
  host-verified Survivor Journal persistence/recovery core, and a progressive
  in-game test/result-export harness, and bounded unified knowledge claims;
  human validation pending.
- EXT-25 includes a bounded, non-mutating recorded-media projection using
  Build 42 media IDs, line GUIDs, and native per-character known-line state.
  Title visibility is caller-policy controlled; reward codes are never exposed.
- EXT-25/26 claims retain provenance, scope, acquisition, confidence,
  completeness, revocation, and replay history. Geographic familiarity accepts
  only explicitly registered regions and never reveals live world state.
- EXT-32 now provides provider-validated, world-persistent survivor-history
  records with stable author/subject/evidence identity, bounded sanitized text,
  visibility checks, full-request replay binding with caller re-authentication,
  and tombstone removal. It creates no
  memorial objects automatically.
- Mod ID: `experienceWorks`
- Author: B47ANCE
- Hard dependencies: none beyond Project Zomboid.
- Consumers: Project M.O.R.T.I.S., Project Nightfall, medWorks, and any other
  mod registering discoverable knowledge.

The canonical Mod ID, source namespace, Lua entry points, sandbox page, and
public global are all **experienceWorks**. Version 0.7.0 corrects the former
misspelling throughout the ecosystem. A private migration helper moves only the
old persisted knowledge, progression, Survivor Journal, and sandbox state; the
misspelled identity is no longer a public integration surface.

**homeWorks is an internal subsystem, not another mod.** It owns knowledge,
literature, research and persistent study/Survivor Journal systems.
Domain mods own their content; vanilla remains authoritative for normal skill
XP and recipes. Semantic XP is implemented. Survivor Journals now provide the
physical persistence, progressive writing, claim, and recovery-plan core; native
timed actions and raw-XP application remain gated on in-game API verification.
Knowledge IDs are namespaced, provider-owned definitions rather than unchecked
document strings. Requirements support nested ALL, ANY, and NOT document or
knowledge rules; legacy prerequisite lists use the same evaluator.

Domain mods may register weighted semantic actions and report only committed,
meaningful outcomes. experienceWorks applies normalized skill weights through
vanilla `addXp`, with bounded failure credit, restrained quality and difficulty,
source-aware diminishing returns, authority rejection, and uncertain-award quarantine.

See [approved requirements](docs/PROGRESSION_AND_JOURNALS.md),
[repository and migration audit](docs/REPOSITORY_AUDIT.md), and
[roadmap](docs/ROADMAP.md). Installed-game API verification precedes new framework
implementation; existing archive consumers remain supported.
