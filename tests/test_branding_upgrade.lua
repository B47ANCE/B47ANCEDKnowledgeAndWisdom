-- Upgrade fixture came from the original 0.12.2 source, not the renamed code.
local fixture=dofile("tests/fixtures/knowledge_0_12_2.lua")
assert(fixture.version=="0.12.2")
isClient=function()return false end;isServer=function()return false end
local API=require "B47ANCEDKnowledgeAndWisdom/Progression"
local Claims=require "B47ANCEDKnowledgeAndWisdom/Claims"
local Journals=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local Legacy=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local data=fixture.character
local character={getModData=function()return data end,getUsername=function()return "fixture" end}
local knowledge=data[API.ROOT_KEY];local progression=data[API.PROGRESSION_ROOT_KEY]
local claims=data[Claims.ROOT_KEY]
API.registerKnowledge{id="fixture.known",owner="fixture",title="Known"}
API.registerDocument{id="fixture.read",project="fixture",category="test",classification="open",title="Fixture",
    content={"fixture"},itemType="B47ANCEDKnowledgeAndWisdom.CC_Manual_Backhoe",grantsKnowledge={"fixture.known"}}
assert(API.hasRead(character,"fixture.read")and API.hasKnowledge(character,"fixture.known"))
assert(API.getDocumentForItem("experienceWorks.CC_Manual_Backhoe").id=="fixture.read")
assert(API.getDocumentForItem("B47ANCEDKnowledgeAndWisdom.CC_Manual_Backhoe").id=="fixture.read")
assert(Legacy.canonicalItemType("Other.Book")=="Other.Book")
assert(Legacy.persistedItemType("B47ANCEDKnowledgeAndWisdom.NotRegistered")=="B47ANCEDKnowledgeAndWisdom.NotRegistered")
local count=#claims.order
local ok,result=API.completeRead(character,{getFullType=function()return "experienceWorks.CC_Manual_Backhoe" end},{worldAgeHours=10})
assert(ok and result.duplicate and result.claim.ok and #claims.order==count,
    "old literature replay must still match its full binding and never duplicate claims")
assert(data[API.ROOT_KEY]==knowledge and data[API.PROGRESSION_ROOT_KEY]==progression and data[Claims.ROOT_KEY]==claims,
    "renaming must reuse exact stored ledgers, never reset or fork them")
assert(API.progressionSnapshot(character).transactions["1"].status=="committed")
API.registerSemanticAction{id="fixture.action",owner="fixture",title="Action",baseXP=10,skills={Maintenance=1},
    outcomes={success=1},repeatWindowHours=24,repeatDecay=1,repeatFloor=.2}
local plan=assert(API.previewSemanticAction(character,"fixture.action",{committed=true,meaningful=true,
    outcome="success",sourceCategory="device",sourceId="one"},{worldAgeHours=7}))
assert(plan.repeatMultiplier==.5,"existing diminishing returns must survive")

local stores={[Legacy.STORAGE_CLAIM_STORE_KEY]=fixture.claims,[Legacy.STORAGE_HISTORY_KEY]=fixture.history}
ModData={get=function(key)return stores[key] end,getOrCreate=function(key)
    stores[key]=stores[key]or{};return stores[key]
end}
local journal={getModData=function()return fixture.journal end}
local before=assert(Journals.snapshot(journal))
local claimed,claimResult=Journals.claim(journal,"successor",{worldAgeHours=12,character=character})
assert(claimed and claimResult.duplicate and claimResult.knowledgeClaim.ok)
assert(not Journals.claim(journal,"different-successor"),"old single-successor lock must survive")
assert(Journals.snapshot(journal).documented.rawXP.Maintenance==before.documented.rawXP.Maintenance)
local History=require "B47ANCEDKnowledgeAndWisdom/HistoryServer"
assert(History.attachProductionStore())
History.registerEvidenceProvider{id="fixture",getActorId=function(actor)return actor.id end,
    validateEvidence=function()error("saved replay must not create a new record")end}
assert(History.create({id="author"},fixture.historyRequest))
assert(#History.list({id="author"}).records==1)
assert(select(2,History.create({id="stranger"},fixture.historyRequest))=="AUTHOR_MISMATCH")
assert(stores[Legacy.STORAGE_CLAIM_STORE_KEY]==fixture.claims and stores[History.STORE_KEY]==fixture.history)

assert(not Legacy.viewerEnabled({experienceWorks={EnableResearchViewer=false},B47ANCEDKnowledgeAndWisdom={EnableResearchViewer=true}}),
    "new sandbox default cannot re-enable a legacy disabled viewer")
assert(not Legacy.viewerEnabled({experianceWorks={EnableResearchViewer=false}}))
assert(not Legacy.viewerEnabled({B47ANCEDKnowledgeAndWisdom={EnableResearchViewer=false}}))
assert(Legacy.viewerEnabled({B47ANCEDKnowledgeAndWisdom={EnableResearchViewer=true}}))
assert(rawget(_G,"B47ANCEDKnowledgeAndWisdom")==API and rawget(_G,"experienceWorks")==nil)
assert(not pcall(require,"experienceWorks/API"),"there must be no second public namespace")
-- Repeated reload of the canonical API must retain state and one registry.
assert(require("B47ANCEDKnowledgeAndWisdom/Progression")==API)
package.loaded["B47ANCEDKnowledgeAndWisdom/Progression"]=nil
local reloaded=require "B47ANCEDKnowledgeAndWisdom/Progression"
assert(reloaded==API and reloaded.hasKnowledge(character,"fixture.known"))
assert(data[API.ROOT_KEY]==knowledge and #claims.order==count)
print("0.12.2 to B47ANCED Knowledge & Wisdom storage/replay upgrade checks passed (host only)")
