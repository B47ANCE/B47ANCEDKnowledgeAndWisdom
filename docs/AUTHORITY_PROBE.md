# Opt-in owned-key query probe

0.16.0 exposes `B47ANCEDKnowledgeAndWisdom.AuthorityProbe.run(character, item)`
on the server/SP loader. It registers no events, commands, timers, file writers
or network handlers and never starts itself. It does not grant XP, alter fixtures,
claim/recover a journal, attach a store, launch anything or promote a gate.

After a separately authorized disposable installation, a trusted SP/server-side
Lua driver supplies the actual fixture character and optional journal objects.
Do not use a normal client console to claim authority, and do not substitute an
online-player index without verifying the disposable target. The probe refuses
ordinary client invocation. No credentials or private raw state belong in Git.

The returned report contains version, declared realm, scope, the implementation
blocker, per-query call/view-availability booleans and `ownedKeysUnchanged`. It
compares bounded before/after copies of only this mod's canonical/legacy owned
keys, including malformed/cyclic fixtures where supported. It emits no snapshot,
identifiers, counts, exceptions, log output or network message. Unsupported input
returns a generic error; a skipped probe is not a PASS.

Cases queried: knowledge snapshot, progression snapshot, claims snapshot, plus
journal snapshot/view when an item is supplied. Server character-ledger queries
are expected to be unavailable in 0.16.0 while the private backend is absent.
A successful before/after comparison is only that observation: it does not prove
absence of transient writes, packet privacy, persistence, death/restart behavior,
XP restoration, headless UI, or working MP gameplay.

Record the report with exact commit, actual engine version/Steam build, OS/realm,
fixture origin and sanitized procedure. Cross-check a disposable save before/after
native save/reload if certifying saved-data purity. Keep raw saves/logs private.
Use AUDIT_CLOSURE_0_16_0.md and MP_AUTHORITY_PLAN.md for required work. G7/G8 remain
BLOCKED; the older broader procedure is historical guidance pending implementation.
