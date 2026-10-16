# B47ANCED Knowledge & Wisdom version and source policy

Root `VERSION` is canonical. The user authorized establishing the observed legacy
0.12.2 baseline on 2026-10-16 and targeting 0.13.0 for the branding/technical-ID
migration. This is a pre-1.0 MINOR increment because consumers must update public
imports and dependency identifiers. Persisted schema versions remain unchanged.

Run `python scripts/check_versions.py` before and after development. It checks
exact current mirrors: authoritative `42/mod.info`, source `info.txt`, shared
`API.lua`, README status, Workshop description, `workshop.txt` description,
current change-note heading, MASTER_ROADMAP canonical version, and the identity
test's API-version assertion. CHANGELOG's newest heading tracks VERSION too.
Historical version references and frozen fixtures are not current mirrors.
Current mirrors also include AGENTS.md and the named current validation record.
The 0.14.0 MINOR iteration adds server sandbox controls and compatible authority,
persistence and bootstrap repairs; schema remains 1. The exact repair contract
and existing-save behavior are in REPAIRS_0_14_0.md and CONFIGURATION.md.

Authoritative runtime root: `src/B47ANCEDKnowledgeAndWisdom/42`. Parent `info.txt` is
authoring metadata. Tests and scripts are development-only. Public Mod ID and
Lua namespace: `B47ANCEDKnowledgeAndWisdom`. Existing Workshop ID: `3792566496`.

`Contents/` is explicitly historical under the inherited project instructions.
`dist/` contains historical candidates, packages and staging backups. Existing
`SHA256SUMS.txt` and `.steamcmd-last-upload.sha256` remain historical provenance.
Artwork changes require user selection; the 0.14.1 PATCH iteration adopts the
user-supplied PNG unchanged for `preview.png` and the source authoring thumbnail.
The separate icon and historical packages retain their original bytes. Previous
artwork is recoverable from Git commit `45cd856`; see ARTWORK.md.
`docs/history/pre-b47-0.12.2/` preserves pre-rename documents with original names,
versions and claims. Never treat those records as validation of the renamed mod.

No current package exists. Future packaging must select the authoritative source
and produce a new `Contents/mods/B47ANCEDKnowledgeAndWisdom/42` layout in separate staging,
with matching version and provenance. Never reuse or overwrite historical staging
as an implicit part of renaming. No build, deploy or publish was authorized here.
`python scripts/check_versions.py --release` deliberately blocks G8 until current
artifacts, provenance and required dedicated MP evidence exist. It does not
validate or relabel old artifacts.

Gameplay G7 dedicated multiplayer is BLOCKED / NOT TESTED; stable G8 is BLOCKED.
Offline checks and SP evidence cannot replace G7. The user approved public
repository B47ANCE/B47ANCEDKnowledgeAndWisdom. Main records the audited 0.13.0
baseline (f615148); the repair branch is fix/authority-persistence-0.14.0. Inspect
freshness and audit the public tree before each commit/push. Record the actual
verified remote SHA and CI result with the iteration; no stable tag without G8.

Named VALIDATION_0_13_0.md, SOURCE_PROVENANCE_0_13_0.json and
RENAME_RETENTION_0_13_0.json remain historical evidence tied to that baseline.
Their old versions, hashes and pre-onboarding backup status are not rewritten.
Likewise, older native audit fingerprints are historical, not current API proof.

0.15.0 is a pre-1.0 MINOR iteration for recorded-journal inspection and its new
sandbox toggle, with fail-closed prerequisite/journal fixes. Schema remains 1;
Mod ID, Workshop ID, immutable storage/replay keys and artwork do not change.
Current version checks also cover IN_GAME_TESTING, IDENTITY_MIGRATION,
REPOSITORY_AUDIT, TESTING and ARCHITECTURE headings to prevent stale current docs.
Named 0.14.x validation/manifests remain historical evidence.
