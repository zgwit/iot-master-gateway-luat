module(..., package.seeall)

request "mapper"
request "modbusRtu"
request "mqttTask"

local pollers = {
    -- 从站，指令，偏移，长度
    {1, 3, 512, 2, mapper.TempratureSensor} -- 测试温度计
}

-- 启动Modbus读取
sys.taskInit(function()
    while true do
        -- 60秒轮询一次（没有计算耗时）
        sys.wait(60000)

        for i, p in ipairs(pollers) do
            local result, data = modbusRtu.send(p[1], p[2], p[3], p[4])
            if result then
                local values = mapper.parse(data, p[5])
                log.info("poller", p[1], p[2], p[3], p[4], json.encode(values))
            end
            -- sys.wait(2000)
        end

    end
end)

-- 可以使用定时器读取
-- sys.timerLoopStart
