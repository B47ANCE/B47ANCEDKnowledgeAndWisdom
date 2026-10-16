local API=require "B47ANCEDKnowledgeAndWisdom/API"

local function install()
    local distributions=rawget(_G,"ProceduralDistributions")
    local added,missing=API.applyDistributions(distributions)
    if added>0 then print("[B47ANCEDKnowledgeAndWisdom] registered "..tostring(added).." restricted research loot entries") end
    if #missing>0 then print("[B47ANCEDKnowledgeAndWisdom] unavailable research loot pools: "..table.concat(missing,", ")) end
end

if rawget(_G,"Events") and Events.OnPreDistributionMerge then Events.OnPreDistributionMerge.Add(install) end
return API
