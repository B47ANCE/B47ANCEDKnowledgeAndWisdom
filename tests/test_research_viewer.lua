package.loaded["B47ANCEDKnowledgeAndWisdom/API"]=nil
B47ANCEDKnowledgeAndWisdom=nil
local API=require "B47ANCEDKnowledgeAndWisdom/API"
API.registerDocument{id="VIEW",project="Test",category="FIELD",classification="SECRET",title="<IMAGE:bad>",itemType="Test.File",content={"Visible",{text="SECRET_FACT",redacted=true,marker="[REDACTED]"}}}
local md={}
local character={getModData=function() return md end}
local item={getFullType=function() return "Test.File" end}
local view=API.getDocumentView(character,item)
assert(view.text=="Visible[REDACTED]" and not view.read and view.content==nil)
assert(next(md)==nil)
local callback
Events={OnFillInventoryObjectContextMenu={Add=function(fn) callback=fn end}}
getText=function(key)
    local values={
        ContextMenu_B47ANCEDKnowledgeAndWisdom_InspectResearchFile="Localized Inspect",
        ContextMenu_B47ANCEDKnowledgeAndWisdom_KnowledgeNotRecorded="Localized Unrecorded",
        ContextMenu_B47ANCEDKnowledgeAndWisdom_InspectDisclaimer="Localized Disclaimer",
    }
    return values[key] or key
end
local Viewer=require "B47ANCEDKnowledgeAndWisdom/ResearchViewer"
assert(not Viewer.format(view):find("SECRET_FACT",1,true))
assert(not Viewer.format(view):find("<IMAGE:",1,true))
assert(Viewer.format(view):find("Localized Unrecorded",1,true) and Viewer.format(view):find("Localized Disclaimer",1,true))
ISInventoryPane={getActualItems=function(items) return items end}
local options={}
local context={addOption=function(_,name,target,fn,selected) options[#options+1]={name=name,target=target,fn=fn,item=selected} end}
callback(0,context,{item})
assert(#options==1 and options[1].item==item and options[1].name=="Localized Inspect")
callback(0,context,{item,item})
assert(#options==1)
callback(0,context,{{getFullType=function() error("unknown provider") end}})
assert(#options==1)
SandboxVars={B47ANCEDKnowledgeAndWisdom={EnableResearchViewer=false}}
callback(0,context,{item})
assert(#options==1 and Viewer.open(0,item)==false)
SandboxVars.B47ANCEDKnowledgeAndWisdom.EnableResearchViewer=true
getSpecificPlayer=function(index) assert(index==0); return character end
getPlayerScreenWidth=function() return 800 end
getPlayerScreenHeight=function() return 600 end
getPlayerScreenLeft=function() return 0 end
getPlayerScreenTop=function() return 0 end
package.preload["ISUI/ISModalRichText"]=function() return {} end
local displayed,destroyed=0,0
ISModalRichText={new=function(_,x,y,w,h,body,yesno,target,onClick,playerNum)
    assert(x>=0 and y>=0 and w<=800 and h<=600 and playerNum==0)
    assert(not body:find("SECRET_FACT",1,true))
    return {initialise=function() end,addToUIManager=function() displayed=displayed+1 end,
        destroy=function() destroyed=destroyed+1 end}
end}
assert(Viewer.open(0,item) and displayed==1)
assert(Viewer.open(0,item) and displayed==2 and destroyed==1)
assert(next(md)==nil)
print("B47ANCEDKnowledgeAndWisdom redacted/read-only research viewer checks passed")
