if not CURRENT_MODE then
	return
end

-- package.cpath = package.cpath..";D:/wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode/bin/?.dll;"
package.cpath = package.cpath..";../wxdebug/?.dll;"
package.path = package.path..";./scripts/wxdebug/?.lua;"

require("wxdebug.launch")