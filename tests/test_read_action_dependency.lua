ISReadABook=nil
local loaded=0
package.preload["TimedActions/ISReadABook"]=function()
 loaded=loaded+1;ISReadABook={complete=function()return true end};return ISReadABook
end
Events={OnGameBoot={Add=function()end}}
require "B47ANCEDKnowledgeAndWisdom/ReadCompletion"
assert(loaded==1 and ISReadABook.__B47ANCEDKnowledgeAndWisdomWrapped,"read hook must load its shared native dependency without relying on server boot order")
print("Explicit shared native reading dependency checks passed")
