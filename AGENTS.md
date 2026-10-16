# Project Zomboid Codex startup

<!-- PZ-CODEX-MANAGED-STARTUP -->
Resolve USERPROFILE and read %USERPROFILE%/.codex/AGENTS.md before work.
Team skills are installed at %USERPROFILE%/.agents/skills.
Preserve project-specific identity, instructions, source, local settings and runtime evidence.
<!-- /PZ-CODEX-MANAGED-STARTUP -->

# Current project identity and source

B47ANCED Knowledge & Wisdom 0.14.1 uses Mod ID and Lua namespace
`B47ANCEDKnowledgeAndWisdom`. Canonical version: root `VERSION`.
Authoritative runtime source: `src/B47ANCEDKnowledgeAndWisdom/42`.
`Contents/`, `dist/`, and old checksum/upload records are historical, never the
current package. Do not build the earlier groundWorks candidate tooling against
this renamed source without a separate integration update.

Run `python scripts/check_versions.py`, `python scripts/validate_source.py`, and
`python scripts/run_host_tests.py` (Lupa Lua 5.1). See docs/VERSION_POLICY.md,
docs/IDENTITY_MIGRATION.md and docs/VALIDATION_0_14_1.md. Preserve immutable storage
keys, replay identities, old-save item types, and historical provenance.

The user approved public repository B47ANCE/B47ANCEDKnowledgeAndWisdom.
Work on fix/authority-persistence-0.14.0; main records the 0.13.0 audited baseline.
Use targeted staging and scripts/check_public_tree.py before public pushes.
Runtime results are supplied by the user; follow docs/RUNTIME_VALIDATION_0_14_0.md.
Do not infer native SP/dedicated evidence from host tests or CI. G7 and stable
G8 remain BLOCKED. No build, deploy or publish during repair work.
