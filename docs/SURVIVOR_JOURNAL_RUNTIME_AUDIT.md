# Survivor Journal Runtime Adapter Audit

## Scope

This audit checks the installed Project Zomboid Build 42.20 runtime surface needed
to apply the raw-XP targets produced by `SurvivorJournals.recoveryPlan`.

The journal core stores absolute documented XP and produces a non-additive target.
The runtime adapter therefore needs to set or add the exact difference without
traits, sandbox multipliers, book multipliers, nutrition, or other progression
rules changing that difference. It must also leave the perk level consistent with
the restored XP.

## Installed-runtime findings

- `getXp():getXP(perk)` exposes the current absolute perk XP.
- `getXp():AddXP(perk, amount, false, false, false, false)` disables the normal
  XP-boost path and performs vanilla level-up/level-down recalculation.
- That six-argument call is still not a raw setter. Vanilla applies protein
  modifiers to Strength before the XP write and may reject Fitness XP based on
  nutrition state.
- `getXp():setXPToLevel(perk, level)` writes only the exact XP threshold for a
  whole level. It cannot preserve an arbitrary raw-XP target within a level and
  does not generally recalculate the character's perk level.
- The underlying XP map has no public exact-XP setter in the inspected runtime.

## Decision

Do not implement a native journal recovery adapter by treating `AddXP` as an
exact raw-XP operation. That would produce state-dependent recovery for Strength
and Fitness and violate the journal core's absolute, non-additive contract.

The existing core remains usable for capture, persistence, claims, discrete
knowledge recovery, and presentation. Raw-XP application remains fail-closed
until one of these is established:

1. a verified engine method that sets exact perk XP and reconciles levels;
2. an explicit product policy excluding or specially handling affected perks;
3. an authority-safe, tested compensation algorithm, including multiplayer
   replication and rollback semantics.

UI and timed-action work that commits XP recovery remains downstream of this
boundary. No runtime behavior was added by this audit.


## 0.16.0 audit follow-up

This preceding report remains historical. NATIVE_AUDIT_0_16_0.md and
NATIVE_EVIDENCE_0_16_0.json recheck the current packaged artifact and distinguish
loose overrides/effective runtime. Negative exact-XP, earned-recipe and transport
findings are now explicit; no native recovery adapter is enabled. See
AUDIT_CLOSURE_0_16_0.md and MP_AUTHORITY_PLAN.md for current dispositions.
