local A=require "B47ANCEDKnowledgeAndWisdom/Progression"
local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local Config=require "B47ANCEDKnowledgeAndWisdom/Config"
A.registerSemanticAction{id="Sandbox.Test",owner="test",title="Test",baseXP=10,skills={Maintenance=1},outcomes={success=1,failure=.1}}
local data={};local actor={getModData=function()return data end}
local observedXP=0
actor.getXp=function()return {getXP=function()return observedXP end}end
local report={committed=true,meaningful=true,sourceId="object"}
SandboxVars={B47ANCEDKnowledgeAndWisdom={SemanticXPPercent=200,RepeatWindowPercent=200,RepeatDecayPercent=200,
    RepeatFloorPercent=50,JournalRecoveryPercent=25,JournalWritingSpeedPercent=200,FailureXPCapPercent=0}}
assert(A.previewSemanticAction(actor,"Sandbox.Test",report,{}).totalXP==20)
Perks={Maintenance="Maintenance"};addXp=function(_,_,amount)observedXP=observedXP+amount end
assert(A.processSemanticAction(actor,"Sandbox.Test",report,{worldAgeHours=1}))
local repeated=assert(A.previewSemanticAction(actor,"Sandbox.Test",report,{worldAgeHours=26}))
assert(repeated.repeatMultiplier<1,"server repeat-window scale must apply")
report.outcome="failure";assert(A.previewSemanticAction(actor,"Sandbox.Test",report,{}).totalXP==0)
local store={};J.setClaimStoreProvider(function()return store end)
local itemData={};local item={getModData=function()return itemData end}
assert(J.beginWriting(item,"author",{rawXP={Maintenance=100}},"write"))
local before=J.snapshot(item);assert(J.advanceWriting(item,"author",1))
assert(J.snapshot(item).writing.completedWork==2,"server writing-speed setting must apply")
assert(J.advanceWriting(item,"author",9999));assert(J.claim(item,"successor"))
assert(J.recoveryPlan(item,"successor",{},1).rawXP.Maintenance==25,"caller cannot exceed the server recovery maximum")
SandboxVars.B47ANCEDKnowledgeAndWisdom={SemanticXPPercent=0/0,JournalRecoveryPercent=9000,RepeatDecayPercent=-100,JournalWritingSpeedPercent="invalid"}
local settings=assert(Config.gameplay())
assert(settings.SemanticXPPercent==100 and settings.JournalRecoveryPercent==100 and settings.RepeatDecayPercent==0 and settings.JournalWritingSpeedPercent==100)
SandboxVars={};assert(Config.gameplay().JournalRecoveryPercent==90,"existing saves without options must keep defaults")
isClient=function()return true end;isServer=function()return false end
SandboxVars={B47ANCEDKnowledgeAndWisdom={SemanticXPPercent=1000}}
assert(Config.gameplay()==nil and A.previewSemanticAction(actor,"Sandbox.Test",report,{})==nil,"client settings cannot own shared calculations")
print("server sandbox interpretation, bounds, defaults and client rejection checks passed")
