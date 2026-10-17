local A=require "B47ANCEDKnowledgeAndWisdom/Progression"
local C=require "B47ANCEDKnowledgeAndWisdom/Claims"
local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local H=require "B47ANCEDKnowledgeAndWisdom/HistoryRecords"
local data={};local calls=0
local actor={getModData=function()return data end,getUsername=function()return "fixture"end,transmitModData=function()calls=calls+1 end}
A.registerDocument{id="fixture",project="test",category="test",classification="open",title="Fixture",content={"body"}}
A.registerSemanticAction{id="Audit.Action",owner="test",title="Audit",baseXP=1,skills={Maintenance=1}}
isClient=function()return false end;isServer=function()return true end
assert(not A.learn(actor,"fixture"),"MP must not write client-replaceable character ModData")
assert(A.snapshot(actor)==nil and not A.hasRead(actor,"fixture"),"server requirements must not trust native player ModData")
assert(A.progressionSnapshot(actor)==nil and not A.processSemanticAction(actor,"Audit.Action",{committed=true,meaningful=true}))
assert(C.snapshot(actor)==nil)
assert(not H.attachStore({}),"MP history must not attach request-readable GlobalModData as a private store")
local itemData={};local item={getModData=function()return itemData end}
assert(not J.beginWriting(item,"author",{rawXP={Maintenance=10}},"op"),"MP journal mutation needs a verified payload anchor")
assert(next(data)==nil and next(itemData)==nil and calls==0)
-- SP remains functional and never invokes the whole-table broadcaster.
isServer=function()return false end
assert(A.learn(actor,"fixture")and A.hasRead(actor,"fixture")and calls==0)
print("MP storage boundary and SP no-broadcast checks passed")

isClient=nil;isServer=nil
assert(not A.learn(actor,"fixture")and A.snapshot(actor)==nil,"unknown realm must fail closed, not become SP authority")
assert(require("B47ANCEDKnowledgeAndWisdom/Config").gameplay()==nil)
