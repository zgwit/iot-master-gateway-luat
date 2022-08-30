
module(...,package.seeall)


local function makeMap(tkey, tvalue)
    local result = {}
    for k, v in ipairs(tkey) do
        result[v] = tvalue[k] 
    end
end


local queue = {} -- {slave, addr, size, unpack="bbb", keys="a,b,c", prefix="", id=""}

--Modbus数据采集线程
sys.taskInit(
    function()
        while true do
            sys.wait(5000) --TODO 参数化

            -- 1、取指令，读

        end
    end
)




require"utils"
require"common"

--保持系统处于唤醒状态，此处只是为了测试需要，所以此模块没有地方调用pm.sleep("testUart")休眠，不会进入低功耗休眠状态
--在开发“要求功耗低”的项目时，一定要想办法保证pm.wake("modbusrtu")后，在不需要串口时调用pm.sleep("testUart")
pm.wake("modbusrtu")

local uart_id = 2
local uart_baud = 9600

--   起始        地址    功能代码    数据    CRC校验    结束
-- 3.5 字符     8 位      8 位    N x 8 位   16 位   3.5 字符

local function modbus_send(slave, code, addr, value)
    local data = (string.format("%02x",slave)..string.format("%02x",code)..string.format("%04x",addr)..string.format("%04x",value)):fromHex()
    local modbus_crc_data= pack.pack('<h', crypto.crc16("MODBUS",data))
    local data_tx = data..modbus_crc_data
    uart.write(uart_id,data_tx)
end

function modbusRead(com, slave, code, addr, size)
    local data = pack.pack('bb>H>H', slave, code, addr, size)
    data = data .. pack.pack('<H', crypto.crc16("MODBUS", data))
    uart.write(com, data)
end

local function modbus_read()
    local cacheData = ""
    while true do
        local s = uart.read(uart_id,1)
        if s == "" then
            if not sys.waitUntil("UART_RECEIVE",35000/uart_baud) then
                if cacheData:len()>0 then
                    local a,_ = string.toHex(cacheData)
                    log.info("modbus接收数据:",a)
                    --用户逻辑处理代码


                    --
                    cacheData = ""
                end
            end
        else
            cacheData = cacheData..s
        end
    end
end

--注册串口的数据发送通知函数
uart.on(uart_id,"receive",function() sys.publish("UART_RECEIVE") end)
uart.on(uart_id,"sent",function() 
	log.info("uart sent")
end)

--配置并且打开串口
--配置并且打开串口
uart.setup(uart_id,uart_baud,8,uart.PAR_NONE,uart.STOP_1, nil, 1)
--485使能
uart.set_rs485_oe(uart_id, pio.P0_23, 1, 1, 1) --银尔达724，其他底板自行修改

--启动串口数据接收任务
sys.taskInit(modbus_read)

sys.taskInit(function ()
    while true do
        sys.wait(5000)
        --modbus_send("0x01","0x01","0x0101","0x04")
		modbus_send(1,3,512,2) --测试温度计
    end
end)


