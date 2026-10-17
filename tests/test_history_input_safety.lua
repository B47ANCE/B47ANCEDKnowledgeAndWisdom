local H=require "B47ANCEDKnowledgeAndWisdom/HistoryRecords"
local store={};assert(H.attachStore(store))
local evidence=function()end
H.registerEvidenceProvider{id="audit",getActorId=function()return "author"end,validateEvidence=function()return true,evidence end}
local request={schemaVersion=1,operationId="one",recordId="record",authorId="author",subjectId="subject",providerId="audit",evidenceId="evidence",text="Remembered",visibility="private"}
assert(not H.create({},request)and next(store.records)==nil,"unsupported evidence must not poison a history store")
evidence={verified=true};request.groupId=string.rep("x",70000)
assert(not H.create({},request)and next(store.operations)==nil,"oversized bound fields cannot poison replay history")
request.groupId=nil;assert(H.create({},request))
local revision=store.operations.one
assert(not H.remove({},{schemaVersion=1,operationId="remove",recordId="record",actorId="author",reason=string.rep("x",70000)}))
assert(store.operations.one==revision and not store.records.record.removed)
print("History binding/evidence rejection preserves saved store checks passed")
