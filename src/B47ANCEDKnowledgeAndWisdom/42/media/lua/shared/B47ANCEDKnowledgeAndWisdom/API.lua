local Guard=require "B47ANCEDKnowledgeAndWisdom/AuthorityGuard"
local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local SavedState=require "B47ANCEDKnowledgeAndWisdom/SavedState"

B47ANCEDKnowledgeAndWisdom=rawget(_G,"B47ANCEDKnowledgeAndWisdom") or {}
B47ANCEDKnowledgeAndWisdom.VERSION="0.17.0"
B47ANCEDKnowledgeAndWisdom.Documents=B47ANCEDKnowledgeAndWisdom.Documents or {}
B47ANCEDKnowledgeAndWisdom.DocumentsByItemType=B47ANCEDKnowledgeAndWisdom.DocumentsByItemType or {}
B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions=B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions or {}
B47ANCEDKnowledgeAndWisdom.ROOT_KEY=LegacyMigration.STORAGE_KNOWLEDGE_KEY

local function copy(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {}; if seen[value] then return nil end; seen[value]=true
    local result={}; for key,child in pairs(value) do result[key]=copy(child,seen) end
    seen[value]=nil; return result
end
local function stringList(values,label)
    if values==nil then return {} end
    assert(type(values)=="table",label.." must be a table")
    assert(SavedState.array(values,function(v)return SavedState.string(v,160)end,512),label.." must be a bounded dense string array")
    local result,seen={},{}
    for _,value in ipairs(values) do assert(type(value)=="string" and value~="",label.." entry required"); if not seen[value] then seen[value]=true; result[#result+1]=value end end
    table.sort(result); return result
end
local function contentSegments(content)
    assert(type(content)=="table" and #content>0,"document content segments required")
    assert(SavedState.array(content,function()return true end,512),"document content must be a bounded dense array")
    local result={}
    for index,segment in ipairs(content) do
        if type(segment)=="string" then result[index]={text=segment,redacted=false}
        else
            assert(type(segment)=="table" and type(segment.text)=="string" and segment.text~="","document segment text required")
            assert(segment.marker==nil or SavedState.string(segment.marker),"redaction marker must be a bounded string")
            result[index]={text=segment.text,redacted=segment.redacted==true,marker=segment.marker or "████████"}
            assert(not result[index].redacted or result[index].marker~="","redacted segment marker required")
        end
    end
    return result
end
local function namespacedId(value,label)
    assert(SavedState.string(value,160) and value:match("^[%w_%-]+%.[%w_.%-]+$"),label.." must be a namespaced identifier")
    return value
end
-- Technical input limits bound provider mistakes; these are not gameplay knobs.
local function requirementCopy(node,path,guard,depth)
    path=path or "requirement";guard=guard or {active={},nodes=0};depth=depth or 1
    guard.nodes=guard.nodes+1
    assert(guard.nodes<=512 and depth<=16,"requirement exceeds safe limits")
    assert(type(node)=="table" and not guard.active[node],path.." must be an acyclic table")
    guard.active[node]=true
    local operators=0
    local allowed={all=true,any=true,["not"]=true,knowledge=true,document=true}
    for key in pairs(node) do assert(allowed[key],path.." has an unknown operator");operators=operators+1 end
    assert(operators==1,path.." must contain exactly one operator")
    local result
    if node.knowledge~=nil then
        assert(SavedState.string(node.knowledge),path..".knowledge invalid")
        result={knowledge=namespacedId(node.knowledge,path..".knowledge")}
    elseif node.document~=nil then
        assert(SavedState.string(node.document),path..".document required")
        result={document=node.document}
    elseif node["not"]~=nil then
        result={["not"]=requirementCopy(node["not"],path..".not",guard,depth+1)}
    else
        local operator=node.all~=nil and "all" or "any"
        local values=node[operator]
        assert(type(values)=="table" and #values>0 and #values<=512,path.." must be a bounded non-empty array")
        local count=0
        for key in pairs(values) do
            assert(SavedState.integer(key) and key>=1 and key<=#values,path.." must be a dense array")
            count=count+1
        end
        assert(count==#values,path.." must be a dense array")
        result={[operator]={}}
        for index,value in ipairs(values) do result[operator][index]=requirementCopy(value,path.."."..operator,guard,depth+1) end
    end
    guard.active[node]=nil
    return result
end
local function requirementReferences(node)
    if node.knowledge then
        if not B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[node.knowledge] then return false,"unknown knowledge definition: "..node.knowledge end
    elseif node.document then
        if not B47ANCEDKnowledgeAndWisdom.Documents[node.document] then return false,"unknown document: "..node.document end
    elseif node["not"] then return requirementReferences(node["not"])
    else
        for _,child in ipairs(node.all or node.any) do
            local ok,err=requirementReferences(child);if not ok then return false,err end
        end
    end
    return true
end
local function assertRequirementKnowledge(node)
    if node.knowledge then assert(B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[node.knowledge],"unknown requirement knowledge: "..node.knowledge); return end
    if node["not"] then assertRequirementKnowledge(node["not"]); return end
    for _,child in ipairs(node.all or node.any or {}) do assertRequirementKnowledge(child) end
end
local knowledgeBackend
function B47ANCEDKnowledgeAndWisdom._installKnowledgeBackend(backend)
    if knowledgeBackend or type(backend)~='table'or type(backend.read)~='function'or Guard.realm()=='unknown'then return false end
    knowledgeBackend=backend;return true
end
local function canWrite()
    if Guard.isServer()and knowledgeBackend and knowledgeBackend.ready then
        if knowledgeBackend.ready()then return true end
        return false,knowledgeBackend.failureCode and knowledgeBackend.failureCode()or'PRIVATE_STORE_UNAVAILABLE'
    end
    return Guard.write()
end

function B47ANCEDKnowledgeAndWisdom.registerKnowledge(definition)
    assert(type(definition)=="table","knowledge definition required")
    assert(SavedState.tree(definition),"definition must be bounded acyclic data")
    local def=copy(definition)
    namespacedId(def.id,"knowledge id")
    assert(type(def.owner)=="string" and def.owner~="","knowledge owner required")
    assert(type(def.title)=="string" and def.title~="","knowledge title required")
    assert(not B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[def.id],"duplicate B47ANCEDKnowledgeAndWisdom knowledge: "..def.id)
    def.description=type(def.description)=="string" and def.description or ""
    def.acquisition=type(def.acquisition)=="string" and def.acquisition or "document"
    B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[def.id]=def
    return copy(def)
end
function B47ANCEDKnowledgeAndWisdom.getKnowledgeDefinition(id) return copy(B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[id]) end
function B47ANCEDKnowledgeAndWisdom.hasKnowledgeDefinition(id) return B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[id]~=nil end
function B47ANCEDKnowledgeAndWisdom.allKnowledgeDefinitions() return copy(B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions) end
local function ledger(character,create)
    if knowledgeBackend and(Guard.isServer()or Guard.realm()=='client')then return knowledgeBackend.read(character)end
    local allowed,reason=Guard.characterRead();if not allowed then return nil,reason end
    if not character or not character.getModData then return nil,"character ModData unavailable" end
    local ok,data=pcall(function() return character:getModData() end)
    if not ok or type(data)~="table" then return nil,"character ModData unavailable" end
    local current=LegacyMigration.readTableKey(data,B47ANCEDKnowledgeAndWisdom.ROOT_KEY,LegacyMigration.KNOWLEDGE_ROOT_KEY)
    if current==nil then
        local empty={schemaVersion=1,documents={},knowledge={}}
        if create then data[B47ANCEDKnowledgeAndWisdom.ROOT_KEY]=empty end
        return empty
    end
    -- Never repair or downgrade an unknown save format from a query. Preserve
    -- corrupt/future data for diagnostics instead of erasing earned knowledge.
    if not SavedState.knowledge(current) then
        return nil,"unsupported or malformed knowledge ledger"
    end
    if create and canWrite() then
        LegacyMigration.moveTableKey(data,B47ANCEDKnowledgeAndWisdom.ROOT_KEY,LegacyMigration.KNOWLEDGE_ROOT_KEY)
    end
    return current
end

function B47ANCEDKnowledgeAndWisdom.registerDocument(definition)
    assert(type(definition)=="table","document definition required")
    assert(SavedState.tree(definition),"definition must be bounded acyclic data")
    local def=copy(definition)
    for _,field in ipairs({"id","project","category","classification","title"}) do assert(type(def[field])=="string" and def[field]~="","document "..field.." required") end
    assert(not B47ANCEDKnowledgeAndWisdom.Documents[def.id],"duplicate B47ANCEDKnowledgeAndWisdom document: "..def.id)
    assert(def.tier==nil or SavedState.finite(tonumber(def.tier)),"document tier must be finite")
    assert(SavedState.string(def.id,160),"document id exceeds safe limit")
    def.tier=math.max(1,math.min(4,math.floor(tonumber(def.tier) or 1)))
    def.content=contentSegments(def.content)
    def.spawnCategories=stringList(def.spawnCategories,"spawnCategories")
    def.references=stringList(def.references,"references")
    def.prerequisiteDocuments=stringList(def.prerequisiteDocuments,"prerequisiteDocuments")
    def.prerequisiteKnowledge=stringList(def.prerequisiteKnowledge,"prerequisiteKnowledge")
    def.grantsKnowledge=stringList(def.grantsKnowledge,"grantsKnowledge")
    for _,knowledge in ipairs(def.prerequisiteKnowledge) do assert(B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[knowledge],"unknown prerequisite knowledge: "..knowledge) end
    for _,knowledge in ipairs(def.grantsKnowledge) do assert(B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[knowledge],"unknown granted knowledge: "..knowledge) end
    local compatibility={}
    for _,id in ipairs(def.prerequisiteDocuments) do compatibility[#compatibility+1]={document=id} end
    for _,id in ipairs(def.prerequisiteKnowledge) do compatibility[#compatibility+1]={knowledge=id} end
    if def.requirements~=nil then compatibility[#compatibility+1]=requirementCopy(def.requirements,"document requirements") end
    def.requirements=#compatibility>0 and (#compatibility==1 and compatibility[1] or {all=compatibility}) or nil
    if def.requirements then assertRequirementKnowledge(def.requirements) end
    def.implementationStatus=def.implementationStatus or "registered"
    if def.itemType~=nil then
        assert(type(def.itemType)=="string" and def.itemType~="","document itemType must be a string")
        assert(not B47ANCEDKnowledgeAndWisdom.DocumentsByItemType[def.itemType],"duplicate document itemType: "..def.itemType)
    end
    if def.distribution~=nil then
        assert(type(def.distribution)=="table","document distribution must be a table")
        for pool,weight in pairs(def.distribution) do assert(type(pool)=="string" and pool~="" and SavedState.finite(tonumber(weight)) and tonumber(weight)>0,"document distribution pool/weight invalid") end
    else def.distribution={} end
    B47ANCEDKnowledgeAndWisdom.Documents[def.id]=def
    if def.itemType then B47ANCEDKnowledgeAndWisdom.DocumentsByItemType[def.itemType]=def.id end
    return copy(def)
end
function B47ANCEDKnowledgeAndWisdom.getDocument(id) return copy(B47ANCEDKnowledgeAndWisdom.Documents[id]) end
function B47ANCEDKnowledgeAndWisdom.hasDocument(id) return B47ANCEDKnowledgeAndWisdom.Documents[id]~=nil end
function B47ANCEDKnowledgeAndWisdom.allDocuments() return copy(B47ANCEDKnowledgeAndWisdom.Documents) end
function B47ANCEDKnowledgeAndWisdom.getDocumentForItem(itemOrFullType)
    local fullType=itemOrFullType
    if type(itemOrFullType)~="string" and itemOrFullType then
        local ok,value=pcall(function() return itemOrFullType:getFullType() end)
        fullType=ok and value or nil
    end
    local id=fullType and (B47ANCEDKnowledgeAndWisdom.DocumentsByItemType[tostring(fullType)]
        or B47ANCEDKnowledgeAndWisdom.DocumentsByItemType[LegacyMigration.canonicalItemType(tostring(fullType))])
    return id and B47ANCEDKnowledgeAndWisdom.getDocument(id) or nil
end
function B47ANCEDKnowledgeAndWisdom.renderDocument(id,revealRedactions)
    local document=B47ANCEDKnowledgeAndWisdom.Documents[id]; if not document then return nil,"unknown document" end
    local parts={}; for _,segment in ipairs(document.content) do parts[#parts+1]=(segment.redacted and not revealRedactions) and segment.marker or segment.text end
    return table.concat(parts)
end
-- Presentation consumers receive only the player-visible text, never canonical
-- redacted segments or an implicit knowledge grant.
function B47ANCEDKnowledgeAndWisdom.getDocumentView(character,item)
    local document=B47ANCEDKnowledgeAndWisdom.getDocumentForItem(item)
    if not document then return nil,"item is not a registered document" end
    local allowed,reason=B47ANCEDKnowledgeAndWisdom.canLearn(character,document.id)
    return {id=document.id,title=document.title,project=document.project,
        classification=document.classification,category=document.category,
        text=B47ANCEDKnowledgeAndWisdom.renderDocument(document.id,false),
        read=B47ANCEDKnowledgeAndWisdom.hasRead(character,document.id),canLearn=allowed,
        prerequisiteStatus=allowed and "Prerequisites satisfied" or tostring(reason)}
end
function B47ANCEDKnowledgeAndWisdom.hasRead(character,id) local current=ledger(character,false); return current~=nil and current.documents[id]~=nil end
function B47ANCEDKnowledgeAndWisdom.hasKnowledge(character,id) local current=ledger(character,false); return current~=nil and current.knowledge[id]~=nil end
local function evaluateRequirement(character,node)
    if node.knowledge then
        if not B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[node.knowledge] then return false,"unknown knowledge definition: "..node.knowledge end
        return B47ANCEDKnowledgeAndWisdom.hasKnowledge(character,node.knowledge),"missing knowledge: "..node.knowledge
    end
    if node.document then return B47ANCEDKnowledgeAndWisdom.hasRead(character,node.document),"missing document: "..node.document end
    if node["not"] then
        local matched=evaluateRequirement(character,node["not"])
        return not matched,matched and "excluded prerequisite matched" or nil
    end
    if node.all then
        for _,child in ipairs(node.all) do local matched,reason=evaluateRequirement(character,child); if not matched then return false,reason end end
        return true
    end
    local reasons={}
    for _,child in ipairs(node.any) do local matched,reason=evaluateRequirement(character,child); if matched then return true end; reasons[#reasons+1]=reason end
    return false,"requires any of: "..table.concat(reasons,"; ")
end
function B47ANCEDKnowledgeAndWisdom.validateRequirement(requirement)
    local ok,result=pcall(requirementCopy,requirement,"requirement")
    if not ok then return false,result end
    return true,result
end
function B47ANCEDKnowledgeAndWisdom.evaluateRequirement(character,requirement)
    local ok,nodeOrError=B47ANCEDKnowledgeAndWisdom.validateRequirement(requirement)
    if not ok then return false,nodeOrError end
    local current,err=ledger(character,false); if not current then return false,err end
    -- Unknown references are errors, not false facts that NOT can invert.
    local valid,reason=requirementReferences(nodeOrError);if not valid then return false,reason end
    return evaluateRequirement(character,nodeOrError)
end
function B47ANCEDKnowledgeAndWisdom.canLearn(character,id)
    local document=B47ANCEDKnowledgeAndWisdom.Documents[id]; if not document then return false,"unknown document" end
    local current,err=ledger(character,false); if not current then return false,err end
    if document.requirements then local allowed,reason=B47ANCEDKnowledgeAndWisdom.evaluateRequirement(character,document.requirements); if not allowed then return false,reason end end
    return true,document
end
function B47ANCEDKnowledgeAndWisdom.learn(character,id,context)
    context=type(context)=="table" and context or {}
    local permitted,authorityError=canWrite();if not permitted then return false,authorityError end
    local allowed,documentOrError=B47ANCEDKnowledgeAndWisdom.canLearn(character,id); if not allowed then return false,documentOrError end
    local learnedAt=tonumber(context.worldAgeHours)
    if context.worldAgeHours~=nil and not SavedState.finite(learnedAt)then return false,"invalid learned timestamp"end
    if context.sourceFullType~=nil and not SavedState.string(context.sourceFullType,160)then return false,"invalid source item type"end
    local current,ledgerError=ledger(character,false);if not current then return false,ledgerError end
    if current.documents[id] then
        local pending
        if Guard.isServer()and knowledgeBackend and knowledgeBackend.project then
            local projected,reason=knowledgeBackend.project(character);if not projected then pending=reason end
        end
        return true,{duplicate=true,newKnowledge={},projectionPending=pending}
    end
    local candidate=copy(current)
    candidate.documents[id]={learnedAtWorldAgeHours=learnedAt,sourceFullType=context.sourceFullType}
    local granted={}
    for _,knowledge in ipairs(documentOrError.grantsKnowledge)do
        local definition=B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[knowledge]
        if type(definition)~="table"or not SavedState.string(definition.owner,160)then return false,"unknown or malformed grant definition"end
        if not candidate.knowledge[knowledge]then
            candidate.knowledge[knowledge]={sourceDocument=id,owner=definition.owner,learnedAtWorldAgeHours=learnedAt}
            granted[#granted+1]=knowledge
        end
    end
    if not SavedState.knowledge(candidate)then return false,"knowledge result exceeds supported save format"end
    if Guard.isServer()and knowledgeBackend then
        local saved,reason=knowledgeBackend.write(character,current,candidate)
        if not saved then return false,reason end
        return true,{duplicate=false,documentId=id,newKnowledge=granted,projectionPending=reason}
    end
    local writable,writeError=ledger(character,true);if not writable then return false,writeError end
    for key,value in pairs(candidate)do writable[key]=value end
    return true,{duplicate=false,documentId=id,newKnowledge=granted}
end
function B47ANCEDKnowledgeAndWisdom.snapshot(character)
    local current,err=ledger(character,false)
    if not current then return nil,err end
    return copy(current)
end

function B47ANCEDKnowledgeAndWisdom.completeRead(character,item,context)
    local document=B47ANCEDKnowledgeAndWisdom.getDocumentForItem(item)
    if not document then return false,"item is not a registered document" end
    local input=type(context)=="table"and context or {}
    context={};for key,value in pairs(input)do context[key]=value end
    context.sourceFullType=document.itemType
    local learned,result=B47ANCEDKnowledgeAndWisdom.learn(character,document.id,context)
    if not learned then return false,result end
    local claims=B47ANCEDKnowledgeAndWisdom.Claims
    local subject=claims and claims.subjectId(character)
    if subject then
        local suffix=subject..":"..document.id
        local operationId,claimId="read:"..suffix,"literature:"..suffix
        if #operationId<=160 and #claimId<=160 then
            local claimed,reason,claim=claims.grantAcquisition(character,{schemaVersion=1,
                operationId=operationId,claimId=claimId,definitionId=LegacyMigration.LITERATURE_DEFINITION,subjectId=subject,
                sourceType="document",sourceId=document.id,sourceOwner=LegacyMigration.PERSISTED_OWNER,
                scope={documentId=document.id,itemType=LegacyMigration.persistedItemType(document.itemType)},acquisition="read-completion",
                confidence=1,completeness=1,worldAgeHours=context.worldAgeHours})
            result.claim={ok=claimed,reason=reason,value=claim}
        else result.claim={ok=false,reason="CLAIM_ID_TOO_LONG"} end
    end
    return true,result
end

function B47ANCEDKnowledgeAndWisdom.applyDistributions(distributions)
    local list=type(distributions)=="table" and (distributions.list or distributions) or nil
    if type(list)~="table" then return 0,{"distribution list unavailable"} end
    local added,missing=0,{}
    for _,document in pairs(B47ANCEDKnowledgeAndWisdom.Documents) do
        if document.itemType then
            for poolName,weight in pairs(document.distribution or {}) do
                local pool=list[poolName]
                if type(pool)~="table" or type(pool.items)~="table" then missing[#missing+1]=poolName
                else
                    local exists=false
                    for index=1,#pool.items,2 do if pool.items[index]==document.itemType then exists=true; break end end
                    if not exists then pool.items[#pool.items+1]=document.itemType; pool.items[#pool.items+1]=tonumber(weight); added=added+1 end
                end
            end
        end
    end
    table.sort(missing)
    return added,missing
end

_G.B47ANCEDKnowledgeAndWisdom=B47ANCEDKnowledgeAndWisdom
return B47ANCEDKnowledgeAndWisdom
