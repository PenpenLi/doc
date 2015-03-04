-- extern color for ccc3
display.COLOR_YELLOW	= ccc3(255, 255, 0)
display.COLOR_MAGENTA	= ccc3(255, 0, 255)
display.COLOR_ORANGE  	= ccc3(255, 127, 0)
display.COLOR_GRAY		= ccc3(166, 166, 166)

display.COLOR_WHITE_C3 = display.COLOR_WHITE
display.COLOR_BLACK_C3 = display.COLOR_BLACK
display.COLOR_RED_C3   = display.COLOR_RED
display.COLOR_GREEN_C3 = display.COLOR_GREEN
display.COLOR_BLUE_C3  = display.COLOR_BLUE

display.COLOR_YELLOW_C3		= display.COLOR_YELLOW
display.COLOR_MAGENTA_C3	= display.COLOR_MAGENTA
display.COLOR_ORANGE_C3  	= display.COLOR_ORANGE
display.COLOR_GRAY_C3		= display.COLOR_GRAY

-- extern color for ccc4
display.COLOR_WHITE_C4 = ccc4(255, 255, 255, 255)
display.COLOR_BLACK_C4 = ccc4(0, 0, 0, 255)
display.COLOR_RED_C4   = ccc4(255, 0, 0, 255)
display.COLOR_GREEN_C4 = ccc4(0, 255, 0, 255)
display.COLOR_BLUE_C4  = ccc4(0, 0, 255, 255)

display.COLOR_YELLOW_C4		= ccc4(255, 255, 0, 255)
display.COLOR_MAGENTA_C4	= ccc4(255, 0, 255, 255)
display.COLOR_ORANGE_C4  	= ccc4(255, 127, 0, 255)
display.COLOR_GRAY_C4		= ccc4(166, 166, 166, 255)

-- extern color for ccc4f
display.COLOR_WHITE_C4F = ccc4f(1, 1, 1, 1)
display.COLOR_BLACK_C4F = ccc4f(0, 0, 0, 1)
display.COLOR_RED_C4F   = ccc4f(1, 0, 0, 1)
display.COLOR_GREEN_C4F = ccc4f(0, 1, 0, 1)
display.COLOR_BLUE_C4F  = ccc4f(0, 0, 1, 1)

display.COLOR_YELLOW_C4F	= ccc4f(1, 1, 0, 1)
display.COLOR_MAGENTA_C4F	= ccc4f(1, 0, 1, 1)
display.COLOR_ORANGE_C4F  	= ccc4f(1, 0.5, 0, 1)
display.COLOR_GRAY_C4F		= ccc4f(0.65, 0.65, 0.65, 1)

scheduler = require("framework.scheduler")

_import = import
function import(moduleName, currentModuleName)
	local theModuleNameParts = string.split(moduleName, ".")
    local theModuleName = theModuleNameParts[#theModuleNameParts]
    local theModule = q[theModuleName]
    if theModule == nil then
    	if not currentModuleName then
            local n,v = debug.getlocal(3, 1)
            currentModuleName = v
        end
    	theModule = _import(moduleName, currentModuleName)
    	q[theModuleName] = theModule
	end

    return theModule
end

_class = class
function class(classname, super)
	local cls = _class(classname, super)
    q[classname] = cls
    return cls
end

_printInfo = printInfo
function printInfo(fmt, ...)
    if DEBUG > 0 then
        printLog("INFO", fmt, ...)
    end
end

function printTable(t, prefix)
    if DEBUG > 0 and t ~= nil and type(t) == "table" then
        if prefix == nil then
            prefix = ""
        end
        print(prefix .. "{")
        local newPrefix = prefix .. "    "
        for k, v in pairs(t) do
            if type(v) == "table" then
                print(newPrefix .. tostring(k) .. ": ")
                local p = newPrefix
                printTable(v, p)
            else
                print(newPrefix .. tostring(k) .. ": " .. tostring(v) .. "") 
            end
        end
        print(prefix .. "}")
    end
end
