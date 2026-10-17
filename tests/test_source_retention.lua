local A=require "B47ANCEDKnowledgeAndWisdom/Progression"
A.registerSemanticAction{id="Retention.Test",owner="test",title="Test",baseXP=1,skills={Maintenance=1},repeatWindowHours=24}
local data={};local actor={getModData=function()return data end}
local observedXP=0
actor.getXp=function()return {getXP=function()return observedXP end}end
Perks={Maintenance="Maintenance"};addXp=function(_,_,amount)observedXP=observedXP+amount end
for i=1,1500 do
    assert(A.processSemanticAction(actor,"Retention.Test",{committed=true,meaningful=true,sourceCategory="object",sourceId=tostring(i)},{worldAgeHours=i*25}))
end
local state=A.progressionSnapshot(actor);local sources=0;for _ in pairs(state.sources)do sources=sources+1 end
assert(sources<=32,"long-expired unique sources must not grow without bound")
assert(state.nextTransaction==1501)
local report={committed=true,meaningful=true,sourceCategory="object",sourceId="active"}
assert(A.processSemanticAction(actor,"Retention.Test",report,{worldAgeHours=40000}))
local repeated=assert(A.previewSemanticAction(actor,"Retention.Test",report,{worldAgeHours=40001}))
assert(repeated.repeatMultiplier<1,"active-window history must remain effective")
addXp=function()error("uncertain native award")end
local bad={committed=true,meaningful=true,sourceCategory="object",sourceId="quarantined"}
assert(not A.processSemanticAction(actor,"Retention.Test",bad,{worldAgeHours=40002}))
addXp=function(_,_,amount)observedXP=observedXP+amount end
for i=1,100 do assert(A.processSemanticAction(actor,"Retention.Test",{committed=true,meaningful=true,sourceId="cleanup"..i},{worldAgeHours=50000+i*25}))end
assert(A.previewSemanticAction(actor,"Retention.Test",bad,{worldAgeHours=60000})==nil,"uncertain awards must never expire out of quarantine")
local saved=data[A.PROGRESSION_ROOT_KEY]
package.loaded["B47ANCEDKnowledgeAndWisdom/Progression"]=nil
A=require "B47ANCEDKnowledgeAndWisdom/Progression"
assert(data[A.PROGRESSION_ROOT_KEY]==saved and A.previewSemanticAction(actor,"Retention.Test",bad,{worldAgeHours=60001})==nil)
-- Capacity is a safety bound, not permission to drop active anti-repeat state.
local full={schemaVersion=1,sources={},transactions={},nextTransaction=1}
for i=1,4096 do full.sources["Retention.Test|object|"..i]={lastAt=10,repeats=1}end
local fullData={[A.PROGRESSION_ROOT_KEY]=full};local fullActor={getModData=function()return fullData end}
fullActor.getXp=actor.getXp
local calls=0;addXp=function(_,_,amount)calls=calls+1;observedXP=observedXP+amount end
assert(not A.processSemanticAction(fullActor,"Retention.Test",report,{worldAgeHours=11})and calls==0)
local fullCount=0;for _ in pairs(full.sources)do fullCount=fullCount+1 end
assert(fullCount==4096,"a full active ledger must reject new sources before native XP is awarded")
print("bounded expired sources, active counters, quarantine and reload checks passed")
