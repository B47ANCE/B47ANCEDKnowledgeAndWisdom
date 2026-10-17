# Installed XP audit — 2026-08-26

Evidence: locally installed `projectzomboid.jar`, SHA-256
`BDA809FB49004A07DBFC560D059C0EE58D0643AB0F33B53351B13BD62F1D8227`.
Inspected `IsoGameCharacter$XP` and `LuaManager$Exposer` using CFR 0.152 in a
temporary directory. No decompiled implementation is distributed in the mod.
This is static evidence, not a multiplayer/runtime test.

## Confirmed findings

| Native method | Observed behavior | Journal consequence |
| --- | --- | --- |
| `getXP(perk)` | Reads stored perk XP | Candidate snapshot query; authority still required |
| `AddXP(perk, amount)` | Local-player guard; delegates with XP boosts enabled | Not raw restoration or a generic server award path |
| `AddXPNoMultiplier(perk, amount)` | Temporarily removes the book multiplier entry, invokes ordinary AddXP, restores entry | NOT a universal multiplier bypass; reject for journal restoration |
| `AddXP(perk, amount, noMultiplier)` | Local-player guard; controls doXPBoost in full overload | Still not guaranteed raw XP, especially passive skills |
| Full AddXP overload | doXPBoost gates profession/trait/book/sandbox factors; Strength nutrition adjustment precedes that gate; Fitness eligibility and sleeping checks also precede it | Disabling boost does not prove exact recovery for all perks |
| `setXPToLevel(perk, level)` | Writes the level threshold into the XP map; debug Fitness special case | Loses partial progress and is not a general level-reconciliation operation |

The full AddXP path clamps to the perk's level-10 total, updates levels by crossing
thresholds, adjusts Fitness stats, and can emit the AddXP event on non-clients.
Do not infer that its `callLua` or `remote` argument names suppress every side
effect: inspect actual usage rather than relying on parameter labels.

LuaManager's exposer explicitly registers `IsoGameCharacter.XP`. Class exposure
supports API availability but does not prove safe overload selection or network
authority. Current mods that alter caps/curves may change valid behavior.

## Decision

No journal recovery mutation is implemented yet. A verified raw target setter
plus level/stat reconciliation and explicit network synchronization is still
required. Do not compensate by multiplying/dividing guesses, temporarily editing
nutrition, or granting ordinary action XP to approximate restoration.

Next inspect native XP map access, admin/packet XP paths and perk-level setters;
then test fractional levels, passive perks, boosts, sleep, caps, custom perks,
server authority and replication. Existing ordinary vanilla XP remains untouched.

## Global functions and packet follow-up

The Lua global **`addXpNoMultiplier`** is distinct from the XP object's
**`AddXPNoMultiplier`**. Installed GlobalObject code rejects players outside the
world, routes server calls to GameServer.addXp with its bypass flag, and uses the
full doXPBoost=false overload in single-player. It does nothing on ordinary
clients. Passive-skill nutrition/eligibility caveats still apply; it is not yet
approved as an exact general restoration primitive.

`addXp` similarly routes server awards to GameServer and single-player awards
to the ordinary XP method. This is stronger evidence for semantic action awards
than invoking the local-player-only XP overload on the server.

`PlayerXpPacket` serializes the player's entire XP object and loads that state on
parse. Its packet annotation requires CanModifyPlayerStatsInThePlayerStatsUI.
Do not repurpose this admin-oriented whole-state packet as client-submitted
journal authority. Sender validation, routing and GameServer award implementation
still require review. Native XP exposes an xpMap field, but public Java field
visibility alone does not prove a safe Lua write/reconciliation contract.

The generated signature/call-site inventory lives in
`../../medWorks/docs/audit/native-api.csv`; its manifest fingerprints inspected
Lua/native-source inputs. It is an audit aid, not a completed behavior matrix.

## 0.16.0 audit follow-up

This preceding report remains historical. NATIVE_AUDIT_0_16_0.md and
NATIVE_EVIDENCE_0_16_0.json recheck the current packaged artifact and distinguish
loose overrides/effective runtime. Negative exact-XP, earned-recipe and transport
findings are now explicit; no native recovery adapter is enabled. See
AUDIT_CLOSURE_0_16_0.md and MP_AUTHORITY_PLAN.md for current dispositions.
