local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local SavedState=require "B47ANCEDKnowledgeAndWisdom/SavedState"
local API=require "B47ANCEDKnowledgeAndWisdom/API"
API.Claims=API.Claims or {}
local Claims=API.Claims
Claims.SCHEMA_VERSION=1
Claims.ROOT_KEY=LegacyMigration.STORAGE_CLAIMS_KEY
Claims.MAX_CLAIMS=512
Claims.MAX_OPERATIONS=1024
local definitions={}
local regions={}
local kinds={literature=true,media=true,journal=true,recovery=true,geography=true,history=true}

local function valid(value,maximum)
    return type(value)=="string" and #value>0 and #value<=(maximum or 160) and value:match("^[%w_%.:%-]+$")~=nil
end
local function authority()
    local client=type(rawget(_G,"isClient"))=="function" and isClient()==true
    local server=type(rawget(_G,"isServer"))=="function" and isServer()==true
    return server or not client
end
local function finite(value)
    value=tonumber(value);return value and value==value and value~=math.huge and value~=-math.huge and value or nil
end
local function unit(value,default)
    value=finite(value);return value and math.max(0,math.min(1,value)) or default
end
local function copy(value,seen,depth)
    if type(value)~="table" then return value end
    depth=(depth or 0)+1;if depth>4 then return nil end
    seen=seen or {};if seen[value] then return nil end;seen[value]=true
    local result={};local count=0
    for key,entry in pairs(value)do
        local allowed=(type(key)=="string" and #key<=64)
            or (type(key)=="number" and key%1==0 and key>=1 and key<=32)
        if allowed and count<32 then result[key]=copy(entry,seen,depth);count=count+1 end
    end
    seen[value]=nil;return result
end
local function subjectId(character)
    if not character then return nil end
    for _,method in ipairs({"getUsername","getSteamID","getOnlineID"})do
        local ok,fn=pcall(function()return character[method]end)
        if ok and type(fn)=="function" then
            local called,value=pcall(fn,character)
            local rawValid=called and ((method=="getUsername"and type(value)=="string"and value~="")
                or (method~="getUsername"and (type(value)=="number"or type(value)=="string")
                    and finite(value)and (method=="getOnlineID"and tonumber(value)>=0 or tonumber(value)>0)))
            if rawValid then
                local candidate=method..":"..tostring(value)
                if valid(candidate)then return candidate end
            end
        end
    end
end
local function ledger(character,create)
    if not character or type(character.getModData)~="function" then return nil,"CHARACTER_MODDATA_UNAVAILABLE" end
    local ok,data=pcall(character.getModData,character)
    if not ok or type(data)~="table" then return nil,"CHARACTER_MODDATA_UNAVAILABLE" end
    local value=data[Claims.ROOT_KEY]
    if value==nil then
        value={schemaVersion=1,claims={},order={},operations={},operationOrder={}}
        if create then data[Claims.ROOT_KEY]=value end
        return value
    end
    if not SavedState.claims(value) then
        return nil,"UNSUPPORTED_OR_MALFORMED_CLAIMS_LEDGER"
    end
    return value
end
local function normalizeScope(definition,value)
    if type(value)~="table" then return nil,"INVALID_SCOPE" end
    if definition.kind=="geography" then
        if not valid(value.regionId,128) then return nil,"REGION_ID_REQUIRED" end
        local granularity=value.granularity or definition.granularity
        if granularity~=definition.granularity then return nil,"GRANULARITY_MISMATCH" end
        local region=regions[value.regionId]
        if not region or region.granularity~=granularity then return nil,"UNKNOWN_OR_INCOMPATIBLE_REGION" end
        return {regionId=value.regionId,granularity=granularity}
    end
    local result={}
    for _,field in ipairs(definition.scopeFields)do
        if not valid(value[field])then return nil,"SCOPE_FIELD_REQUIRED:"..field end
        result[field]=value[field]
    end
    return result
end
local function scalar(value)
    local kind=type(value)
    if kind=="nil" then return "n:" end
    if kind=="boolean" then return value and "b:1" or "b:0" end
    if kind=="number" then
        local number=finite(value);return number and ("d:"..string.format("%.17g",number)) or "x:"
    end
    local text=tostring(value)
    return "s:"..#text..":"..text
end
local function requestBinding(action,request,scope)
    local parts={scalar(action),scalar(request.claimId),scalar(request.definitionId),scalar(request.subjectId),
        scalar(request.sourceType),scalar(request.sourceId),scalar(request.sourceOwner),scalar(request.acquisition),
        scalar(request.confidence),scalar(request.completeness),scalar(request.worldAgeHours),scalar(request.reason)}
    local keys={};for key in pairs(scope or {})do keys[#keys+1]=key end;table.sort(keys)
    for _,key in ipairs(keys)do parts[#parts+1]=scalar(key).."="..scalar(scope[key])end
    return table.concat(parts,"|")
end
local function remember(current,id,action,request,result,binding)
    current.operations[id]={action=action,claimId=request.claimId,definitionId=request.definitionId,
        subjectId=request.subjectId,binding=binding,ok=result.ok,reason=result.reason,claim=copy(result.claim)}
    current.operationOrder[#current.operationOrder+1]=id
    while #current.operationOrder>Claims.MAX_OPERATIONS do current.operations[table.remove(current.operationOrder,1)]=nil end
end
local function replay(current,request,action,binding)
    local value=current.operations[request.operationId];if not value then return nil end
    if type(value.binding)~="string"then return false,"OPERATION_REPLAY_UNVERIFIABLE"end
    if value.action~=action or value.binding~=binding then return false,"OPERATION_ID_CONFLICT" end
    return value.ok,value.reason,copy(value.claim)
end
local function scopesEqual(left,right)
    for key,value in pairs(left or {})do if right[key]~=value then return false end end
    for key,value in pairs(right or {})do if left[key]~=value then return false end end
    return true
end

function Claims.registerDefinition(definition)
    assert(type(definition)=="table" and valid(definition.id),"claim definition id required")
    assert(valid(definition.owner),"claim definition owner required")
    assert(kinds[definition.kind],"claim definition kind required")
    assert(not definitions[definition.id],"duplicate claim definition: "..definition.id)
    local def={id=definition.id,owner=definition.owner,kind=definition.kind,title=tostring(definition.title or definition.id):sub(1,160),
        acquisition=tostring(definition.acquisition or "explicit"):sub(1,80),scopeFields={}}
    if def.kind=="geography" then
        assert(definition.granularity=="locality" or definition.granularity=="county" or definition.granularity=="region",
            "geographic granularity must be locality, county, or region")
        def.granularity=definition.granularity
    else
        local seen={};for _,field in ipairs(definition.scopeFields or {})do
            assert(valid(field,64),"claim scope field invalid")
            if not seen[field]then seen[field]=true;def.scopeFields[#def.scopeFields+1]=field end
        end
        table.sort(def.scopeFields)
        assert(#def.scopeFields<=32,"claim definition has too many scope fields")
    end
    definitions[def.id]=def;return copy(def)
end
function Claims.getDefinition(id)return copy(definitions[id])end
function Claims.registerRegion(definition)
    assert(type(definition)=="table" and valid(definition.id,128),"region id required")
    assert(definition.granularity=="locality" or definition.granularity=="county" or definition.granularity=="region",
        "region granularity must be locality, county, or region")
    assert(valid(definition.owner),"region owner required")
    assert(not regions[definition.id],"duplicate region: "..definition.id)
    regions[definition.id]={id=definition.id,owner=definition.owner,granularity=definition.granularity,
        title=tostring(definition.title or definition.id):sub(1,160)}
    return copy(regions[definition.id])
end
function Claims.getRegion(id)return copy(regions[id])end

function Claims.grant(character,request)
    if not authority()then return false,"NON_AUTHORITY" end
    if type(request)~="table" or request.schemaVersion~=1 or not valid(request.operationId) or not valid(request.claimId)
        or not valid(request.definitionId) or not valid(request.subjectId) or not valid(request.sourceType,64)
        or not valid(request.sourceId) or not valid(request.sourceOwner)then return false,"INVALID_REQUEST" end
    if subjectId(character)~=request.subjectId then return false,"SUBJECT_MISMATCH" end
    local current,err=ledger(character,true);if not current then return false,err end
    local definition=definitions[request.definitionId];if not definition then return false,"UNKNOWN_DEFINITION" end
    if request.sourceOwner~=definition.owner and request.sourceOwner~=LegacyMigration.PERSISTED_OWNER then return false,"SOURCE_OWNER_MISMATCH" end
    local scope,scopeError=normalizeScope(definition,request.scope);if not scope then return false,scopeError end
    local binding=requestBinding("grant",request,scope)
    local replayOK,replayReason,replayClaim=replay(current,request,"grant",binding)
    if replayOK~=nil then return replayOK,replayReason,replayClaim end
    local existing=current.claims[request.claimId]
    if existing then
        local same=existing.definitionId==request.definitionId and existing.subjectId==request.subjectId
            and existing.source.type==request.sourceType and existing.source.id==request.sourceId
            and existing.source.owner==request.sourceOwner and scopesEqual(existing.scope,scope)
            and existing.acquisition==tostring(request.acquisition or definition.acquisition):sub(1,80)
            and existing.confidence==unit(request.confidence,1) and existing.completeness==unit(request.completeness,1)
            and existing.acquiredAtWorldAgeHours==finite(request.worldAgeHours)
        local replayResult={ok=same,reason=same and "DUPLICATE" or "CLAIM_ID_CONFLICT",claim=copy(existing)}
        remember(current,request.operationId,"grant",request,replayResult,binding);return replayResult.ok,replayResult.reason,replayResult.claim
    end
    if #current.order>=Claims.MAX_CLAIMS then return false,"CLAIM_LIMIT_REACHED" end
    local claim={schemaVersion=1,claimId=request.claimId,definitionId=definition.id,kind=definition.kind,owner=definition.owner,
        subjectId=request.subjectId,source={type=request.sourceType,id=request.sourceId,owner=request.sourceOwner},scope=scope,
        acquisition=tostring(request.acquisition or definition.acquisition):sub(1,80),confidence=unit(request.confidence,1),
        completeness=unit(request.completeness,1),acquiredAtWorldAgeHours=finite(request.worldAgeHours),revoked=false}
    current.claims[claim.claimId]=claim;current.order[#current.order+1]=claim.claimId
    local result={ok=true,reason="GRANTED",claim=copy(claim)};remember(current,request.operationId,"grant",request,result,binding)
    if type(character.transmitModData)=="function"then pcall(character.transmitModData,character)end
    return true,result.reason,copy(claim)
end

-- Built-in adapters describe acquisition of one immutable fact, not a new
-- request every time that fact is observed. Preserve its original timestamp;
-- grant still validates every other bound field and direct requests stay strict.
function Claims.grantAcquisition(character,request)
    if not authority() then return false,"NON_AUTHORITY" end
    if type(request)~="table" or not valid(request.claimId) then return false,"INVALID_REQUEST" end
    if request.sourceOwner~=LegacyMigration.PERSISTED_OWNER or (request.definitionId~=LegacyMigration.LITERATURE_DEFINITION
        and request.definitionId~=LegacyMigration.RECOVERY_DEFINITION and request.definitionId~=LegacyMigration.HOMETOWN_DEFINITION)then
        return false,"BUILTIN_ACQUISITION_REQUIRED"
    end
    local current,err=ledger(character,false);if not current then return false,err end
    local previous=current.claims[request.claimId]
    if previous then
        if previous.revoked then return false,"CLAIM_REVOKED",copy(previous)end
        local logical={};for key,value in pairs(request)do logical[key]=value end
        logical.worldAgeHours=previous.acquiredAtWorldAgeHours
        return Claims.grant(character,logical)
    end
    return Claims.grant(character,request)
end

function Claims.revoke(character,request)
    if not authority()then return false,"NON_AUTHORITY" end
    if type(request)~="table" or request.schemaVersion~=1 or not valid(request.operationId) or not valid(request.claimId)
        or not valid(request.subjectId) or not valid(request.reason)then return false,"INVALID_REQUEST" end
    if subjectId(character)~=request.subjectId then return false,"SUBJECT_MISMATCH" end
    local current,err=ledger(character,true);if not current then return false,err end
    local binding=requestBinding("revoke",request)
    local replayOK,replayReason,replayClaim=replay(current,request,"revoke",binding)
    if replayOK~=nil then return replayOK,replayReason,replayClaim end
    local claim=current.claims[request.claimId];if not claim then return false,"UNKNOWN_CLAIM" end
    if not claim.revoked then claim.revoked=true;claim.revocationReason=request.reason:sub(1,160);claim.revokedAtWorldAgeHours=finite(request.worldAgeHours) end
    local result={ok=true,reason="REVOKED",claim=copy(claim)};remember(current,request.operationId,"revoke",request,result,binding)
    if type(character.transmitModData)=="function"then pcall(character.transmitModData,character)end
    return true,result.reason,copy(claim)
end

function Claims.snapshot(character,options)
    local current,err=ledger(character,false);if not current then return nil,err end
    options=type(options)=="table" and options or {};local includeRevoked=options.includeRevoked==true
    local maximum=math.max(1,math.min(Claims.MAX_CLAIMS,math.floor(tonumber(options.maximum) or 128)))
    local result={schemaVersion=1,subjectId=subjectId(character),claims={},limited=false}
    for _,id in ipairs(current.order)do
        local claim=current.claims[id]
        if claim and (includeRevoked or not claim.revoked)then
            if #result.claims>=maximum then result.limited=true;break end
            result.claims[#result.claims+1]=copy(claim)
        end
    end
    return result
end
Claims.subjectId=subjectId
Claims.KINDS=kinds
if not definitions[LegacyMigration.LITERATURE_DEFINITION]then
    Claims.registerDefinition{id=LegacyMigration.LITERATURE_DEFINITION,owner=LegacyMigration.PERSISTED_OWNER,kind="literature",
        title="Literature read",acquisition="read-completion",scopeFields={"documentId","itemType"}}
end
if not definitions[LegacyMigration.RECOVERY_DEFINITION]then
    Claims.registerDefinition{id=LegacyMigration.RECOVERY_DEFINITION,owner=LegacyMigration.PERSISTED_OWNER,kind="recovery",
        title="Survivor journal recovery",acquisition="journal-claim",scopeFields={"payloadId"}}
end
if not definitions[LegacyMigration.HOMETOWN_DEFINITION]then
    Claims.registerDefinition{id=LegacyMigration.HOMETOWN_DEFINITION,owner=LegacyMigration.PERSISTED_OWNER,kind="geography",
        title="Hometown familiarity",acquisition="explicit-origin-provider",granularity="locality"}
end
return Claims
