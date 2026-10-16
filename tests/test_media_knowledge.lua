for _,name in ipairs({"B47ANCEDKnowledgeAndWisdom/API","B47ANCEDKnowledgeAndWisdom/LegacyMigration","B47ANCEDKnowledgeAndWisdom/MediaKnowledge"})do package.loaded[name]=nil end
B47ANCEDKnowledgeAndWisdom=nil

local function line(id)return{getTextGuid=function()return id end}end
local lines={line("media.line.1"),line("media.line.2")}
local media={getId=function()return"media.training.1"end,getLineCount=function()return#lines end,
    getLine=function(_,index)return lines[index+1]end,getCategory=function()return"Retail-VHS"end,
    getTranslatedTitle=function()return"Training Tape"end,getTranslatedSubTitle=function()return"Episode One"end}
local item={getFullType=function()return"Base.VHS_Retail"end,getMediaData=function()return media end}
local character={isKnownMediaLine=function(_,id)return id=="media.line.1"end}

local Media=require "B47ANCEDKnowledgeAndWisdom/MediaKnowledge"
local model=assert(Media.inspect(character,item))
assert(model.mediaId=="media.training.1" and model.itemType=="Base.VHS_Retail")
assert(model.state=="partial" and model.knownLineCount==1 and model.lineCount==2 and model.completion==0.5)
assert(model.title=="Training Tape" and model.subtitle=="Episode One","known policy reveals titles after discovery")
local hidden=assert(Media.inspect(character,item,{revealTitle="never"}))
assert(hidden.title==nil and hidden.subtitle==nil,"never policy must not reveal titles")
local unseen=assert(Media.inspect({isKnownMediaLine=function()return false end},item))
assert(unseen.state=="unseen" and unseen.title==nil,"default policy must not reveal an unseen title")
local catalog=assert(Media.inspect({isKnownMediaLine=function()return false end},item,{revealTitle="always"}))
assert(catalog.title=="Training Tape","explicit catalog policy may reveal the title")
assert(select(2,Media.inspect(character,item,{revealTitle="spoilers"}))=="INVALID_REVEAL_POLICY")

local oversized={getId=media.getId,getLineCount=function()return Media.MAX_LINES+1 end}
assert(select(2,Media.inspect(character,{getFullType=item.getFullType,getMediaData=function()return oversized end}))=="MEDIA_LINE_LIMIT_EXCEEDED")
local duplicate={getId=media.getId,getLineCount=function()return 2 end,getLine=function()return line("same")end}
assert(select(2,Media.inspect(character,{getFullType=item.getFullType,getMediaData=function()return duplicate end}))=="DUPLICATE_MEDIA_LINE_ID")
assert(#lines==2 and character.addKnownMediaLine==nil,"inspection must not mutate native media knowledge")
print("B47ANCEDKnowledgeAndWisdom recorded-media knowledge projection checks passed")
