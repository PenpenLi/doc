--
-- Author: wkwang
-- Date: 2014-07-24 17:33:46
--
local QErrorInfo = class("QErrorInfo")

local QUIViewController = import("..ui.QUIViewController")
local QStaticDatabase = import("..controllers.QStaticDatabase")

function QErrorInfo:handle(code)
	--体力不足
	if code == "ENERGY_NOT_ENOUGH" then
		app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBuyVirtual", options = {typeName="energy", enough=false}})
	elseif code ~= nil then
		local errorCode = QStaticDatabase:sharedDatabase():getErrorCode(code)
		local errorStr = ""
		local isAlert = true
		if errorCode == nil then
			errorStr = "服务错误："..code
		else
			errorStr = errorCode.desc
			isAlert = errorCode.type == 1
		end

		if isAlert == true then
			app:alert({content=errorStr,title="系统提示"}, false, true)
		else
			app.tip:floatTip(errorStr)
		end
	end
end

return QErrorInfo