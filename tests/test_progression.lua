package.loaded["B47ANCEDKnowledgeAndWisdom/API"]=nil
package.loaded["B47ANCEDKnowledgeAndWisdom/Progression"]=nil
B47ANCEDKnowledgeAndWisdom=nil
local API=require "B47ANCEDKnowledgeAndWisdom/Progression"
API.registerSemanticAction{id="Test.Repair",owner="Test",title="Repair",baseXP=10,
    skills={Maintenance=3,Electricity=1},outcomes={success=1,partial=.5,failure=.5},
    repeatWindowHours=24,repeatDecay=1,repeatFloor=.2}
assert(API.hasSemanticAction("Test.Repair"))
assert(math.abs(API.getSemanticAction("Test.Repair").skills.Maintenance-.75)<.0001)
local data={}
local character={getModData=function() return data end,transmitModData=function(self) self.transmitted=true end}
local xp={}
character.getXp=function()return {getXP=function(_,perk)return xp[perk]or 0 end}end
local invalid,reason=API.previewSemanticAction(character,"Test.Repair",{committed=false,meaningful=true})
assert(invalid==nil and reason)
local plan=assert(API.previewSemanticAction(character,"Test.Repair",{committed=true,meaningful=true,outcome="failure",difficulty=2,quality=1,sourceCategory="device",sourceId="one"},{worldAgeHours=5}))
assert(math.abs(plan.totalXP-2.5)<.0001) -- failure is capped at 10%, then quality/difficulty apply
Perks={Maintenance="maintenance",Electricity="electricity"}
local awards={}
addXp=function(who,perk,amount) assert(who==character); awards[#awards+1]={perk=perk,amount=amount};xp[perk]=(xp[perk]or 0)+amount end
local ok,result=API.processSemanticAction(character,"Test.Repair",{committed=true,meaningful=true,outcome="success",sourceCategory="device",sourceId="one"},{worldAgeHours=6})
assert(ok and result.applied and #awards==2 and result.totalXP==10)
assert(not character.transmitted and API.progressionSnapshot(character).transactions[result.transactionId].status=="committed")
local repeatPlan=assert(API.previewSemanticAction(character,"Test.Repair",{committed=true,meaningful=true,outcome="success",sourceCategory="device",sourceId="one"},{worldAgeHours=7}))
assert(repeatPlan.repeatMultiplier==.5 and repeatPlan.totalXP==5)
isClient=function() return true end; isServer=function() return false end
assert(API.processSemanticAction(character,"Test.Repair",{committed=true,meaningful=true})==false)
isClient=function() return false end
local calls=0
addXp=function(_,perk,amount) calls=calls+1; if calls==2 then error("award failure") end;xp[perk]=(xp[perk]or 0)+amount end
ok,reason=API.processSemanticAction(character,"Test.Repair",{committed=true,meaningful=true,outcome="success",sourceCategory="device",sourceId="two"},{worldAgeHours=8})
assert(not ok and reason:find("uncertain",1,true))
local snapshot=API.progressionSnapshot(character)
assert(snapshot.transactions["2"].status=="uncertain" and snapshot.sources["Test.Repair|device|two"].quarantinedTransaction=="2")
assert(API.previewSemanticAction(character,"Test.Repair",{committed=true,meaningful=true,sourceCategory="device",sourceId="two"},{worldAgeHours=9})==nil)
assert(API.resolveSemanticTransaction(character,"2","accept-uncertain"))
assert(API.progressionSnapshot(character).transactions["2"].status=="resolved-uncertain")
print("B47ANCEDKnowledgeAndWisdom semantic progression policy/authority/quarantine checks passed")
