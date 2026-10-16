package.loaded["B47ANCEDKnowledgeAndWisdom/API"]=nil
package.loaded["B47ANCEDKnowledgeAndWisdom/SurvivorJournals"]=nil
B47ANCEDKnowledgeAndWisdom=nil
local Journals=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local claims={}; Journals.setClaimStoreProvider(function()return claims end)
local data={}; local item={getModData=function()return data end,transmitModData=function(self)self.sent=(self.sent or 0)+1 end}
local capture={rawXP={Aiming=3000,Maintenance=500},documents={MagazineA=true},recipes={RecipeA=true},media={VHS_A=true},knowledge={K1=true},research={R1=true}}
local ok,result=Journals.beginWriting(item,"author",capture,"write-1",{worldAgeHours=10})
assert(ok and result.entries==7 and result.totalWork>0 and item.sent==1)
local duplicate=assert(Journals.beginWriting(item,"author",capture,"write-1"));assert(duplicate)
assert(not Journals.beginWriting(item,"other",capture,"write-2"))
local snap=assert(Journals.snapshot(item));local firstWork=snap.queue[1].work
assert(Journals.advanceWriting(item,"author",firstWork/2))
snap=assert(Journals.snapshot(item));assert(math.abs(snap.documented.rawXP.Aiming-1500)<.001 and (not snap.documented.discrete.documents or snap.documented.discrete.documents.MagazineA==nil))
-- Partial work is physical item state and survives a module reload.
package.loaded["B47ANCEDKnowledgeAndWisdom/SurvivorJournals"]=nil
Journals=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"; Journals.setClaimStoreProvider(function()return claims end)
snap=assert(Journals.snapshot(item));assert(math.abs(snap.documented.rawXP.Aiming-1500)<.001)
assert(Journals.advanceWriting(item,"author",9999));snap=assert(Journals.snapshot(item))
assert(not snap.writing and snap.documented.rawXP.Aiming==3000 and snap.documented.discrete.documents.MagazineA)
assert(Journals.claim(item,"successor-a",{worldAgeHours=20}))
assert(not Journals.claim(item,"successor-b"))
local plan=assert(Journals.recoveryPlan(item,"successor-a",{Aiming=2800,Maintenance=1000},.9))
assert(plan.rawXP.Aiming==2800 and plan.rawXP.Maintenance==1000,"recovery must never lower or add to current XP")
assert(plan.discrete.media.VHS_A and plan.discrete.research.R1)
assert(Journals.exhaust(item,"successor-a"));assert(Journals.recoveryPlan(item,"successor-a",{})==nil)
assert(not Journals.beginWriting(item,"author",capture,"write-3"),"exhausted item remains a keepsake")
local cloneData={};for k,v in pairs(data)do cloneData[k]=v end
local clone={getModData=function()return cloneData end}
assert(not Journals.claim(clone,"successor-b"),"persistent payload claim must reject cloned journals")
isClient=function()return true end;isServer=function()return false end
assert(not Journals.advanceWriting(item,"author",1));assert(not Journals.claim(item,"client"))
print("B47ANCEDKnowledgeAndWisdom interruption-safe survivor journal/claim/recovery checks passed")
