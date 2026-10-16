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

Authoritative runtime root: `src/B47ANCEDKnowledgeAndWisdom/42`. Parent `info.txt` is
authoring metadata. Tests and scripts are development-only. Public Mod ID and
Lua namespace: `B47ANCEDKnowledgeAndWisdom`. Existing Workshop ID: `3792566496`.

`Contents/` is explicitly historical under the inherited project instructions.
`dist/` contains historical candidates, packages and staging backups. Existing
`SHA256SUMS.txt` and `.steamcmd-last-upload.sha256` remain historical provenance.
`preview.png` and manually supplied source artwork retain their original bytes.
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
Offline checks and SP evidence cannot replace G7. GitHub iteration requirements
remain applicable, but this folder is not a Git checkout and no remote was
provided. This iteration is NOT BACKED UP TO GITHUB; onboarding must verify the
destination with the user before creating/configuring a public repository.
