-- Pure Lua validation. Never repairs, normalizes or deletes persisted input.
local V={}
function V.finite(v)return type(v)=="number"and v==v and v~=math.huge and v~=-math.huge end
function V.string(v,n)return type(v)=="string"and #v>0 and #v<=(n or 4096)end
function V.optionalNumber(v)return v==nil or V.finite(v)end
function V.integer(v)return V.finite(v)and v>=0 and v%1==0 and v<9007199254740991 end
function V.empty(v)if type(v)~="table"then return false end;for _ in pairs(v)do return false end;return true end
-- Technical deserialization limits, not gameplay settings. Shared sub-tables are
-- legal; cycles, unsupported values and pathological trees fail without mutation.
function V.tree(value)
    local active,count={},0
    local function visit(v,depth)
        count=count+1;if count>262144 or depth>12 then return false end
        local kind=type(v)
        if kind=="number"then return V.finite(v)end
        if kind=="string"then return #v<=65536 end
        if kind=="boolean"or kind=="nil"then return true end
        if kind~="table"or active[v]then return false end
        active[v]=true
        for key,child in pairs(v)do
            if (type(key)~="string"and type(key)~="number")or not visit(key,depth+1)or not visit(child,depth+1)then return false end
        end
        active[v]=nil;return true
    end
    return visit(value,0)
end
function V.array(values,check,maximum)
    if type(values)~="table"then return false end
    local count=0
    for key,value in pairs(values)do
        if not V.integer(key)or key<1 or key>#values or not check(value)then return false end
        count=count+1
    end
    return count==#values and (not maximum or count<=maximum)
end
local function map(values,check)
    if type(values)~="table"then return false end
    for key,value in pairs(values)do if not V.string(key)or not check(value,key)then return false end end
    return true
end
local function indexed(order,values,maximum)
    local seen={}
    if not V.array(order,function(id)
        if not V.string(id)or seen[id]or values[id]==nil then return false end
        seen[id]=true;return true
    end,maximum)then return false end
    for id in pairs(values)do if not seen[id]then return false end end
    return true
end
function V.knowledge(v)
    if type(v)~="table"or v.schemaVersion~=1 or not V.tree(v)then return false end
    local function record(r)
        return r==true or (type(r)=="table"and V.optionalNumber(r.learnedAtWorldAgeHours)
            and (r.sourceFullType==nil or V.string(r.sourceFullType)))
    end
    return map(v.documents,record)and map(v.knowledge,record)
end
local statuses={pending=true,uncertain=true,committed=true,["resolved-uncertain"]=true}
function V.progression(v)
    if type(v)~="table"or v.schemaVersion~=1 or not V.tree(v)or not V.integer(v.nextTransaction)or v.nextTransaction<1 then return false end
    if type(v.sources)~="table"then return false end
    if v.sourceOrder~=nil and (not indexed(v.sourceOrder,v.sources)
        or not V.integer(v.sourceCursor)or v.sourceCursor<1 or v.sourceCursor>math.max(1,#v.sourceOrder))then return false end
    return map(v.sources,function(r,key)
        if type(r)=="table"and r.quarantinedTransaction~=nil then
            local tx=type(v.transactions)=="table"and v.transactions[r.quarantinedTransaction]or nil
            if type(tx)~="table"or (tx.status~="uncertain"and tx.status~="pending")or tx.sourceKey~=key then return false end
        end
        return type(r)=="table"and V.finite(r.lastAt)and V.integer(r.repeats)
            and (r.windowHours==nil or (V.finite(r.windowHours)and r.windowHours>0))
            and (r.quarantinedTransaction==nil or V.string(r.quarantinedTransaction))
    end)and map(v.transactions,function(r,id)
        local ordinal=tonumber(id)
        if not V.integer(ordinal)or ordinal<1 or ordinal>=v.nextTransaction then return false end
        if type(r)=="table"and (r.status=="pending"or r.status=="uncertain")then
            local source=v.sources[r.sourceKey]
            if type(source)~="table"or source.quarantinedTransaction~=id then return false end
        end
        return type(r)=="table"and statuses[r.status]==true and V.string(r.action)and V.string(r.sourceKey)
            and V.finite(r.worldAgeHours)and (r.totalXP==nil or (V.finite(r.totalXP)and r.totalXP>=0))
    end)
end
local categories={documents=true,recipes=true,maps=true,media=true,knowledge=true,research=true}
local function documented(v)
    return type(v)=="table"and map(v.rawXP,function(n)return V.finite(n)and n>=0 end)
        and map(v.discrete,function(set,category)
            return categories[category]==true and map(set,function(flag)return type(flag)=="boolean"end)
        end)
end
function V.journal(v)
    if type(v)~="table"or v.schemaVersion~=1 or not V.tree(v)or not V.integer(v.revision)or not documented(v.documented)then return false end
    if (v.payloadId~=nil and not V.string(v.payloadId))or (v.authorId~=nil and not V.string(v.authorId))then return false end
    local remaining,seen=0,{}
    if not V.array(v.queue,function(r)
        if type(r)~="table"or not V.string(r.id)or not V.finite(r.work)or r.work<=0
            or not V.finite(r.done)or r.done<0 or r.done>r.work then return false end
        if r.kind~="xp"and r.kind~="discrete"then return false end
        local key=r.kind=="xp"and("xp:"..r.id)or("discrete:"..tostring(r.category)..":"..r.id)
        if seen[key]then return false end;seen[key]=true
        remaining=remaining+(r.work-r.done);if not V.finite(remaining)then return false end
        if r.kind=="xp"then return V.finite(r.from)and r.from>=0 and V.finite(r.to)and r.to>=r.from end
        return r.kind=="discrete"and categories[r.category]==true
    end,512)then return false end
    if v.writing~=nil then
        local w=v.writing
        if type(w)~="table"or not V.string(w.operationId)or not documented(w.target)
            or not V.finite(w.totalWork)or w.totalWork<0 or not V.finite(w.completedWork)
            or w.completedWork<0 or w.completedWork>w.totalWork+0.0000001 then return false end
        if math.abs(w.totalWork-w.completedWork-remaining)>0.00001 then return false end
        for _,entry in ipairs(v.queue)do
            if entry.kind=="xp"then
                if w.target.rawXP[entry.id]~=entry.to then return false end
            elseif not w.target.discrete[entry.category]or w.target.discrete[entry.category][entry.id]~=true then return false end
        end
    elseif #v.queue>0 then return false end
    local r=v.recovery
    return r==nil or (type(r)=="table"and V.string(r.successorId)and type(r.exhausted)=="boolean"
        and V.finite(r.studiedWork)and r.studiedWork>=0)
end
function V.claimStore(v)
    return type(v)=="table"and V.tree(v)and map(v,function(r)
        return type(r)=="table"and V.string(r.successorId)and type(r.exhausted)=="boolean"
            and V.optionalNumber(r.claimedAtWorldAgeHours)
    end)
end
local kinds={literature=true,media=true,journal=true,recovery=true,geography=true,history=true}
local function claim(r,id)
    return type(r)=="table"and r.schemaVersion==1 and r.claimId==id and V.string(r.definitionId)
        and V.string(r.subjectId)and V.string(r.owner)and kinds[r.kind]==true
        and type(r.source)=="table"and V.string(r.source.type)and V.string(r.source.id)and V.string(r.source.owner)
        and map(r.scope,function(s)return V.string(s,160)end)and V.string(r.acquisition,80)
        and V.finite(r.confidence)and r.confidence>=0 and r.confidence<=1
        and V.finite(r.completeness)and r.completeness>=0 and r.completeness<=1
        and V.optionalNumber(r.acquiredAtWorldAgeHours)and type(r.revoked)=="boolean"
end
function V.claims(v)
    if type(v)~="table"or v.schemaVersion~=1 or not V.tree(v)
        or not map(v.claims,claim)or not map(v.operations,function(r)
            return type(r)=="table"and (r.action=="grant"or r.action=="revoke")and V.string(r.claimId)
                and V.string(r.subjectId)and type(r.ok)=="boolean"
                and (r.binding==nil or V.string(r.binding,65536))
                and (r.claim==nil or claim(r.claim,r.claimId))
        end)then return false end
    return indexed(v.order,v.claims,512)and indexed(v.operationOrder,v.operations,1024)
end
local visibility={private=true,group=true,public=true}
local function historyRecord(r,id)
    return type(r)=="table"and r.schemaVersion==1 and r.recordId==id and V.string(r.authorId)
        and V.string(r.subjectId)and V.string(r.providerId)and V.string(r.evidenceId)
        and V.string(r.text,1024)and visibility[r.visibility]==true and type(r.removed)=="boolean"
        and (r.removalPolicy=="author"or r.removalPolicy=="provider")
        and (r.visibility~="group"or V.string(r.groupId))and V.optionalNumber(r.createdAtWorldAgeHours)
end
function V.history(v)
    if type(v)~="table"or not V.tree(v)then return false end
    if V.empty(v)then return true end
    if v.schemaVersion==nil then
        return V.empty(v.records)and V.empty(v.operations)and V.empty(v.order)and V.empty(v.operationOrder)
    end
    if v.schemaVersion~=1 or not map(v.records,historyRecord)or not map(v.operations,function(r)
        return type(r)=="table"and (r.action=="create"or r.action=="remove")and V.string(r.recordId)
            and V.string(r.authorId)and type(r.ok)=="boolean"and (r.binding==nil or V.string(r.binding,65536))
            and (r.record==nil or historyRecord(r.record,r.recordId))
    end)then return false end
    return indexed(v.order,v.records,512)and indexed(v.operationOrder,v.operations,1024)
end
return V
