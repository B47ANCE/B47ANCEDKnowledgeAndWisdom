local API=require "B47ANCEDKnowledgeAndWisdom/API"
local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local Viewer={}
local Window=require "B47ANCEDKnowledgeAndWisdom/InspectionWindow"

local function tr(key,fallback,...)
    local get=rawget(_G,"getText")
    if type(get)~="function" then return fallback end
    local ok,value=pcall(get,key,...)
    if ok and type(value)=="string" and value~="" and value~=key then return value end
    return fallback
end

local function enabled()
    local root=rawget(_G,"SandboxVars")
    return LegacyMigration.viewerEnabled(root)
end

local function text(value)
    -- Provider text is plain text, not trusted PZ rich-text instructions.
    return tostring(value or ""):gsub("<","‹"):gsub(">","›"):gsub("\r",""):gsub("\n"," <LINE> ")
end

function Viewer.format(view)
    return text(view.title).." <LINE> "..text(view.id).." | "..text(view.classification)
        .." <LINE> "..text(view.project).." / "..text(view.category)
        .." <LINE> <LINE> "..text(view.text).." <LINE> <LINE> "
        ..(view.read and tr("ContextMenu_B47ANCEDKnowledgeAndWisdom_KnowledgeRecorded","Knowledge recorded")
            or tr("ContextMenu_B47ANCEDKnowledgeAndWisdom_KnowledgeNotRecorded","Knowledge not recorded"))
        .." <LINE> "..text(view.prerequisiteStatus)
        .." <LINE> "..tr("ContextMenu_B47ANCEDKnowledgeAndWisdom_InspectDisclaimer",
            "Use the normal Read action to learn. Inspecting this file grants no knowledge.")
end

function Viewer.open(playerNum,item)
    if not enabled() then return false,"viewer disabled" end
    local character=getSpecificPlayer(playerNum)
    if not character then return false,"character unavailable" end
    local view=API.getDocumentView(character,item)
    if not view then return false,"document unavailable" end
    return Window.open(playerNum,Viewer.format(view))
end

function Viewer.fill(playerNum,context,items)
    if not enabled() then return end
    -- Inventory hooks must isolate unfamiliar items and unavailable UI helpers.
    pcall(function()
        local selected=ISInventoryPane.getActualItems(items)
        if #selected~=1 or not API.getDocumentForItem(selected[1]) then return end
        context:addOption(tr("ContextMenu_B47ANCEDKnowledgeAndWisdom_InspectResearchFile","Inspect Research File"),playerNum,Viewer.open,selected[1])
    end)
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(Viewer.fill)
end
return Viewer
