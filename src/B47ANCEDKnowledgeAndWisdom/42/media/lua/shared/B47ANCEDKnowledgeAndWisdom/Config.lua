local Guard=require "B47ANCEDKnowledgeAndWisdom/AuthorityGuard"
-- Gameplay snapshots are read only on authority. Clients cannot choose rates.
local Config={}
local specs={
    SemanticXPPercent={0,1000,100},
    RepeatWindowPercent={25,400,100},
    RepeatDecayPercent={0,400,100},
    RepeatFloorPercent={0,400,100},
    JournalRecoveryPercent={0,100,90},
    JournalWritingSpeedPercent={10,1000,100},
    FailureXPCapPercent={0,10,10},
}
function Config.gameplay()
    local realm=Guard.realm()
    if realm=="client"or realm=="unknown"then return nil,"non-authority"end
    local root=type(SandboxVars)=="table"and SandboxVars.B47ANCEDKnowledgeAndWisdom or nil
    local result={}
    for key,spec in pairs(specs)do
        local value=type(root)=="table"and root[key]or nil
        if type(value)~="number"or value~=value or value==math.huge or value==-math.huge then value=spec[3]end
        result[key]=math.floor(math.max(spec[1],math.min(spec[2],value)))
    end
    return result
end
return Config
