module(..., package.seeall)

require "http"

local function cbFnc(result,prompt,head,body)
    log.info("testHttp.cbFnc",result,prompt)
    if result and head then
        for k,v in pairs(head) do
            log.info("testHttp.cbFnc",k..": "..v)
        end
    end
    if result and body then
        log.info("testHttp.cbFnc","body="..body)
    end

    -- todo 上传失败，缓存再上传
end

http.request("POST", -- method
"36.7.87.100:6500", -- url
nil, -- cert
{
    ['Content-Type'] = "application/json"
}, -- headers
{
    [1] = "begin\r\n",
    [2] = {
        file = "/lua/http.lua"
    },
    [3] = "end\r\n"
}, -- content
30000, -- timeout
cbFnc) -- cb




