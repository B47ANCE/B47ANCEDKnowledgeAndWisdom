# Installed recipe knowledge audit

2026-08-26. Static inspection of installed ISReadABook.lua and locally decompiled
IsoGameCharacter. Native JAR fingerprint and method are recorded in
NATIVE_XP_AUDIT.md. No vanilla implementation is included in the mod.

## Verified distinctions

| Native surface | Observed behavior | Framework consequence |
| --- | --- | --- |
| getKnownRecipes() | Returns the character's explicit known-recipe list | Candidate learned-state snapshot; do not replace with all craftable recipes |
| isRecipeKnown(Recipe) | Debug/visibility settings can return true; otherwise checks original recipe name | UI visibility is not proof of earned knowledge |
| isRecipeKnown(CraftRecipe, ignoreSandbox) | Accepts unlearned-not-required recipes, name, meta-recipe or translation-name entries; know-all also bypasses | Craft availability is not the same as an explicit learned record |
| isRecipeKnown(String, ignoreSandbox) | Resolves a legacy Recipe first; that branch delegates to its ordinary overload | Do not assume ignoreSandbox uniformly bypasses visibility across overloads |
| isRecipeActuallyKnown | Delegates to corresponding ignoreSandbox overload | Name alone does not prove strict membership or exclude debug know-all |
| learnRecipe(name, checkMetaRecipe) | Adds when its known check fails, optionally invokes ScriptManager.checkMetaRecipe | Use verified native grant semantics, then verify result; false can mean already known |
| ReadLiterature | Iterates literature recipe names, uses learnRecipe; consume-on-read items may be used | Reuse vanilla reading; don't independently replay the same recipe/consumption work |

ISReadABook.complete records recipe-bearing books in alreadyReadBook, delegates
literature effects, handles item ModData learnedRecipe, literature title and print
media, then synchronizes player fields with mask 0x00000007 (recipes, traits,
already-read books) and item fields. This is an observed vanilla action path,
not approval to reuse that mask for all knowledge subsystem state.

## Design implications

Keep explicit learned recipe IDs separate from skill-gated availability,
auto-learning, visibility cheats and meta-recipe implications. Journal snapshots
must not enumerate every visible craft and mark it permanently learned. Native
recipe ownership remains authoritative; knowledge subsystem adds provenance only.

Recipe restoration should be idempotent and must not rerun literature mood,
consumption or book multiplier effects. A callback returning false is not alone
proof of failure; compare authoritative membership and applicable meta-recipe
state. Unknown IDs from removed mods need preservation/diagnostics rather than
guessed translation or deletion.

## Open checks before implementation

- ScriptManager meta-recipe expansion, current craft recipe auto-learning and
  actual required-skill eligibility paths.
- Profession/trait recipe initialization and native save/load of known recipes.
- Player-field packet authority, recipients, persistence and reconnect behavior.
- Behavior with visibility/debug settings and legacy-vs-CraftRecipe name overlap.
- Read media recipe grants and recipes recovered from partially written journals.
- Native and modded recipes after rename/removal, plus duplicate restoration.

No recipe-restoration runtime is added by this audit. The overloaded known checks
are a concrete reason to finish native verification before coding recovery.

## 0.16.0 audit follow-up

This preceding report remains historical. NATIVE_AUDIT_0_16_0.md and
NATIVE_EVIDENCE_0_16_0.json recheck the current packaged artifact and distinguish
loose overrides/effective runtime. Negative exact-XP, earned-recipe and transport
findings are now explicit; no native recovery adapter is enabled. See
AUDIT_CLOSURE_0_16_0.md and MP_AUTHORITY_PLAN.md for current dispositions.
