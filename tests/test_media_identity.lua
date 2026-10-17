local M=require "B47ANCEDKnowledgeAndWisdom/MediaKnowledge"
local prefix=string.rep("x",160)
local line={getTextGuid=function()return prefix.."actual"end}
local media={getId=function()return "media"end,getLineCount=function()return 1 end,getLine=function()return line end}
local item={getFullType=function()return "Base.VHS"end,getMediaData=function()return media end}
local calls=0;local actor={isKnownMediaLine=function(_,guid)calls=calls+1;return guid==prefix end}
assert(M.inspect(actor,item)==nil and calls==0,"stable line IDs must not be truncated into another known line")
line.getTextGuid=function()return "valid"end
media.getId=function()return prefix.."too-long"end
assert(M.inspect(actor,item)==nil and calls==0)
print("Exact recorded-media identity rejection checks passed")
