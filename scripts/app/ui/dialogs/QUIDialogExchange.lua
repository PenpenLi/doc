--
-- Author: Qinyuanji
-- Date: 2014-11-19 
-- This dialog is to show the cd key exchange dialog

local QUIDialog = import(".QUIDialog")
local QUIDialogExchange = class("QUIDialogExchange", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIDialogExchange.NO_INPUT_ERROR = "兑换码不能为空"
QUIDialogExchange.EXCHANGE_SUCCEED = "兑换成功"

function QUIDialogExchange:ctor(options)
	local ccbFile = "ccb/Dialog_MyInformation_ChangeName&Duihuan.ccbi";
	local callBacks = {
		{ccbCallbackName = "onTriggerCancel", callback = handler(self, QUIDialogExchange._onTriggerCancel)},
		{ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogExchange._onTriggerConfirm)},
	}
	QUIDialogExchange.super.ctor(self,ccbFile,callBacks,options)
	self.isAnimation = true

	-- update layout 
	self._ccbOwner.tf_changeName:setVisible(false)
	self._ccbOwner.tf_exchangeNode:setVisible(true)

	-- add input text box
    self._exchangeCode = ui.newEditBox({image = "ui/none.png", listener = function () end, size = CCSize(350, 48)})
    self._exchangeCode:setFont(global.font_default, 26)
    self._exchangeCode:setMaxLength(11)
    self._ccbOwner.tf_exchangeInput:addChild(self._exchangeCode)
end

function QUIDialogExchange:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogExchange:_onTriggerConfirm()
	app.sound:playSound("common_confirm")
	self._cdKey = self._exchangeCode:getText()
	if self._cdKey == nil or self._cdKey == "" then
		app.tip:floatTip(QUIDialogExchange.NO_INPUT_ERROR)
		return
	end

	app:getClient():sendCdKey(self._cdKey, function (data)
			app.tip:floatTip(QUIDialogExchange.EXCHANGE_SUCCEED)
			app:getClient():mailList()
			self:_onTriggerClose()
		end, function ( data )
			local error = QStaticDatabase:sharedDatabase():getErrorCode(data.error)
			if error == nil then
				app.tip:floatTip(data.error)
			else
				self:_showErrorDialog(error)
			end
		end)
end

-- Hide the input cd key and show it up when error dialog is dismissed
function QUIDialogExchange:_showErrorDialog(error)
	if error.type == 1 then
		self._exchangeCode:setText("")
		app:alert({content=error.desc, title="", comfirmBack = function ()
			self._exchangeCode:setText(self._cdKey)
		end, callBack = function ()
			self._exchangeCode:setText(self._cdKey)
		end}, false)	
	else
		app.tip:floatTip(error.desc)
	end
end

function QUIDialogExchange:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogExchange:_onTriggerCancel()
	app.sound:playSound("common_cancel")
	self:_onTriggerClose()
end

function QUIDialogExchange:_onTriggerClose()
	self._exchangeCode:setText("")
    self:playEffectOut()
end

return QUIDialogExchange
