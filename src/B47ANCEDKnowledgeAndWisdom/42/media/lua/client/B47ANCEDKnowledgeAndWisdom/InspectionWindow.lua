-- Client-only presentation; this window never writes gameplay or saved data.
local Window={}
local windows={}
function Window.open(playerNum,body)
    local ok,result=pcall(function()
        if not getSpecificPlayer(playerNum)then return false end
        require "ISUI/ISModalRichText"
        local sw,sh=getPlayerScreenWidth(playerNum),getPlayerScreenHeight(playerNum)
        if sw<240 or sh<200 then return false end
        local left,top=getPlayerScreenLeft(playerNum),getPlayerScreenTop(playerNum)
        local width,height=math.min(620,sw-40),math.min(460,sh-40)
        local x,y=left+(sw-width)/2,top+(sh-height)/2
        if windows[playerNum]then windows[playerNum]:destroy()end
        local modal
        modal=ISModalRichText:new(x,y,width,height,body,false,nil,function()
            if windows[playerNum]==modal then windows[playerNum]=nil end
        end,playerNum)
        modal:initialise()
        -- Vanilla auto-height uses the full game screen. Rebound this instance
        -- to its player's viewport and update its scrolling/button layout.
        local update=modal.update
        if type(update)=="function"then
            modal.update=function(self,...)
                update(self,...)
                local excess=self:getHeight()-height
                if excess>0 then
                    self:setHeight(height);self:updateButtons()
                    self.chatText:setHeight(math.max(1,self.chatText:getHeight()-excess))
                    self.chatText:updateScrollbars()
                end
                self:setY(math.max(top+20,math.min(self:getY(),top+sh-self:getHeight()-20)))
            end
        end
        modal:addToUIManager();windows[playerNum]=modal
        if type(getJoypadData)=="function"and getJoypadData(playerNum)then
            modal.prevFocus=getJoypadData(playerNum).focus
            setJoypadFocus(playerNum,modal)
        end
        return true
    end)
    if not ok then return false,"inspection UI unavailable"end
    return result==true
end
return Window
