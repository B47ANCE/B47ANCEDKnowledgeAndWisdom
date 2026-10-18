-- Owner-connection presentation only; no client ledger is gameplay authority.
local Guard=require'B47ANCEDKnowledgeAndWisdom/AuthorityGuard'
local Saved=require'B47ANCEDKnowledgeAndWisdom/SavedState'
local Codec=require'B47ANCEDKnowledgeAndWisdom/PrivateCodec'
local API=require'B47ANCEDKnowledgeAndWisdom/API'
local Projection={}
local cache=setmetatable({},{__mode='k'})
local requests=setmetatable({},{__mode='k'})
local MODULE='B47ANCEDKnowledgeAndWisdom.Knowledge'
function Projection.read(actor)
    local current=cache[actor]
    if not current or current.onlineId~=actor:getOnlineID()then return nil,'KNOWLEDGE_PROJECTION_PENDING'end
    return Codec.decode(Codec.encode(current.ledger))
end
function Projection.receive(module,command,args)
    if Guard.realm()~='client'or module~=MODULE or command~='snapshot'or type(args)~='table'
        or not Saved.integer(args.slot)or args.slot>3 or not Saved.integer(args.onlineId)
        or not Saved.integer(args.revision)or not Saved.string(args.life,64)or not Saved.knowledge(args.ledger)then return false end
    local actor=getSpecificPlayer(args.slot)
    if not actor or actor:getOnlineID()~=args.onlineId or requests[actor]~=args.requestId then return false end
    local current=cache[actor]
    if current and(current.life~=args.life or args.revision<current.revision)then return false end
    local encoded,payload=pcall(Codec.encode,args.ledger)
    if not encoded or(current and args.revision==current.revision and payload~=Codec.encode(current.ledger))then return false end
    cache[actor]={life=args.life,onlineId=args.onlineId,revision=args.revision,ledger=Codec.decode(payload)}
    return true
end
function Projection.request(slot,actor)
    if Guard.realm()~='client'or not actor or actor~=getSpecificPlayer(slot)then return false end
    if not requests[actor]then cache[actor]=nil;requests[actor]=getRandomUUID()end
    sendClientCommand(actor,MODULE,'request',{requestId=requests[actor]})
    return true
end
if Guard.realm()=='client'then
    API._installKnowledgeBackend(Projection)
    if rawget(_G,'Events')then
        if Events.OnServerCommand then Events.OnServerCommand.Add(Projection.receive)end
        if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(Projection.request)end
        if Events.OnGameStart then Events.OnGameStart.Add(function()
            for slot=0,3 do local actor=getSpecificPlayer(slot);if actor then Projection.request(slot,actor)end end
        end)end
    end
end
return Projection
