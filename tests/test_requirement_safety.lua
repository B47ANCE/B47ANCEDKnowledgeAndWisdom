local API=require "B47ANCEDKnowledgeAndWisdom/API"
local md={};local character={getModData=function()return md end}
API.registerKnowledge{id="Test.Known",owner="Test",title="Known"}
API.registerDocument{id="KNOWN",project="Test",category="Test",classification="OPEN",title="Known",content={"body"}}
assert(not API.evaluateRequirement(character,{["not"]={knowledge="Missing.Knowledge"}}),"unknown knowledge under NOT must fail closed")
assert(not API.evaluateRequirement(character,{["not"]={document="MISSING"}}),"unknown document under NOT must fail closed")
assert(not API.evaluateRequirement(character,{any={{["not"]={knowledge="Test.Known"}},{knowledge="Missing.Knowledge"}}}),"all references must be valid even in an unvisited branch")
assert(API.evaluateRequirement(character,{["not"]={knowledge="Test.Known"}}),"registered unearned knowledge can satisfy NOT")
assert(API.evaluateRequirement(character,{["not"]={document="KNOWN"}}))
assert(not API.validateRequirement({all={[1]={document="KNOWN"},[3]={document="MISSING"}}}),"sparse arrays must not silently drop requirements")
assert(not API.validateRequirement({knowledge="Test.Known",extra=true}),"unknown operators must not be ignored")
local node={document="KNOWN"};for i=1,40 do node={["not"]=node}end
assert(not API.validateRequirement(node),"pathological depth must be rejected")
local cycle={};cycle["not"]=cycle;assert(not API.validateRequirement(cycle))
assert(next(md)==nil,"requirement queries must not initialize saves")
print("Requirement fail-closed reference and structural checks passed")
