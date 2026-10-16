# experienceWorks in-game validation

Version 0.8.0 is the first stage of the progressive Nightfall dependency test.
Enable only experienceWorks on a new single-player test character. The harness
does not certify itself: visual, save/reload, old-save, hosted, and dedicated
observations must come from Project Zomboid.

## Commands

| Command | Purpose | Persistent change |
| --- | --- | --- |
| `experienceWorksTestStart(true)` | Reset test-only knowledge for this character, create a session, grant two one-page research files, validate canonical startup, and export the first report. | Test session and test-only knowledge entries |
| `experienceWorksTestAuto()` | Recheck canonical API/version, deterministic fixture registration, and result-file writing. | Command/result record only |
| `experienceWorksTestGiveFiles()` | Restore missing session-tagged Foundation and Advanced files without duplicating existing ones. | Adds test-only physical items |
| `experienceWorksTestKnowledge()` | Inspect Foundation/Advanced read and knowledge state; automatically records established unlock/prerequisite transitions. | Command/result record only |
| `experienceWorksTestProgression()` | Submit one committed semantic test action and verify observed Mechanics XP increases. It awards at most once per session. | About 1 Mechanics XP plus transaction provenance |
| `experienceWorksTestJournal()` | Create a test physical journal and commit one minute of a longer fixed write target. | Test journal item and partial journal state |
| `experienceWorksTestJournalStatus()` | Inspect the exact nested-inventory test journal. It records PASS only after a new Lua runtime observes the same payload/revision. | Result record |
| `experienceWorksTestSandbox()` | Report the active viewer sandbox option; visual off/on behavior remains human-confirmed. | Command record only |
| `experienceWorksTestPass("note")` | Mark the next pending manual step PASS. | Result record |
| `experienceWorksTestFail("issue")` | Mark the next pending step FAIL with the observed defect. | Result record |
| `experienceWorksTestBlocked("reason")` | Mark the next pending step BLOCKED by a genuine unavailable prerequisite. | Result record |
| `experienceWorksTestReport()` | Print and rewrite the complete result report. | Result file |
| `experienceWorksTestWhere()` | Print the Windows result location. | None |

Every command appends its feature, outcome, detail, and timestamp to the report.
The report is rewritten after each command so a crash still leaves useful
evidence. A command returning without an error is not treated as proof of a
visual or manual requirement.

The writer implementation uses Build 42's documented global
[`getFileWriter`](https://projectzomboid.com/modding/zombie/Lua/LuaManager.GlobalObject.html)
and [`LuaFileWriter`](https://projectzomboid.com/modding/zombie/Lua/LuaManager.GlobalObject.LuaFileWriter.html)
surface. It requests a user-data-relative filename rather than hardcoding a
Windows profile path; on Windows the resulting file is presented to the tester
as `%USERPROFILE%\Zomboid\Lua\...`.

## Feature coverage

| Feature | Primary path | Alternate/boundary path | Human | Reload | Integration |
| --- | --- | --- | :---: | :---: | :---: |
| Canonical Mod ID/API/load graph | `experienceWorksTestAuto()` | package/manifest host validators | no | no | consumers tested in host suite |
| Result export | start/auto/report | missing-writer failure is recorded | confirm file is accessible | no | no |
| Redacted viewer | inspect Foundation | inspect Advanced before/after prerequisite | yes | no | uiWorks remains optional |
| Read completion | normal one-page Read, then knowledge status | ordinary unregistered literature remains vanilla | yes | ledger check | no |
| Knowledge prerequisites | Advanced status before and after Foundation | denied completion must not grant knowledge | yes | ledger check | no |
| Semantic progression | progression command | repeated command awards no additional XP | observe XP panel | transaction ledger | vanilla XP route |
| Survivor Journal partial write | journal command | nested-item lookup and bounded one-minute partial commit | inspect item retention | required | GlobalModData claim later |
| Viewer sandbox option | sandbox status | disabled-world inventory menu | yes | new/reloaded world | no |
| Pre-0.7.0 migration | old save copy | knowledge/progression/journal state | yes | required | corrected Mod ID selection |
| Authority/replication | remote read/unlock | reconnect, late join, dedicated server | yes | required | hosted/dedicated |

## PASS/FAIL rules

- PASS requires the described in-game result, not merely a clean console line.
- FAIL means established behavior is wrong; include the exact symptom and attach
  the current `console.txt` when possible.
- BLOCKED is reserved for a missing old save, hosted/dedicated environment, or
  another genuine prerequisite. It is not a label for an ordinary defect.
- Test files and journals never enter loot distributions. They exist only for
  deterministic command-driven validation.
