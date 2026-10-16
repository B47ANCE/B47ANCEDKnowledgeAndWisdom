local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local L=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local data={};local item={getModData=function()return data end}
assert(J.beginWriting(item,"author",{rawXP={Maintenance=10}},"write"));assert(J.advanceWriting(item,"author",9999))
local payload=J.snapshot(item).payloadId
local stores={[L.CLAIM_STORE_KEY]={[payload]={successorId="successor",claimedAtWorldAgeHours=10,exhausted=false}},[L.STORAGE_CLAIM_STORE_KEY]={}}
ModData={get=function(key)return stores[key]end,getOrCreate=function(key)stores[key]=stores[key]or{};return stores[key]end,
    remove=function(key)stores[key]=nil end}
next=nil;table.unpack=nil
local ok,result=J.claim(item,"successor")
assert(ok and result.duplicate,"valid legacy claim migration must work without the host-only next global")
assert(stores[L.CLAIM_STORE_KEY]==nil and stores[L.STORAGE_CLAIM_STORE_KEY][payload].successorId=="successor")
assert(J.claim(item,"successor"),"migration must remain idempotent")
assert(not J.claim(item,"other"))
print("legacy claim migration without next/table.unpack passed")
