PROJECT = "JY_POWER"
VERSION = "1.0.0"

--加载日志功能模块，并且设置日志输出等级
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE

require "sys"

require "net"

net.startQueryAll(60000, 60000)


