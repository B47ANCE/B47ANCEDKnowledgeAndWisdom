local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
isClient=function()return false end;isServer=function()return true end
local API={Claims={}};package.preload["B47ANCEDKnowledgeAndWisdom/API"]=function()return API end
local grants=0;local regions={rosewood={id="rosewood",granularity="locality"}}
API.Claims={getRegion=function(id)return regions[id]end,subjectId=function()return"getUsername:alice"end,
    grant=function(_,request)grants=grants+1;return true,"GRANTED",request end}
package.preload["B47ANCEDKnowledgeAndWisdom/Claims"]=function()return API.Claims end
local Origin=dofile(arg[1]);Origin.registerProvider{id="fixture.origin",owner="mapFixture",observe=function()
    return{originId="rosewood-start",regionId="rosewood",evidenceId="creation:rosewood",confidence=.9}end}
local observed=assert(Origin.observe({}));assert(observed.regionId=="rosewood"and observed.confidence==.9)
local ok,reason,request=Origin.grant({},{worldAgeHours=12});assert(ok and reason=="GRANTED"and grants==1)
assert(request.scope.granularity=="locality"and request.sourceId=="creation:rosewood"and request.sourceOwner==LegacyMigration.PERSISTED_OWNER)
local API2={Claims={getRegion=function()end,subjectId=function()return"x"end,grant=function()error("must not grant")end}}
package.loaded["B47ANCEDKnowledgeAndWisdom/API"]=nil;package.loaded["B47ANCEDKnowledgeAndWisdom/Claims"]=nil
package.preload["B47ANCEDKnowledgeAndWisdom/API"]=function()return API2 end;package.preload["B47ANCEDKnowledgeAndWisdom/Claims"]=function()return API2.Claims end
local Missing=dofile(arg[1]);Missing.registerProvider{id="fixture.bad",observe=function()return{originId="x",regionId="unknown",evidenceId="x"}end}
assert(Missing.grant({})==false)
print("B47ANCEDKnowledgeAndWisdom explicit origin-knowledge provider checks passed")
