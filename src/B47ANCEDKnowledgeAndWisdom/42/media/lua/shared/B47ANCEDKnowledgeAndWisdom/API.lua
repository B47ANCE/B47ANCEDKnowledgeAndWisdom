local LegacyMigration=require "B47ANCEDKnowledgeAndWisdom/LegacyMigration"
local SavedState=require "B47ANCEDKnowledgeAndWisdom/SavedState"

B47ANCEDKnowledgeAndWisdom=rawget(_G,"B47ANCEDKnowledgeAndWisdom") or {}
B47ANCEDKnowledgeAndWisdom.VERSION="0.14.1"
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
    local result,seen={},{}
    for _,value in ipairs(values) do assert(type(value)=="string" and value~="",label.." entry required"); if not seen[value] then seen[value]=true; result[#result+1]=value end end
    table.sort(result); return result
end
local function contentSegments(content)
    assert(type(content)=="table" and #content>0,"document content segments required")
    local result={}
    for index,segment in ipairs(content) do
        if type(segment)=="string" then result[index]={text=segment,redacted=false}
        else
            assert(type(segment)=="table" and type(segment.text)=="string" and segment.text~="","document segment text required")
            result[index]={text=segment.text,redacted=segment.redacted==true,marker=segment.marker or "████████"}
            assert(not result[index].redacted or result[index].marker~="","redacted segment marker required")
        end
    end
    return result
end
local function namespacedId(value,label)
    assert(type(value)=="string" and value:match("^[%w_%-]+%.[%w_.%-]+$"),label.." must be a namespaced identifier")
    return value
end
local function requirementCopy(node,path)
    path=path or "requirement"
    assert(type(node)=="table",path.." must be a table")
    local operators=0
    for _,key in ipairs({"all","any","not","knowledge","document"}) do if node[key]~=nil then operators=operators+1 end end
    assert(operators==1,path.." must contain exactly one operator")
    if node.knowledge~=nil then return {knowledge=namespacedId(node.knowledge,path..".knowledge")} end
    if node.document~=nil then assert(type(node.document)=="string" and node.document~="",path..".document required"); return {document=node.document} end
    if node["not"]~=nil then return {["not"]=requirementCopy(node["not"],path..".not")} end
    local operator=node.all~=nil and "all" or "any"
    local values=node[operator]
    assert(type(values)=="table" and #values>0,path.."."..operator.." must be a non-empty array")
    local result={[operator]={}}
    for index,value in ipairs(values) do result[operator][index]=requirementCopy(value,path.."."..operator.."["..index.."]") end
    return result
end
local function assertRequirementKnowledge(node)
    if node.knowledge then assert(B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[node.knowledge],"unknown requirement knowledge: "..node.knowledge); return end
    if node["not"] then assertRequirementKnowledge(node["not"]); return end
    for _,child in ipairs(node.all or node.any or {}) do assertRequirementKnowledge(child) end
end
local function canWrite()
    local client=type(rawget(_G,"isClient"))=="function" and isClient()==true
    local server=type(rawget(_G,"isServer"))=="function" and isServer()==true
    return server or not client
end

function B47ANCEDKnowledgeAndWisdom.registerKnowledge(definition)
    assert(type(definition)=="table","knowledge definition required")
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
    local def=copy(definition)
    for _,field in ipairs({"id","project","category","classification","title"}) do assert(type(def[field])=="string" and def[field]~="","document "..field.." required") end
    assert(not B47ANCEDKnowledgeAndWisdom.Documents[def.id],"duplicate B47ANCEDKnowledgeAndWisdom document: "..def.id)
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
        for pool,weight in pairs(def.distribution) do assert(type(pool)=="string" and pool~="" and tonumber(weight) and tonumber(weight)>0,"document distribution pool/weight invalid") end
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
    return evaluateRequirement(character,nodeOrError)
end
function B47ANCEDKnowledgeAndWisdom.canLearn(character,id)
    local document=B47ANCEDKnowledgeAndWisdom.Documents[id]; if not document then return false,"unknown document" end
    local current,err=ledger(character,false); if not current then return false,err end
    if document.requirements then local allowed,reason=evaluateRequirement(character,document.requirements); if not allowed then return false,reason end end
    return true,document
end
function B47ANCEDKnowledgeAndWisdom.learn(character,id,context)
    context=type(context)=="table" and context or {}
    if not canWrite() then return false,"non-authority" end
    local allowed,documentOrError=B47ANCEDKnowledgeAndWisdom.canLearn(character,id); if not allowed then return false,documentOrError end
    local current,ledgerError=ledger(character,true)
    if not current then return false,ledgerError end
    if current.documents[id] then return true,{duplicate=true,newKnowledge={}} end
    local learnedAt=tonumber(context.worldAgeHours)
    current.documents[id]={learnedAtWorldAgeHours=learnedAt,sourceFullType=context.sourceFullType}
    local granted={}; for _,knowledge in ipairs(documentOrError.grantsKnowledge) do if not current.knowledge[knowledge] then current.knowledge[knowledge]={sourceDocument=id,owner=B47ANCEDKnowledgeAndWisdom.KnowledgeDefinitions[knowledge].owner,learnedAtWorldAgeHours=learnedAt}; granted[#granted+1]=knowledge end end
    if character.transmitModData then pcall(function() character:transmitModData() end) end
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
    context=type(context)=="table" and context or {}
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
