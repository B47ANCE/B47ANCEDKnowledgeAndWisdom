-- Development-only in-game harness. Project Zomboid exposes this predicate
-- in real runtimes; host tests omit it and therefore retain harness coverage.
if type(isDebugEnabled)=="function" and isDebugEnabled()~=true then return {} end

local Guard=require "B47ANCEDKnowledgeAndWisdom/AuthorityGuard"
local API=require "B47ANCEDKnowledgeAndWisdom/Progression"
local Journals=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"
local Fixtures=require "B47ANCEDKnowledgeAndWisdom/TestFixtures"

local Harness={}
local RESULT_FILE="B47ANCED Knowledge & Wisdom Test Results.txt"
local DATA_KEY="B47ANCEDKnowledgeAndWisdom.TestSession.V1"
-- Keep the identity alive: a temporary table's address can be reused by GC.
local runtimeIdentity={}
Harness.runtimeIdentity=runtimeIdentity
local RUNTIME_TOKEN=tostring(runtimeIdentity)
local FOUNDATION_KNOWLEDGE=Fixtures.FOUNDATION_KNOWLEDGE
local ADVANCED_KNOWLEDGE=Fixtures.ADVANCED_KNOWLEDGE
local FOUNDATION_DOCUMENT=Fixtures.FOUNDATION_DOCUMENT
local ADVANCED_DOCUMENT=Fixtures.ADVANCED_DOCUMENT
local FOUNDATION_ITEM=Fixtures.FOUNDATION_ITEM
local ADVANCED_ITEM=Fixtures.ADVANCED_ITEM
local JOURNAL_ITEM=Fixtures.JOURNAL_ITEM
local SEMANTIC_ACTION=Fixtures.SEMANTIC_ACTION

local steps={
    {id="startup",feature="Canonical load and result export",automatic=true,
        instruction="Run B47ANCEDKnowledgeAndWisdomTestAuto(). The canonical API, fixtures, version, and report writer must all pass."},
    {id="research_viewer",feature="Redacted research viewer",manual=true,
        instruction="Right-click the Foundation test file and choose Inspect Research File. Confirm the modal is readable, contains a redaction block, and does not mark the file read."},
    {id="read_unlock",feature="Vanilla read-completion knowledge unlock",automatic=true,
        instruction="Read the one-page Foundation test file normally, then run B47ANCEDKnowledgeAndWisdomTestKnowledge()."},
    {id="prerequisite",feature="Knowledge prerequisite enforcement",automatic=true,
        instruction="Before reading Foundation, Advanced must be ineligible. After Foundation, read Advanced and run B47ANCEDKnowledgeAndWisdomTestKnowledge()."},
    {id="semantic_progression",feature="Semantic action XP routing",automatic=true,
        instruction="Run B47ANCEDKnowledgeAndWisdomTestProgression(). It awards one small, source-tracked Mechanics XP test action."},
    {id="journal_partial",feature="Progressive Survivor Journal writing",automatic=true,
        instruction="Run B47ANCEDKnowledgeAndWisdomTestJournal(). It creates a test journal and commits only one minute of a longer write."},
    {id="journal_persistence",feature="Physical journal save/reload persistence",automatic=true,persistence=true,
        instruction="After the journal command, save and quit, reload the same character, then run B47ANCEDKnowledgeAndWisdomTestJournalStatus()."},
    {id="sandbox_toggle",feature="Research viewer sandbox toggle",manual=true,
        instruction="In a test world with the viewer option disabled, confirm Inspect Research File is absent while ordinary reading still works."},
    {id="legacy_migration",feature="Pre-0.7.0 saved-state migration",manual=true,persistence=true,
        instruction="Load a copy of a pre-0.7.0 character with recorded knowledge/journal state and confirm the state remains available. Mark BLOCKED if no old test save exists."},
    {id="multiplayer",feature="Hosted and dedicated authority",manual=true,
        instruction="On hosted and dedicated servers, read registered files as a remote client and verify one authoritative unlock with no duplicate XP/state. Mark BLOCKED until that environment is available."},
}

local function safe(value)
    return tostring(value or ""):gsub("[\r\n]+"," "):sub(1,500)
end

local function now()
    local library=rawget(_G,"os")
    if type(library)=="table" and type(library.date)=="function" then
        local ok,value=pcall(library.date,"!%Y-%m-%dT%H:%M:%SZ")
        if ok and value then return tostring(value) end
    end
    return "timestamp unavailable"
end

local function worldAge()
    local getter=rawget(_G,"getGameTime")
    if type(getter)~="function" then return nil end
    local ok,time=pcall(getter); if not ok or not time then return nil end
    local read,value=pcall(function() return time:getWorldAgeHours() end)
    return read and tonumber(value) or nil
end

local function pzVersion()
    local getter=rawget(_G,"getCore")
    if type(getter)~="function" then return "unavailable" end
    local ok,core=pcall(getter); if not ok or not core then return "unavailable" end
    for _,method in ipairs({"getVersionNumber","getVersion"}) do
        if type(core[method])=="function" then
            local read,value=pcall(core[method],core)
            if read and value~=nil then return tostring(value) end
        end
    end
    return "unavailable"
end

local function player()
    local specific=rawget(_G,"getSpecificPlayer")
    if type(specific)=="function" then local ok,value=pcall(specific,0); if ok and value then return value end end
    local getter=rawget(_G,"getPlayer")
    if type(getter)=="function" then local ok,value=pcall(getter); if ok then return value end end
    return nil
end

local function modData(character)
    if not character or type(character.getModData)~="function" then return nil end
    local ok,data=pcall(character.getModData,character)
    return ok and type(data)=="table" and data or nil
end

local function session(create)
    local permitted,reason=Guard.write();if not permitted then return nil,nil,reason end
    local character=player(); local data=modData(character)
    if not data then return nil,nil,"local player ModData unavailable" end
    if create and type(data[DATA_KEY])~="table" then
        local age=worldAge() or 0
        data[DATA_KEY]={schemaVersion=1,sessionId=string.format("EW-%s-%.3f",safe(now()),age),
            startedAt=now(),pzVersion=pzVersion(),modId="B47ANCEDKnowledgeAndWisdom",modVersion=API.VERSION,
            results={},commands={},complete=false}
    end
    return data[DATA_KEY],character
end

local function resultCounts(current)
    local counts={PASS=0,FAIL=0,BLOCKED=0,PENDING=0}
    for _,step in ipairs(steps) do
        local status=current.results[step.id] and current.results[step.id].status or "PENDING"
        counts[status]=(counts[status] or 0)+1
    end
    return counts
end

local function overall(current)
    local counts=resultCounts(current)
    if counts.FAIL>0 then return "FAIL" end
    if counts.PENDING>0 then return "IN_PROGRESS" end
    if counts.BLOCKED>0 then return "BLOCKED" end
    return "PASS"
end

local function lines(current)
    local output={
        "B47ANCED Knowledge & Wisdom in-game test results",
        "Mod: B47ANCED Knowledge & Wisdom",
        "Mod ID: B47ANCEDKnowledgeAndWisdom",
        "Mod version: "..safe(current.modVersion),
        "Project Zomboid version: "..safe(current.pzVersion),
        "Session: "..safe(current.sessionId),
        "Started: "..safe(current.startedAt),
        "Generated: "..now(),
        "Dependencies enabled for this stage: none",
        "Overall session status: "..overall(current),
        "",
        "FEATURE RESULTS",
    }
    for index,step in ipairs(steps) do
        local result=current.results[step.id] or {status="PENDING",note=""}
        output[#output+1]=string.format("%02d. [%s] %s | %s | %s",index,result.status,step.id,step.feature,safe(result.note))
    end
    output[#output+1]=""
    output[#output+1]="COMMAND LOG"
    for index,entry in ipairs(current.commands) do
        output[#output+1]=string.format("%03d. %s | %s | %s | %s | %s",index,safe(entry.at),safe(entry.command),safe(entry.feature),safe(entry.outcome),safe(entry.detail))
    end
    output[#output+1]=""
    output[#output+1]="Send this file plus screenshots for failed visual checks to development."
    return output
end

local function writeReport(current)
    local factory=rawget(_G,"getFileWriter")
    if type(factory)~="function" then return false,"getFileWriter unavailable" end
    local ok,err=pcall(function()
        local writer=factory(RESULT_FILE,true,false)
        if not writer then error("writer unavailable") end
        for _,line in ipairs(lines(current)) do
            if type(writer.writeln)=="function" then writer:writeln(line)
            elseif type(writer.write)=="function" then writer:write(line.."\n")
            else error("writer has no write method") end
        end
        if type(writer.close)=="function" then writer:close() end
    end)
    if ok then return true,nil end
    return false,safe(err)
end

local function printLine(message) print("[B47ANCEDKnowledgeAndWisdom][Test] "..message) end

local function log(current,command,feature,outcome,detail)
    current.commands[#current.commands+1]={at=now(),command=command,feature=feature,outcome=outcome,detail=safe(detail)}
    while #current.commands>128 do table.remove(current.commands,1) end
end

local function record(current,id,status,note)
    if status~="PASS" and status~="FAIL" and status~="BLOCKED" then return false,"invalid status" end
    current.results[id]={status=status,note=safe(note),recordedAt=now()}
    current.complete=overall(current)~="IN_PROGRESS"
    return true
end

local function finish(current,command,feature,outcome,detail)
    log(current,command,feature,outcome,detail)
    local saved,saveError=writeReport(current)
    printLine(string.format("%s: %s %s",command,outcome,safe(detail)))
    if saved then printLine("Results saved to Zomboid/Lua/"..RESULT_FILE)
    else printLine("Result export failed: "..safe(saveError)) end
    return outcome=="PASS",detail
end

local function ensureFixtures()
    local ok,err=Fixtures.ensure()
    return ok,err and safe(err) or nil
end

local function itemList(container)
    if not container or type(container.getItems)~="function" then return nil end
    local ok,items=pcall(container.getItems,container); return ok and items or nil
end

local function each(items,callback)
    if not items then return end
    if type(items.size)=="function" and type(items.get)=="function" then
        local ok,count=pcall(items.size,items); if not ok then return end
        for index=0,math.min(tonumber(count) or 0,512)-1 do local read,item=pcall(items.get,items,index); if read then callback(item) end end
    elseif type(items)=="table" then
        for index=1,math.min(#items,512) do callback(items[index]) end
    end
end

local function fullType(item)
    if not item or type(item.getFullType)~="function" then return nil end
    local ok,value=pcall(item.getFullType,item); return ok and tostring(value) or nil
end

local function findMarked(container,kind,sessionId,depth,seen)
    depth=depth or 0; seen=seen or {}; if not container or depth>4 or seen[container] then return nil end; seen[container]=true
    local found
    each(itemList(container),function(item)
        if found then return end
        local data
        if item and type(item.getModData)=="function" then local ok,value=pcall(item.getModData,item); if ok then data=value end end
        if type(data)=="table" and data.B47ANCEDKnowledgeAndWisdomTestKind==kind
            and (not sessionId or data.B47ANCEDKnowledgeAndWisdomTestSession==sessionId) then found=item; return end
        local child
        if item and type(item.getInventory)=="function" then local ok,value=pcall(item.getInventory,item); if ok then child=value end end
        if not child and item and type(item.getItemContainer)=="function" then local ok,value=pcall(item.getItemContainer,item); if ok then child=value end end
        if child then found=findMarked(child,kind,sessionId,depth+1,seen) end
    end)
    return found
end

local function addTestItem(character,current,fullTypeValue,kind)
    if not character or type(character.getInventory)~="function" then return nil,"player inventory unavailable" end
    local ok,inventory=pcall(character.getInventory,character); if not ok or not inventory then return nil,"player inventory unavailable" end
    local existing=findMarked(inventory,kind,current.sessionId)
    if existing then return existing end
    if type(inventory.AddItem)~="function" then return nil,"inventory AddItem unavailable" end
    -- Build 42 exposes item creation through the container's full-type overload.
    local added,item=pcall(inventory.AddItem,inventory,fullTypeValue)
    if not added or not item then return nil,"item unavailable through inventory: "..fullTypeValue end
    if type(item.getModData)=="function" then
        local data=item:getModData(); data.B47ANCEDKnowledgeAndWisdomTestKind=kind; data.B47ANCEDKnowledgeAndWisdomTestSession=current.sessionId
    end
    return item
end

local function resetFixtureState(character)
    local data=modData(character); local ledger=data and data[API.ROOT_KEY]
    if type(ledger)=="table" then
        if type(ledger.documents)=="table" then ledger.documents[FOUNDATION_DOCUMENT]=nil; ledger.documents[ADVANCED_DOCUMENT]=nil end
        if type(ledger.knowledge)=="table" then ledger.knowledge[FOUNDATION_KNOWLEDGE]=nil; ledger.knowledge[ADVANCED_KNOWLEDGE]=nil end
    end
end

local function currentPending(current)
    for _,step in ipairs(steps) do if not current.results[step.id] then return step end end
    return nil
end

function Harness.auto()
    local current,character,sessionError=session(true)
    if not current then printLine(sessionError); return false,sessionError end
    local fixtures,fixtureError=ensureFixtures()
    local canonical=rawget(_G,"B47ANCEDKnowledgeAndWisdom")==API and API.VERSION==current.modVersion
    local writerOk,writerError=writeReport(current)
    local pass=fixtures and canonical and writerOk
    local detail=string.format("canonical=%s fixtures=%s writer=%s%s",tostring(canonical),tostring(fixtures),tostring(writerOk),writerError and (" error="..writerError) or "")
    record(current,"startup",pass and "PASS" or "FAIL",fixtureError or detail)
    return finish(current,"B47ANCEDKnowledgeAndWisdomTestAuto()","startup",pass and "PASS" or "FAIL",fixtureError or detail)
end

function Harness.giveFiles()
    local current,character,err=session(true); if not current then printLine(err); return false,err end
    local fixtures,fixtureError=ensureFixtures(); if not fixtures then return finish(current,"B47ANCEDKnowledgeAndWisdomTestGiveFiles()","test fixtures","FAIL",fixtureError) end
    local granted={}
    for _,definition in ipairs({{FOUNDATION_ITEM,"foundation"},{ADVANCED_ITEM,"advanced"}}) do
        local item,itemError=addTestItem(character,current,definition[1],definition[2])
        if not item then return finish(current,"B47ANCEDKnowledgeAndWisdomTestGiveFiles()","research files","FAIL",itemError) end
        granted[#granted+1]=definition[1]
    end
    return finish(current,"B47ANCEDKnowledgeAndWisdomTestGiveFiles()","research files","PASS","available="..table.concat(granted,","))
end

function Harness.start(reset)
    local current,character,err=session(true); if not current then printLine(err); return false,err end
    if reset==true then
        local data=modData(character); data[DATA_KEY]=nil; current=session(true); resetFixtureState(character)
    end
    ensureFixtures()
    local allowed=API.canLearn(character,ADVANCED_DOCUMENT)
    current.prerequisiteInitiallyBlocked=allowed~=true
    Harness.giveFiles()
    Harness.auto()
    local nextStep=currentPending(current)
    printLine("Session started. Use the one-page files in inventory and follow the current step.")
    if nextStep then printLine("NEXT ["..nextStep.id.."] "..nextStep.instruction) end
    return true,current.sessionId
end

function Harness.knowledgeStatus()
    local current,character,err=session(false); if not current then printLine(err or "No session; run B47ANCEDKnowledgeAndWisdomTestStart(true)"); return false,err end
    local foundationRead=API.hasRead(character,FOUNDATION_DOCUMENT)
    local foundationKnowledge=API.hasKnowledge(character,FOUNDATION_KNOWLEDGE)
    local advancedRead=API.hasRead(character,ADVANCED_DOCUMENT)
    local advancedKnowledge=API.hasKnowledge(character,ADVANCED_KNOWLEDGE)
    local advancedAllowed=API.canLearn(character,ADVANCED_DOCUMENT)==true
    if foundationRead and foundationKnowledge then record(current,"read_unlock","PASS","foundation document and knowledge recorded") end
    if current.prerequisiteInitiallyBlocked and advancedRead and advancedKnowledge then
        record(current,"prerequisite","PASS","advanced document was initially blocked and later unlocked")
    end
    local detail=string.format("foundationRead=%s foundationKnowledge=%s advancedAllowed=%s advancedRead=%s advancedKnowledge=%s",
        tostring(foundationRead),tostring(foundationKnowledge),tostring(advancedAllowed),tostring(advancedRead),tostring(advancedKnowledge))
    return finish(current,"B47ANCEDKnowledgeAndWisdomTestKnowledge()","knowledge and prerequisites","PASS",detail)
end

local function xpValue(character)
    local perks=rawget(_G,"Perks"); if not perks or perks.Mechanics==nil or not character or type(character.getXp)~="function" then return nil end
    local ok,xp=pcall(character.getXp,character); if not ok or not xp or type(xp.getXP)~="function" then return nil end
    local read,value=pcall(xp.getXP,xp,perks.Mechanics); return read and tonumber(value) or nil
end

function Harness.progression()
    local current,character,err=session(false); if not current then printLine(err or "No session"); return false,err end
    if current.results.semantic_progression and current.results.semantic_progression.status=="PASS" then
        return finish(current,"B47ANCEDKnowledgeAndWisdomTestProgression()","semantic progression","PASS","already completed; no additional XP awarded")
    end
    local fixtures,fixtureError=ensureFixtures(); if not fixtures then return finish(current,"B47ANCEDKnowledgeAndWisdomTestProgression()","semantic progression","FAIL",fixtureError) end
    local before=xpValue(character)
    local ok,result=API.processSemanticAction(character,SEMANTIC_ACTION,
        {committed=true,meaningful=true,outcome="success",quality=.5,sourceCategory="test",sourceId=current.sessionId},
        {worldAgeHours=worldAge() or 0})
    local after=xpValue(character)
    local pass=ok==true and type(result)=="table" and result.applied==true and (before==nil or after==nil or after>before)
    local detail=string.format("applied=%s before=%s after=%s totalXP=%s",tostring(ok and result and result.applied),tostring(before),tostring(after),tostring(result and result.totalXP))
    record(current,"semantic_progression",pass and "PASS" or "FAIL",pass and detail or (result or detail))
    return finish(current,"B47ANCEDKnowledgeAndWisdomTestProgression()","semantic progression",pass and "PASS" or "FAIL",pass and detail or result)
end

function Harness.journal()
    local current,character,err=session(false); if not current then printLine(err or "No session"); return false,err end
    local item,itemError=addTestItem(character,current,JOURNAL_ITEM,"journal")
    if not item then return finish(current,"B47ANCEDKnowledgeAndWisdomTestJournal()","Survivor Journal","FAIL",itemError) end
    local currentXP=xpValue(character) or 0
    local capture={rawXP={Mechanics=currentXP+100},documents={[FOUNDATION_DOCUMENT]=API.hasRead(character,FOUNDATION_DOCUMENT)},
        knowledge={[FOUNDATION_KNOWLEDGE]=API.hasKnowledge(character,FOUNDATION_KNOWLEDGE)}}
    local author="B47ANCEDKnowledgeAndWisdom-test-local"
    local began,beginResult=Journals.beginWriting(item,author,capture,current.sessionId,{worldAgeHours=worldAge()})
    if not began then return finish(current,"B47ANCEDKnowledgeAndWisdomTestJournal()","Survivor Journal","FAIL",beginResult) end
    local advanced,advanceResult=Journals.advanceWriting(item,author,1)
    local snapshot,snapshotError=Journals.snapshot(item)
    local partial=advanced and snapshot and snapshot.writing~=nil and #snapshot.queue>0
    if partial then
        current.journalPayloadId=snapshot.payloadId; current.journalRevision=snapshot.revision
        current.journalRuntimeToken=RUNTIME_TOKEN
        record(current,"journal_partial","PASS","one minute committed with unfinished queue and payload="..safe(snapshot.payloadId))
    else
        record(current,"journal_partial","FAIL",snapshotError or "journal did not retain partial work")
    end
    return finish(current,"B47ANCEDKnowledgeAndWisdomTestJournal()","Survivor Journal",partial and "PASS" or "FAIL",
        partial and ("revision="..tostring(snapshot.revision).." remaining="..tostring(#snapshot.queue)) or (snapshotError or advanceResult))
end

function Harness.journalStatus()
    local current,character,err=session(false); if not current then printLine(err or "No session"); return false,err end
    local inventory=character and character:getInventory()
    local item=findMarked(inventory,"journal",current.sessionId)
    if not item then record(current,"journal_persistence","FAIL","marked journal not found after reload"); return finish(current,"B47ANCEDKnowledgeAndWisdomTestJournalStatus()","journal persistence","FAIL","marked journal not found") end
    local snapshot,snapshotError=Journals.snapshot(item)
    local same=snapshot and snapshot.payloadId==current.journalPayloadId and snapshot.revision==current.journalRevision and snapshot.writing~=nil
    local reloaded=current.journalRuntimeToken~=RUNTIME_TOKEN
    if same and reloaded then record(current,"journal_persistence","PASS","payload, revision, and partial writing survived runtime reload")
    elseif not same then record(current,"journal_persistence","FAIL",snapshotError or "journal state changed or disappeared") end
    local status=same and reloaded and "PASS" or (same and "BLOCKED" or "FAIL")
    local detail=same and (reloaded and "reload verified" or "state intact; save/quit/reload still required") or (snapshotError or "state mismatch")
    return finish(current,"B47ANCEDKnowledgeAndWisdomTestJournalStatus()","journal persistence",status,detail)
end

function Harness.sandboxStatus()
    local current=session(false); if not current then printLine("No session"); return false end
    local root=rawget(_G,"SandboxVars"); local options=root and root.B47ANCEDKnowledgeAndWisdom
    local detail="EnableResearchViewer="..tostring(options and options.EnableResearchViewer)
    return finish(current,"B47ANCEDKnowledgeAndWisdomTestSandbox()","sandbox toggle","PASS",detail.."; visual disabled-world confirmation remains manual")
end

function Harness.recordCurrent(status,note)
    local current=session(false); if not current then printLine("No session"); return false end
    local step=currentPending(current); if not step then printLine("All steps already recorded"); return false end
    record(current,step.id,status,note)
    finish(current,"B47ANCEDKnowledgeAndWisdomTest"..status:sub(1,1)..status:sub(2):lower().."()",step.id,status,note)
    local nextStep=currentPending(current)
    if nextStep then printLine("NEXT ["..nextStep.id.."] "..nextStep.instruction)
    else printLine("All steps recorded. Run B47ANCEDKnowledgeAndWisdomTestReport().") end
    return true
end

function Harness.report()
    local current=session(false); if not current then printLine("No session"); return false end
    printLine("REPORT BEGIN")
    for _,line in ipairs(lines(current)) do printLine(line) end
    printLine("REPORT END")
    local saved,err=writeReport(current)
    if saved then printLine("Results saved to Zomboid/Lua/"..RESULT_FILE) else printLine("Result export failed: "..safe(err)) end
    return saved,err
end

function Harness.where() printLine("Windows result file: %USERPROFILE%\\Zomboid\\Lua\\"..RESULT_FILE); return RESULT_FILE end

B47ANCEDKnowledgeAndWisdomTestStart=function(reset) return Harness.start(reset) end
B47ANCEDKnowledgeAndWisdomTestAuto=function() return Harness.auto() end
B47ANCEDKnowledgeAndWisdomTestGiveFiles=function() return Harness.giveFiles() end
B47ANCEDKnowledgeAndWisdomTestKnowledge=function() return Harness.knowledgeStatus() end
B47ANCEDKnowledgeAndWisdomTestProgression=function() return Harness.progression() end
B47ANCEDKnowledgeAndWisdomTestJournal=function() return Harness.journal() end
B47ANCEDKnowledgeAndWisdomTestJournalStatus=function() return Harness.journalStatus() end
B47ANCEDKnowledgeAndWisdomTestSandbox=function() return Harness.sandboxStatus() end
B47ANCEDKnowledgeAndWisdomTestPass=function(note) return Harness.recordCurrent("PASS",note) end
B47ANCEDKnowledgeAndWisdomTestFail=function(note) return Harness.recordCurrent("FAIL",note) end
B47ANCEDKnowledgeAndWisdomTestBlocked=function(note) return Harness.recordCurrent("BLOCKED",note) end
B47ANCEDKnowledgeAndWisdomTestReport=function() return Harness.report() end
B47ANCEDKnowledgeAndWisdomTestWhere=function() return Harness.where() end

API.TestHarness=Harness
printLine("Ready: B47ANCEDKnowledgeAndWisdomTestStart(true); results export to Zomboid/Lua/"..RESULT_FILE)
return Harness
