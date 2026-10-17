# Private authority implementation status

0.17.0 implements document/knowledge private storage and life binding for fresh dedicated fixtures; see DEDICATED_KNOWLEDGE.md. No SP prerequisite. Broader journal/claims/XP/history/migration work below remains unresolved and guarded. CAT integration is dropped.

## Historical 0.16.0 plan and broader unresolved requirements

# Mandatory private-authority implementation gate

0.16.0 currently refuses affected multiplayer gameplay. There is no enable toggle
or permissive fallback. This plan records remaining implementation work; it is
not a completed backend, a release approval or a claim that tests alone enable MP.

1. **Private persistence:** use a verified Lua-only server-private store, outside
   request-readable GlobalModData and network-replaceable player ModData. Establish
   world/profile isolation, bounded serialization (never eval saved code), write-
   ahead/commit/recovery semantics, detectable write failures and crash/restart
   behavior. Current file-writer observations alone do not prove that contract.
2. **Lifetime and payload identity:** bind authenticated accounts/slots to a server-
   owned character generation. Username/SteamID/session online ID are not a proven
   life key. Define creation, death, slot changes, reconnect and restart rules before
   implementation. Anchor documented journal payload/revision and successor locks
   on authority; never authorize XP from client item fields or an unverified legacy
   claim. Keep unwritten capture/queue details private on server.
3. **Conservative migration:** preserve immutable old keys/replay identities and
   backups. Explicitly map supported native old saves to verified server identities.
   Reject ambiguous/unverifiable inputs without resetting earned data. Verify a
   recoverable private copy before retiring any public table. This iteration does
   not remove native GlobalModData tables; existing history/claim data may still be
   request-readable even though new store attachment is blocked. Do not activate
   this on real player data as if the guard had sanitized it.
4. **Authenticated protocol:** clients submit bounded intent, never facts/totals.
   Server validates actor, item/inventory access, revision, sandbox policy and
   operation identity before mutating/persisting. Send only the allowed projection
   to the owning connection, with explicit local-player routing. Test stale replies,
   malformed/replayed commands, cross-player reads, transfer and contention.
5. **Native actions:** use verified shared server callbacks; derive incremental
   work from authority-owned timing and validated item/instrument ownership. Bound
   active jobs; do not use client update/maxTime as elapsed game minutes. Persist
   completed increments and test movement, sleep, logout, death and restart.
6. **Recovery:** exact-XP/level/stat/recipe/media contracts must pass independently.
   Preserve quarantine for uncertain partial awards; no automatic replay. A discrete-
   only or limited-perk product policy requires an explicit decision and validated
   authority route; it is not silently substituted for the existing raw-XP contract.
7. **Evidence:** complete disposable SP upgrade/reload tests, then at least two
   dedicated clients through join/rejoin, late join, privacy, duplication, restart
   and deliberate save/write failure. Record exact version/commit/build and clean
   engine/class provenance. Source/CI/test stubs never count as these observations.

Safe current work: local read-only presentation, SP-oriented offline core tests,
API/format validation, source audit and opt-in query observations. AuthorityGuard
is intentionally internal; exposing a sandbox bypass would violate authority policy.
No backend/action implementation may proceed on an assumed private native store.
G7 remains BLOCKED for implementation and evidence, stable G8 BLOCKED. No deploy,
package, server launch, upload or destructive migration is authorized by this plan.
