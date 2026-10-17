package.loaded["B47ANCEDKnowledgeAndWisdom/HistoryRecords"]=nil
local callback,store
Events={OnInitGlobalModData={Add=function(fn)callback=fn end}}
ModData={getOrCreate=function(key)store={key=key};return store end}
B47ANCEDKnowledgeAndWisdom={HistoryRecords={STORE_KEY="history.test",attachStore=function(value)value.attached=true;return true end}}
package.preload["B47ANCEDKnowledgeAndWisdom/HistoryRecords"]=function()return B47ANCEDKnowledgeAndWisdom.HistoryRecords end
local History=dofile("src/B47ANCEDKnowledgeAndWisdom/42/media/lua/server/B47ANCEDKnowledgeAndWisdom/HistoryServer.lua")
assert(type(callback)=="function"and callback()and store.key=="history.test"and store.attached)
assert(History==B47ANCEDKnowledgeAndWisdom.HistoryRecords)
print("test_history_server.lua: PASS")

isServer=function()return true end
local original=store
assert(not callback()and store==original,"MP bootstrap must not initialize a request-readable private store")
