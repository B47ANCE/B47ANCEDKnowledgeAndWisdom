# Changelog

## 0.14.0 — 2026-10-16

- Kept all client/authority queries non-mutating; moved validated legacy storage
  migration to authority writes only.
- Required persistent successor and exhaustion checks for recovery plans and
  rejected exhausted stale journal copies, including after reload.
- Preserved acquisition time for built-in repeated facts while retaining strict
  full-request replay checks for direct grants and changed evidence.
- Rejected blank/sentinel identity payloads before trying fallback identifiers.
- Added non-destructive nested saved-state validation and removed the legacy
  claim migration dependency on global next.
- Pruned expired progression sources in bounded work, retained active/quarantined
  counters and rejected new sources at the technical capacity before XP awards.
- Aligned all realm bootstrap exports and added seven server sandbox controls
  with validated integer bounds, defaults and localization/fallback keys.
- Added focused regressions, pinned offline CI and the native runtime procedure.
- Offline checks only. User will supply SP/dedicated evidence. G7 and stable G8
  remain BLOCKED. No deployment, server/game launch or Workshop publication.

## 0.13.0 — 2026-10-16

- Renamed the project to B47ANCED Knowledge & Wisdom and the technical Mod ID, source
  directory, Lua namespace/global, sandbox page, translations, script filenames
  and debug commands to `B47ANCEDKnowledgeAndWisdom`.
- Updated current documentation and Workshop metadata for the same existing item.
- Kept immutable saved storage and replay identities private; retained old saved
  item types and disabled sandbox settings without a second public Lua API.
- Established canonical VERSION from the user-approved 0.12.2 baseline and added
  exact mirror checks, source validation and an isolated Lua 5.1 host runner.
- Added a synthetic old-source upgrade fixture and storage/replay regression.
- Preserved historical packages, staging, artwork and original documentation.
- Offline validation only. SP/dedicated NOT TESTED; G7 and stable G8 BLOCKED.
  Git checkout/remote absent: NOT BACKED UP TO GITHUB. No build/deploy/publish.

Earlier changes retain their original versions and names in
`docs/history/pre-b47-0.12.2/WORKSHOP_CHANGE_NOTE.txt`.
