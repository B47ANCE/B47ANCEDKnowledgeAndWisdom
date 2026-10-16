local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
for _,name in ipairs({
    "B47ANCEDKnowledgeAndWisdom/API",
    "B47ANCEDKnowledgeAndWisdom/LegacyMigration",
    "B47ANCEDKnowledgeAndWisdom/Progression",
    "B47ANCEDKnowledgeAndWisdom/SurvivorJournals",
}) do package.loaded[name]=nil end
_G.B47ANCEDKnowledgeAndWisdom=nil

local API=require "B47ANCEDKnowledgeAndWisdom/Progression"
local Journals=require "B47ANCEDKnowledgeAndWisdom/SurvivorJournals"

assert(API==_G.B47ANCEDKnowledgeAndWisdom,"canonical require must publish only the correctly spelled global")
assert(API.VERSION=="0.13.0","canonical API version must match the current release")

local character={modData={}}
function character:getModData() return self.modData end
character.modData.EXPERIANCE_WORKS_KNOWLEDGE_V1={schemaVersion=1,documents={legacyDocument=true},knowledge={legacyKnowledge=true}}
character.modData.EXPERIANCE_WORKS_PROGRESSION_V1={schemaVersion=1,sources={},transactions={},nextTransaction=1}

assert(API.hasRead(character,"legacyDocument"),"legacy knowledge ledger should migrate on first read")
assert(character.modData[API.ROOT_KEY]~=nil and character.modData.EXPERIANCE_WORKS_KNOWLEDGE_V1==nil,
    "knowledge migration must move state to the canonical key")
local progression=API.progressionSnapshot(character)
assert(progression and progression.nextTransaction==1,"legacy progression ledger should remain readable")
assert(character.modData[API.PROGRESSION_ROOT_KEY]~=nil and character.modData.EXPERIANCE_WORKS_PROGRESSION_V1==nil,
    "progression migration must move state to the canonical key")

local journal={modData={experianceWorksSurvivorJournal={
    schemaVersion=1,payloadId="legacy",authorId="author",
    documented={rawXP={},discrete={}},queue={},writing=nil,recovery=nil,revision=0,
}}}
function journal:getModData() return self.modData end
local snapshot=Journals.snapshot(journal)
assert(snapshot and snapshot.payloadId=="legacy","legacy Survivor Journal should remain readable")
assert(journal.modData[LegacyMigration.STORAGE_JOURNAL_KEY]~=nil and journal.modData.experianceWorksSurvivorJournal==nil,
    "Survivor Journal migration must move state to the canonical key")

print("B47ANCEDKnowledgeAndWisdom canonical identity and legacy save-state migration checks passed")
