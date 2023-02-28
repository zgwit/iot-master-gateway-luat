module(..., package.seeall)

require "utils"
require "common"

-- 保持系统处于唤醒状态，此处只是为了测试需要，所以此模块没有地方调用pm.sleep("testUart")休眠，不会进入低功耗休眠状态
-- 在开发“要求功耗低”的项目时，一定要想办法保证pm.wake("modbusrtu")后，在不需要串口时调用pm.sleep("testUart")
pm.wake("modbusrtu")

-- TODO 配置化

-- 串口ID
local uart_id = 2
-- 波特率
local uart_baud = 9600
-- 读超时
local timeout = 2000

-- 配置并且打开串口
uart.setup(uart_id, uart_baud, 8, uart.PAR_NONE, uart.STOP_1, nil, 1)

-- 485使能
uart.set_rs485_oe(uart_id, pio.P0_23, 1, 1, 1) -- 银尔达724，其他底板自行修改

-- 注册串口的数据发送通知函数
uart.on(uart_id, "receive", function() sys.publish("UART_RECEIVE") end)
-- uart.on(uart_id, "sent", function() log.info("modbus", "uart sent") end)

function send(slave, code, addr, size)
    --   起始        地址    功能代码    数据    CRC校验    结束
    -- 3.5 字符     8 位      8 位    N x 8 位   16 位   3.5 字符
    -- local data = (string.format("%02x", slave) .. string.format("%02x", code) ..
    --                  string.format("%04x", addr) .. string.format("%04x", value)):fromHex()
    local data = pack.pack('bb>H>H', slave, code, addr, size)
    local crc = pack.pack('<h', crypto.crc16("MODBUS", data))
    uart.write(uart_id, data .. crc)

    -- 等待响应
    return sys.waitUntil("MODBUS_RECEIVE", timeout)
end

-- 启动串口数据接收任务
sys.taskInit(function()
    local cacheData = ""
    while true do
        -- 依次读取，直到结束
        local s = uart.read(uart_id, 1)
        if s == "" then
            -- 等待Modbus指令间隔，3.5个字符
            if not sys.waitUntil("UART_RECEIVE", 35000 / uart_baud) then
                if cacheData:len() > 0 then
                    local a, _ = string.toHex(cacheData)
                    log.info("modbus", "read", a)

                    -- 用户逻辑处理代码
                    sys.publish("MODBUS_RECEIVE", string.sub(cacheData, 4))

                    cacheData = ""
                end
            end
        else
            cacheData = cacheData .. s
        end
    end
end)

