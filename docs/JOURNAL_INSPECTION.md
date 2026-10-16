# Survivor Journal inspection

Implemented in 0.15.0; native display NOT TESTED. On a single selected inventory
item with a valid recorded journal payload, choose **Inspect Survivor Journal**.
The vanilla-style read-only window shows local status (writing, recorded, claimed
or recovered keepsake), recorded skill and completed knowledge counts, category
counts, and current-session writing percentage/unfinished entry count when present.

The view does not show account IDs, payload IDs, explicit knowledge IDs or the
unwritten capture. It does not infer a character's current undocumented progress,
request an authority claim store, migrate state, grant knowledge/XP, claim or recover.
Local flags may be stale; they do not certify authoritative recovery eligibility.
It does not display author names or a last-update time: the existing schema has
no verified display-name/last-commit metadata. Those remain roadmap work.

Blank, corrupt and unsupported journals, unrelated items and multiple selection
have no inspection option. No new item definition/distribution is introduced.
Any provider-owned physical item with a supported payload can be inspected. The
existing TestSurvivorJournal remains a debug-only fixture; production timed
writing/recovery actions are still absent.

EnableJournalViewer is a sandbox boolean, default true (also when absent from old
world settings). False hides journal inspection; it does not alter saved payloads
or affect research inspection. Labels have English fallbacks in all 29 supported
folders; native translations/visual rendering are not verified. The window shares
one per-player lifecycle with research, restores vanilla controller focus and
bounds its own auto-height/scroll layout to the selected player's viewport.

## User-run validation after an authorized current test installation

Use disposable old-save copies and a fresh control; identify exact mod commit,
version, engine version, Steam build, enabled mods, roles and fixture origin.
Do not deploy historical Contents/dist. This procedure does not authorize install,
launch, deployment or publication. The existing SP debug harness can create a
partial recorded journal; it cannot certify dedicated authority or synchronization.

1. Inspect a partially written journal. Compare recorded counts/current-session
   progress with the approved driver/harness state. Opening/closing repeatedly
   must leave item state, revision and legacy/canonical key presence untouched.
2. Finish or cancel writing through a reviewed authority driver; reopen to observe
   recorded state. Inspect claimed and exhausted items plus an independent stale
   copy. Verify local status only; any recovery operation must still consult the
   server's persistent claim/exhaustion store and reject stale copies.
3. Inspect disposable legacy and malformed/future fixtures. Legacy remains intact;
   malformed/future/blank/unrelated and multi-selection show no action or mutation.
4. Switch the sandbox toggle off/on. Confirm visibility and preserved state.
5. Open research then journal for each split-screen player. Check scrolling, UI
   scale/small viewport, one active window per player, OK/button/controller closure,
   focus restoration and no window spilling into another player's viewport.
6. On a separately authorized dedicated setup, repeat with two clients, late join,
   reconnect and server restart. Compare each client's displayed projection with
   authoritative physical-item state; private character ledgers must not leak.
   A window opening is not synchronization, persistence or privacy proof.

Record each case PASS/FAIL/BLOCKED with sanitized evidence; keep private saves/logs
outside Git. SP and dedicated results are separate. G7/G8 remain BLOCKED until
required runtime cases pass. The broader RUNTIME_VALIDATION_0_14_0.md procedure
still applies with the actual tested 0.15.0 commit/version recorded.
