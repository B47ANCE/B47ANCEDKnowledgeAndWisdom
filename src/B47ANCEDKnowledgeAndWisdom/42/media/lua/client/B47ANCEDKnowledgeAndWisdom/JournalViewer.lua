local Journals=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local Window=require "B47ANCEDKnowledgeAndWisdom/InspectionWindow"
local Viewer={}
local function enabled()
    local settings=type(SandboxVars)=="table"and SandboxVars.B47ANCEDKnowledgeAndWisdom
    return type(settings)~="table"or settings.EnableJournalViewer~=false
end
local function tr(suffix,fallback)
    local key="ContextMenu_B47ANCEDKnowledgeAndWisdom_"..suffix
    if type(getText)=="function"then
        local ok,value=pcall(getText,key)
        if ok and type(value)=="string"and value~=""and value~=key then return value end
    end
    return fallback
end
local function plain(value)
    return tostring(value):gsub("<","‹"):gsub(">","›"):gsub("[%c]"," ")
end
function Viewer.format(view)
    local states={writing={"JournalWriting","Writing in progress"},recorded={"JournalRecorded","Recorded"},
        claimed={"JournalClaimed","Claimed for recovery"},exhausted={"JournalExhausted","Recovered keepsake"}}
    local status=states[view.status]or states.recorded
    local lines={tr("InspectJournal","Inspect Survivor Journal"),tr(status[1],status[2]),
        tr("JournalSkills","Skills with recorded XP")..": "..view.recordedSkills,
        tr("JournalEntries","Completed knowledge entries")..": "..view.recordedEntries}
    local categories={documents="JournalDocuments",recipes="JournalRecipes",maps="JournalMaps",
        media="JournalMedia",knowledge="JournalKnowledge",research="JournalResearch"}
    for _,category in ipairs({"documents","recipes","maps","media","knowledge","research"})do
        lines[#lines+1]=tr(categories[category],category)..": "..(view.categories[category]or 0)
    end
    if view.writingPercent then
        lines[#lines+1]=tr("JournalProgress","Current writing session")..": "..view.writingPercent.."%"
        lines[#lines+1]=tr("JournalRemaining","Unfinished entries")..": "..view.remainingEntries
    end
    lines[#lines+1]=tr("JournalDisclaimer","Inspection shows locally available journal data. It does not write, claim, or recover knowledge or XP.")
    for index,line in ipairs(lines)do lines[index]=plain(line)end
    return table.concat(lines," <LINE> ")
end
function Viewer.open(playerNum,item)
    if not enabled()then return false,"viewer disabled"end
    local view,err=Journals.view(item);if not view then return false,err end
    return Window.open(playerNum,Viewer.format(view))
end
function Viewer.fill(playerNum,context,items)
    if not enabled()then return end
    -- Unknown inventory providers and malformed journals receive no action.
    local ok,selected=pcall(function()return ISInventoryPane.getActualItems(items)end)
    if not ok or type(selected)~="table"or #selected~=1 then return end
    local read,view=pcall(Journals.view,selected[1]);if not read or not view then return end
    context:addOption(tr("InspectJournal","Inspect Survivor Journal"),playerNum,Viewer.open,selected[1])
end
if Events and Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(Viewer.fill)end
return Viewer
