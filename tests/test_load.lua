for _,name in ipairs({
    "B47ANCEDKnowledgeAndWisdom/Load",
    "B47ANCEDKnowledgeAndWisdom/API","B47ANCEDKnowledgeAndWisdom/Progression",
    "B47ANCEDKnowledgeAndWisdom/SurvivorJournals","B47ANCEDKnowledgeAndWisdom/TestFixtures","B47ANCEDKnowledgeAndWisdom/ReadCompletion",
}) do package.loaded[name]=nil end
B47ANCEDKnowledgeAndWisdom=nil

local bootAdds=0
Events={OnGameBoot={Add=function() bootAdds=bootAdds+1 end}}
ISReadABook={complete=function() return true end}
local original=ISReadABook.complete

local API=require "B47ANCEDKnowledgeAndWisdom/Load"
local wrapped=ISReadABook.complete

assert(API==B47ANCEDKnowledgeAndWisdom,"production Load must expose the canonical global")
assert(type(API.registerSemanticAction)=="function" and type(API.processSemanticAction)=="function"
        and type(API.SurvivorJournals)=="table" and type(API.TestFixtures)=="table"
        and type(API.inspectRecordedMedia)=="function",
    "production Load must expose progression, Survivor Journals, and validation fixtures")
assert(wrapped~=original and ISReadABook.__B47ANCEDKnowledgeAndWisdomWrapped==true,
    "production Load must install the registered-document completion hook")
assert(bootAdds==1,"production Load must schedule exactly one delayed hook check")
assert(require("B47ANCEDKnowledgeAndWisdom/Load")==API and ISReadABook.complete==wrapped and bootAdds==1,
    "repeated canonical loading must share one hook lifecycle")

print("B47ANCEDKnowledgeAndWisdom production load-graph checks passed")
