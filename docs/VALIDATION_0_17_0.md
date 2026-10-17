# Dedicated knowledge validation

Version: 0.17.0

Environment: offline Windows / Python / Lupa 2.6 Lua 5.1. Native dedicated NOT TESTED. Source audit: Steam build 25485521 / packaged Core 42.21; effective runtime/class precedence UNKNOWN. No game/server, real saved data or live install touched.

Exact commands from repository root:

```sh
python scripts/check_versions.py
python scripts/validate_source.py
python scripts/run_host_tests.py
python scripts/check_public_tree.py --staged
git diff --check
```

Before edits, 0.16.0 passed 17 mirrors. The full host suite now passes 37/37 files, including private codec/knowledge/projection coverage for owned/cancelled reads, duplicate events, pending identity/retirement, account/slot separation, forged ModData, no grant RPC, stale replies, reconnect/restart, missing migration, world separation, silent failure and torn-tail refusal. The original no-backend MP refusal tests remain intact and the other guards stay closed. Static source validation passes 64 Lua 5.1 parses, exact-case imports, 87 translation/fallback files, 38 saved item types and Workshop mirrors. Current version/public-tree results are checked before commit; remote SHA/CI are verified with the PR. These are offline results only.

See DEDICATED_KNOWLEDGE.md for architecture, storage limits and native-first tests. Existing-world migration, broader progression/claims/journal/recovery/history implementation, native lifecycle and coordinated crash/backup behavior remain explicit gates. CAT integration is dropped; old item declarations/IDs remain inert compatibility data. G7 BLOCKED / NOT_TESTED; stable G8 BLOCKED. No deploy, upload, launch or stable tag.
