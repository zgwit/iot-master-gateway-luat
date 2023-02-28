module(..., package.seeall)


--按键消息处理函数
local function keyMsg(msg)
    --保存按键名
    --msg.key_matrix_row：行索引
    --msg.key_matrix_col：列索引
    --local keyName = tKeypad[msg.key_matrix_row..msg.key_matrix_col]  
    log.info("keyMsg", msg.key_matrix_row, msg.key_matrix_col, msg.pressed, keyName)  
end

rtos.on(rtos.MSG_KEYPAD ,keyMsg)

-- 键盘初始化，参考https://doc.openluat.com/wiki/6?wiki_page_id=57
rtos.init_module(rtos.MOD_KEYPAD, 0, 0x3c, 0x01)
--rtos.init_module(rtos.MOD_KEYPAD, 0, 0x3c, 0x0F)