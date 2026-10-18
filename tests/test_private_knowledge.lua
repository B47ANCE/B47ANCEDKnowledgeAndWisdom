isServer=function()return true end;isClient=function()return false end
local files,players,messages={}, {},{}
local uuid=0;local mode='normal';local currentWorld='dedicated-fixture-one'
getCurrentSaveName=function()return currentWorld end
getRandomUUID=function()uuid=uuid+1;return string.format('00000000-0000-0000-0000-%012d',uuid)end
getOnlinePlayers=function()return{size=function()return #players end,get=function(_,i)return players[i+1]end}end
getFileReader=function(path)
    if files[path]==nil then return nil end
    local data,pos=files[path],1
    return{readLine=function()
        if pos>#data then return nil end
        local last=data:find('\n',pos,true)or(#data+1);local line=data:sub(pos,last-1);pos=last+1;return line
    end,close=function()end}
end
getFileWriter=function(path,create,append)
    assert(create==true and append==true,'private log is append only')
    return{write=function(_,data)
        if mode=='drop'then return end
        if mode=='partial'then data=data:sub(1,23)end
        files[path]=(files[path]or'')..data
    end,close=function()end}
end
sendServerCommand=function(actor,module,command,args)messages[#messages+1]={actor=actor,module=module,command=command,args=args}end
local function actor(name,slot,id)
    local data={};local value={dead=false}
    value.getModData=function()return data end;value.getUsername=function()return name end
    value.getPlayerNum=function()return slot end;value.getOnlineID=function()return id end
    value.isDead=function()return value.dead end
    return value,data
end
local A,S
local function load()
    package.loaded['B47ANCEDKnowledgeAndWisdom/API']=nil
    package.loaded['B47ANCEDKnowledgeAndWisdom/PrivateKnowledge']=nil
    B47ANCEDKnowledgeAndWisdom=nil
    A=require'B47ANCEDKnowledgeAndWisdom/API'
    A.registerKnowledge{id='test.operation',owner='Test',title='Operate'}
    A.registerDocument{id='test.manual',project='Test',category='Test',classification='open',title='Manual',content={'text'},itemType='Test.Manual',grantsKnowledge={'test.operation'}}
    S=require'B47ANCEDKnowledgeAndWisdom/PrivateKnowledge'
end
load();assert(not S.initialize(false),'existing world requires reviewed migration')
assert(S.initialize(true))
local firstJournal;for _,bytes in pairs(files)do firstJournal=bytes end
assert(S.initialize(true),'duplicate initialization is idempotent')
for _,bytes in pairs(files)do assert(bytes==firstJournal)end
local reader=actor('reader',0,9);players={reader}
assert(S.newLife(reader));local afterBirth;for _,bytes in pairs(files)do afterBirth=bytes end
assert(S.newLife(reader),'duplicate native birth is idempotent')
for _,bytes in pairs(files)do assert(bytes==afterBirth)end
local held=false;reader.getInventory=function()return{contains=function()return held end}end
local book={getFullType=function()return'Test.Manual'end}
ISReadABook={complete=function()return true end}
require'B47ANCEDKnowledgeAndWisdom/ReadCompletion'
local action={character=reader,item=book}
assert(ISReadABook.complete(action)and not A.hasKnowledge(reader,'test.operation'),'unheld document cannot grant on server')
held=true;action.forceStopped=true
assert(ISReadABook.complete(action)and not A.hasKnowledge(reader,'test.operation'),'cancelled server action cannot grant')
action.forceStopped=false
assert(ISReadABook.complete(action)and A.hasKnowledge(reader,'test.operation'),'owned completed server read persists knowledge')
local alice,aliceData=actor('alice',0,1);local bob,bobData=actor('bob',0,2);players={alice,bob}
assert(S.newLife(alice)and S.newLife(bob))
assert(not S.command('B47ANCEDKnowledgeAndWisdom.Knowledge','grant',alice,{document='test.manual'}))
assert(not S.command('B47ANCEDKnowledgeAndWisdom.Knowledge','request',alice,{requestId=getRandomUUID(),subject='bob'}))
local aliceRequest=getRandomUUID()
assert(S.command('B47ANCEDKnowledgeAndWisdom.Knowledge','request',alice,{requestId=aliceRequest}))
assert(#messages==1 and messages[1].actor==alice and messages[1].args.requestId==aliceRequest)
assert(A.learn(alice,'test.manual')and A.hasKnowledge(alice,'test.operation'))
assert(not A.hasKnowledge(bob,'test.operation'))
local snapshot=A.snapshot(alice);snapshot.knowledge['test.operation']=nil
assert(A.hasKnowledge(alice,'test.operation'),'query returns a detached snapshot')
assert(A.learn(alice,'test.manual'))
local transmissions=#messages
assert(S.command('B47ANCEDKnowledgeAndWisdom.Knowledge','request',alice,{requestId=aliceRequest}))
assert(not S.command('B47ANCEDKnowledgeAndWisdom.Knowledge','request',alice,{requestId=aliceRequest}))
assert(#messages==transmissions+1,'bounded requests; no grants from commands')
local bobToken=bobData[S.LIFE_KEY];bobData[S.LIFE_KEY]=aliceData[S.LIFE_KEY]
assert(A.snapshot(bob)==nil,'cross-account token cannot authorize')
bobData[S.LIFE_KEY]=bobToken
bobData[A.ROOT_KEY]={schemaVersion=1,documents={},knowledge={['test.operation']=true}}
assert(not A.hasKnowledge(bob,'test.operation'),'native ModData does not grant knowledge')
local disconnected=actor('alice',0,3)
assert(A.snapshot(disconnected)==nil,'unlisted actor is not a connected authority subject')
-- Fresh VM/restart simulation retains only disk and the native opaque references.
load();assert(S.initialize(false));assert(A.hasKnowledge(alice,'test.operation'))
local rejoined,rejoinedData=actor('alice',0,4);rejoinedData[S.LIFE_KEY]=aliceData[S.LIFE_KEY];players={rejoined,bob}
assert(A.hasKnowledge(rejoined,'test.operation'),'reconnect retains the server ledger')
-- New native birth must bind before old references can be replayed in that slot.
local nextLife,nextData=actor('alice',0,5);assert(S.newLife(nextLife))
local issued=nextData[S.LIFE_KEY];nextData[S.LIFE_KEY]=rejoinedData[S.LIFE_KEY];players={nextLife,bob}
assert(A.snapshot(nextLife)==nil,'unmatched birth prevents replay of prior live token')
nextData[S.LIFE_KEY]=issued
assert(A.snapshot(nextLife)and not A.hasKnowledge(nextLife,'test.operation'),'fresh character starts without prior life grants')
rejoinedData[S.LIFE_KEY]=issued;players={nextLife,rejoined,bob}
assert(A.snapshot(nextLife)==nil,'duplicate native references are ambiguous, not trusted')
players={nextLife,bob}
-- A retired token cannot return after its replacement is bound.
rejoinedData[S.LIFE_KEY]=aliceData[S.LIFE_KEY];players={rejoined,bob}
assert(A.snapshot(rejoined)==nil);players={nextLife,bob}
assert(A.learn(nextLife,'test.manual'));nextLife.dead=true;assert(S.death(nextLife));assert(A.snapshot(nextLife)==nil)
local second,secondData=actor('bob',1,6);assert(S.newLife(second));players={bob,second}
assert(A.snapshot(bob)and A.snapshot(second));assert(A.learn(second,'test.manual'))
assert(not A.hasKnowledge(bob,'test.operation'),'same-account slots remain separate')
local before=A.snapshot(bob);mode='drop'
local learned,reason=A.learn(bob,'test.manual')
assert(not learned and reason=='PRIVATE_STORE_WRITE_UNCERTAIN')
assert(not S.ready()and A.snapshot(bob)==nil,'silent native writer failure latches closed')
assert(not S.initialize(false),'initialization cannot clear an uncertain-write latch')
mode='normal';load();assert(S.initialize(false));assert(not A.hasKnowledge(bob,'test.operation'),'failed append did not grant')
mode='partial';assert(not A.learn(bob,'test.manual'));mode='normal'
local damaged;for _,bytes in pairs(files)do damaged=bytes end
load();assert(not S.initialize(false)and not S.ready(),'torn tail cannot fall back to stale authority')
for _,bytes in pairs(files)do assert(bytes==damaged,'corrupt log is preserved without repair')end
currentWorld='dedicated-fixture-two';load();assert(S.initialize(true))
assert(A.snapshot(bob)==nil,'another world cannot import a public life reference')
print('Private knowledge identity, owner projection, slots, replay, reconnect/restart and write-failure simulations passed')
