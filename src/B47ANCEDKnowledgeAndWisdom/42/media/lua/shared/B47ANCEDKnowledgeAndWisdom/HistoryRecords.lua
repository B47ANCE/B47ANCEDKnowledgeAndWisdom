local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local API=require "B47ANCEDKnowledgeAndWisdom/API"
API.HistoryRecords=API.HistoryRecords or {}
local History=API.HistoryRecords
History.SCHEMA_VERSION=1
History.STORE_KEY=LegacyMigration.STORAGE_HISTORY_KEY
History.MAX_RECORDS=512
History.MAX_OPERATIONS=1024
local providers={};local store=nil
local visibilities={private=true,group=true,public=true}

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
local function text(value,maximum)
    value=tostring(value or ""):gsub("[%c]"," "):gsub("%s+"," ")
    value=value:gsub("^%s+",""):gsub("%s+$","")
    if #value>maximum then value=value:sub(1,maximum)end
    return value
end
local function copy(value,depth)
    if type(value)~="table"then return value end
    depth=(depth or 0)+1;if depth>3 then return nil end
    local result={};local count=0
    for key,entry in pairs(value)do
        if type(key)=="string" and #key<=64 and count<32 then result[key]=copy(entry,depth);count=count+1 end
    end
    return result
end
local function provider(id)
    for _,value in ipairs(providers)do if value.id==id then return value end end
end
local function actorId(source,actor)
    local ok,value=pcall(source.getActorId,actor);value=ok and tostring(value or "")or""
    return valid(value)and value or nil
end
local function operationResult(entry)
    return entry.ok,entry.reason,copy(entry.record)
end
local function scalar(value)
    local kind=type(value)
    if kind=="nil"then return"n:"end
    if kind=="boolean"then return value and"b:1"or"b:0"end
    if kind=="number"then local number=finite(value);return number and("d:"..string.format("%.17g",number))or"x:"end
    local valueText=tostring(value);return"s:"..#valueText..":"..valueText
end
local function binding(action,request,body)
    return table.concat({scalar(action),scalar(request.recordId),scalar(request.authorId),scalar(request.actorId),
        scalar(request.subjectId),scalar(request.providerId),scalar(request.evidenceId),scalar(body),
        scalar(request.visibility),scalar(request.groupId),scalar(request.removalPolicy),scalar(request.reason),
        scalar(request.regionId),scalar(request.worldAgeHours)},"|")
end
local function remember(operationId,entry)
    store.operations[operationId]=entry;store.operationOrder[#store.operationOrder+1]=operationId
    while #store.operationOrder>History.MAX_OPERATIONS do store.operations[table.remove(store.operationOrder,1)]=nil end
end

function History.attachStore(value)
    if not authority()or type(value)~="table"then return false,"AUTHORITY_STORE_REQUIRED"end
    if value.schemaVersion~=nil and value.schemaVersion~=1 then return false,"UNSUPPORTED_SCHEMA"end
    value.schemaVersion=1;value.records=type(value.records)=="table"and value.records or {}
    value.operations=type(value.operations)=="table"and value.operations or {}
    local order,seen={},{}
    for _,id in ipairs(type(value.order)=="table"and value.order or {})do
        if valid(id)and type(value.records[id])=="table"and not seen[id]then order[#order+1]=id;seen[id]=true end
    end
    while #order>History.MAX_RECORDS do value.records[table.remove(order,1)]=nil end
    value.order=order
    local operationOrder,operationSeen={},{}
    for _,id in ipairs(type(value.operationOrder)=="table"and value.operationOrder or {})do
        if valid(id)and type(value.operations[id])=="table"and not operationSeen[id]then
            operationOrder[#operationOrder+1]=id;operationSeen[id]=true
        end
    end
    while #operationOrder>History.MAX_OPERATIONS do value.operations[table.remove(operationOrder,1)]=nil end
    value.operationOrder=operationOrder
    store=value;return true
end
function History.registerEvidenceProvider(definition)
    assert(type(definition)=="table"and valid(definition.id),"history evidence provider id required")
    for _,name in ipairs({"getActorId","validateEvidence"})do assert(type(definition[name])=="function","history provider "..name.." required")end
    assert(not provider(definition.id),"duplicate history evidence provider: "..definition.id)
    providers[#providers+1]={id=definition.id,getActorId=definition.getActorId,validateEvidence=definition.validateEvidence,
        canRead=definition.canRead,canRemove=definition.canRemove}
    table.sort(providers,function(a,b)return a.id<b.id end);return {id=definition.id}
end
function History.create(actor,request)
    if not authority()then return false,"NON_AUTHORITY"end
    if not store then return false,"STORE_UNAVAILABLE"end
    if type(request)~="table"or request.schemaVersion~=1 or not valid(request.operationId)or not valid(request.recordId)
        or not valid(request.authorId)or not valid(request.subjectId)or not valid(request.providerId)
        or not valid(request.evidenceId)or not visibilities[request.visibility]then return false,"INVALID_REQUEST"end
    local source=provider(request.providerId);if not source then return false,"PROVIDER_UNAVAILABLE"end
    if actorId(source,actor)~=request.authorId then return false,"AUTHOR_MISMATCH"end
    local body=text(request.text,1024);if #body<1 then return false,"CONTENT_REQUIRED"end
    local requestBinding=binding("create",request,body)
    local prior=store.operations[request.operationId]
    if prior then
        if type(prior.binding)~="string"then return false,"OPERATION_REPLAY_UNVERIFIABLE"end
        if prior.action~="create"or prior.binding~=requestBinding then return false,"OPERATION_ID_CONFLICT"end
        return operationResult(prior)
    end
    if store.records[request.recordId]then return false,"RECORD_ID_CONFLICT"end
    if #store.order>=History.MAX_RECORDS then return false,"RECORD_LIMIT_REACHED"end
    local called,allowed,evidence=pcall(source.validateEvidence,actor,request.subjectId,request.evidenceId,request)
    if not called or allowed~=true then return false,text(evidence or "EVIDENCE_REJECTED",160)end
    local record={schemaVersion=1,recordId=request.recordId,authorId=request.authorId,subjectId=request.subjectId,
        providerId=request.providerId,evidenceId=request.evidenceId,evidence=copy(evidence),text=body,
        createdAtWorldAgeHours=finite(request.worldAgeHours),visibility=request.visibility,
        groupId=valid(request.groupId)and request.groupId or nil,removalPolicy=request.removalPolicy=="provider"and"provider"or"author",
        removed=false}
    if record.visibility=="group"and not record.groupId then return false,"GROUP_ID_REQUIRED"end
    store.records[record.recordId]=record;store.order[#store.order+1]=record.recordId
    local result={action="create",recordId=record.recordId,authorId=record.authorId,binding=requestBinding,
        ok=true,reason="CREATED",record=copy(record)}
    remember(request.operationId,result);return true,result.reason,copy(record)
end
local function readable(source,actor,record)
    local id=actorId(source,actor);if not id then return false end
    if record.visibility=="public"or record.authorId==id then return true end
    if type(source.canRead)~="function"then return false end
    local ok,value=pcall(source.canRead,actor,record);return ok and value==true
end
function History.list(actor,options)
    if not store then return nil,"STORE_UNAVAILABLE"end
    options=type(options)=="table"and options or {};local maximum=math.max(1,math.min(256,math.floor(tonumber(options.maximum) or 64)))
    local result={schemaVersion=1,records={},limited=false}
    for _,id in ipairs(store.order)do
        local record=store.records[id];local source=record and provider(record.providerId)
        if record and source and (options.includeRemoved==true or not record.removed)and readable(source,actor,record)then
            if #result.records>=maximum then result.limited=true;break end
            result.records[#result.records+1]=copy(record)
        end
    end
    return result
end
function History.remove(actor,request)
    if not authority()then return false,"NON_AUTHORITY"end
    if not store then return false,"STORE_UNAVAILABLE"end
    if type(request)~="table"or request.schemaVersion~=1 or not valid(request.operationId)or not valid(request.recordId)
        or not valid(request.actorId)or not valid(request.reason)then return false,"INVALID_REQUEST"end
    local record=store.records[request.recordId];if not record then return false,"UNKNOWN_RECORD"end
    local source=provider(record.providerId);if not source or actorId(source,actor)~=request.actorId then return false,"ACTOR_MISMATCH"end
    local requestBinding=binding("remove",request)
    local prior=store.operations[request.operationId]
    if prior then
        if type(prior.binding)~="string"then return false,"OPERATION_REPLAY_UNVERIFIABLE"end
        if prior.action~="remove"or prior.binding~=requestBinding then return false,"OPERATION_ID_CONFLICT"end
        return operationResult(prior)
    end
    local allowed=record.removalPolicy=="author"and record.authorId==request.actorId
    if not allowed and type(source.canRemove)=="function"then local ok,value=pcall(source.canRemove,actor,record,request);allowed=ok and value==true end
    if not allowed then return false,"REMOVAL_DENIED"end
    record.removed=true;record.removedBy=request.actorId;record.removalReason=request.reason;record.removedAtWorldAgeHours=finite(request.worldAgeHours)
    local result={action="remove",recordId=record.recordId,authorId=request.actorId,binding=requestBinding,
        ok=true,reason="REMOVED",record=copy(record)}
    remember(request.operationId,result);return true,result.reason,copy(record)
end
return History
