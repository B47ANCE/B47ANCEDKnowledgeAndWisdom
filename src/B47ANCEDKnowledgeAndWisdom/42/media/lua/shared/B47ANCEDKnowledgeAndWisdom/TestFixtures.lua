-- Test documents and registrations must not enter normal player progression.
if type(isDebugEnabled)=="function" and isDebugEnabled()~=true then return {} end

local API=require "B47ANCEDKnowledgeAndWisdom/Progression"

local Fixtures={
    FOUNDATION_KNOWLEDGE="B47ANCEDKnowledgeAndWisdom.Test.FoundationKnowledge",
    ADVANCED_KNOWLEDGE="B47ANCEDKnowledgeAndWisdom.Test.AdvancedKnowledge",
    FOUNDATION_DOCUMENT="EW-TEST-FOUNDATION",
    ADVANCED_DOCUMENT="EW-TEST-PREREQUISITE",
    FOUNDATION_ITEM="B47ANCEDKnowledgeAndWisdom.TestResearchFoundation",
    ADVANCED_ITEM="B47ANCEDKnowledgeAndWisdom.TestResearchAdvanced",
    JOURNAL_ITEM="B47ANCEDKnowledgeAndWisdom.TestSurvivorJournal",
    SEMANTIC_ACTION="B47ANCEDKnowledgeAndWisdom.Test.SemanticProgression",
}

function Fixtures.ensure()
    local ok,err=pcall(function()
        if not API.hasKnowledgeDefinition(Fixtures.FOUNDATION_KNOWLEDGE) then
            API.registerKnowledge{id=Fixtures.FOUNDATION_KNOWLEDGE,owner="B47ANCEDKnowledgeAndWisdom",title="Test foundation knowledge",acquisition="document"}
        end
        if not API.hasKnowledgeDefinition(Fixtures.ADVANCED_KNOWLEDGE) then
            API.registerKnowledge{id=Fixtures.ADVANCED_KNOWLEDGE,owner="B47ANCEDKnowledgeAndWisdom",title="Test prerequisite knowledge",acquisition="document"}
        end
        if not API.hasDocument(Fixtures.FOUNDATION_DOCUMENT) then
            API.registerDocument{id=Fixtures.FOUNDATION_DOCUMENT,project="B47ANCEDKnowledgeAndWisdom",category="validation",classification="TEST",
                title="Foundation Validation File",tier=1,itemType=Fixtures.FOUNDATION_ITEM,
                content={{text="Visible foundation text. "},{text="hidden validation phrase",redacted=true},{text=" End of file."}},
                grantsKnowledge={Fixtures.FOUNDATION_KNOWLEDGE},implementationStatus="test-only"}
        end
        if not API.hasDocument(Fixtures.ADVANCED_DOCUMENT) then
            API.registerDocument{id=Fixtures.ADVANCED_DOCUMENT,project="B47ANCEDKnowledgeAndWisdom",category="validation",classification="TEST",
                title="Prerequisite Validation File",tier=1,itemType=Fixtures.ADVANCED_ITEM,
                content={"This file validates an established knowledge prerequisite."},
                requirements={knowledge=Fixtures.FOUNDATION_KNOWLEDGE},grantsKnowledge={Fixtures.ADVANCED_KNOWLEDGE},implementationStatus="test-only"}
        end
        if not API.hasSemanticAction(Fixtures.SEMANTIC_ACTION) then
            API.registerSemanticAction{id=Fixtures.SEMANTIC_ACTION,owner="B47ANCEDKnowledgeAndWisdom",title="Validation action",baseXP=1,
                skills={Mechanics=1},outcomes={success=1},repeatWindowHours=24,repeatDecay=.35,repeatFloor=.1}
        end
    end)
    if ok then return true,nil end
    return false,tostring(err)
end

Fixtures.ensure()
API.TestFixtures=Fixtures
return Fixtures
