-- Opt-in diagnostics only: no events, messages, file writes or gate promotion.
local API=require "B47ANCEDKnowledgeAndWisdom/API"
local Claims=require "B47ANCEDKnowledgeAndWisdom/Claims"
local Journals=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local L=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local Guard=require "B47ANCEDKnowledgeAndWisdom/AuthorityGuard"
local Probe={}
local function owned(object,keys)
    local data=object:getModData();if type(data)~="table"then error("unavailable")end
    local result={};for _,key in ipairs(keys)do result[key]=data[key]end
    return result
end
local function clone(value,seen,budget,depth)
    budget.count=budget.count+1;if budget.count>262144 or depth>16 then error("limit")end
    local kind=type(value)
    if kind~="table"then
        if kind~="nil"and kind~="string"and kind~="number"and kind~="boolean"then error("unsupported")end
        return value
    end
    if seen[value]then return seen[value]end
    local result={};seen[value]=result
    for key,child in pairs(value)do
        if type(key)~="string"and type(key)~="number"then error("key")end
        result[key]=clone(child,seen,budget,depth+1)
    end
    return result
end
local function equal(a,b,seen)
    if type(a)~=type(b)then return false end
    if type(a)~="table"then return a==b or(type(a)=="number"and a~=a and b~=b)end
    if seen[a]then return seen[a]==b end;seen[a]=b
    for key,value in pairs(a)do if not equal(value,b[key],seen)then return false end end
    for key in pairs(b)do if a[key]==nil then return false end end
    return true
end
function Probe.run(character,item)
    local realm=Guard.realm()
    if realm=="client"then return nil,"NON_AUTHORITY_PROBE"end
    if realm=="unknown"then return nil,"REALM_UNAVAILABLE"end
    local report={version=API.VERSION,role=realm,scope="owned-key query purity only",
        multiplayerGameplayAvailable=false,implementationGate=Guard.MULTIPLAYER_BLOCKED,cases={}}
    local keys={L.STORAGE_KNOWLEDGE_KEY,L.KNOWLEDGE_ROOT_KEY,L.STORAGE_PROGRESSION_KEY,L.PROGRESSION_ROOT_KEY,L.STORAGE_CLAIMS_KEY}
    local itemKeys={L.STORAGE_JOURNAL_KEY,L.JOURNAL_ROOT_KEY}
    local function capture()
        return clone({character=owned(character,keys),journal=item and owned(item,itemKeys)or nil},{},{count=0},0)
    end
    local ready,before=pcall(capture);if not ready then return nil,"UNSUPPORTED_OR_UNAVAILABLE_PROBE_INPUT"end
    local queries={knowledge=function()return API.snapshot(character)end,progression=function()return API.progressionSnapshot(character)end,
        claims=function()return Claims.snapshot(character)end}
    if item then queries.journal=function()return Journals.snapshot(item)end;queries.journalView=function()return Journals.view(item)end end
    for _,name in ipairs({"knowledge","progression","claims","journal","journalView"})do
        if queries[name]then
            local called,result=pcall(queries[name])
            report.cases[name]={callSucceeded=called,viewAvailable=called and result~=nil or false}
        end
    end
    local captured,after=pcall(capture)
    report.ownedKeysUnchanged=captured and equal(before,after,{})or false
    -- Report no private values, identifiers, counts, exception text or snapshots.
    return report
end
API.AuthorityProbe=Probe
return Probe
