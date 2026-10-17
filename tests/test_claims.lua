local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
isClient=function()return false end;isServer=function()return false end
package.loaded["B47ANCEDKnowledgeAndWisdom/API"]=nil;B47ANCEDKnowledgeAndWisdom=nil
local API=require "B47ANCEDKnowledgeAndWisdom/API"
local Claims=dofile("src/B47ANCEDKnowledgeAndWisdom/42/media/lua/shared/B47ANCEDKnowledgeAndWisdom/Claims.lua")
local transmitted=0;local character={data={}}
function character:getModData()return self.data end
function character:getUsername()return "alice" end
function character:transmitModData()transmitted=transmitted+1 end
Claims.registerDefinition{id="B47ANCEDKnowledgeAndWisdom.ReadBook",owner="B47ANCEDKnowledgeAndWisdom",kind="literature",title="Read book",
    acquisition="read",scopeFields={"itemType"}}
assert(Claims.getDefinition("B47ANCEDKnowledgeAndWisdom.ReadBook").scopeFields[1]=="itemType")
Claims.registerRegion{id="rosewood",owner="B47ANCEDKnowledgeAndWisdom",granularity="locality",title="Rosewood"}
local request={schemaVersion=1,operationId="claim:op:1",claimId="claim:book:1",definitionId="B47ANCEDKnowledgeAndWisdom.ReadBook",
    subjectId="getUsername:alice",sourceType="item",sourceId="Base.Book",sourceOwner="B47ANCEDKnowledgeAndWisdom",
    scope={itemType="Base.Book"},confidence=.9,completeness=1,worldAgeHours=12}
local ok,reason,claim=Claims.grant(character,request)
assert(ok and reason=="GRANTED" and claim.scope.itemType=="Base.Book")
assert(Claims.grant(character,request) and transmitted==0,"replay must not retransmit")
local collision={};for key,value in pairs(request)do collision[key]=value end;collision.claimId="claim:other"
local replayOK,replayReason=Claims.grant(character,collision);assert(not replayOK and replayReason=="OPERATION_ID_CONFLICT")
local sourceCollision={};for key,value in pairs(request)do sourceCollision[key]=value end;sourceCollision.sourceId="Base.OtherBook"
assert(select(2,Claims.grant(character,sourceCollision))=="OPERATION_ID_CONFLICT","replay must bind source")
local confidenceCollision={};for key,value in pairs(request)do confidenceCollision[key]=value end;confidenceCollision.confidence=.2
assert(select(2,Claims.grant(character,confidenceCollision))=="OPERATION_ID_CONFLICT","replay must bind confidence")
local scopeCollision={};for key,value in pairs(request)do scopeCollision[key]=value end;scopeCollision.scope={itemType="Base.OtherBook"}
assert(select(2,Claims.grant(character,scopeCollision))=="OPERATION_ID_CONFLICT","replay must bind scope")
local duplicateChanged={};for key,value in pairs(request)do duplicateChanged[key]=value end
duplicateChanged.operationId="claim:op:changed";duplicateChanged.confidence=.2
assert(select(2,Claims.grant(character,duplicateChanged))=="CLAIM_ID_CONFLICT","claim identity must bind immutable facts")
local hometown={};for key,value in pairs(request)do hometown[key]=value end
hometown.operationId="claim:op:2";hometown.claimId="claim:home:1";hometown.definitionId=LegacyMigration.HOMETOWN_DEFINITION
hometown.sourceType="background";hometown.sourceId="origin:rosewood";hometown.scope={regionId="rosewood",granularity="locality"}
hometown.sourceOwner=LegacyMigration.PERSISTED_OWNER
assert(Claims.grant(character,hometown))
local bad={};for key,value in pairs(hometown)do bad[key]=value end
bad.operationId="claim:op:bad";bad.claimId="claim:bad:1";bad.scope={regionId="rosewood",granularity="region"}
assert(not Claims.grant(character,bad),"geography cannot silently widen granularity")
bad.operationId="claim:op:unknown";bad.claimId="claim:bad:2";bad.scope={regionId="unknown",granularity="locality"}
assert(not Claims.grant(character,bad),"unregistered regions cannot become knowledge")
local snapshot=assert(Claims.snapshot(character,{maximum=1}));assert(#snapshot.claims==1 and snapshot.limited)
local revoke={schemaVersion=1,operationId="claim:revoke:1",claimId="claim:book:1",subjectId="getUsername:alice",
    reason="source-invalidated",worldAgeHours=13}
assert(Claims.revoke(character,revoke));assert(#assert(Claims.snapshot(character)).claims==1)
local revokeCollision={};for key,value in pairs(revoke)do revokeCollision[key]=value end;revokeCollision.reason="different"
assert(select(2,Claims.revoke(character,revokeCollision))=="OPERATION_ID_CONFLICT","replay must bind revocation reason")
character.data[Claims.ROOT_KEY].operations["legacy:op"]={action="grant",claimId=request.claimId,
    definitionId=request.definitionId,subjectId=request.subjectId,ok=true,reason="GRANTED"}
table.insert(character.data[Claims.ROOT_KEY].operationOrder,"legacy:op")
local legacy={};for key,value in pairs(request)do legacy[key]=value end;legacy.operationId="legacy:op"
assert(select(2,Claims.grant(character,legacy))=="OPERATION_REPLAY_UNVERIFIABLE",
    "legacy operations without a full binding must fail closed")
assert(#assert(Claims.snapshot(character,{includeRevoked=true})).claims==2)
API.registerKnowledge{id="B47ANCEDKnowledgeAndWisdom.ClaimTest",owner="B47ANCEDKnowledgeAndWisdom",title="Claim test"}
API.registerDocument{id="CLAIM-DOC",project="Test",category="Test",classification="Open",title="Claim document",
    content={"test"},itemType="Base.ClaimBook",grantsKnowledge={"B47ANCEDKnowledgeAndWisdom.ClaimTest"}}
local item={getFullType=function()return "Base.ClaimBook" end}
local readOK,readResult=API.completeRead(character,item,{worldAgeHours=14})
assert(readOK and readResult.claim.ok and readResult.claim.value.kind=="literature")
local afterRead=assert(Claims.snapshot(character,{includeRevoked=true}));assert(#afterRead.claims==3)
local oversized={data={},getModData=character.getModData,getUsername=function()return string.rep("a",160)end,
    getSteamID=function()return "76561198000000000"end}
local oversizedRequest={};for key,value in pairs(request)do oversizedRequest[key]=value end
oversizedRequest.operationId="claim:op:oversized";oversizedRequest.claimId="claim:oversized"
oversizedRequest.subjectId="getSteamID:76561198000000000"
local oversizedOK,oversizedReason=Claims.grant(oversized,oversizedRequest)
assert(oversizedOK and oversizedReason=="GRANTED","overlong prefixed username must fall through to a bounded identity")
local Origin=require "B47ANCEDKnowledgeAndWisdom/OriginKnowledge"
Origin.registerProvider{id="external.origin.fixture",owner="mapFixture",observe=function()
    return{originId="rosewood-start",regionId="rosewood",evidenceId="creation:rosewood"}end}
local originOK,originReason,originClaim=Origin.grant(character,{worldAgeHours=15})
assert(originOK and originReason=="GRANTED"and originClaim.source.owner==LegacyMigration.PERSISTED_OWNER,
    "external evidence must retain immutable hometown-claim ownership")
character.data[Claims.ROOT_KEY]={schemaVersion=99}
assert(Claims.snapshot(character)==nil,"future schemas must be preserved and fail closed")
print("test_claims.lua: PASS")
