local C=require'B47ANCEDKnowledgeAndWisdom/PrivateCodec'
local value={text='line\n\0\255',nested={yes=true,no=false,number=1.125},empty={}}
local encoded=C.encode(value);local result=assert(C.decode(encoded))
assert(result.text==value.text and result.nested.number==1.125 and result.nested.no==false)
assert(C.encode(result)==encoded and not encoded:find('\n'))
assert(C.checksum('Wikipedia')=='11e60398','standard Adler32 check vector')
for _,bad in ipairs({'return os.execute("bad")','T2:S1:61B1S1:61B0','S3:61','N3:nan','B2','T1:S1:61','T99999999:','S999999999999:','N1:1extra'})do
    assert(C.decode(bad)==nil,'must reject malformed data: '..bad)
end
local cycle={};cycle.self=cycle
assert(not pcall(C.encode,cycle))
assert(not pcall(C.encode,{bad=math.huge}))
assert(not pcall(C.encode,setmetatable({},{__index={}})))
assert(not pcall(C.encode,{[1]='array index not supported'}))
print('Private codec data-only roundtrip, bounds and corruption checks passed')
