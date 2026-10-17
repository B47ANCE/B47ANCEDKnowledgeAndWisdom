# Changelog

## 0.16.0 — 2026-10-16

- Completed the selected source/native audit with 27 class fingerprints and 13
  bounded API observations. Packaged Core reports 42.21; effective runtime remains
  unverified because inspected loose character classes differ from packaged bytes.
- Removed whole-character ModData broadcasts. Native player tables are replaceable
  and GlobalModData tables are request-readable: affected MP APIs now fail closed
  until private server persistence, lifetime/payload identity and migration exist.
- Added an opt-in authority query-purity probe without messages, writes or gate promotion.
- Required observed SP XP increase, quarantined silent/partial refusals, blocked
  native callback reentrancy before awards, and rejected weight overflow/invalid perks.
- Prepared schema-valid knowledge results; rejected malformed timestamps, source
  types, sparse registration lists, infinite loot weights and missing grant definitions.
- Rejected invalid claim acquisitions/history evidence and bound-field overflow;
  preserved exact media IDs rather than truncating them into different known facts.
- Validated journal queue totals/identities/targets and recovery IDs/inputs without
  repairing corrupt saves. Stored schema remains 1; old data/artifacts/artwork retained.
- MINOR compatibility gate; native SP NOT TESTED, G7 and stable G8 BLOCKED. No build,
  deploy, game/server launch, Workshop upload, stable tag or merge.

## 0.15.0 — 2026-10-16

- Added native-style read-only inspection for recorded Survivor Journals: status,
  recorded skill/knowledge counts and current writing progress, without account
  IDs, payload IDs or unwritten captures. Added EnableJournalViewer (default true).
- Shared inspection-window lifecycle with research and bounded vanilla modal
  auto-height to the selected player viewport. Native UI validation is pending.
- Rejected unknown prerequisite references before ALL/ANY/NOT evaluation and
  bounded requirement depth/size; sparse arrays and unknown fields fail closed.
- Prepared and validated journal writes before persistence; invalid captures and
  rejected journal operations no longer create/migrate item state. Active writing
  operation IDs reject changed captures; successful migration retains table identity.
- Added audit, regressions, English fallback coverage and current version-doc checks.
- MINOR feature iteration, schema 1 unchanged. Offline only; G7/G8 BLOCKED.
  No build, deployment, game/server launch or Workshop publication.

## 0.14.1 — 2026-10-16

- Adopted the user-supplied Knowledge & Wisdom thumbnail for the Workshop preview
  and authoritative source authoring thumbnail, preserving exact PNG bytes.
- Documented artwork provenance and displayed the thumbnail in the README.
- PATCH artwork iteration; gameplay, saved schemas, Mod ID and icon are unchanged.
  G7 and stable G8 remain BLOCKED. No packaging, deployment or Workshop upload.

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
