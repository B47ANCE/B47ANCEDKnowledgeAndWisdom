isClient=function()return false end;isServer=function()return true end
package.loaded["B47ANCEDKnowledgeAndWisdom/API"]=nil;B47ANCEDKnowledgeAndWisdom=nil
require "B47ANCEDKnowledgeAndWisdom/API"
local History=dofile("src/B47ANCEDKnowledgeAndWisdom/42/media/lua/shared/B47ANCEDKnowledgeAndWisdom/HistoryRecords.lua")
assert(not History.attachStore({schemaVersion=9}));assert(History.attachStore({}))
local author={id="person:author"};local stranger={id="person:stranger"}
History.registerEvidenceProvider{id="fixture",getActorId=function(actor)return actor.id end,
    validateEvidence=function(_,subject,evidence)return subject=="person:dead"and evidence=="corpse:1",{kind="corpse",verified=true}end,
    canRead=function(actor,record)return record.groupId=="group:1"and actor.id=="person:member"end}
local request={schemaVersion=1,operationId="history:create:1",recordId="history:1",authorId="person:author",
    subjectId="person:dead",providerId="fixture",evidenceId="corpse:1",text="  Remembered\n survivor  ",
    visibility="private",removalPolicy="author",worldAgeHours=20}
local ok,reason,record=History.create(author,request);assert(ok and reason=="CREATED"and record.text=="Remembered survivor")
assert(History.create(author,request)and #assert(History.list(author)).records==1)
local collision={};for k,v in pairs(request)do collision[k]=v end;collision.recordId="history:2"
local replayOK,replayReason=History.create(author,collision);assert(not replayOK and replayReason=="OPERATION_ID_CONFLICT")
local textCollision={};for k,v in pairs(request)do textCollision[k]=v end;textCollision.text="Different memory"
assert(select(2,History.create(author,textCollision))=="OPERATION_ID_CONFLICT","replay must bind normalized content")
assert(select(2,History.create(stranger,request))=="AUTHOR_MISMATCH","replay must re-authenticate actor")
assert(#assert(History.list(stranger)).records==0,"private records must fail closed")
local removal={schemaVersion=1,operationId="history:remove:1",recordId="history:1",actorId="person:stranger",reason="requested"}
assert(not History.remove(stranger,removal));removal.actorId="person:author";assert(History.remove(author,removal))
local removalCollision={};for k,v in pairs(removal)do removalCollision[k]=v end;removalCollision.reason="different"
assert(select(2,History.remove(author,removalCollision))=="OPERATION_ID_CONFLICT","replay must bind removal reason")
assert(#assert(History.list(author)).records==0 and #assert(History.list(author,{includeRemoved=true})).records==1)
local legacyStore={records={},order={},operations={},operationOrder={}}
assert(History.attachStore(legacyStore));legacyStore.records["legacy:record"]={recordId="legacy:record",providerId="fixture",
    authorId="person:author",visibility="private",removed=false};legacyStore.order[1]="legacy:record"
legacyStore.operations["legacy:remove"]={action="remove",recordId="legacy:record",authorId="person:author",ok=true}
legacyStore.operationOrder[1]="legacy:remove"
assert(select(2,History.remove(author,{schemaVersion=1,operationId="legacy:remove",recordId="legacy:record",
    actorId="person:author",reason="test"}))=="OPERATION_REPLAY_UNVERIFIABLE")
print("test_history_records.lua: PASS")
