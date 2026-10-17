# Current native capability audit

2026-10-16. Version 0.16.0. Source inspection only, runtime NOT TESTED.
See NATIVE_EVIDENCE_0_16_0.json for exact input/class/Lua fingerprints and bounded
observations. The inspected JAR is SHA-256
`e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`.
Steam appmanifest build: 25485521. Packaged Core initializes GameVersion(42, 21, "").
Effective runtime version and loose-class precedence are UNKNOWN; selected
IsoGameCharacter/XP/IsoPlayer loose bytes differ. No engine files were modified.

Method: selected current class bytes were read with [CFR 0.152](https://www.benf.org/other/cfr/)
in a temporary directory using the installed JRE as tooling. Its downloaded bytes
matched the author's listed MD5 and have a recorded SHA-256. The game JAR was an
input file, not a JVM classpath; no game/server or engine classes were executed.
No custom Java/JAR mod dependency, bridge, raw game source or decompiler output
is included in runtime source/CI. Thirteen bounded findings were recorded as
INFERRED native observations in the unmanaged local API draft; this does not
promote untested Lua dispatch or effective runtime behavior to VERIFIED.

## Storage and transport conclusions

- IsoObject.transmitModData uses ObjectModData; GameServer sends it to relative
  clients. The packet writes the full table. MovingObject supports player IDs;
  the inspected consistency check tests resolution, and parse loads the table.
  A native player ledger is therefore unsuitable for private server authority.
- GlobalModData.receiveRequest returns the requested named table to that
  connection. There is no framework record/group/privacy filter in that route.
  Keeping a table in server ModData without calling transmit does not make it private.
- InventoryItem does not define transmitModData. The exposed syncItemModData
  route is server-only and sends whole item data to relative clients. An opaque
  server-owned payload reference/public documented projection is needed before
  broadcasting a journal containing private unwritten targets.
- SyncPlayerFields has six native field families: recipes, traits, read books,
  body damage, reading and fitness. Its masks do not synchronize arbitrary mod
  ledgers or provide a generic media/XP restore packet contract.
- Targeted sendServerCommand(player, ...) resolves that player's connection.
  This is a possible owner-connection transport, not persistence, per-life
  identity, delivery/rejoin proof or automatic split-screen routing.

## XP, recipes and media

- getXP reads raw perk totals. Full AddXP can return early for sleep/Fitness and
  applies Strength protein changes before the boost branch. Global addXp is void,
  can reject an out-of-world player, and has additional server checks. A successful
  protected Lua call does not establish an award. SP now observes before/after;
  totalXP is the planned policy amount and observedXP reflects native gain.
- setXPToLevel is a threshold operation, not exact fractional recovery. setTotalXP
  is not a per-perk target setter. Public xpMap visibility alone establishes no
  approved Lua mutation, level/stat reconciliation or MP contract. Exact recovery
  remains disabled; no nutrition edits, guessed compensation or Java fallback.
- getKnownRecipes returns explicit entries. isRecipeKnown overloads include debug,
  visibility, non-learning-required and meta-recipe cases. learnRecipe can return
  false for known/derived state. ScriptManager's auto/meta paths evaluate derived
  requirements separately. Do not snapshot all craftable/visible recipes as earned.
- isKnownMediaLine checks trimmed GUID membership; known lines have character
  save/load paths. RecordedMedia has category/type lookup APIs in inspected bytes.
  Snapshotting a bounded registered media set is a possible future design, not
  approval to enumerate rewards, reapply media XP or assume synchronization.

## Timed actions and persistence candidates

NetTimedAction invokes serverStart/serverStop/complete in the inspected paths;
its update body is empty. ActionManager schedules server completion using server
milliseconds. NetTimedAction adjusts duration and scales it by 20. Client update
or raw action-duration units must not be treated as authoritative game minutes.
Inventory/instrument ownership, action deserialization, movement/death/logout,
partial work and native synchronization still require a verified adapter/runtime
suite after private persistence exists. The reading wrapper now explicitly loads
its verified shared native dependency instead of relying on OnGameBoot ordering.

getFileWriter is a candidate Lua-only private backend surface: it writes beneath
the Lua cache root, has append behavior and may return null. This audit does not
establish durable flush, atomic replace, partial-write recovery, world isolation
or a native per-life identity. Those are mandatory design and runtime work,
not grounds to reuse public GlobalModData or client-owned tables.

No native origin/hometown authority mapping is established in this bounded audit.
Profession, current position, spawn location and exploration remain prohibited
substitutes. Approved provider evidence/region content and external integrations
are explicit feature dependencies. No external mod code/assets were analyzed/copied.

The source audit closes the previous API questions with these conclusions and
constraints. Native SP, dedicated authority, privacy, lifecycle and old-save tests
remain NOT TESTED. G7 and stable G8 remain BLOCKED.
