# experienceWorks 0.8.0 playtester handoff

Enable **experienceWorks only** on a new single-player test character. Open the
Lua debug console and run:

`experienceWorksTestStart(true)`

Then follow this compact sequence:

1. Right-click **Foundation Validation File** → **Inspect Research File**.
   Confirm readable text, a redaction block, and “Knowledge not recorded.” Run
   `experienceWorksTestPass("viewer and redaction correct")` or report the issue
   with `experienceWorksTestFail("issue")`.
2. Inspect **Prerequisite Validation File** before reading Foundation; it should
   report missing foundation knowledge. Read Foundation normally, run
   `experienceWorksTestKnowledge()`, inspect Advanced again, then read Advanced
   and rerun the status command.
3. Run `experienceWorksTestProgression()`. Confirm the output reports an applied
   action and the Mechanics XP panel increases slightly. A second run must award
   nothing more.
4. Run `experienceWorksTestJournal()`. Keep the created test journal, save/quit,
   reload the same character, then run `experienceWorksTestJournalStatus()`.
5. Test a world with **Enable research-file inspection** disabled: the Inspect
   option should be absent but normal reading should still work. Record the next
   step with Pass/Fail/Blocked.
6. If available, test a copy of a pre-0.7.0 save and confirm its recorded
   knowledge/journal state survived the corrected Mod ID. Otherwise mark this
   step blocked.
7. Hosted and dedicated-server testing is a separate required step. Mark it
   blocked until that environment is actually tested; do not call it passed from
   single-player evidence.
8. Run `experienceWorksTestReport()`.

Send back this file:

`%USERPROFILE%\Zomboid\Lua\theWorks Test Results - experienceWorks.txt`

Also send `%USERPROFILE%\Zomboid\console.txt` and screenshots for visual failures.
Do not enable Project M.O.R.T.I.S. or later Nightfall dependencies until this
stage has been reviewed.

