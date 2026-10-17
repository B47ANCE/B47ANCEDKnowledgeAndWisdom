for _,name in ipairs({
    "B47ANCEDKnowledgeAndWisdom/API","B47ANCEDKnowledgeAndWisdom/Progression","B47ANCEDKnowledgeAndWisdom/SurvivorJournals","B47ANCEDKnowledgeAndWisdom/TestHarness",
}) do package.loaded[name]=nil end
_G.B47ANCEDKnowledgeAndWisdom=nil

local script=assert(io.open(arg[1],"r")):read("*a")
for _,name in ipairs({"TestResearchFoundation","TestResearchAdvanced","TestSurvivorJournal"}) do
    assert(script:find("item "..name,1,true),"missing deterministic script item "..name)
end

isClient=function() return false end
isServer=function() return false end
local age=12
getGameTime=function() return {getWorldAgeHours=function() return age end} end
getCore=function() return {getVersionNumber=function() return "42.20.3-test" end} end

local lastReport={}
getFileWriter=function(name,create,append)
    assert(name=="B47ANCED Knowledge & Wisdom Test Results.txt" and create==true and append==false)
    lastReport={}
    return {writeln=function(_,line) lastReport[#lastReport+1]=line end,close=function() end}
end

local function newItem(fullType)
    local item={fullType=fullType,modData={}}
    function item:getFullType() return self.fullType end
    function item:getModData() return self.modData end
    function item:transmitModData() self.transmitted=true end
    return item
end

local inventory={items={}}
function inventory:getItems() return self.items end
function inventory:AddItem(value)
    local item=type(value)=="string" and newItem(value) or value
    self.items[#self.items+1]=item
    return item
end

local mechanics={}
Perks={Mechanics=mechanics}
local player={modData={},xp=0,inventory=inventory}
function player:getModData() return self.modData end
function player:transmitModData() self.transmitted=true end
function player:getInventory() return self.inventory end
function player:getXp() return {getXP=function() return player.xp end} end
getSpecificPlayer=function(index) assert(index==0); return player end
addXp=function(character,perk,amount) assert(character==player and perk==mechanics); player.xp=player.xp+amount end

local Harness=require "B47ANCEDKnowledgeAndWisdom/TestHarness"
assert(Harness.start(true)==true,"guided session should start")
local session=player.modData["B47ANCEDKnowledgeAndWisdom.TestSession.V1"]
assert(session and session.results.startup.status=="PASS","startup/export check should pass")
assert(#inventory.items==2,"start should grant the two research files once")
assert(Harness.giveFiles()==true and #inventory.items==2,"repeated kit command must not duplicate session files")

local API=require "B47ANCEDKnowledgeAndWisdom/API"
local foundation,advanced
for _,item in ipairs(inventory.items) do
    if item:getFullType()=="B47ANCEDKnowledgeAndWisdom.TestResearchFoundation" then foundation=item end
    if item:getFullType()=="B47ANCEDKnowledgeAndWisdom.TestResearchAdvanced" then advanced=item end
end
assert(foundation and advanced,"both deterministic research fixtures required")
local allowed=API.canLearn(player,"EW-TEST-PREREQUISITE")
assert(allowed==false,"advanced fixture must begin blocked")
assert(API.completeRead(player,foundation,{worldAgeHours=age})==true)
Harness.knowledgeStatus()
assert(session.results.read_unlock.status=="PASS","foundation read should auto-record")
assert(API.canLearn(player,"EW-TEST-PREREQUISITE")==true,"foundation knowledge should unlock advanced fixture")
assert(API.completeRead(player,advanced,{worldAgeHours=age})==true)
Harness.knowledgeStatus()
assert(session.results.prerequisite.status=="PASS","advanced read should prove prerequisite transition")

assert(Harness.progression()==true,"semantic progression probe should pass")
assert(player.xp>0 and session.results.semantic_progression.status=="PASS","native XP observation should be recorded")
local awarded=player.xp
assert(Harness.progression()==true and player.xp==awarded,"repeated command must not award more XP")

assert(Harness.journal()==true,"partial journal probe should pass")
assert(session.results.journal_partial.status=="PASS" and #inventory.items==3,"partial journal evidence should persist on a physical item")
local sameRuntime=Harness.journalStatus()
assert(sameRuntime==false and session.results.journal_persistence==nil,"same runtime cannot self-certify save/reload")

package.loaded["B47ANCEDKnowledgeAndWisdom/TestHarness"]=nil
Harness=require "B47ANCEDKnowledgeAndWisdom/TestHarness"
assert(Harness.journalStatus()==true,"reloaded harness should verify preserved journal state")
assert(session.results.journal_persistence.status=="PASS","reload evidence should be recorded")
assert(Harness.report()==true,"human-readable report should export")
local joined=table.concat(lastReport,"\n")
assert(joined:find("Mod ID: B47ANCEDKnowledgeAndWisdom",1,true) and joined:find("COMMAND LOG",1,true),"report must identify build and commands")

print("B47ANCEDKnowledgeAndWisdom in-game test harness/result-export checks passed")

assert(not player.transmitted,"SP debug harness must never broadcast all character ModData")
isClient=function()return true end;isServer=function()return false end
local priorCount=#inventory.items
assert(not Harness.start(true)and not Harness.giveFiles()and #inventory.items==priorCount,"MP debug clients cannot mutate fixtures or sessions")
