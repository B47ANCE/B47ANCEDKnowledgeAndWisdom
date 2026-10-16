package.loaded["B47ANCEDKnowledgeAndWisdom/API"]=nil
_G.B47ANCEDKnowledgeAndWisdom=nil
local API=require "B47ANCEDKnowledgeAndWisdom/API"
API.registerKnowledge{id="Test.Knowledge",owner="Test",title="Test Knowledge"}
API.registerDocument{id="TEST-001",project="Test",category="FIELD",classification="SECRET",title="Test",tier=2,itemType="Test.Research",distribution={LaboratoryBooks=.1},spawnCategories={"lab"},grantsKnowledge={"Test.Knowledge"},content={"Visible ",{text="hidden fact",redacted=true,marker="â–ˆâ–ˆâ–ˆâ–ˆ"}}}
assert(API.renderDocument("TEST-001",false)=="Visible â–ˆâ–ˆâ–ˆâ–ˆ")
assert(API.renderDocument("TEST-001",true)=="Visible hidden fact")
API.registerDocument{id="TEST-DEFAULT-REDACTION",project="Test",category="Test",classification="SECRET",title="Unicode",
    content={{text="hidden",redacted=true}}}
assert(API.renderDocument("TEST-DEFAULT-REDACTION",false)=="████████","default redaction glyphs must remain UTF-8 intact")
local character={modData={}}; function character:getModData() return self.modData end
local item={getFullType=function() return "Test.Research" end}
assert(API.canLearn(character,"TEST-001"))
assert(not API.hasRead(character,"TEST-001") and not API.hasKnowledge(character,"Test.Knowledge"))
assert(API.snapshot(character).schemaVersion==1 and next(character.modData)==nil)
for _,bad in ipairs({false,"invalid",7,{schemaVersion=2,documents={},knowledge={}},
    {schemaVersion=1,documents="bad",knowledge={}}}) do
    character.modData[API.ROOT_KEY]=bad
    assert(API.hasRead(character,"TEST-001")==false)
    assert(API.hasKnowledge(character,"Test.Knowledge")==false)
    assert(API.canLearn(character,"TEST-001")==false)
    assert(API.learn(character,"TEST-001")==false)
    local snapshot,err=API.snapshot(character)
    assert(snapshot==nil and err)
    assert(character.modData[API.ROOT_KEY]==bad)
end
character.modData={}
assert(API.getDocumentForItem(item).id=="TEST-001")
local distributions={list={LaboratoryBooks={items={"Base.Book",1}}}}
local added,missing=API.applyDistributions(distributions)
assert(added==1 and #missing==0 and distributions.list.LaboratoryBooks.items[3]=="Test.Research")
assert(API.applyDistributions(distributions)==0)
local ok,result=API.completeRead(character,item,{worldAgeHours=10})
assert(ok and not result.duplicate and API.hasKnowledge(character,"Test.Knowledge"))
ok,result=API.learn(character,"TEST-001",{worldAgeHours=11})
assert(ok and result.duplicate and #result.newKnowledge==0)
API.registerKnowledge{id="Test.Alternative",owner="Test",title="Alternative"}
API.registerDocument{id="TEST-REQ",project="Test",category="FIELD",classification="SECRET",title="Requirements",content={"x"},requirements={any={{knowledge="Test.Alternative"},{all={{document="TEST-001"},{["not"]={knowledge="Test.Alternative"}}}}}}}
assert(API.canLearn(character,"TEST-REQ"))
local valid,normalized=API.validateRequirement({all={{knowledge="Test.Knowledge"},{document="TEST-001"}}})
assert(valid and normalized.all and #normalized.all==2)
assert(API.validateRequirement({any={}})==false)
assert(API.getKnowledgeDefinition("Test.Knowledge").owner=="Test")
local duplicate=pcall(API.registerKnowledge,{id="Test.Knowledge",owner="Test",title="Duplicate"})
assert(not duplicate)
local unknownRequirement=pcall(API.registerDocument,{id="TEST-BAD",project="Test",category="FIELD",classification="SECRET",title="Bad",content={"x"},requirements={knowledge="Missing.Knowledge"}})
assert(not unknownRequirement)
isClient=function() return true end; isServer=function() return false end
API.registerDocument{id="TEST-002",project="Test",category="FIELD",classification="SECRET",title="Client",content={"x"}}
assert(API.learn(character,"TEST-002")==false)
local freshClient={getModData=function() return character.modData end}
character.modData={}
assert(API.canLearn(freshClient,"TEST-002")==true and next(character.modData)==nil)
print("B47ANCEDKnowledgeAndWisdom archive/redaction/knowledge checks passed")
