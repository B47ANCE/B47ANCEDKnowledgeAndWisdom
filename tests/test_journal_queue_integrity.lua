local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local data={};local item={getModData=function()return data end}
assert(J.beginWriting(item,"author",{rawXP={Maintenance=10}},"op"))
local state=data[J.ROOT_KEY];local total=state.writing.totalWork
state.writing.totalWork=total+1
assert(J.snapshot(item)==nil,"inconsistent queue work totals must fail before advancing saved state")
assert(not J.advanceWriting(item,"author",1)and state.writing.totalWork==total+1)
state.writing.totalWork=total
state.queue[2]=state.queue[1]
assert(J.snapshot(item)==nil,"duplicated work identities must not be applied twice")
state.queue[2]=nil
assert(J.advanceWriting(item,"author",9999))
local store={};J.setClaimStoreProvider(function()return store end)
assert(not J.claim(item,string.rep("x",4097))and next(store)==nil,"oversized successor IDs cannot poison persistent claims")
assert(not J.claim(item,{}))
assert(J.claim(item,"successor"))
assert(J.recoveryPlan(item,"successor",{Maintenance=0/0})==nil)
assert(J.recoveryPlan(item,"successor",{},math.huge)==nil)
print("Journal queue invariants and recovery input rejection passed")
