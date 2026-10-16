# Native validation procedure

Version: 0.14.0. User-run evidence only. Initial status: SP NOT TESTED;
dedicated G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Do not treat offline tests,
the harness's mock output or GitHub CI as runtime PASS.

## Prerequisites and evidence identity

1. Select the exact repair commit and record its source manifest, actual game
   version and Steam build, OS, SP/dedicated role, and enabled mod versions. Start
   with this mod alone; add each updated consumer only in a later compatibility
   run. Do not assume historical audit JAR hashes describe the current engine.
2. Use disposable copies of legally available old native saves and a fresh
   control world. Record each original save's exact mod version and schema.
   Keep originals/backups intact and identify the copy used. The frozen Lua
   0.12.2 fixture in tests is synthetic and cannot serve as a native old save.
3. A current test package/install is a separate prerequisite. No package,
   deployment or Workshop upload was produced during repair. Never substitute
   ignored historical Contents/dist output. Mark the gate BLOCKED until a
   separately authorized current test build is available.
4. Enable only the new Mod ID. Update the disposable world's mod list from the
   old ID and remove the old package from that test environment. Avoid mixing
   old/new peers or stale consumer dependencies. Record the selected identity.
5. Native reading/viewer paths have existing game hooks. Journal timed actions,
   exact raw-XP restoration and a dedicated authority-side test driver are not
   implemented by these repairs. API-only cases below require a reviewed test
   driver that actually executes on authority and observes both peers. If it is
   unavailable, mark those cases BLOCKED; do not substitute client Lua calls.

## SP first

Run on a fresh disposable character, then copies of supported old saves:

| Case | Procedure | Required evidence |
| --- | --- | --- |
| Identity/load | Select B47ANCEDKnowledgeAndWisdom, inspect startup and open registered research | No missing imports, duplicate hooks or script item errors; exact version |
| Old items | Load old literature/journal full types and open the read-only viewer | Items survive native serialization and display the new text |
| Query purity | With the approved driver, capture legacy/canonical key presence and field contents, query knowledge/progression/journal repeatedly | Exact native data unchanged by queries |
| Write migration | Complete a valid server/SP-owned write on a legacy copy, then save/reload twice | One validated migration, original earned data preserved, no repeated migration |
| Cancellation/re-read | Cancel a registered read, then finish it; read again later | Cancellation grants nothing; finish learns once; later read has no duplicate XP/claim or replay conflict |
| Journal copy | Driver captures an independent stale item copy before exhaustion; consume original, reload and retry both | Persistent successor/exhaustion rejects both stale planning and a different successor |
| Missing/bad state | Use only disposable malformed fixtures; inspect returned errors and compare saved data before/after | Clean refusal, no crash, reset, silent truncation or repaired-away diagnostics |
| Sandbox | Test defaults and selected non-default rates; compare declared UI bounds and observed server calculations | Correct defaults on old worlds, clamped values, original state retained |
| Reload/retention | Record repeat counters/quarantines, perform bounded expiry work and reload | Active/uncertain counters survive; expired counters disappear without a stall |

The existing debug-session commands in IN_GAME_TESTING.md may help observe
reading/viewer behavior. Start a new 0.14.0 session; old reports are historical.
Their client-only operation cannot certify dedicated server awards. Actual
native XP restoration remains BLOCKED until its implementation/API contract is
verified; a recovery-plan table is not restored XP.

## Dedicated multiplayer after SP

Use a disposable dedicated world and at least two separate clients. The user
controls any authorized installation, launch, restart or diagnostic collection.
Read-only SFTP diagnostics do not authorize remote changes. No server credentials
or private player data belong in Git or the evidence report.

1. **Headless startup and settings:** confirm server-only storage initialization,
   stable Mod ID and the intended sandbox values. Deliberately differing client
   preferences must not choose XP, repeat, journal speed or recovery rates.
2. **Remote reading:** from client A, finish/cancel/re-read registered documents.
   Observe the server's single committed result and the correct client's view.
   Client B must not receive A's private knowledge/history. Verify ownership and
   the actual native synchronization path, not merely a successful method call.
3. **Intent validation:** through an approved driver, attempt malformed, stale,
   altered-scope/source/timestamp and wrong-identity requests. Server state must
   remain unchanged for rejected intent. Direct client mutation remains rejected.
4. **Join/rejoin:** capture authoritative state, disconnect A mid-operation,
   reconnect, then have B join late. Check grants, private views and successor
   locks for missing or duplicated state, including repeated same-fact requests.
5. **Journal contention:** race two successors and independent stale item copies.
   Exactly the matching persistent successor can plan an unexhausted payload.
   Exhaust the original; every copy must fail after reconnect and restart.
6. **Persistence/restarts:** save, gracefully restart the disposable server and
   reconnect both clients. Check knowledge, progression transactions, active
   repeat counters, quarantine, claim exhaustion and private history/tombstones.
   Uncertain/pending awards must remain blocked for review, never auto-granted.
7. **Capacity/configuration:** exercise a bounded disposable stress fixture and
   approved sandbox changes. No eviction of active/quarantined anti-repeat state,
   client authority, XP at capacity rejection, malformed-save reset or long tick
   stalls is acceptable. Record timing observations without inventing thresholds.

## Recording and gates

For every case provide: exact commit/source hashes, environment/build, fixture
version, roles, steps, expected/actual result, PASS/FAIL/BLOCKED, and a sanitized
evidence reference. Keep raw logs and private snapshots outside the public repo.
Distinguish SP VERIFIED from DEDICATED MP VERIFIED for each tested behavior.

Any unavailable driver/native feature, missing old-save fixture, failed sync or
untested required dedicated case keeps G7 BLOCKED / NOT TESTED and stable G8
BLOCKED. Offline repair success does not authorize deployment/publication or
clear those gates. Submit the observations for review before changing a gate.
