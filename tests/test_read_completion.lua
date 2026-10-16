package.loaded["B47ANCEDKnowledgeAndWisdom/API"]=nil
package.loaded["B47ANCEDKnowledgeAndWisdom/ReadCompletion"]=nil
B47ANCEDKnowledgeAndWisdom=nil
local API=require "B47ANCEDKnowledgeAndWisdom/API"
API.registerKnowledge{id="Read.Known",owner="Test",title="Read Knowledge"}
API.registerDocument{id="READ",project="Test",category="FIELD",classification="OPEN",title="Read",itemType="Test.Read",grantsKnowledge={"Read.Known"},content={"body"}}
local function character()
    local data={}
    return {getModData=function() return data end}
end
local item={getFullType=function() return "Test.Read" end}
local installs={}
Events={OnGameBoot={Add=function(fn) installs[#installs+1]=fn end}}
ISReadABook=nil
require "B47ANCEDKnowledgeAndWisdom/ReadCompletion"
assert(#installs==1)
local vanillaCalls=0
ISReadABook={complete=function(self,value)
    vanillaCalls=vanillaCalls+1
    assert(value=="forwarded")
    return self.result
end}
installs[1]()
local wrapped=ISReadABook.complete
installs[1]()
assert(ISReadABook.complete==wrapped)
local function finish(result,stopped,book)
    local reader=character()
    local action={character=reader,item=book or item,result=result,forceStopped=stopped}
    assert(ISReadABook.complete(action,"forwarded")==result)
    return reader
end
assert(not API.hasKnowledge(finish(false),"Read.Known"))
assert(not API.hasKnowledge(finish(true,true),"Read.Known"))
assert(not API.hasKnowledge(finish(true,false,{getFullType=function() return "Base.Book" end}),"Read.Known"))
assert(API.hasKnowledge(finish(true),"Read.Known"))
isClient=function() return true end
isServer=function() return false end
assert(not API.hasKnowledge(finish(true),"Read.Known"))
isClient=function() return false end
local original=API.completeRead
API.completeRead=function() error("provider failure") end
local realPrint=print
print=function() error("diagnostic failure") end
finish(true)
print=realPrint
API.completeRead=original
assert(vanillaCalls==6)
print("B47ANCEDKnowledgeAndWisdom reading cancellation/load-order/failure-isolation checks passed")
