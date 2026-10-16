local API=require "B47ANCEDKnowledgeAndWisdom/API"
local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local SavedState=require "B47ANCEDKnowledgeAndWisdom/SavedState"
local Config=require "B47ANCEDKnowledgeAndWisdom/Config"

local Journals={SCHEMA_VERSION=1,ROOT_KEY=LegacyMigration.STORAGE_JOURNAL_KEY,MAX_QUEUE=512}
local discreteOrder={documents=1,recipes=2,maps=3,media=4,knowledge=5,research=6}
local claimStoreProvider

local function finite(value)
    value=tonumber(value)
    return value and value==value and value~=math.huge and value~=-math.huge and value or nil
end
local function copy(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {}; if seen[value] then return nil end; seen[value]=true
    local result={}; for key,child in pairs(value) do result[key]=copy(child,seen) end
    seen[value]=nil; return result
end
local function canWrite()
    local client=type(rawget(_G,"isClient"))=="function" and isClient()==true
    local server=type(rawget(_G,"isServer"))=="function" and isServer()==true
    return server or not client
end
local function itemData(item)
    if not item or type(item.getModData)~="function" then return nil,"journal ModData unavailable" end
    local ok,data=pcall(item.getModData,item)
    if not ok or type(data)~="table" then return nil,"journal ModData unavailable" end
    return data
end
local function state(item,create,write)
    local data,err=itemData(item); if not data then return nil,err end
    local current=LegacyMigration.readTableKey(data,Journals.ROOT_KEY,LegacyMigration.JOURNAL_ROOT_KEY)
    if current==nil then
        if not create then return nil,"journal is blank" end
        current={schemaVersion=1,payloadId=nil,authorId=nil,documented={rawXP={},discrete={}},queue={},writing=nil,recovery=nil,revision=0}
        data[Journals.ROOT_KEY]=current
    end
    if not SavedState.journal(current) then
        return nil,"unsupported or malformed survivor journal"
    end
    if (create or write) and canWrite() then
        LegacyMigration.moveTableKey(data,Journals.ROOT_KEY,LegacyMigration.JOURNAL_ROOT_KEY)
    end
    return current
end
local function normalizedSet(values,label)
    if values==nil then return {} end
    assert(type(values)=="table",label.." must be a table")
    local result={}
    for key,value in pairs(values) do
        local id=type(key)=="number" and value or key
        local enabled=type(key)=="number" or value==true
        assert(type(id)=="string" and id~="",label.." identifier required")
        if enabled then result[id]=true end
    end
    return result
end
local function normalizeCapture(capture)
    assert(type(capture)=="table","journal capture required")
    local result={rawXP={},discrete={}}
    for perk,value in pairs(capture.rawXP or {}) do
        local amount=finite(value)
        assert(type(perk)=="string" and perk~="" and amount and amount>=0,"raw XP entry invalid")
        result.rawXP[perk]=amount
    end
    for category,_ in pairs(discreteOrder) do result.discrete[category]=normalizedSet(capture[category] or (capture.discrete and capture.discrete[category]),category) end
    return result
end
local function payloadId(authorId,operationId)
    assert(type(operationId)=="string" and operationId~="","stable journal operation ID required")
    return tostring(authorId)..":"..operationId
end
local function xpWork(delta)
    if delta<=0 then return 0 end
    return math.max(1,math.min(240,4+(math.log(1+delta)/math.log(2))*2))
end
local function buildQueue(documented,target)
    local queue={}
    local perks={}; for perk in pairs(target.rawXP) do perks[#perks+1]=perk end; table.sort(perks)
    for _,perk in ipairs(perks) do
        local from=finite(documented.rawXP[perk]) or 0; local to=target.rawXP[perk]
        if to>from then queue[#queue+1]={kind="xp",id=perk,from=from,to=to,work=xpWork(to-from),done=0} end
    end
    local categories={}; for category in pairs(discreteOrder) do categories[#categories+1]=category end
    table.sort(categories,function(a,b)return discreteOrder[a]<discreteOrder[b]end)
    for _,category in ipairs(categories) do
        local prior=documented.discrete[category] or {}; local ids={}
        for id in pairs(target.discrete[category]) do if not prior[id] then ids[#ids+1]=id end end
        table.sort(ids); for _,id in ipairs(ids) do queue[#queue+1]={kind="discrete",category=category,id=id,work=5,done=0} end
    end
    assert(#queue<=Journals.MAX_QUEUE,"journal work queue exceeds safe limit")
    return queue
end
local function transmit(item)
    if item and type(item.transmitModData)=="function" then pcall(item.transmitModData,item) end
end
local function defaultClaimStore()
    local modData=rawget(_G,"ModData")
    if type(modData)=="table" and type(modData.getOrCreate)=="function" then
        local canonicalKey=LegacyMigration.STORAGE_CLAIM_STORE_KEY
        if type(modData.get)~="function"then return nil end
        local read,existing=pcall(modData.get,LegacyMigration.CLAIM_STORE_KEY)
        if not read or (existing~=nil and type(existing)~="table")then return nil end
        local ok,result=pcall(modData.getOrCreate,canonicalKey)
        if not ok or not SavedState.claimStore(result) then return nil end
        if existing then
            if not SavedState.claimStore(existing) then return nil end
            -- Validate collisions before touching either store. Exhaustion is
            -- monotonic; a legacy copy cannot reopen a consumed payload.
            for key,value in pairs(existing) do
                if result[key] and result[key].successorId~=value.successorId then return nil end
            end
            for key,value in pairs(existing) do
                if result[key]==nil then result[key]=copy(value)
                elseif value.exhausted then result[key].exhausted=true end
            end
            if type(modData.remove)=="function" then pcall(modData.remove,LegacyMigration.CLAIM_STORE_KEY) end
        end
        if ok and type(result)=="table" then return result end
    end
    return nil
end

function Journals.setClaimStoreProvider(provider)
    assert(provider==nil or type(provider)=="function","claim-store provider must be a function")
    claimStoreProvider=provider
end
function Journals.beginWriting(item,authorId,capture,operationId,context)
    if not canWrite() then return false,"non-authority" end
    if authorId==nil or tostring(authorId)=="" then return false,"stable author ID required" end
    if type(operationId)~="string" or operationId=="" then return false,"stable journal operation ID required" end
    local ok,target=pcall(normalizeCapture,capture); if not ok then return false,target end
    local current,err=state(item,true); if not current then return false,err end
    if current.recovery and current.recovery.exhausted then return false,"recovered keepsake cannot be rewritten" end
    if current.authorId and current.authorId~=tostring(authorId) then return false,"journal belongs to another author" end
    if current.writing then
        if current.writing.operationId==operationId then return true,{duplicate=true,remaining=#current.queue} end
        return false,"journal already has unfinished writing"
    end
    current.authorId=tostring(authorId); current.payloadId=current.payloadId or payloadId(authorId,operationId)
    current.queue=buildQueue(current.documented,target)
    current.writing={operationId=operationId,target=target,startedAtWorldAgeHours=finite(context and context.worldAgeHours),totalWork=0,completedWork=0}
    for _,entry in ipairs(current.queue) do current.writing.totalWork=current.writing.totalWork+entry.work end
    current.revision=current.revision+1; transmit(item)
    return true,{duplicate=false,totalWork=current.writing.totalWork,entries=#current.queue,payloadId=current.payloadId}
end
function Journals.advanceWriting(item,authorId,minutes)
    if not canWrite() then return false,"non-authority" end
    minutes=finite(minutes); if not minutes or minutes<=0 then return false,"positive finite work minutes required" end
    local current,err=state(item,false,true); if not current then return false,err end
    if current.authorId~=tostring(authorId) then return false,"journal belongs to another author" end
    if not current.writing then return false,"no writing in progress" end
    local settings=Config.gameplay()
    local speed=settings.JournalWritingSpeedPercent/100
    local remaining=minutes*speed
    if not finite(remaining)then return false,"finite work duration required"end
    while remaining>0 and #current.queue>0 do
        local entry=current.queue[1]; local used=math.min(remaining,entry.work-entry.done)
        entry.done=entry.done+used; current.writing.completedWork=current.writing.completedWork+used; remaining=remaining-used
        if entry.kind=="xp" then
            local ratio=math.min(1,entry.done/entry.work)
            current.documented.rawXP[entry.id]=entry.from+(entry.to-entry.from)*ratio
        end
        if entry.done>=entry.work then
            if entry.kind=="discrete" then
                current.documented.discrete[entry.category]=current.documented.discrete[entry.category] or {}
                current.documented.discrete[entry.category][entry.id]=true
            end
            table.remove(current.queue,1)
        end
    end
    local completed=#current.queue==0
    if completed then current.writing=nil end
    current.revision=current.revision+1; transmit(item)
    return true,{completed=completed,unusedMinutes=remaining/speed,remainingEntries=#current.queue,documented=copy(current.documented)}
end
function Journals.cancelWriting(item,authorId)
    if not canWrite() then return false,"non-authority" end
    local current,err=state(item,false,true); if not current then return false,err end
    if current.authorId~=tostring(authorId) then return false,"journal belongs to another author" end
    -- Persist the partially documented payload but discard the fixed unwritten target.
    current.queue={}; current.writing=nil; current.revision=current.revision+1; transmit(item)
    return true
end
function Journals.claim(item,successorId,context)
    if not canWrite() then return false,"non-authority" end
    if successorId==nil or tostring(successorId)=="" then return false,"stable successor ID required" end
    local current,err=state(item,false,true); if not current then return false,err end
    if not current.payloadId then return false,"journal has no recovery payload" end
    local provider=claimStoreProvider or defaultClaimStore
    local ok,store=pcall(provider,context); if not ok or type(store)~="table" then return false,"persistent claim store unavailable" end
    local id=tostring(successorId); local claim=store[current.payloadId]; local duplicate=claim~=nil
    if not SavedState.claimStore(store) then return false,"malformed persistent journal claim" end
    if claim and claim.successorId~=id then return false,"journal payload already claimed" end
    if (claim and claim.exhausted==true) or (current.recovery and current.recovery.exhausted==true) then
        return false,"journal payload exhausted"
    end
    if current.recovery and current.recovery.successorId~=id then return false,"journal payload already claimed" end
    if not claim then claim={successorId=id,claimedAtWorldAgeHours=finite(context and context.worldAgeHours),exhausted=false}; store[current.payloadId]=claim end
    current.recovery=current.recovery or {successorId=id,studiedWork=0,exhausted=false}
    if current.recovery.successorId~=id then return false,"journal payload already claimed" end
    transmit(item)
    local result={duplicate=duplicate,exhausted=claim.exhausted==true,payloadId=current.payloadId}
    local claims=API.Claims;local character=context and context.character
    local subject=claims and character and claims.subjectId(character)
    local claimId=subject and "recovery:"..subject..":"..current.payloadId or nil
    local operationId=subject and "journal-claim:"..subject..":"..current.payloadId or nil
    if claimId and #claimId<=160 and #operationId<=160 then
        local granted,reason,value=claims.grantAcquisition(character,{schemaVersion=1,operationId=operationId,claimId=claimId,
            definitionId=LegacyMigration.RECOVERY_DEFINITION,subjectId=subject,sourceType="journal",
            sourceId=current.payloadId,sourceOwner=LegacyMigration.PERSISTED_OWNER,scope={payloadId=current.payloadId},
            acquisition="journal-claim",confidence=1,completeness=1,worldAgeHours=context.worldAgeHours})
        result.knowledgeClaim={ok=granted,reason=reason,value=value}
    end
    return true,result
end
function Journals.recoveryPlan(item,successorId,currentXP,recoveryFraction,context)
    if not canWrite() then return nil,"non-authority" end
    local current,err=state(item,false); if not current then return nil,err end
    if not current.recovery or current.recovery.successorId~=tostring(successorId) then return nil,"successor has not claimed journal" end
    if current.recovery.exhausted then return nil,"journal payload exhausted" end
    local provider=claimStoreProvider or defaultClaimStore
    local ok,store=pcall(provider,context)
    local claim=ok and type(store)=="table" and store[current.payloadId] or nil
    if not SavedState.claimStore(store) or type(claim)~="table" then return nil,"persistent journal claim unavailable" end
    if claim.successorId~=tostring(successorId) then return nil,"journal payload already claimed" end
    if claim.exhausted==true then return nil,"journal payload exhausted" end
    local maximum=Config.gameplay().JournalRecoveryPercent/100
    local fraction=finite(recoveryFraction);if not fraction then fraction=maximum end
    fraction=math.max(0,math.min(maximum,fraction))
    local plan={rawXP={},discrete=copy(current.documented.discrete),fraction=fraction,payloadId=current.payloadId}
    currentXP=type(currentXP)=="table" and currentXP or {}
    for perk,documented in pairs(current.documented.rawXP) do
        local existing=finite(currentXP[perk]) or 0; local target=documented*fraction
        plan.rawXP[perk]=math.max(existing,target)
    end
    return plan
end
function Journals.exhaust(item,successorId,context)
    if not canWrite() then return false,"non-authority" end
    local current,err=state(item,false,true); if not current then return false,err end
    if not current.recovery or current.recovery.successorId~=tostring(successorId) then return false,"successor has not claimed journal" end
    local provider=claimStoreProvider or defaultClaimStore; local ok,store=pcall(provider,context)
    if not ok or not SavedState.claimStore(store) or type(store[current.payloadId])~="table" then return false,"persistent claim store unavailable" end
    if store[current.payloadId].successorId~=tostring(successorId) then return false,"journal payload already claimed" end
    store[current.payloadId].exhausted=true; current.recovery.exhausted=true; current.queue={}; current.writing=nil
    current.revision=current.revision+1; transmit(item); return true
end
function Journals.snapshot(item)local current,err=state(item,false);return current and copy(current)or nil,err end

API.SurvivorJournals=Journals
return Journals
