module(..., package.seeall)

-- 数据类型
local FLOAT = 'f'
local DOUBLE = 'd'
-- local NUMBER = 'n'
local CHAR = 'c'
local BYTE = 'b'
local SHORT = 'h'
local WORD = 'H'
local INT = 'i'
local UINT = 'I'
local LONG = 'l'
local ULONG = 'L'

-- 大小端
local BE = '>'
local LE = '<'

TempratureSensor = {
    -- 偏移，大小端， 类型, 名称，倍率，校准
    {0, BE, WORD, "temp", 0.1},
    {2, BE, WORD, "wed", 0.1}, 
}

function parse(data, map)
    local result = {}
    for i, m in ipairs(map) do
        local str = string.sub(cacheData, m[1])
        local _, v = pack.unpack(str, m[2] .. m[3])
        if #m > 3 then v = v * m[4] end
        if #m > 4 then v = v + m[5] end
        result[m[4]] = v
    end
    return result
end
