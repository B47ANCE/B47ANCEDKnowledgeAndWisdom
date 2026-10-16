local API=require "B47ANCEDKnowledgeAndWisdom/API"

API.MediaKnowledge=API.MediaKnowledge or {}
local Media=API.MediaKnowledge
Media.SCHEMA_VERSION=1
Media.MAX_LINES=2048

local function call(object,name,...)
    if not object then return nil,"OBJECT_UNAVAILABLE" end
    local ok,method=pcall(function()return object[name]end)
    if not ok or type(method)~="function" then return nil,"METHOD_UNAVAILABLE:"..name end
    local called,value=pcall(method,object,...)
    if not called then return nil,"METHOD_FAILED:"..name end
    return value
end

local function clean(value,maximum)
    if value==nil then return nil end
    value=tostring(value):gsub("[%c]"," ")
    if #value<1 then return nil end
    return value:sub(1,maximum or 256)
end

function Media.inspect(character,item,options)
    options=type(options)=="table" and options or {}
    local reveal=options.revealTitle or "known"
    if reveal~="never" and reveal~="known" and reveal~="always" then return nil,"INVALID_REVEAL_POLICY" end
    if not character or not item then return nil,"CHARACTER_AND_ITEM_REQUIRED" end

    local itemType,itemTypeError=call(item,"getFullType")
    if not itemType then return nil,itemTypeError end
    local media,mediaError=call(item,"getMediaData")
    if not media then return nil,mediaError==nil and "NOT_RECORDED_MEDIA" or mediaError end
    local mediaId,idError=call(media,"getId")
    mediaId=clean(mediaId,160)
    if not mediaId then return nil,idError or "MEDIA_ID_UNAVAILABLE" end
    local lineCount,countError=call(media,"getLineCount")
    lineCount=tonumber(lineCount)
    if not lineCount or lineCount%1~=0 or lineCount<0 then return nil,countError or "INVALID_LINE_COUNT" end
    if lineCount>Media.MAX_LINES then return nil,"MEDIA_LINE_LIMIT_EXCEEDED" end

    local known,seen=0,{}
    for index=0,lineCount-1 do
        local line,lineError=call(media,"getLine",index)
        if not line then return nil,lineError or "MEDIA_LINE_UNAVAILABLE" end
        local guid,guidError=call(line,"getTextGuid")
        guid=clean(guid,160)
        if not guid then return nil,guidError or "MEDIA_LINE_ID_UNAVAILABLE" end
        if seen[guid] then return nil,"DUPLICATE_MEDIA_LINE_ID" end
        seen[guid]=true
        local isKnown,knownError=call(character,"isKnownMediaLine",guid)
        if isKnown==nil then return nil,knownError end
        if isKnown==true then known=known+1 end
    end

    local result={schemaVersion=Media.SCHEMA_VERSION,itemType=clean(itemType,160),mediaId=mediaId,
        category=clean(call(media,"getCategory"),128),lineCount=lineCount,knownLineCount=known,
        completion=lineCount==0 and 0 or known/lineCount,complete=lineCount>0 and known==lineCount,
        state=lineCount==0 and "empty" or (known==0 and "unseen" or (known==lineCount and "complete" or "partial"))}
    if reveal=="always" or (reveal=="known" and known>0) then
        result.title=clean(call(media,"getTranslatedTitle"),256)
        result.subtitle=clean(call(media,"getTranslatedSubTitle"),256)
    end
    return result
end

API.inspectRecordedMedia=Media.inspect
return Media
