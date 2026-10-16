local common={
    "B47ANCEDKnowledgeAndWisdom/Progression",
    "B47ANCEDKnowledgeAndWisdom/SurvivorJournals",
    "B47ANCEDKnowledgeAndWisdom/TestFixtures",
    "B47ANCEDKnowledgeAndWisdom/ReadCompletion",
    "B47ANCEDKnowledgeAndWisdom/Claims",
    "B47ANCEDKnowledgeAndWisdom/HistoryRecords",
    "B47ANCEDKnowledgeAndWisdom/OriginKnowledge",
    "B47ANCEDKnowledgeAndWisdom/MediaKnowledge",
    "B47ANCEDKnowledgeAndWisdom/API",
}

local function exercise(path,realmModules)
    local modules={}
    for _,name in ipairs(common) do modules[#modules+1]=name end
    for _,name in ipairs(realmModules) do modules[#modules+1]=name end
    local loaded={}
    for _,name in ipairs(modules) do
        package.loaded[name]=nil
        package.preload[name]=function() loaded[name]=(loaded[name] or 0)+1; return {} end
    end
    dofile(path)
    for _,name in ipairs(modules) do
        assert(loaded[name]==1,"realm production loader omitted or duplicated "..name)
        package.preload[name]=nil
        package.loaded[name]=nil
    end
end

exercise(arg[1],{"B47ANCEDKnowledgeAndWisdom/ResearchViewer","B47ANCEDKnowledgeAndWisdom/TestHarness"})
exercise(arg[2],{"B47ANCEDKnowledgeAndWisdom/HistoryServer","B47ANCEDKnowledgeAndWisdom/Distribution"})

print("B47ANCEDKnowledgeAndWisdom client/server production load-graph checks passed")
