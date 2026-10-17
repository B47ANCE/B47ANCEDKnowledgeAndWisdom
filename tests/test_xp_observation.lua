local A=require "B47ANCEDKnowledgeAndWisdom/Progression"
A.registerSemanticAction{id="Audit.XP",owner="test",title="XP",baseXP=1,skills={Maintenance=1}}
Perks={Maintenance="maintenance",None="none",MAX="max",FromString=function()return "none"end}
local data={};local amount=0;local calls=0
local actor={getModData=function()return data end,getXp=function()return {getXP=function()return amount end}end}
addXp=function()calls=calls+1 end
local ok,reason=A.processSemanticAction(actor,"Audit.XP",{committed=true,meaningful=true,sourceId="silent"})
assert(not ok and reason:find("uncertain",1,true),"a void native call with no observed XP must not be marked applied")
assert(A.progressionSnapshot(actor).transactions["1"].status=="uncertain")
assert(not A.processSemanticAction(actor,"Audit.XP",{committed=true,meaningful=true,sourceId="silent"})and calls==1)
addXp=function(_,_,delta)amount=amount+delta*2 end
local applied,result=A.processSemanticAction(actor,"Audit.XP",{committed=true,meaningful=true,sourceId="good"})
assert(applied and result.totalXP==1 and result.awards[1].observedXP==2,"observe native multipliers without applying them again")
local invalid=pcall(A.registerSemanticAction,{id="Audit.Overflow",owner="test",title="Overflow",baseXP=1,skills={A=1e308,B=1e308}})
assert(not invalid,"overflowed skill totals must not normalize to zero weights")
A.registerSemanticAction{id="Audit.InvalidPerk",owner="test",title="Bad perk",baseXP=1,skills={Unknown=1}}
assert(not A.processSemanticAction(actor,"Audit.InvalidPerk",{committed=true,meaningful=true}))
local empty={};local sleeping={getModData=function()return empty end,isAsleep=function()return true end,getXp=actor.getXp}
assert(not A.processSemanticAction(sleeping,"Audit.XP",{committed=true,meaningful=true})and next(empty)==nil)
-- Native callbacks see a valid pending quarantine and cannot reenter the source.
local seen=false
addXp=function(_,_,delta)
 local snapshot=assert(A.progressionSnapshot(actor));assert(snapshot.transactions["3"].status=="pending")
 assert(not A.processSemanticAction(actor,"Audit.XP",{committed=true,meaningful=true,sourceId="reentrant"}))
 seen=true;amount=amount+delta
end
assert(A.processSemanticAction(actor,"Audit.XP",{committed=true,meaningful=true,sourceId="reentrant"})and seen)
print("Native refusal, observation, numeric/perk and reentrancy checks passed")
