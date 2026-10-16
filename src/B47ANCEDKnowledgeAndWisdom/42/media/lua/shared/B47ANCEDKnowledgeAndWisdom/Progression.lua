local API=require "B47ANCEDKnowledgeAndWisdom/API"
local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local SavedState=require "B47ANCEDKnowledgeAndWisdom/SavedState"
local Config=require "B47ANCEDKnowledgeAndWisdom/Config"

API.SemanticActions=API.SemanticActions or {}
API.PROGRESSION_ROOT_KEY=LegacyMigration.STORAGE_PROGRESSION_KEY
-- Technical storage/work bounds. Never evict active or quarantined history.
local MAX_SOURCES=4096
local PRUNE_BUDGET=32

local function finite(value)
    value=tonumber(value)
    return value and value==value and value~=math.huge and value~=-math.huge and value or nil
end
local function copy(value)
    if type(value)~="table" then return value end
    local result={}; for key,child in pairs(value) do result[key]=copy(child) end; return result
end
local function canWrite()
    local client=type(rawget(_G,"isClient"))=="function" and isClient()==true
    local server=type(rawget(_G,"isServer"))=="function" and isServer()==true
    return server or not client
end
local function state(character,create,write)
    if not character or type(character.getModData)~="function" then return nil,"character ModData unavailable" end
    local ok,data=pcall(character.getModData,character)
    if not ok or type(data)~="table" then return nil,"character ModData unavailable" end
    local current=LegacyMigration.readTableKey(data,API.PROGRESSION_ROOT_KEY,LegacyMigration.PROGRESSION_ROOT_KEY)
    if current==nil then
        current={schemaVersion=1,sources={},transactions={},nextTransaction=1}
        if create then data[API.PROGRESSION_ROOT_KEY]=current end
        return current
    end
    if not SavedState.progression(current) then
        return nil,"unsupported or malformed progression ledger"
    end
    if (create or write) and canWrite() then
        LegacyMigration.moveTableKey(data,API.PROGRESSION_ROOT_KEY,LegacyMigration.PROGRESSION_ROOT_KEY)
    end
    return current
end
local function normalizedSkills(skills)
    assert(type(skills)=="table","semantic action skills required")
    local result,total={},0
    for skill,weight in pairs(skills) do
        local amount=finite(weight)
        assert(type(skill)=="string" and skill~="" and amount and amount>0,"semantic skill/weight invalid")
        result[skill]=amount; total=total+amount
    end
    assert(total>0,"semantic action needs at least one weighted skill")
    for skill,weight in pairs(result) do result[skill]=weight/total end
    return result
end

function API.registerSemanticAction(definition)
    assert(type(definition)=="table","semantic action definition required")
    local def=copy(definition)
    assert(type(def.id)=="string" and def.id:match("^[%w_%-]+%.[%w_.%-]+$"),"semantic action id must be namespaced")
    assert(type(def.owner)=="string" and def.owner~="","semantic action owner required")
    assert(type(def.title)=="string" and def.title~="","semantic action title required")
    assert(not API.SemanticActions[def.id],"duplicate semantic action: "..def.id)
    def.baseXP=finite(def.baseXP); assert(def.baseXP and def.baseXP>0,"semantic action baseXP must be finite and positive")
    def.skills=normalizedSkills(def.skills)
    def.outcomes=type(def.outcomes)=="table" and copy(def.outcomes) or {success=1,partial=.5,failure=.05}
    for name,multiplier in pairs(def.outcomes) do
        multiplier=finite(multiplier)
        assert(type(name)=="string" and name~="" and multiplier and multiplier>=0 and multiplier<=2,"semantic outcome invalid")
        if name=="failure" then multiplier=math.min(multiplier,.1) end
        def.outcomes[name]=multiplier
    end
    def.repeatWindowHours=finite(def.repeatWindowHours) or 24
    def.repeatDecay=finite(def.repeatDecay) or .35
    def.repeatFloor=finite(def.repeatFloor) or .1
    assert(def.repeatWindowHours>0 and def.repeatDecay>=0 and def.repeatFloor>=0 and def.repeatFloor<=1,"semantic repeat policy invalid")
    API.SemanticActions[def.id]=def
    return copy(def)
end
function API.getSemanticAction(id) return copy(API.SemanticActions[id]) end
function API.hasSemanticAction(id) return API.SemanticActions[id]~=nil end

local function preview(character,id,report,context,current)
    local settings,settingsError=Config.gameplay();if not settings then return nil,settingsError end
    local def=API.SemanticActions[id]; if not def then return nil,"unknown semantic action" end
    report=type(report)=="table" and report or {}
    context=type(context)=="table" and context or {}
    if report.committed~=true or report.meaningful~=true then return nil,"action was not a committed meaningful change" end
    local outcome=type(report.outcome)=="string" and report.outcome or "success"
    local outcomeMultiplier=def.outcomes[outcome]
    if outcomeMultiplier==nil then return nil,"unsupported semantic outcome" end
    if outcome=="failure"then outcomeMultiplier=math.min(outcomeMultiplier,settings.FailureXPCapPercent/100)end
    local difficulty=finite(report.difficulty) or 1; difficulty=math.max(.25,math.min(4,difficulty))
    local quality=finite(report.quality); quality=quality and math.max(0,math.min(1,quality)) or .5
    local qualityMultiplier=.75+(.5*quality)
    local sourceCategory=type(report.sourceCategory)=="string" and report.sourceCategory or "unspecified"
    local sourceId=type(report.sourceId)=="string" and report.sourceId or "shared"
    if #sourceCategory<1 or #sourceCategory>64 or #sourceId<1 or #sourceId>160
        or sourceCategory:find("|",1,true)or sourceId:find("|",1,true)then return nil,"invalid semantic source identity"end
    local now=finite(context.worldAgeHours) or 0
    local sourceKey=id.."|"..sourceCategory.."|"..sourceId
    local prior=current and current.sources[sourceKey]
    if type(prior)=="table" and prior.quarantinedTransaction then return nil,"semantic source quarantined by transaction "..tostring(prior.quarantinedTransaction) end
    local repeats=0
    local windowHours=def.repeatWindowHours*settings.RepeatWindowPercent/100
    if not finite(windowHours)then return nil,"invalid semantic repeat window"end
    if type(prior)=="table" and finite(prior.lastAt) and now-prior.lastAt<=windowHours then repeats=math.max(0,math.floor(finite(prior.repeats) or 0)) end
    local floor=math.min(1,def.repeatFloor*settings.RepeatFloorPercent/100)
    local repeatMultiplier=math.max(floor,1/(1+repeats*def.repeatDecay*settings.RepeatDecayPercent/100))
    local total=def.baseXP*outcomeMultiplier*difficulty*qualityMultiplier*repeatMultiplier*settings.SemanticXPPercent/100
    if not finite(total)then return nil,"non-finite semantic award"end
    local awards={}
    for skill,weight in pairs(def.skills) do awards[#awards+1]={skill=skill,amount=total*weight} end
    table.sort(awards,function(a,b) return a.skill<b.skill end)
    return {id=id,owner=def.owner,outcome=outcome,sourceKey=sourceKey,sourceCategory=sourceCategory,
        worldAgeHours=now,repeatsBefore=repeats,repeatMultiplier=repeatMultiplier,windowHours=windowHours,totalXP=total,awards=awards}
end

local function pruneSources(current,now)
    if current.sourceOrder==nil then
        -- One-time legacy index construction; bounded by saved-state validation.
        current.sourceOrder={}
        for key in pairs(current.sources)do current.sourceOrder[#current.sourceOrder+1]=key end
        table.sort(current.sourceOrder);current.sourceCursor=1
    end
    local order=current.sourceOrder
    local settings=Config.gameplay()
    local budget=math.min(PRUNE_BUDGET,#order)
    for _=1,budget do
        local cursor=current.sourceCursor or 1
        if cursor>#order then cursor=1 end
        local key=order[cursor];local source=key and current.sources[key]
        if not source then break end
        local action=API.SemanticActions[key:match("^([^|]+)|")]
        local window=source.windowHours
        if action then window=math.max(window or 0,action.repeatWindowHours*settings.RepeatWindowPercent/100)end
        if not source.quarantinedTransaction and window and now>=source.lastAt and now-source.lastAt>window then
            current.sources[key]=nil;table.remove(order,cursor)
        else cursor=cursor+1 end
        current.sourceCursor=(cursor<=#order and cursor or 1)
    end
end
function API.previewSemanticAction(character,id,report,context)
    local current,err=state(character,false); if not current then return nil,err end
    return preview(character,id,report,context,current)
end
local function resolvePerk(skill)
    local perks=rawget(_G,"Perks")
    if type(perks)~="table" and type(perks)~="userdata" then return nil end
    local direct=perks[skill]; if direct~=nil then return direct end
    if type(perks.FromString)=="function" then local ok,value=pcall(perks.FromString,skill); if ok then return value end end
    return nil
end
function API.processSemanticAction(character,id,report,context)
    if not canWrite() then return false,"non-authority" end
    local existing,err=state(character,false); if not existing then return false,err end
    local plan,planError=preview(character,id,report,context,existing); if not plan then return false,planError end
    if plan.totalXP<=0 then return true,{applied=false,totalXP=0,awards={}} end
    local add=rawget(_G,"addXp"); if type(add)~="function" then return false,"native addXp unavailable" end
    for _,award in ipairs(plan.awards) do award.perk=resolvePerk(award.skill); if award.perk==nil then return false,"unknown perk: "..award.skill end end
    local current,stateError=state(character,true); if not current then return false,stateError end
    pruneSources(current,plan.worldAgeHours)
    if current.sources[plan.sourceKey]==nil and #current.sourceOrder>=MAX_SOURCES then
        return false,"semantic source capacity reached; active history preserved"
    end
    if current.sources[plan.sourceKey]==nil then current.sourceOrder[#current.sourceOrder+1]=plan.sourceKey end
    local transactionId=tostring(current.nextTransaction); current.nextTransaction=current.nextTransaction+1
    current.transactions[transactionId]={status="pending",action=id,sourceKey=plan.sourceKey,worldAgeHours=plan.worldAgeHours}
    for index,award in ipairs(plan.awards) do
        local ok,awardError=pcall(add,character,award.perk,award.amount)
        if not ok then
            current.transactions[transactionId].status="uncertain"
            current.transactions[transactionId].failedAward=index
            current.transactions[transactionId].error=tostring(awardError)
            current.sources[plan.sourceKey]={quarantinedTransaction=transactionId,lastAt=plan.worldAgeHours,repeats=plan.repeatsBefore,windowHours=plan.windowHours}
            if character.transmitModData then pcall(character.transmitModData,character) end
            return false,"semantic award uncertain; inspect transaction "..transactionId
        end
    end
    current.transactions[transactionId].status="committed"
    current.transactions[transactionId].totalXP=plan.totalXP
    current.sources[plan.sourceKey]={lastAt=plan.worldAgeHours,repeats=plan.repeatsBefore+1,windowHours=plan.windowHours}
    local committed={}
    for key,transaction in pairs(current.transactions) do if transaction.status=="committed"or transaction.status=="resolved-uncertain" then committed[#committed+1]={key=key,id=tonumber(key) or 0} end end
    table.sort(committed,function(a,b) return a.id>b.id end)
    for index=65,#committed do current.transactions[committed[index].key]=nil end
    if character.transmitModData then pcall(character.transmitModData,character) end
    for _,award in ipairs(plan.awards) do award.perk=nil end
    return true,{applied=true,transactionId=transactionId,totalXP=plan.totalXP,awards=plan.awards,repeatMultiplier=plan.repeatMultiplier}
end
function API.resolveSemanticTransaction(character,transactionId,resolution)
    if not canWrite() then return false,"non-authority" end
    if resolution~="accept-uncertain" then return false,"unsupported resolution" end
    local current,err=state(character,false,true); if not current then return false,err end
    local transaction=current.transactions[tostring(transactionId)]
    if type(transaction)~="table" or transaction.status~="uncertain" then return false,"transaction is not uncertain" end
    transaction.status="resolved-uncertain"; transaction.resolution=resolution
    local source=current.sources[transaction.sourceKey]
    if type(source)=="table" and tostring(source.quarantinedTransaction)==tostring(transactionId) then
        source.quarantinedTransaction=nil; source.repeats=(tonumber(source.repeats) or 0)+1
    end
    if character.transmitModData then pcall(character.transmitModData,character) end
    return true,copy(transaction)
end
function API.progressionSnapshot(character)
    local current,err=state(character,false); if not current then return nil,err end
    return copy(current)
end

return API
