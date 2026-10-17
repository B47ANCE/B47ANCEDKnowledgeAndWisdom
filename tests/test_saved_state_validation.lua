local A=require "B47ANCEDKnowledgeAndWisdom/Progression"
local C=require "B47ANCEDKnowledgeAndWisdom/Claims"
local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local H=require "B47ANCEDKnowledgeAndWisdom/HistoryRecords"
local function reject(reader,key,value)
    local data={[key]=value};local actor={getModData=function()return data end,getUsername=function()return "test"end}
    local ok,result=pcall(reader,actor)
    assert(ok and result==nil,"malformed nested state must return an error, never throw or appear empty")
    assert(data[key]==value,"rejection must preserve the original saved object")
end
reject(C.snapshot,C.ROOT_KEY,{schemaVersion=1,claims={bad=true},order={"bad"},operations={},operationOrder={}})
reject(C.snapshot,C.ROOT_KEY,{schemaVersion=1,claims={},order={},operations={bad=false},operationOrder={"bad"}})
reject(C.snapshot,C.ROOT_KEY,{schemaVersion=1,claims={},order={"missing"},operations={},operationOrder={}})
reject(A.progressionSnapshot,A.PROGRESSION_ROOT_KEY,{schemaVersion=1,sources={},transactions={bad=true},nextTransaction=1})
reject(A.progressionSnapshot,A.PROGRESSION_ROOT_KEY,{schemaVersion=1,sources={bad=true},transactions={},nextTransaction=1})
reject(A.progressionSnapshot,A.PROGRESSION_ROOT_KEY,{schemaVersion=1,sources={},transactions={},nextTransaction=0/0})
reject(A.snapshot,A.ROOT_KEY,{schemaVersion=1,documents={bad=false},knowledge={}})
reject(J.snapshot,J.ROOT_KEY,{schemaVersion=1,documented={rawXP={},discrete={}},queue={},revision=0,recovery=true})
reject(J.snapshot,J.ROOT_KEY,{schemaVersion=1,documented={rawXP={},discrete={}},queue={false},revision=0})
local cycle={schemaVersion=1,documents={},knowledge={}};cycle.extra=cycle
reject(A.snapshot,A.ROOT_KEY,cycle)
for _,bad in ipairs({false,"preserve-me",7})do
    local saved={schemaVersion=1,records=bad,order={},operations={},operationOrder={}}
    assert(not H.attachStore(saved)and saved.records==bad,"history attachment must not overwrite malformed data")
end
local history={schemaVersion=1,records={valid={recordId="valid"}},order={},operations={},operationOrder={}}
assert(not H.attachStore(history)and history.records.valid.recordId=="valid","orphan/malformed history must remain untouched")
assert(H.attachStore({}),"genuinely fresh stores may initialize")
local old=dofile("tests/fixtures/knowledge_0_12_2.lua")
assert(H.attachStore(old.history),"original schema-1 history must remain readable")
local untouched={};local actor={getModData=function()return untouched end,getUsername=function()return "test"end}
local invalid={schemaVersion=1,operationId="invalid:op",claimId="invalid:claim",definitionId="unknown",
    subjectId="getUsername:test",sourceType="test",sourceId="test",sourceOwner="test",scope={}}
assert(not C.grant(actor,invalid))
assert(untouched[C.ROOT_KEY]==nil,"invalid grant must not initialize a saved ledger")
assert(not C.revoke(actor,{schemaVersion=1,operationId="invalid:revoke",claimId="missing",subjectId="getUsername:test",reason="test"}))
assert(untouched[C.ROOT_KEY]==nil,"invalid revocation must not initialize a saved ledger")
print("nested schema validation, cycle rejection and data preservation checks passed")
