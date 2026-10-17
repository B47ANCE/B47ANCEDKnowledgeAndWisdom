local C=require "B47ANCEDKnowledgeAndWisdom/Claims"
assert(not pcall(C.registerDefinition,{id="Audit.Invalid",owner="test",kind="journal",acquisition="",scopeFields={"payloadId"}}),"empty acquisition definitions must not produce malformed saved claims")
C.registerDefinition{id="Audit.Valid",owner="test",kind="journal",scopeFields={"payloadId"}}
local data={};local actor={getModData=function()return data end,getUsername=function()return "fixture"end}
local request={schemaVersion=1,operationId="one",claimId="claim",definitionId="Audit.Valid",subjectId="getUsername:fixture",sourceType="test",sourceId="one",sourceOwner="test",scope={payloadId="one"},acquisition=""}
assert(not C.grant(actor,request)and next(data)==nil)
request.acquisition="recorded";request.reason=string.rep("x",70000)
assert(not C.grant(actor,request)and next(data)==nil)
request.reason=nil;assert(C.grant(actor,request))
assert(C.snapshot(actor,{maximum=0/0}))
print("Claim acquisition and bounded-query input checks passed")
