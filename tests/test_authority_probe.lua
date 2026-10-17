local A=require "B47ANCEDKnowledgeAndWisdom/Progression"
require "B47ANCEDKnowledgeAndWisdom/Claims"
local Probe=require "B47ANCEDKnowledgeAndWisdom/AuthorityProbe"
local L=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local old={schemaVersion=1,documents={private=true},knowledge={}}
local md={[L.KNOWLEDGE_ROOT_KEY]=old};local actor={getModData=function()return md end}
local report=assert(Probe.run(actor))
assert(report.ownedKeysUnchanged and md[L.KNOWLEDGE_ROOT_KEY]==old and not md[L.STORAGE_KNOWLEDGE_KEY])
assert(report.cases.knowledge.viewAvailable and not report.character and not report.snapshot)
local cycle={};cycle.self=cycle;md[L.KNOWLEDGE_ROOT_KEY]=cycle
assert(Probe.run(actor).ownedKeysUnchanged and md[L.KNOWLEDGE_ROOT_KEY]==cycle)
isServer=function()return true end;isClient=function()return false end
report=assert(Probe.run(actor));assert(report.ownedKeysUnchanged and not report.cases.knowledge.viewAvailable and not report.multiplayerGameplayAvailable)
isClient=function()return true end;isServer=function()return false end
assert(Probe.run(actor)==nil)
print("Opt-in query-purity probe, cycle preservation and no-private-output checks passed")
