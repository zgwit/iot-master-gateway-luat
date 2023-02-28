module(..., package.seeall)

require "misc"
require "mqtt"


-- MQTT Broker 参数配置
local clientId = misc.getImei() -- 默认使用IMEI号
local username = ""
local password = ""
local server = "lbsmqtt.airm2m.com"
local port = 1884


local ready = false

function isReady() return ready end

-- 数据发送的消息队列
local msgQueue = {}

function publish(topic, payload, cb)
    log.info("MQTT", "publish", topic)
    table.insert(msgQueue, {t = topic, p = payload, q = 0, c = cb})
    sys.publish("APP_SOCKET_SEND_DATA") -- 终止接收等待，处理发送
end

local function send(client)
    while #msgQueue > 0 do
        local msg = table.remove(msgQueue, 1)
        local result = client:publish(msg.t, msg.p, msg.q)
        if msg.c then msg.c(result) end
        if not result then return end
    end
    return true
end

local function receive(client)
    local result, data
    while true do
        result, data = client:receive(60000, "APP_SOCKET_SEND_DATA")
        -- 接收到数据
        if result then
            log.info("MQTT", "message", data.topic, data.payload)
            -- TODO：根据需求自行处理data.payload

        else
            break
        end
    end

    return result or data == "timeout" or data == "APP_SOCKET_SEND_DATA"
end


-- 启动MQTT客户端任务
sys.taskInit(function()
    local retry = 0
    while true do
        if not socket.isReady() then
            retry = 0
            -- 等待网络环境准备就绪，超时时间是5分钟
            sys.waitUntil("IP_READY_IND", 300000)
        end

        if socket.isReady() then

            local client = mqtt.client(clientId, 600, username, password)

            -- 阻塞执行MQTT CONNECT动作，直至成功
            -- 如果使用ssl连接，打开client:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})，根据自己的需求配置
            -- client:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})
            if client:connect(server, port, "tcp") then
                retry = 0
                ready = true

                -- 订阅主题
                -- client:subscribe({["/event0"]=0})

                -- 循环处理接收和发送的数据
                while true do
                    if not receive(client) then
                        log.error("MQTT", "receive error")
                        break
                    end
                    if not send(client) then
                        log.error("MQTT", "send error")
                        break
                    end
                end
                    
                ready = false
            else
                retry = retry + 1
            end

            -- 断开MQTT连接
            client:disconnect()
            if retry >= 5 then
                link.shut()
                retry = 0
            end
            sys.wait(5000)
        else
            -- 飞行模式20秒，重置网络
            net.switchFly(true)
            sys.wait(20000)
            net.switchFly(false)
        end
    end
end)
