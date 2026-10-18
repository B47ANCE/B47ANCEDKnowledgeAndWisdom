isClient=function()return true end;isServer=function()return false end
local P=require'B47ANCEDKnowledgeAndWisdom/KnowledgeProjection'
local A=require'B47ANCEDKnowledgeAndWisdom/API'
local sent,requests={},{'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'}
local actor={getOnlineID=function()return 7 end}
getSpecificPlayer=function(slot)return slot==0 and actor or nil end
getRandomUUID=function()return table.remove(requests,1)end
sendClientCommand=function(subject,module,command,args)sent[#sent+1]={actor=subject,args=args}end
assert(P.request(0,actor)and #sent==1)
local args={slot=0,onlineId=7,life='life-one',revision=1,requestId=sent[1].args.requestId,ledger={schemaVersion=1,documents={},knowledge={known=true}}}
assert(P.receive('B47ANCEDKnowledgeAndWisdom.Knowledge','snapshot',args))
assert(A.hasKnowledge(actor,'known')and not A.learn(actor,'anything'),'projection cannot grant authority')
local current=A.snapshot(actor);current.knowledge.known=nil;assert(A.hasKnowledge(actor,'known'))
args.revision=0;assert(not P.receive('B47ANCEDKnowledgeAndWisdom.Knowledge','snapshot',args))
args.revision=2;args.slot=1;assert(not P.receive('B47ANCEDKnowledgeAndWisdom.Knowledge','snapshot',args))
args.slot=0;args.requestId='stale-request';assert(not P.receive('B47ANCEDKnowledgeAndWisdom.Knowledge','snapshot',args))
args.requestId=sent[1].args.requestId;args.onlineId=8;assert(not P.receive('B47ANCEDKnowledgeAndWisdom.Knowledge','snapshot',args))
actor={getOnlineID=function()return 7 end};assert(P.request(0,actor))
args.onlineId=7;assert(not P.receive('B47ANCEDKnowledgeAndWisdom.Knowledge','snapshot',args),'old reply cannot seed a reconnected projection')
args.requestId=sent[2].args.requestId;assert(P.receive('B47ANCEDKnowledgeAndWisdom.Knowledge','snapshot',args))
print('Owner projection routing, revision, reconnect correlation and client-authority rejection passed')
