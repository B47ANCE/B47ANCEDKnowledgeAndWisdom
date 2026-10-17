local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local md={};local item={getModData=function()return md end,transmitModData=function()error("must not transmit rejected writes")end}
local large={rawXP={}};for i=1,513 do large.rawXP["Perk"..i]=100 end
local called,ok=pcall(J.beginWriting,item,"author",large,"too-large")
assert(called and ok==false,"oversized queues must return a clean failure")
assert(next(md)==nil,"rejected capture must leave blank saves untouched")
item.transmitModData=nil
assert(J.beginWriting(item,"author",{rawXP={Aiming=100}},"first"))
assert(J.cancelWriting(item,"author"))
local old=md[J.ROOT_KEY];local revision=old.revision;local author=old.authorId
called,ok=pcall(J.beginWriting,item,"author",large,"too-large")
assert(called and ok==false and md[J.ROOT_KEY]==old and old.revision==revision and old.authorId==author and not old.writing)
local invalid={rawXP={[string.rep("x",4097)]=100}}
assert(not J.beginWriting(item,"author",invalid,"invalid-id"),"invalid serialized identifiers must fail before persistence")
assert(J.snapshot(item) and old.revision==revision)
assert(J.beginWriting(item,"author",{rawXP={Aiming=100}},"second"))
local current=J.snapshot(item)
assert(not J.beginWriting(item,"author",{rawXP={Aiming=200}},"second"),"changed capture cannot reuse an active operation ID")
assert(J.snapshot(item).revision==current.revision)
assert(J.beginWriting(item,"author",{rawXP={Aiming=100}},"second"))
local L=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
md[L.JOURNAL_ROOT_KEY]=md[J.ROOT_KEY];md[J.ROOT_KEY]=nil
assert(not J.beginWriting(item,"other",{rawXP={Aiming=200}},"third"))
assert(md[L.JOURNAL_ROOT_KEY] and md[J.ROOT_KEY]==nil,"rejected writes must not migrate legacy keys")
print("Journal atomic rejection and active-operation binding passed")

isClient=function()return false end
local canonical={};local another={getModData=function()return canonical end}
assert(J.beginWriting(another,"author",{rawXP={Aiming=1}},"a"))
assert(J.cancelWriting(another,"author"))
local coexist={diagnostic=true};canonical[L.JOURNAL_ROOT_KEY]=coexist
assert(J.beginWriting(another,"author",{rawXP={Aiming=2}},"b"))
assert(canonical[L.JOURNAL_ROOT_KEY]==coexist,"canonical writes must preserve coexisting legacy diagnostics")

for _,attempt in ipairs({
 function(i)return J.cancelWriting(i,"other")end,
 function(i)return J.advanceWriting(i,"other",1)end,
 function(i)return J.claim(i,"successor")end,
 function(i)return J.exhaust(i,"successor")end,
})do
 local prior=J.snapshot(another);local data={[L.JOURNAL_ROOT_KEY]=prior}
 local i={getModData=function()return data end}
 J.setClaimStoreProvider(function()return nil end)
 assert(not attempt(i))
 assert(data[L.JOURNAL_ROOT_KEY]==prior and data[J.ROOT_KEY]==nil,"rejected journal operations must not migrate legacy state")
end

J.setClaimStoreProvider(nil)
local created=0
ModData={get=function()return {bad="malformed"}end,getOrCreate=function()created=created+1;return {}end}
assert(not J.claim(another,"successor"))
assert(created==0,"malformed legacy claim stores must be validated before canonical store creation")
