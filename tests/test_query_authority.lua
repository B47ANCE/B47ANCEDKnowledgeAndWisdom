local A=require "B47ANCEDKnowledgeAndWisdom/Progression"
local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local L=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local knowledge={schemaVersion=1,documents={old=true},knowledge={}}
local progression={schemaVersion=1,sources={},transactions={},nextTransaction=1}
local journal={schemaVersion=1,payloadId="old",authorId="author",documented={rawXP={},discrete={}},queue={},revision=0}
local data={[L.KNOWLEDGE_ROOT_KEY]=knowledge,[L.PROGRESSION_ROOT_KEY]=progression}
local itemData={[L.JOURNAL_ROOT_KEY]=journal}
local actor={getModData=function()return data end}
local item={getModData=function()return itemData end}
for _,client in ipairs({true,false})do
    isClient=function()return client end;isServer=function()return false end
    assert(A.hasRead(actor,"old")and A.snapshot(actor)and A.progressionSnapshot(actor)and J.snapshot(item))
    assert(data[L.KNOWLEDGE_ROOT_KEY]==knowledge and data[A.ROOT_KEY]==nil,"knowledge query must not move saved keys")
    assert(data[L.PROGRESSION_ROOT_KEY]==progression and data[A.PROGRESSION_ROOT_KEY]==nil,"progression query must not move saved keys")
    assert(itemData[L.JOURNAL_ROOT_KEY]==journal and itemData[J.ROOT_KEY]==nil,"item query must not move saved keys")
end
A.registerDocument{id="new",project="test",category="test",classification="open",title="New",content={"test"}}
isClient=function()return true end;isServer=function()return false end
assert(not A.learn(actor,"new")and data[L.KNOWLEDGE_ROOT_KEY]==knowledge)
assert(not L.moveTableKey(data,A.ROOT_KEY,L.KNOWLEDGE_ROOT_KEY),"migration helper must reject client mutation")
isClient=function()return false end;isServer=function()return false end
assert(A.learn(actor,"new"))
assert(data[A.ROOT_KEY]==knowledge and data[L.KNOWLEDGE_ROOT_KEY]==nil,"authority write must migrate validated knowledge")
assert(J.beginWriting(item,"author",{rawXP={Maintenance=5}},"next"))
assert(itemData[J.ROOT_KEY]==journal and itemData[L.JOURNAL_ROOT_KEY]==nil,"authority write must migrate validated item state")
local malformed={schemaVersion=99,documents={},knowledge={}}
local bad={[L.KNOWLEDGE_ROOT_KEY]=malformed}
assert(not A.learn({getModData=function()return bad end},"new"))
assert(bad[L.KNOWLEDGE_ROOT_KEY]==malformed and bad[A.ROOT_KEY]==nil,"failed validation must not migrate or repair data")
print("query authority and validated-write migration checks passed")
