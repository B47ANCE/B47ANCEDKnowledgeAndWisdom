-- Dedicated knowledge only. No GlobalModData, client-owned ledgers or eval.
local Guard=require'B47ANCEDKnowledgeAndWisdom/AuthorityGuard'
local Codec=require'B47ANCEDKnowledgeAndWisdom/PrivateCodec'
local Saved=require'B47ANCEDKnowledgeAndWisdom/SavedState'
local API=require'B47ANCEDKnowledgeAndWisdom/API'
local Store={LIFE_KEY='B47ANCEDKnowledgeAndWisdom.privateLife.v1'}
local state,journal,sequence,filename,world,failure=nil,'',0,nil,nil,'PRIVATE_STORE_NOT_INITIALIZED'
local MODULE='B47ANCEDKnowledgeAndWisdom.Knowledge'
local initialized=false
-- Technical safety bounds on disk/parser/network work, never gameplay tuning.
local MAX_LOG,MAX_RECORDS=16777216,16384
local subscriptions=setmetatable({},{__mode='k'})
local function clone(value)
    local encoded=Codec.encode(value);return assert(Codec.decode(encoded))
end
local function account(actor)
    if not actor or type(actor.getUsername)~='function'then return nil end
    local name=actor:getUsername()
    if not Saved.string(name,128)then return nil end
    -- Native creation assigns the authenticated username. Never convert 64-bit
    -- Steam IDs through Lua doubles, or accept an identity in command arguments.
    return Codec.encode({username=name})
end
local function token(actor)
    if not actor or type(actor.getModData)~='function'then return nil end
    local data=actor:getModData()
    return type(data)=='table'and data[Store.LIFE_KEY]or nil
end
local function validId(id)return type(id)=='string'and #id>=16 and #id<=64 and id:match('^[%w%-]+$')~=nil end
local function apply(current,record)
    if type(record)~='table'then error('invalid record')end
    if record.kind=='world'then
        if record.world~=world or not validId(record.epoch)then error('world identity mismatch')end
        return{epoch=record.epoch,lives={},active={},pending={}}
    end
    if not current or record.epoch~=current.epoch then error('epoch mismatch')end
    if record.kind=='birth'then
        if not validId(record.id)or not Saved.string(record.account,2048)or current.lives[record.id]then error('invalid birth')end
        current.lives[record.id]={account=record.account,ledger={schemaVersion=1,documents={},knowledge={}},revision=0,retired=false}
        current.pending[record.id]=true
    elseif record.kind=='bind'then
        local life=current.lives[record.id]
        if not life or life.retired or not current.pending[record.id]or not Saved.integer(record.slot)or record.slot>3 then error('invalid binding')end
        local key=life.account..':'..record.slot
        local prior=current.active[key]
        if prior and prior~=record.id then current.lives[prior].retired=true end
        life.slot=record.slot;current.active[key]=record.id;current.pending[record.id]=nil
    elseif record.kind=='knowledge'then
        local life=current.lives[record.id]
        if not life or life.retired or life.slot==nil or not Saved.knowledge(record.ledger)then error('invalid knowledge')end
        life.ledger=record.ledger;life.revision=life.revision+1
    elseif record.kind=='death'then
        local life=current.lives[record.id];if not life then error('unknown life')end
        life.retired=true;current.pending[record.id]=nil
        if life.slot~=nil and current.active[life.account..':'..life.slot]==record.id then current.active[life.account..':'..life.slot]=nil end
    else error('unknown operation')end
    return current
end
local function readLog()
    local reader=getFileReader(filename,false)
    if not reader then return nil,'PRIVATE_STORE_MISSING'end
    local rebuilt,parts,count,size=nil,{},0,0
    local ok,err=pcall(function()
        while true do
            local line=reader:readLine();if line==nil then break end
            count=count+1;size=size+#line+1
            if count>MAX_RECORDS or size>MAX_LOG then error('private log limit')end
            local ordinal,checksum,payload=line:match('^KW1|(%d+)|([0-9a-f]+)|(.+)$')
            if tonumber(ordinal)~=count or checksum~=Codec.checksum(payload or'')then error('private log integrity')end
            local record=assert(Codec.decode(payload));rebuilt=apply(rebuilt,record)
            parts[#parts+1]=line..'\n'
        end
    end)
    local closed=pcall(function()reader:close()end)
    if not ok or not closed then return nil,'PRIVATE_STORE_CORRUPT'end
    return rebuilt,table.concat(parts),count
end
local function commit(record)
    if failure then return false,failure end
    record.epoch=record.epoch or(state and state.epoch)
    local ok,payload=pcall(Codec.encode,record)
    if not ok then return false,'PRIVATE_RECORD_INVALID'end
    local line='KW1|'..(sequence+1)..'|'..Codec.checksum(payload)..'|'..payload..'\n'
    if #journal+#line>MAX_LOG or sequence>=MAX_RECORDS then failure='PRIVATE_STORE_LIMIT';return false,failure end
    -- Validate before appending. An uncertain write latches this process closed.
    local candidate
    local valid=pcall(function()candidate=apply(state and clone(state)or nil,clone(record));Codec.encode(candidate)end)
    if not valid then return false,'PRIVATE_RECORD_INVALID'end
    local written=pcall(function()
        local writer=assert(getFileWriter(filename,true,true),'writer unavailable')
        local didWrite,writeError=pcall(function()writer:write(line)end)
        local closed,closeError=pcall(function()writer:close()end)
        if not didWrite or not closed then error(writeError or closeError)end
    end)
    local readOK,rebuilt,bytes,count=pcall(readLog)
    if not written or not readOK or not rebuilt or bytes~=journal..line or Codec.encode(rebuilt)~=Codec.encode(candidate)then
        failure='PRIVATE_STORE_WRITE_UNCERTAIN';return false,failure
    end
    state,journal,sequence=rebuilt,bytes,count
    return true
end
function Store.ready()return Guard.isServer()and failure==nil end
function Store.failureCode()return failure or'PRIVATE_STORE_UNAVAILABLE'end
function Store.initialize(isNewWorld)
    if not Guard.isServer()then return false,'non-authority'end
    if initialized then return Store.ready(),failure end
    failure='PRIVATE_STORE_NOT_INITIALIZED'
    if type(getCurrentSaveName)~='function'or type(getFileReader)~='function'or type(getFileWriter)~='function'or type(getRandomUUID)~='function'
        or type(getOnlinePlayers)~='function'or type(sendServerCommand)~='function'then failure='PRIVATE_API_UNAVAILABLE';return false,failure end
    world=getCurrentSaveName()
    if not Saved.string(world,2048)then return false,'PRIVATE_WORLD_UNAVAILABLE'end
    -- Hash is a filename locator only; every log checks the exact world string.
    filename='B47ANCEDKnowledgeAndWisdom/private-knowledge-'..Codec.checksum(world)..'.txt'
    local ok,loaded,bytes,count=pcall(readLog)
    if not ok then failure='PRIVATE_STORE_READ_FAILED';return false,failure end
    if not loaded and bytes~='PRIVATE_STORE_MISSING'then failure=bytes;return false,failure end
    if loaded then state,journal,sequence=loaded,bytes,count
    else state,journal,sequence=nil,'',0 end
    if type(isNewWorld)~='boolean'then return false,'PRIVATE_WORLD_STATUS_UNAVAILABLE'end
    if not loaded and not isNewWorld then failure='PRIVATE_MIGRATION_REQUIRED';return false,failure end
    failure=nil
    if isNewWorld then
        local ok,reason=commit{kind='world',world=world,epoch=getRandomUUID()}
        if ok then initialized=true end
        return ok,reason
    end
    initialized=true
    return true
end
function Store.newLife(actor)
    if not Store.ready()then return false,failure or'non-authority'end
    local owner=account(actor);local data=actor and actor.getModData and actor:getModData()
    if not owner or type(data)~='table'then return false,'PRIVATE_IDENTITY_UNAVAILABLE'end
    local existing=state.lives[data[Store.LIFE_KEY]]
    if existing and not existing.retired and existing.account==owner and state.pending[data[Store.LIFE_KEY]]then return true end
    local id=getRandomUUID()
    local ok,reason=commit{kind='birth',id=id,account=owner}
    if not ok then failure=reason or'PRIVATE_BIRTH_UNCERTAIN';return false,failure end
    -- Public opaque reference only; never a ledger, grant or authenticity proof.
    data[Store.LIFE_KEY]=id
    return true
end
local function bindPending(owner)
    local pending=false
    for id in pairs(state.pending)do if state.lives[id].account==owner then pending=true end end
    if not pending then return true end
    -- OnNewGame precedes native slot assignment. Resolve only authenticated,
    -- server-listed players; never use a requested slot or client-supplied actor.
    local players=getOnlinePlayers()
    if not players or players:size()>1024 then return false,'PRIVATE_BINDING_PENDING'end
    local found,slots={},{}
    for i=0,players:size()-1 do
        local actor=players:get(i);local id=token(actor)
        if account(actor)==owner and state.pending[id]then
            local slot=actor:getPlayerNum()
            if not Saved.integer(slot)or slot>3 or slots[slot]or found[id]then return false,'PRIVATE_BINDING_AMBIGUOUS'end
            slots[slot]=true;found[id]=slot
        end
    end
    for id in pairs(state.pending)do
        if state.lives[id].account==owner and found[id]==nil then return false,'PRIVATE_BINDING_PENDING'end
    end
    local ids={};for id in pairs(found)do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids)do local ok,reason=commit{kind='bind',id=id,slot=found[id]};if not ok then return false,reason end end
    return true
end
local function resolve(actor)
    if not Store.ready()then return nil,failure or'non-authority'end
    if not actor or not actor.isDead or actor:isDead()then return nil,'PRIVATE_ACTOR_UNAVAILABLE'end
    local owner=account(actor);if not owner then return nil,'PRIVATE_IDENTITY_UNAVAILABLE'end
    local listed,copies=false,0;local players=getOnlinePlayers();local reference=token(actor)
    if players and players:size()<=1024 then
        for i=0,players:size()-1 do
            local other=players:get(i)
            if other==actor then listed=true end
            if reference and token(other)==reference and account(other)==owner then copies=copies+1 end
        end
    end
    if not listed then return nil,'PRIVATE_ACTOR_NOT_CONNECTED'end
    if copies>1 then return nil,'PRIVATE_BINDING_AMBIGUOUS'end
    local ok,reason=bindPending(owner);if not ok then return nil,reason end
    local id=token(actor);local life=state.lives[id]
    if not life or life.retired or life.account~=owner or life.slot~=actor:getPlayerNum()or state.active[owner..':'..life.slot]~=id then return nil,'PRIVATE_LIFE_UNBOUND'end
    return life,id
end
function Store.read(actor)
    local life,reason=resolve(actor);if not life then return nil,reason end
    return clone(life.ledger)
end
function Store.project(actor)
    local life,id=resolve(actor);if not life then return false,id end
    local subscription=subscriptions[actor]
    if not subscription then return false,'PRIVATE_PROJECTION_PENDING'end
    if type(sendServerCommand)~='function'then return false,'PRIVATE_TRANSPORT_UNAVAILABLE'end
    local sent=pcall(sendServerCommand,actor,MODULE,'snapshot',{requestId=subscription.id,slot=actor:getPlayerNum(),onlineId=actor:getOnlineID(),life=id,revision=life.revision,ledger=clone(life.ledger)})
    if not sent then return false,'PRIVATE_TRANSPORT_FAILED'end
    return true
end
function Store.write(actor,before,after)
    local life,id=resolve(actor);if not life then return false,id end
    if not Saved.knowledge(after)or Codec.encode(before)~=Codec.encode(life.ledger)then return false,'PRIVATE_REVISION_CONFLICT'end
    local ok,reason=commit{kind='knowledge',id=id,ledger=clone(after)}
    if ok then
        local projected,why=Store.project(actor)
        return true,not projected and why or nil
    end
    return ok,reason
end
function Store.death(actor)
    if not Store.ready()then return false,failure or'non-authority'end
    local owner=account(actor);if not owner then return false,'PRIVATE_LIFE_UNBOUND'end
    local id=token(actor);local life=state.lives[id]
    if not life or life.account~=owner then return false,'PRIVATE_LIFE_UNBOUND'end
    if life.retired then return true end
    return commit{kind='death',id=id}
end
function Store.command(module,command,actor,args)
    if module~=MODULE or command~='request'or type(args)~='table'or not validId(args.requestId)then return false end
    for key in pairs(args)do if key~='requestId'then return false end end
    -- At most two initial projections per actual player object, covering create
    -- and fully-connected startup. Writes push subsequent revisions.
    -- No client command grants knowledge or chooses a subject, slot or revision.
    if not actor then return false end
    local subscription=subscriptions[actor]
    if subscription and(subscription.id~=args.requestId or subscription.requests>=2)then return false end
    local life=resolve(actor);if not life then return false end
    subscription=subscription or{id=args.requestId,requests=0};subscriptions[actor]=subscription
    subscription.requests=subscription.requests+1
    local ok,reason=Store.project(actor)
    return ok,reason
end
if Guard.isServer()then
    API._installKnowledgeBackend(Store)
    if rawget(_G,'Events')then
        local function report(callback,...)
            local ok,reason=callback(...)
            if not ok then print('[B47ANCEDKnowledgeAndWisdom] '..tostring(reason))end
        end
        if Events.OnInitGlobalModData then Events.OnInitGlobalModData.Add(function(newWorld)report(Store.initialize,newWorld)end)end
        if Events.OnNewGame then Events.OnNewGame.Add(function(actor)report(Store.newLife,actor)end)end
        if Events.OnCharacterDeath then Events.OnCharacterDeath.Add(function(actor)
            if account(actor)and state and state.lives[token(actor)]then report(Store.death,actor)end
        end)end
        if Events.OnClientCommand then Events.OnClientCommand.Add(Store.command)end
    end
end
return Store
