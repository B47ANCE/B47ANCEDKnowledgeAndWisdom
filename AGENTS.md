# Project Zomboid Codex startup

<!-- PZ-CODEX-MANAGED-STARTUP -->
Resolve USERPROFILE and read %USERPROFILE%/.codex/AGENTS.md before work.
Team skills are installed at %USERPROFILE%/.agents/skills.
Preserve project-specific identity, instructions, source, local settings and runtime evidence.
<!-- /PZ-CODEX-MANAGED-STARTUP -->

# Current project identity and source

B47ANCED Knowledge & Wisdom 0.17.0 uses Mod ID and Lua namespace
`B47ANCEDKnowledgeAndWisdom`. Canonical version: root `VERSION`.
Authoritative runtime source: `src/B47ANCEDKnowledgeAndWisdom/42`.
`Contents/`, `dist/`, and old checksum/upload records are historical, never the
current package. Do not build the earlier groundWorks candidate tooling against
this renamed source without a separate integration update.

Run `python scripts/check_versions.py`, `python scripts/validate_source.py`, and
`python scripts/run_host_tests.py` (Lupa Lua 5.1). See docs/VERSION_POLICY.md,
docs/IDENTITY_MIGRATION.md and docs/VALIDATION_0_16_0.md. Preserve immutable storage
keys, replay identities, old-save item types, and historical provenance.

The user approved public repository B47ANCE/B47ANCEDKnowledgeAndWisdom.
Work on fix/authority-persistence-0.14.0; main records the 0.13.0 audited baseline.
Use targeted staging and scripts/check_public_tree.py before public pushes.
Runtime results are supplied by the user; follow docs/RUNTIME_VALIDATION_0_14_0.md.
Do not infer native SP/dedicated evidence from host tests or CI. G7 and stable
G8 remain BLOCKED. No build, deploy or publish during repair work.

0.16.0 native audit found player ModData replacement/broadcast and request-readable
GlobalModData. AuthorityGuard intentionally blocks affected MP APIs; never add a
sandbox bypass or claim an MP pass from these offline tests. Preserve historical
stores; private migration requires the MP_AUTHORITY_PLAN.md contract. The opt-in
AuthorityProbe is read-only and grants no validation/release gate.

## Dedicated document knowledge (0.17.0)

Dedicated is the first native target; SP is never a prerequisite. Read docs/DEDICATED_KNOWLEDGE.md and docs/MP_TEST_CONTRACT.json. The private backend enables document/knowledge only for fresh worlds/server-created lives. Never broaden that exception to progression, claims, journal/recovery, XP or history. Preserve all other guards, immutable old keys, uncertain/corrupt storage and historical evidence. Native G7 and stable G8 remain blocked.

Current branch feat/dedicated-knowledge-0.17.0 starts from merged main 0f20ad2; earlier branch/main descriptions above are historical. Maintain reviewed docs/MOD_OVERVIEW.json with current version/source digest. CAT integration is dropped; saved item declarations/aliases remain inert compatibility data. No build, install, launch or upload is performed by the source checks.

Authorized 2026-10-18 matching MP-test publication: read docs/WORKSHOP_0.17.0.md and docs/MP_TEST_BUILD_SET.json. Source PRs are merged; earlier no-package/upload statements are historical task limits. Preserve merged runtime bytes, fixed existing item identity/visibility and all prior artifacts. G7/stable G8 remain blocked. Never run a wrapper that restarts Steam; ask separately after successful uploads.
