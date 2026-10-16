# B47ANCED Knowledge & Wisdom identity migration

Current version: 0.13.0. Display name: **B47ANCED Knowledge & Wisdom**. Technical Mod ID,
source folder, Lua import prefix/global and sandbox page: `B47ANCEDKnowledgeAndWisdom`.

For a consumer, change `require=experienceWorks` in mod.info to
`require=B47ANCEDKnowledgeAndWisdom`. Change imports such as
`require "experienceWorks/API"` to `require "B47ANCEDKnowledgeAndWisdom/API"` and the
global to `B47ANCEDKnowledgeAndWisdom`. Update full item types owned by this project to
the new module for newly created items. This task only changes this project;
consumers in other repositories need their own verified updates. Provider-owned
knowledge/document/action IDs must remain stable across that consumer update.

Back up a test save. Replace the old package and update the save/server mod list
to the new Mod ID before loading. Enable only one identity; simultaneous old/new
packages and mixed-version peers are unsupported. Lua cannot rewrite a server's
mod list or update another mod's declared dependency. No old public Lua loader,
global or duplicate registry is shipped. Workshop item 3792566496 is unchanged.

Private compatibility deliberately retains the established character knowledge,
progression and claims ModData keys; item journal key; GlobalModData claim/history
keys; built-in claim definition IDs and recorded owners. These are immutable
storage/content identity, not the active Mod ID. Keeping them avoids rewriting
full request bindings, unlocking duplicate claims, losing a successor lock or
resetting diminishing returns. No stored ledger or operation binding is renamed
or cleared. Existing unsupported schemas still fail closed.

Nineteen historical script item types remain as saved-inventory compatibility
definitions. Their display text uses the new branding; new content uses the new
module. Old full types resolve through the canonical document index. Built-in
literature claim scope preserves the historical full type so already recorded
requests still replay exactly. CAT provider registration/content remains owned
by its provider; this project does not modify third-party mods.

The viewer remains local read-only presentation. Either a current or historical
explicit `EnableResearchViewer=false` disables it, so the new default true cannot
override an old disabled setting. To intentionally re-enable after migration,
remove the historical option from a backed-up saved sandbox configuration and
set `B47ANCEDKnowledgeAndWisdom.EnableResearchViewer=true`. Unknown sandbox engine
migration guarantees are not assumed. Other gameplay/progression configuration
and authority behavior are unchanged; this rename adds no gameplay knobs.

Existing pre-0.7.0 misspelled storage imports remain. They keep the inherited
move-on-access behavior and do not establish new native replication guarantees.
Debug fixture/session IDs use the new identity and require a fresh validation
session, so historical test-session results are never adopted as current proof.

[TESTED: offline Lua 5.1] The frozen synthetic 0.12.2 fixture was emitted by
the original source under host mocks. Upgrade tests reuse exact saved ledger
tables, replay literature and journal claims, retain successor contention and
diminishing returns, attach existing history storage, reauthenticate history
replays, and check reloads and sandbox fallback. Its original source SHA-256
inventory is `tests/fixtures/PROVENANCE.json`.

[RUNTIME GATE] Test old-save loading, saved item types and translations, disabled
sandbox retention, new Mod ID selection, one reading hook, remote reading,
late join/rejoin, restart persistence and replay rejection on a dedicated server.
Native script loading/serialization and network behavior are NOT TESTED. G7 and
stable G8 remain BLOCKED. Use backups for rollback; no general downgrade guarantee
is made for gameplay changes beyond this identity-only iteration.
