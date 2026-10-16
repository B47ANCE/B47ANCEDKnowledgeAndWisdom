local A=require "B47ANCEDKnowledgeAndWisdom/API"
local C=require "B47ANCEDKnowledgeAndWisdom/Claims"
local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local O=require "B47ANCEDKnowledgeAndWisdom/OriginKnowledge"
local L=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local data={};local actor={getModData=function()return data end,getUsername=function()return "alice"end}
A.registerDocument{id="audit.doc",project="test",category="test",classification="open",title="Book",content={"x"},itemType="Test.Book"}
local item={getFullType=function()return "Test.Book"end}
local ok,first=A.completeRead(actor,item,{worldAgeHours=10});assert(ok and first.claim.ok)
local ok2,second=A.completeRead(actor,item,{worldAgeHours=11})
assert(ok2 and second.duplicate and second.claim.ok,"later legitimate reading must retain the original acquisition")
assert(second.claim.value.acquiredAtWorldAgeHours==10)
local stored=data[C.ROOT_KEY].claims[first.claim.value.claimId]
local direct={schemaVersion=1,operationId="read:getUsername:alice:audit.doc",claimId=stored.claimId,
    definitionId=L.LITERATURE_DEFINITION,subjectId="getUsername:alice",sourceType="document",sourceId="audit.doc",
    sourceOwner=L.PERSISTED_OWNER,scope={documentId="audit.doc",itemType="Test.Book"},acquisition="read-completion",
    confidence=1,completeness=1,worldAgeHours=11}
assert(select(2,C.grant(actor,direct))=="OPERATION_ID_CONFLICT","direct request binding must still include time")
direct.worldAgeHours=10;direct.sourceId="changed"
assert(select(2,C.grant(actor,direct))=="OPERATION_ID_CONFLICT","changed evidence must still fail closed")
local claims={};J.setClaimStoreProvider(function()return claims end)
local journalData={};local journal={getModData=function()return journalData end}
assert(J.beginWriting(journal,"author",{rawXP={Maintenance=10}},"write"));assert(J.advanceWriting(journal,"author",9999))
local claimed,r=J.claim(journal,"successor",{worldAgeHours=12,character=actor});assert(claimed and r.knowledgeClaim.ok)
local claimedAgain,r2=J.claim(journal,"successor",{worldAgeHours=13,character=actor})
assert(claimedAgain and r2.duplicate and r2.knowledgeClaim.ok)
C.registerRegion{id="home",owner="test",granularity="locality"}
O.registerProvider{id="test.origin",observe=function()return {originId="one",regionId="home",evidenceId="creation:one"}end}
assert(O.grant(actor,{worldAgeHours=14}));assert(O.grant(actor,{worldAgeHours=15}))
for _,method in ipairs({"empty","nil","throws","false"})do
    local value={getUsername=function()
        if method=="throws"then error("unavailable")end
        if method=="empty"then return ""end
        if method=="false"then return false end
    end,getSteamID=function()return "76561198000000000"end}
    assert(C.subjectId(value)=="getSteamID:76561198000000000","invalid raw username must fall through")
end
assert(C.subjectId({getSteamID=function()return 0 end,getOnlineID=function()return -1 end})==nil)
assert(C.subjectId({getOnlineID=function()return 0 end})=="getOnlineID:0")
print("logical acquisition replay, strict direct binding and identity fallback checks passed")
