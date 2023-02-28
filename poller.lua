module(..., package.seeall)

request "mapper"
request "modbus"
request "mqttTask"

pollers = {
    -- 从站，指令，偏移，长度
    {
        slave = 1,
        code = 3,
        address = 512,
        size = 2,
        mapper = "TempratureSensor"
    } -- 测试温度计
}

local filename = "pollers.json"

function load()
    if not io.exists(filename) then return end
    local data = io.readFile(filename)
    if #data > 0 then
        pollers = json.decode(data)
    end
end

-- 加载配置
load()

function store()
    local data = json.encode(pollers)
    io.writeFile(filename, data)
end

-- 启动Modbus读取
sys.taskInit(function()
    while true do
        -- 60秒轮询一次（没有计算耗时）
        sys.wait(60000)

        for i, p in ipairs(pollers) do
            local result, data = modbus.send(p.slave, p.code, p.address, p.size)
            if result then
                local map = mapper.mappers[m.mapper]
                local values = mapper.parse(data, map)
                local payload = json.encode(values)
                log.info("poller", p.slave, p.code, p.address, p.size, payload)

                if mqttTask.isReady() then
                    mqttTask.publish("/data", payload)
                else
                    -- 保存到缓存中，下次上线续传
                end
            end
            -- sys.wait(2000)
        end

    end
end)

-- 可以使用定时器读取
-- sys.timerLoopStart
