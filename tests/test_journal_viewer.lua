local J=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local L=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local md={};local item={getModData=function()return md end}
assert(J.view(item)==nil and next(md)==nil)
local calls=0;J.setClaimStoreProvider(function()calls=calls+1;error("inspector must not access authority claims")end)
assert(J.beginWriting(item,"PRIVATE_ACCOUNT",{rawXP={Aiming=100},documents={Written=true},knowledge={SECRET_TARGET=true}},"PRIVATE_PAYLOAD"))
local snap=J.snapshot(item)
assert(J.advanceWriting(item,"PRIVATE_ACCOUNT",snap.queue[1].work+5))
local state=md[J.ROOT_KEY];local revision=state.revision
-- Observe exactly the client-side legacy case, without migration or authority access.
md[L.JOURNAL_ROOT_KEY]=state;md[J.ROOT_KEY]=nil
isClient=function()return true end;isServer=function()return false end
local view=assert(J.view(item))
assert(view.status=="writing" and view.recordedSkills==1 and view.recordedEntries==1)
assert(view.categories.documents==1 and not view.authorId and not view.payloadId and not view.target and not view.rawXP)
assert(view.writingPercent>0 and view.writingPercent<100 and view.remainingEntries==1)
view.categories.documents=999;assert(J.view(item).categories.documents==1)
assert(md[L.JOURNAL_ROOT_KEY]==state and not md[J.ROOT_KEY]and state.revision==revision and calls==0)
local callback
Events={OnFillInventoryObjectContextMenu={Add=function(fn)callback=fn end}}
local V=require "B47ANCEDKnowledgeAndWisdom/JournalViewer"
local body=V.format(J.view(item))
assert(not body:find("PRIVATE",1,true)and not body:find("SECRET_TARGET",1,true))
getText=function()return "<IMAGE:injected>"end
assert(not V.format(J.view(item)):find("<IMAGE:",1,true));getText=nil
ISInventoryPane={getActualItems=function(items)return items end}
local options={};local context={addOption=function(_,name,target,fn,selected)options[#options+1]={fn=fn,item=selected}end}
callback(0,context,{item});assert(#options==1 and options[1].item==item)
callback(0,context,{item,item});callback(0,context,{{getModData=function()error("bad provider")end}})
assert(#options==1)
SandboxVars={B47ANCEDKnowledgeAndWisdom={EnableJournalViewer=false}}
callback(0,context,{item});assert(#options==1 and V.open(0,item)==false)
SandboxVars.B47ANCEDKnowledgeAndWisdom.EnableJournalViewer=true
package.preload["ISUI/ISModalRichText"]=function()return {}end
getSpecificPlayer=function()return {}end
getPlayerScreenWidth=function()return 640 end;getPlayerScreenHeight=function()return 360 end
getPlayerScreenLeft=function()return 640 end;getPlayerScreenTop=function()return 360 end
local focus={};local joypad={focus=focus};getJoypadData=function()return joypad end
setJoypadFocus=function(_,value)joypad.focus=value end
local shown,destroyed,modal=0,0
ISModalRichText={new=function(_,x,y,w,h,text,yesno,target,onClick,playerNum)
 assert(x>=640 and y>=360 and w<=600 and h<=320 and playerNum==0)
 assert(not text:find("PRIVATE",1,true))
 local m={height=h,y=y,initialise=function()end,addToUIManager=function()shown=shown+1 end,
  destroy=function()destroyed=destroyed+1;joypad.focus=focus;onClick()end,
  getHeight=function(self)return self.height end,setHeight=function(self,value)self.height=value end,
  getY=function(self)return self.y end,setY=function(self,value)self.y=value end,
  updateButtons=function(self)self.buttonsUpdated=true end,
  update=function(self)self.height=900;self.y=20;self.chatText.height=860 end}
 m.chatText={height=0,getHeight=function(self)return self.height end,setHeight=function(self,v)self.height=v end,updateScrollbars=function(self)self.updated=true end}
 modal=m;return m
end}
assert(V.open(0,item)and shown==1 and modal.prevFocus==focus and joypad.focus==modal)
modal:update();assert(modal.height==320 and modal.y==380 and modal.chatText.height==280 and modal.buttonsUpdated)
assert(V.open(0,item)and shown==2 and destroyed==1)
state.recovery={successorId="PRIVATE_SUCCESSOR",studiedWork=0,exhausted=false}
assert(J.view(item).status=="claimed")
state.recovery.exhausted=true;assert(J.view(item).status=="exhausted")
md[L.JOURNAL_ROOT_KEY]={schemaVersion=99};callback(0,context,{item})
assert(#options==1 and V.open(0,item)==false and md[L.JOURNAL_ROOT_KEY].schemaVersion==99)
assert(calls==0 and not md[J.ROOT_KEY])
print("Read-only journal projection, privacy, menu and split-screen lifecycle passed")
