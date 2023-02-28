PROJECT = "IoT-Master-Gateway"
VERSION = "1.0.0"

--加载日志功能模块，并且设置日志输出等级
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE

require "sys"

require "net"

-- 查询信号强度和基站信息
-- net.startQueryAll(60000, 60000)

-- 关闭虚拟网卡
ril.request("AT+RNDISCALL=0,1")


pmd.ldoset(2,pmd.LDO_VLCD)


require "netLed"
--netLed.setup(true,pio.P0_1,pio.P0_4)


require "mqttTask"
request "modbus"


--启动系统框架
sys.init(0, 0)
sys.run()