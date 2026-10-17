# Dedicated document knowledge contract

Version: 0.17.0

This MINOR iteration implements a Lua-only, server-private document/knowledge ledger for fresh dedicated test worlds and server-created characters. It replaces the knowledge API's blanket storage refusal with an actual backend. It does not remove AuthorityGuard for progression, claims, journal mutation/recovery, raw-XP restoration or survivor history. Those APIs remain blocked. Dedicated is the first native target; SP is optional and never a prerequisite. Native G7 is NOT TESTED / BLOCKED and stable G8 BLOCKED.

## State, identity and transaction boundary

PrivateKnowledge is loaded only by the server loader. It writes an append-only `.txt` journal under the host's Lua cache, using a filename locator derived from `getCurrentSaveName()`. That helper returns the full current save directory; the journal header verifies the exact string, so a checksum collision cannot attach another world's data. OnInitGlobalModData's new-world flag creates a new server-generated epoch for a new world, including reuse of the same profile path. Old journal bytes are retained. An existing world with no private journal returns PRIVATE_MIGRATION_REQUIRED; a missing or corrupt journal is never silently treated as an empty earned ledger.

OnNewGame runs in the inspected server character-creation path after the authenticated username is assigned and before the native player database save. It commits a new server-generated UUID and empty life ledger before placing an opaque reference in player ModData. No knowledge, claim or history is put there. Username identifies an authenticated account, never a life by itself. Steam IDs are not converted through Lua doubles. The private record owns the generation; public references are only lookup candidates.

The native creation callback precedes slot assignment. Pending births are therefore reconciled against actual server-listed player objects and their native slots, without a client-selected subject/slot. Every pending birth for that account must have an unambiguous server-listed match before binding; duplicate references, unmatched pending births, unlisted actors, cross-account tokens, retired generations and slot mismatches fail closed. Binding retires the previous generation in that slot and preserves its record. OnCharacterDeath retires the matching life. Repeated initialization/birth/death events are idempotent. Native split-screen username/slot behavior still requires the dedicated scenario below; mismatched identities are rejected rather than guessed.

PrivateCodec uses a bounded typed, length-prefixed data format with hex-encoded strings, finite numbers and string-keyed tables. It rejects executable Lua, cycles, metatables, malformed/truncated values and duplicate keys; it never calls loadstring or eval. Each log record has a sequence, checksum and complete operation. Candidate state is validated before append. The writer is closed and the complete journal is re-read, replayed and compared with the expected bytes/state before acknowledgement. Native LuaFileWriter wraps PrintWriter without exposing checkError; read-back verification detects silent refused writes. A failed/uncertain write latches the process closed. An incomplete/corrupt tail is preserved and blocks startup; no fallback to an older authority snapshot, truncation or automatic retry is performed.

This is read-back-verified persistence, not a claim of OS fsync or atomic coordination with native player/world database files. After any I/O failure, stop affected testing and preserve the private journal and native save together. Do not resume a player database/private-journal pair restored from different moments. Abrupt process/storage failure, acknowledged-write durability and coordinated backup/restore are mandatory native fault-injection gates. Do not use real player data for those tests. Downgrade requires restoring the matched pre-upgrade backup; 0.16.0 cannot consume the private backend.

Technical limits bound parser, disk and network work: 1 MiB encoded record/state, 32,768 nodes, depth 12, 16 MiB log, 16,384 journal records and 1,024 server-listed players per lookup. Reaching a limit rejects new mutations and preserves prior data; no implicit compaction/deletion is included. These are implementation safety limits, not gameplay tuning. Existing sandbox gameplay settings remain server-authoritative and unchanged. There is no MP bypass toggle. Scans happen on births/knowledge operations/projection requests, never per tick. Production compaction/retention remains separate work; this test iteration must not be presented as unbounded storage.

## Queries, reading and network boundary

Dedicated API queries read detached copies from the private ledger. SP retains its validated legacy key/migration behavior. Native player ModData and GlobalModData are never imported as authoritative MP knowledge. Existing old data and immutable keys are preserved; ambiguity means rejection, not reset or automatic migration. Existing private history/claim exposure from earlier versions is not sanitized by this implementation. Use a fresh disposable world for first testing.

The native server read-completion wrapper checks successful completion, cancellation and actual reader inventory ownership before calling the trusted server API. Clients have no grant/read-complete RPC. Other trusted server providers may call the existing knowledge API, subject to private identity, document definitions, prerequisites and save validation. Duplicate reads are idempotent and may refresh the owning projection; they never reissue knowledge grants. Optional claim acquisition still reports its independent blocked status and cannot become a private-history bypass.

Clients request only their own projection using the engine-supplied actor and a bounded correlation ID. The request accepts no subject, slot, document, totals or revisions. At most two initial sends per native actor cover creation and fully connected startup; later committed reads push new revisions. Targeted sendServerCommand addresses the owning connection. Replies include slot, online ID, life generation and revision; the client verifies its own local actor and request ID, rejects stale/mismatched replies and exposes a read-only local cache. A client cache cannot grant server knowledge or mutate native ModData. A transport failure does not undo an already verified knowledge commit; it returns a projection-pending diagnostic and requires native resynchronization checks.

CAT integrations are dropped at the user's request. No CAT adapter/document registration or loot integration is introduced here. The old canonical/legacy manual item declarations, translation keys and immutable saved IDs are retained solely to keep existing saved items/data loadable; no CAT dependency or automatic knowledge grant is created by those declarations.

## Installed evidence and exact checks

[VERIFIED inventory] Steam manifest build 25485521. Inspected JAR SHA-256 `e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`; packaged Core reports 42.21. Effective runtime/class precedence remains UNKNOWN because selected loose character classes differ. No game/engine files were changed or executed. Read-only tooling inspected selected class bytes; no custom Java/JAR runtime dependency is used. `NATIVE_EVIDENCE_0_17_0.json` records portable class/Lua fingerprints and bounded findings. Native inspection/binding construction is not actual Lua invocation or MP evidence.

```sh
python scripts/check_versions.py
python scripts/validate_source.py
python scripts/run_host_tests.py
python scripts/check_public_tree.py --staged
git diff --check
```

The private-codec, private-knowledge and knowledge-projection regressions simulate two accounts, slots, owned/cancelled reading, immutable queries, native state forgery, retired/cross-account reference rejection, duplicate events, reconnect/restart, stale replies, silent write refusal, torn log tails and world separation. These are offline Lua 5.1 simulations, not dedicated PASS.

## Dedicated acceptance, first native target

Use an explicitly authorized disposable dedicated installation, clean native class provenance and two clients; record exact game versions/builds, clean source commit/digest, sandbox values and sanitized evidence. No launch, install or upload is performed by these checks.

1. New world: verify initialization and server OnNewGame issue references; start with no earned knowledge. Confirm a client cannot request another player's ledger or grant knowledge via malformed commands/native ModData replacement.
2. Read an independently registered test document while owning it; cancel/move/remove it in negative cases. Verify only the valid server-completed read grants its definitions, and the other client remains unchanged. Confirm the owning research projection refreshes.
3. Repeat the read and replay requests. Verify no duplicate grant, bounded request sends, preserved timestamps and correct reconnect correlation.
4. Disconnect/rejoin, then gracefully save/restart/rejoin. Verify the same generation/knowledge returns and the other account cannot present its token. Test late join and out-of-order/mismatched projection replies.
5. Create another local slot, then replace a character in a previously used slot. Verify actual native usernames/slots match the documented binding, separate ledgers, retirement and no inherited qualifications. Any ambiguity remains BLOCKED; do not substitute account-wide grants.
6. Kill a test character and create its successor. Verify OnCharacterDeath retirement and new generation binding. Replayed old references cannot recover knowledge. Preserve archived private records.
7. Inject denied writes, silent/truncated writes and abrupt process/storage failure on disposable fixtures. Verify no success acknowledgement without read-back, latched refusal, corrupt-tail startup refusal and consistent native/private backup recovery. Record any cross-file crash gap; do not call it PASS from the mock tests.
8. Create a fresh world with the same profile path, then a separate world. Verify epochs/world headers prevent cross-world knowledge. An existing world with no private journal must return PRIVATE_MIGRATION_REQUIRED and leave old keys unchanged.
9. Confirm progression, history claims and journal recovery still return their independent guard errors. The SP development harness remains SP-only; it cannot certify dedicated knowledge or bypass the guards.

Do not promote this development source to stable release until required dedicated G7 evidence exists. Broader framework recovery/migration features remain explicitly blocked, independently of document knowledge test readiness.
