# B47ANCEDKnowledgeAndWisdom 0.17.0 Workshop MP testing preparation

The user authorized merging Knowledge, MORTIS and Nightfall in dependency order
and publishing matching existing Workshop items on 2026-10-18 America/Phoenix.
Source PRs are merged: Knowledge #2, MORTIS #17, Nightfall #9 then #10.
Merged runtime commit: `368a447545e3448a40392e036450e2d161da696e`. This publication follow-up preserves
those runtime bytes and existing schemas, authority, research and category rules.
The version stays 0.17.0: metadata/tooling preparation for the still-unpackaged
iteration, not a gameplay change or stable-release approval.

MP testing build - dedicated multiplayer NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
Build 42 minimum declaration 42.20.3; local evidence Steam build 25485521.
Exact executed native version remains UNKNOWN / NOT TESTED. The known normal
launcher has unrelated non-Lua alterations; it is not an acceptance baseline.

## Matching source selection

[Build-set inventory](MP_TEST_BUILD_SET.json) pins the exact three merged runtime
inputs, versions and existing Workshop identities. Metadata follow-ups do not
turn prior evidence into current runtime proof. Knowledge private documents are
for fresh disposable dedicated worlds/server-created lives only. Existing-world
migration, progression, claims, journal recovery, XP and history remain guarded.
Three effigy models/rendering and other documented Nightfall gates remain open.
All server/client copies must match; other existing Nightfall dependency IDs stay
unchanged. No local deployment, server changes, native launch or stable tag.

## Packaging and upload boundary

Use only authoritative src/ source and supplied art. Preserve all earlier
Contents, packages, backups and receipts; no cleanup. Each candidate is verified
for exact inventory/bytes, SHA-256, CRC, safe paths/types/case and Lua-only payload.
Description and current changenote contain the required MP-test label and known
limits, real paragraphs and public source link. Use fixed existing item
3792566496 / App 108600; omit visibility changes and never create an item.
Each pre-upload receipt binds actual release SHA, package/source/text/preview
hashes, exact validation evidence and attempt outcome. Existing cached SteamCMD
authentication only; no credential in source/log reports. Actual SteamCMD success
and public-page verification are distinct; subscription/native acceptance remain
human / NOT TESTED. Steam desktop restart needs a new explicit confirmation
after upload success; upload scripts have no restart stage.

Offline validation and exact-head CI results will be recorded in the publication
PR and receipt. This preparation document itself does not claim upload success.

## Current offline evidence

[TESTED: Windows / Python 3.12.14 / Lupa 2.6 Lua 5.1] 37 Lua host files, 4 Python packaging tests, 64 source/test Lua parses, 87 localization catalogs, 38 item definitions, 23 current version mirrors and 122 current runtime provenance hashes PASS.

```text
python scripts/check_versions.py
python scripts/validate_source.py
python scripts/run_host_tests.py
python -m unittest discover -s tests -p "test_*.py"
python scripts/check_public_tree.py --staged
python scripts/prepare_workshop.py --output dist/workshop-mp-test/<selected-commit>
python scripts/prepare_workshop.py --output dist/workshop-mp-test/<selected-commit> --verify
git -c core.autocrlf=false diff --cached --check
```

Packaging verification and actual upload success are recorded only after execution. Exact-head CI results and final SHA are recorded in the publication PR. All G7/stable G8 native gates remain blocked.
