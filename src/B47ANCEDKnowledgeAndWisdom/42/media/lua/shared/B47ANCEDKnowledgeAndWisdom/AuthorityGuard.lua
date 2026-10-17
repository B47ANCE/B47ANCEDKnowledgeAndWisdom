-- Internal implementation gates: no sandbox bypass or client-authority fallback.
-- Native player ModData is replaceable; GlobalModData is request-readable.
local Guard={MULTIPLAYER_BLOCKED="MULTIPLAYER_STORAGE_UNAVAILABLE"}
function Guard.realm()
    if type(isServer)~="function"or type(isClient)~="function"then return "unknown"end
    local serverOK,server=pcall(isServer);local clientOK,client=pcall(isClient)
    if not serverOK or not clientOK or type(server)~="boolean"or type(client)~="boolean"then return "unknown"end
    if server then return "server"end
    return client and "client"or "sp"
end
function Guard.isServer()return Guard.realm()=="server"end
function Guard.characterRead()
    local realm=Guard.realm()
    if realm=="server"then return false,Guard.MULTIPLAYER_BLOCKED end
    if realm=="unknown"then return false,"REALM_UNAVAILABLE"end
    return true
end
function Guard.write()
    local realm=Guard.realm()
    if realm=="server"then return false,Guard.MULTIPLAYER_BLOCKED end
    if realm=="client"then return false,"non-authority"end
    if realm=="unknown"then return false,"REALM_UNAVAILABLE"end
    return true
end
return Guard
