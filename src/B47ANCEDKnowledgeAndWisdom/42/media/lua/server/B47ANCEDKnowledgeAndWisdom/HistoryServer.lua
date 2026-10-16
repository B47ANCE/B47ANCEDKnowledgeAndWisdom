local History=require "B47ANCEDKnowledgeAndWisdom/HistoryRecords"
local function attach()
    if not ModData or type(ModData.getOrCreate)~="function"then return false,"MODDATA_UNAVAILABLE"end
    local ok,value=pcall(ModData.getOrCreate,History.STORE_KEY);if not ok then return false,"MODDATA_READ_FAILED"end
    return History.attachStore(value)
end
if Events and Events.OnInitGlobalModData then Events.OnInitGlobalModData.Add(attach)end
History.attachProductionStore=attach
return History
