local A=require "B47ANCEDKnowledgeAndWisdom/API"
A.registerDocument{id="audit",project="test",category="test",classification="open",title="Audit",content={"body"}}
local data={};local actor={getModData=function()return data end}
assert(not A.learn(actor,"audit",{worldAgeHours=0/0}),"non-finite learned time must not poison saved ledgers")
assert(next(data)==nil)
assert(not A.learn(actor,"audit",{sourceFullType={}})and next(data)==nil)
local function doc(values)
 local d={id="bad",project="test",category="test",classification="open",title="Bad",content={"body"}}
 for k,v in pairs(values)do d[k]=v end;return d
end
assert(not pcall(A.registerDocument,doc({prerequisiteDocuments={[1]="audit",[3]="missing"}})),"sparse legacy prerequisite lists must not drop requirements")
assert(not pcall(A.registerDocument,doc({distribution={Pool=math.huge}})),"infinite loot weights must be refused")
assert(not pcall(A.registerDocument,doc({content={{text="secret",redacted=true,marker={}}}})))
A.registerKnowledge{id="Audit.Known",owner="test",title="Known"}
A.registerDocument{id="grant",project="test",category="test",classification="open",title="Grant",content={"body"},grantsKnowledge={"Audit.Known"}}
A.KnowledgeDefinitions["Audit.Known"]=nil
local called,ok=pcall(A.learn,actor,"grant")
assert(called and not ok and next(data)==nil,"removed grant definitions must fail before save initialization")
print("Knowledge input/persistence and registry rejection checks passed")

A.registerDocument{id="context",project="test",category="test",classification="open",title="Context",content={"body"},itemType="Test.Context"}
local context={worldAgeHours=1};local book={getFullType=function()return "Test.Context"end}
assert(A.completeRead(actor,book,context)and context.sourceFullType==nil,"read completion must not mutate caller-owned context")
