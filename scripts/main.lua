
-- require("lib.debugger.mobdebug").start()

function __G__TRACKBACK__(errorMessage)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    local debugTarceBack = debug.traceback("", 2)
    print(debugTarceBack)
    local errorLog = errorMessage .. "\n" .. debugTarceBack .. "\n"
    if DEBUG > 0 then
    	CCMessageBox(errorLog, "LUA ERROR")
    end
    QUtility:addLuaError(errorLog)
    print("----------------------------------------")
end

local scriptPath = QUtility:getScriptPath()
print("scriptPath:" .. scriptPath)
print("package.path:" .. package.path)

require("app.MyApp").new():start()
-- pcall(require, "test.client.test")
