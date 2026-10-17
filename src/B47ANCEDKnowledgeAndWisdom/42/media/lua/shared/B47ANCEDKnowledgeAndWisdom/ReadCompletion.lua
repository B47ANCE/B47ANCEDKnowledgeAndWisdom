local API=require "B47ANCEDKnowledgeAndWisdom/API"
local Guard=require "B47ANCEDKnowledgeAndWisdom/AuthorityGuard"

local function worldAge()
    local ok,time=pcall(function() return getGameTime() end)
    if not ok or not time then return nil end
    local read,value=pcall(function() return time:getWorldAgeHours() end)
    return read and value or nil
end

local function install()
    if not rawget(_G,"ISReadABook")then require "TimedActions/ISReadABook"end
if rawget(_G,"ISReadABook") and not ISReadABook.__B47ANCEDKnowledgeAndWisdomWrapped then
    local original=ISReadABook.complete
    if type(original)=="function" then
        ISReadABook.complete=function(self,...)
            local result=original(self,...)
            if result==true and self and not self.forceStopped and self.character and self.item then
                local held=true
                if Guard.isServer()then
                    local queried,owned=pcall(function()return self.character:getInventory():contains(self.item)end)
                    held=queried and owned==true
                end
                local called,ok,err
                if held then called,ok,err=pcall(API.completeRead,self.character,self.item,{worldAgeHours=worldAge()})
                else called,ok,err=true,false,"document item is not held by the reader"end
                if not called then err="knowledge callback failed" end
                if (not called or not ok) and err~="item is not a registered document" and err~="non-authority" then
                    pcall(print,"[B47ANCEDKnowledgeAndWisdom] research read did not unlock: "..tostring(err))
                end
            end
            return result
        end
        ISReadABook.__B47ANCEDKnowledgeAndWisdomWrapped=true
    end
end
end

install()
if rawget(_G,"Events") and Events.OnGameBoot then Events.OnGameBoot.Add(install) end

return API
