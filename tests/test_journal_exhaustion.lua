local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local store={};J.setClaimStoreProvider(function()return store end)
local data={};local item={getModData=function()return data end}
local function copy(v)if type(v)~="table"then return v end;local r={};for k,x in pairs(v)do r[k]=copy(x)end;return r end
assert(J.beginWriting(item,"author",{rawXP={Maintenance=100}},"write"))
assert(J.advanceWriting(item,"author",9999));assert(J.claim(item,"successor"))
local cloned=copy(data);local clone={getModData=function()return cloned end}
assert(J.recoveryPlan(clone,"successor",{},.9))
assert(J.exhaust(item,"successor"))
assert(J.recoveryPlan(item,"successor",{})==nil)
assert(J.recoveryPlan(clone,"successor",{})==nil,"persistent exhaustion must reject a stale saved-item copy")
assert(not J.claim(clone,"successor"),"reclaim must reject globally exhausted payloads")
assert(not J.claim(clone,"other"))
-- A reload must reconsult persistent state, rather than trusting copied flags.
package.loaded["B47ANCEDKnowledgeAndWisdom/SurvivorJournals"]=nil
J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals";J.setClaimStoreProvider(function()return store end)
assert(J.recoveryPlan(clone,"successor",{})==nil)
store={};assert(J.recoveryPlan(clone,"successor",{})==nil,"missing authority records must fail closed")
isClient=function()return true end;isServer=function()return false end
assert(J.recoveryPlan(clone,"successor",{})==nil,"clients cannot authorize recovery")
print("persistent exhaustion, stale-copy, reload and missing-store checks passed")
