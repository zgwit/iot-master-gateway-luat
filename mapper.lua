module(..., package.seeall)

require "define"


-- 数据类型

local types = {
    --    bit = '',
    float = 'f',
    double = 'd',
    -- local NUMBER = 'n'
    int8 = 'c',
    uint8 = 'b',
    int16 = 'h',
    uint16 = 'H',
    int32 = 'i',
    uint32 = 'I',
    int64 = 'l',
    uint64 = 'L'
}

-- 大小端
local BE = '>'
local LE = '<'

mappers = {
    TempratureSensor = {
        -- 偏移，大小端， 类型, 名称，倍率，校准
        {offset = 0, be = true, type = "uint16", name = "temp", rate = 0.1},
        {2, true, "uint16", "wed", 0.1, 0}
    }
}


function load()
    if not io.exists(define.mapper) then return end
    local data = io.readFile(define.mapper)
    if #data > 0 then mappers = json.decode(data) end
end

-- 加载配置
load()


function parse(data, map)
    local result = {}
    for i, m in ipairs(map) do
        local str = string.sub(cacheData, m.offset)
        -- 拼接格式
        local fmt = (m.be and '>' or '<') .. types[m.type]
        local _, v = pack.unpack(str, fmt)
        -- 倍率
        if m.rate ~= 0 and m.rate ~= 1 then
            v = v * m.rate
        end
        -- 校准
        if m.adjust ~= 0 then
            v = v + m.adjust
        end

        result[m.name] = v
    end
    return result
end
