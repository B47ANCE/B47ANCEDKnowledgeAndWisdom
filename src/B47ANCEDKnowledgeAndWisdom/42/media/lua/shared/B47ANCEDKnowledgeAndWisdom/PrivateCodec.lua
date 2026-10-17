-- Bounded data-only format. Never evaluates saved Lua or accepts metatables.
local Codec={MAX_BYTES=1048576}
local function hex(value)return(value:gsub('.',function(c)return string.format('%02x',string.byte(c))end))end
local function unhex(value)
    if #value%2~=0 or value:find('[^0-9a-f]')then error('invalid hex')end
    return(value:gsub('..',function(c)return string.char(tonumber(c,16))end))
end
function Codec.checksum(value)
    local a,b=1,0
    for i=1,#value do a=(a+value:byte(i))%65521;b=(b+a)%65521 end
    return string.format('%08x',b*65536+a)
end
function Codec.encode(value)
    local active,nodes={},0
    local function visit(v,depth)
        nodes=nodes+1;if nodes>32768 or depth>12 then error('data limit')end
        local kind=type(v)
        if kind=='boolean'then return v and 'B1'or 'B0'end
        if kind=='number'then
            if v~=v or v==math.huge or v==-math.huge then error('nonfinite')end
            local text=string.format('%.17g',v);return'N'..#text..':'..text
        end
        if kind=='string'then
            if #v>65536 then error('string limit')end
            return'S'..#v..':'..hex(v)
        end
        if kind~='table'or getmetatable(v)~=nil or active[v]then error('unsupported data')end
        active[v]=true
        local keys={};for key in pairs(v)do if type(key)~='string'then error('string keys required')end;keys[#keys+1]=key end
        table.sort(keys);local parts={'T'..#keys..':'}
        for _,key in ipairs(keys)do parts[#parts+1]=visit(key,depth+1);parts[#parts+1]=visit(v[key],depth+1)end
        active[v]=nil;return table.concat(parts)
    end
    local encoded=visit(value,0);if #encoded>Codec.MAX_BYTES then error('record limit')end
    return encoded
end
function Codec.decode(text)
    if type(text)~='string'or #text>Codec.MAX_BYTES then return nil,'record limit'end
    local pos,nodes=1,0
    local function visit(depth)
        nodes=nodes+1;if nodes>32768 or depth>12 then error('data limit')end
        local kind=text:sub(pos,pos);pos=pos+1
        if kind=='B'then
            local flag=text:sub(pos,pos);pos=pos+1
            if flag~='0'and flag~='1'then error('invalid boolean')end;return flag=='1'
        end
        local first,last,digits=text:find('^(%d+):',pos)
        if first~=pos or #digits>7 then error('invalid length')end
        local length=tonumber(digits);pos=last+1
        if kind=='S'then
            if length>65536 or pos+length*2-1>#text then error('string limit')end
            local value=unhex(text:sub(pos,pos+length*2-1));pos=pos+length*2;return value
        elseif kind=='N'then
            if length>32 or pos+length-1>#text then error('number limit')end
            local raw=text:sub(pos,pos+length-1);pos=pos+length
            if not raw:match('^[%d%.eE%+%-]+$')then error('invalid number')end
            local value=tonumber(raw);if not value or value~=value or value==math.huge or value==-math.huge then error('nonfinite')end
            return value
        elseif kind=='T'then
            if length>16384 then error('table limit')end
            local value={}
            for _=1,length do
                local key=visit(depth+1);if type(key)~='string'or value[key]~=nil then error('duplicate/invalid key')end
                value[key]=visit(depth+1)
            end
            return value
        end
        error('invalid tag')
    end
    local ok,value=pcall(visit,0)
    if not ok or pos~=#text+1 then return nil,'invalid saved data'end
    return value
end
return Codec
