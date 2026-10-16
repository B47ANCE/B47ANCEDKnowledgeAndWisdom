# Reading, media and map audit — 2026-08-26

Installed Lua/native inspection; incomplete runtime and network verification.
Native evidence uses the same local JAR fingerprint as NATIVE_XP_AUDIT.md.

## Existing reading behavior

`shared/TimedActions/ISReadABook.lua` keeps page progress on both the literature
item and character. Its server ReadAPage animation handler derives progress from
the network action, retains startPage, clamps pages, updates character pages and
calls syncItemFields. This is a useful persistent-progress precedent, not a
ready-made journal-writing implementation.

Completion handles learned recipes, skill-book multipliers, ordinary literature,
modData learnedRecipe/literatureTitle/printMedia and synchronization. The
forceStopped server case returns true early. Our existing ReadCompletion wrapper
correctly checks forceStopped separately before granting a document unlock.
Do not interpret a successful base completion return alone as finished reading.

Current experienceWorks grants discrete document knowledge only at completion.
It does not replace vanilla reading, store arbitrary partial research work, or
implement journal transfer. Those requirements remain separate runtime work.

## Media reward identity

`shared/RadioCom/ISRadioInteractions.lua:checkPlayer` checks sleep and source
environment, then uses `isKnownMediaLine(guid)` and `addKnownMediaLine(guid)` before
processing reward codes. Known line IDs suppress repeated processing. Codes may
grant XP or call learnRecipe; there are also interaction cooldowns. A whole-tape
watched flag would be the wrong granularity for partial media recovery.

Native IsoGameCharacter owns a private knownMediaLines set and exposes add,
remove, clear and membership methods. Inspected save/load helpers serialize its
GUID entries with a short count. Need verify their full player lifecycle/network
call chain and safe bounds before assuming journal snapshots can enumerate or
restore it. Do not access the private field or blindly copy native save bytes.

itjustWorks already queries an individual item's media data/lines and membership
for read-only completion hints. Keep that QoL presentation there. experienceWorks
should own recovery state and anti-repeat policy, not duplicate the UI tracker.

## Map distinction

ISReadABook records read print-media IDs, then optionally reveals associated map
rectangles using WorldMapVisitedServer or WorldMapVisited setKnownInSquares.
This establishes a document-triggered reveal path, not a per-character archive
of every revealed rectangle's origin. Do not serialize all explored map state
as document knowledge. Explicit document IDs and verified metadata are candidates;
fog-of-war transfer remains excluded.

## Unresolved recovery ordering constraint

Raw XP must be written first, but aggregate native XP includes media rewards.
If a partial journal contains XP but not yet the corresponding media line
history, recovering that XP and then replaying the media could duplicate gains.
Target-based recovery alone does not prevent this cross-source exploit.

Before implementation, establish a verified source-accounting or anti-repeat
policy that respects ALL of these requirements: physically written data only,
raw-XP-first writing, no automatic death snapshot, no unearned media knowledge,
and no double media XP. Do not silently mark every tape watched, fabricate missing
history, or claim completion while this remains unresolved. Legacy XP lacking
source provenance needs an explicit supported policy.

## External precedent (claims, not verified integration)

[Read and Recall](https://steamcommunity.com/workshop/filedetails/?id=3728582856)
describes quizzes/minigames affecting skill-book multipliers and multiplayer
support. This confirms a compatibility surface around reading completion and
multiplier ownership; it does not establish a generic persistent journal API.
Its introductory XP wording is not authoritative evidence of vanilla behavior.
Source-level compatibility testing remains pending; no implementation was copied.

Next: enumerate media/catalog APIs, verify player serialization and field sync,
trace recipe ownership and map document metadata, then resolve the journal
anti-repeat policy before coding recovery.
