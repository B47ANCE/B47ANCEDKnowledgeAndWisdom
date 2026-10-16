-- Private storage compatibility. Keys and built-in record identities are immutable
-- across branding changes: rewriting them would break saved ledgers/replay bindings.
-- New integrations use B47ANCEDKnowledgeAndWisdom, never these historical namespaces.
local LegacyMigration={
    STORAGE_KNOWLEDGE_KEY="EXPERIENCE_WORKS_KNOWLEDGE_V1",
    STORAGE_PROGRESSION_KEY="EXPERIENCE_WORKS_PROGRESSION_V1",
    STORAGE_CLAIMS_KEY="EXPERIENCE_WORKS_CLAIMS_V1",
    STORAGE_JOURNAL_KEY="experienceWorksSurvivorJournal",
    STORAGE_CLAIM_STORE_KEY="experienceWorks.SurvivorJournalClaims.V1",
    STORAGE_HISTORY_KEY="experienceWorks.HistoryRecords.v1",
    PERSISTED_OWNER="experienceWorks",
    LITERATURE_DEFINITION="experienceWorks.LiteratureRead",
    RECOVERY_DEFINITION="experienceWorks.JournalRecovery",
    HOMETOWN_DEFINITION="experienceWorks.Hometown",
    PREVIOUS_SANDBOX_KEY="experienceWorks",
    KNOWLEDGE_ROOT_KEY="EXPERIANCE_WORKS_KNOWLEDGE_V1",
    PROGRESSION_ROOT_KEY="EXPERIANCE_WORKS_PROGRESSION_V1",
    JOURNAL_ROOT_KEY="experianceWorksSurvivorJournal",
    CLAIM_STORE_KEY="experianceWorks.SurvivorJournalClaims.V1",
    SANDBOX_ROOT_KEY="experianceWorks",
}

function LegacyMigration.moveTableKey(data,canonicalKey,legacyKey)
    if type(data)~="table" or data[canonicalKey]~=nil or data[legacyKey]==nil then return false end
    data[canonicalKey]=data[legacyKey]
    data[legacyKey]=nil
    return true
end

-- Old saved item types resolve through the canonical document index without
-- creating a second Lua API or registry. Only this mod's known types are mapped.
local itemTypes={}
itemTypes["experienceWorks.TestResearchFoundation"]=true
itemTypes["experienceWorks.TestResearchAdvanced"]=true
itemTypes["experienceWorks.TestSurvivorJournal"]=true
itemTypes["experienceWorks.CC_Manual_Backhoe"]=true
itemTypes["experienceWorks.CC_Manual_CATExcavator"]=true
itemTypes["experienceWorks.CC_Manual_WheelLoader"]=true
itemTypes["experienceWorks.CC_Manual_CompactLoader"]=true
itemTypes["experienceWorks.CC_Manual_SkidSteer"]=true
itemTypes["experienceWorks.CC_Manual_Skid332D"]=true
itemTypes["experienceWorks.CC_Manual_RoadRoller"]=true
itemTypes["experienceWorks.CC_Manual_UralTipper"]=true
itemTypes["experienceWorks.CC_Manual_MiningTipper"]=true
itemTypes["experienceWorks.CC_Manual_MixerTruck"]=true
itemTypes["experienceWorks.CC_Manual_RoughTerrainCrane"]=true
itemTypes["experienceWorks.CC_Manual_CrawlerCrane"]=true
itemTypes["experienceWorks.CC_Manual_MobileCrane"]=true
itemTypes["experienceWorks.CC_Manual_CompactExcavator"]=true
itemTypes["experienceWorks.CC_Manual_WheeledExcavator"]=true
itemTypes["experienceWorks.CC_Manual_MiniExcavator"]=true

function LegacyMigration.canonicalItemType(value)
    if itemTypes[value] then return "B47ANCEDKnowledgeAndWisdom."..value:sub(17) end
    return value
end

function LegacyMigration.persistedItemType(value)
    local prefix="B47ANCEDKnowledgeAndWisdom."
    if type(value)=="string" and value:sub(1,#prefix)==prefix then
        local historical="experienceWorks."..value:sub(#prefix+1)
        if itemTypes[historical] then return historical end
    end
    return value
end

-- A new world's default true must not mask an old world's explicit false.
-- To re-enable after migration, remove the historical option in the saved config.
function LegacyMigration.viewerEnabled(root)
    if type(root)~="table" then return true end
    for _,key in ipairs({"B47ANCEDKnowledgeAndWisdom",LegacyMigration.PREVIOUS_SANDBOX_KEY,LegacyMigration.SANDBOX_ROOT_KEY}) do
        local options=root[key]
        if type(options)=="table" and options.EnableResearchViewer==false then return false end
    end
    return true
end

return LegacyMigration
