local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local API=require "B47ANCEDKnowledgeAndWisdom/API"
local Claims=API.Claims or require "B47ANCEDKnowledgeAndWisdom/Claims"
local Origin={MAX_PROVIDERS=32};local providers={};local providerCount=0
local function valid(value,maximum)return type(value)=="string"and#value>0 and#value<=(maximum or 160)and value:match("^[%w_%.:%-]+$")~=nil end
local function finite(value)value=tonumber(value);return value and value==value and value~=math.huge and value~=-math.huge and value or nil end
function Origin.registerProvider(definition)
    assert(type(definition)=="table"and valid(definition.id,96)and type(definition.observe)=="function","origin provider id/observe required")
    assert(not providers[definition.id],"duplicate origin provider")
    providerCount=providerCount+1;assert(providerCount<=Origin.MAX_PROVIDERS,"origin provider limit reached")
    providers[definition.id]={id=definition.id,owner=valid(definition.owner,96)and definition.owner or definition.id,
        priority=finite(definition.priority)or 0,observe=definition.observe};return{id=definition.id}
end
function Origin.observe(character,context)
    local ordered={};for _,provider in pairs(providers)do ordered[#ordered+1]=provider end
    table.sort(ordered,function(a,b)return a.priority==b.priority and a.id<b.id or a.priority>b.priority end)
    for _,provider in ipairs(ordered)do
        local ok,value=pcall(provider.observe,character,context or{})
        if ok and value~=nil then
            if type(value)~="table"or not valid(value.originId,128)or not valid(value.regionId,128)
                or not valid(value.evidenceId,160)then return nil,"INVALID_ORIGIN_EVIDENCE"end
            local region=Claims.getRegion(value.regionId)
            if not region or region.granularity~="locality"then return nil,"UNKNOWN_OR_INCOMPATIBLE_REGION"end
            return{schemaVersion=1,providerId=provider.id,providerOwner=provider.owner,originId=value.originId,
                regionId=value.regionId,evidenceId=value.evidenceId,confidence=math.max(0,math.min(1,finite(value.confidence)or 1))}
        end
    end
    return nil,"ORIGIN_UNAVAILABLE"
end
function Origin.grant(character,context)
    local evidence,reason=Origin.observe(character,context);if not evidence then return false,reason end
    local subject=Claims.subjectId(character);if not subject then return false,"SUBJECT_UNAVAILABLE"end
    local suffix=subject..":"..evidence.providerId..":"..evidence.originId..":"..evidence.regionId
    local operationId="origin-grant:"..suffix;local claimId="hometown:"..suffix
    if#operationId>160 or#claimId>160 then return false,"ORIGIN_IDENTITY_TOO_LONG"end
    return Claims.grantAcquisition(character,{schemaVersion=1,operationId=operationId,claimId=claimId,
        definitionId=LegacyMigration.HOMETOWN_DEFINITION,subjectId=subject,sourceType="origin-provider",
        sourceId=evidence.evidenceId,sourceOwner=LegacyMigration.PERSISTED_OWNER,scope={regionId=evidence.regionId,granularity="locality"},
        acquisition="explicit-origin-provider",confidence=evidence.confidence,completeness=1,
        worldAgeHours=finite(context and context.worldAgeHours)})
end
API.OriginKnowledge=Origin;API.registerOriginProvider=Origin.registerProvider
API.observeOriginKnowledge=Origin.observe;API.grantOriginKnowledge=Origin.grant
return Origin
