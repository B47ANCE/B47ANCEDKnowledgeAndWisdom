# B47ANCED Knowledge & Wisdom 0.13.0 playtester handoff

Use a backed-up disposable save and follow [identity migration](docs/IDENTITY_MIGRATION.md).
Enable **B47ANCED Knowledge & Wisdom only** on a new single-player test character. Open the
Lua debug console and run:

`B47ANCEDKnowledgeAndWisdomTestStart(true)`

Then follow this compact sequence:

1. Right-click **Foundation Validation File** → **Inspect Research File**.
   Confirm readable text, a redaction block, and “Knowledge not recorded.” Run
   `B47ANCEDKnowledgeAndWisdomTestPass("viewer and redaction correct")` or report the issue
   with `B47ANCEDKnowledgeAndWisdomTestFail("issue")`.
2. Inspect **Prerequisite Validation File** before reading Foundation; it should
   report missing foundation knowledge. Read Foundation normally, run
   `B47ANCEDKnowledgeAndWisdomTestKnowledge()`, inspect Advanced again, then read Advanced
   and rerun the status command.
3. Run `B47ANCEDKnowledgeAndWisdomTestProgression()`. Confirm the output reports an applied
   action and the Mechanics XP panel increases slightly. A second run must award
   nothing more.
4. Run `B47ANCEDKnowledgeAndWisdomTestJournal()`. Keep the created test journal, save/quit,
   reload the same character, then run `B47ANCEDKnowledgeAndWisdomTestJournalStatus()`.
5. Test a world with **Enable research-file inspection** disabled: the Inspect
   option should be absent but normal reading should still work. Record the next
   step with Pass/Fail/Blocked.
6. If available, test a copy of a pre-0.7.0 save and confirm its recorded
   knowledge/journal state survived the corrected Mod ID. Otherwise mark this
   step blocked.
7. Hosted and dedicated-server testing is a separate required step. Mark it
   blocked until that environment is actually tested; do not call it passed from
   single-player evidence.
8. Run `B47ANCEDKnowledgeAndWisdomTestReport()`.

Send back this file:

`%USERPROFILE%\Zomboid\Lua\B47ANCED Knowledge & Wisdom Test Results.txt`

Also send `%USERPROFILE%\Zomboid\console.txt` and screenshots for visual failures.
Do not enable Project M.O.R.T.I.S. or later Nightfall dependencies until this
stage has been reviewed.

