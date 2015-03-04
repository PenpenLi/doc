--
-- Author: Qinyuanji
-- Date: 2014-11-19 
-- 
local QUIDialog = import(".QUIDialog")
local QUIDialogChangeName = class("QUIDialogChangeName", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIDialogChangeName.NO_INPUT_ERROR = "名字不能为空"
QUIDialogChangeName.DEFAULT_PROMPT = "请输入昵称"

function QUIDialogChangeName:ctor(options)
	local ccbFile = "ccb/Dialog_MyInformation_ChangeName&Duihuan.ccbi";
	local callBacks = {
		{ccbCallbackName = "onTriggerCancel", callback = handler(self, QUIDialogChangeName._onTriggerCancel)},
		{ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogChangeName._onTriggerConfirm)},
		{ccbCallbackName = "onTriggerRandomName", callback = handler(self, QUIDialogChangeName._onTriggerRandomName)},
	}
	QUIDialogChangeName.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true --是否动画显示

	-- update layout
	self._ccbOwner.tf_changeName:setVisible(true)
	self._ccbOwner.tf_exchangeNode:setVisible(false)

	-- add input box
    g_NickName = ui.newEditBox({image = "ui/none.png", listener = QUIDialogChangeName.onEdit, size = CCSize(230, 48)})
    g_NickName:setFont(global.font_default, 26)
    g_NickName:setMaxLength(7)
    self._ccbOwner.tf_nickName:addChild(g_NickName)

    self._oldName = options.nickName or ""
	g_NickName:setText(QUIDialogChangeName.DEFAULT_PROMPT)
	g_NickName:setFontColor(display.COLOR_GRAY)
	g_NickName:setVisible(false)
	self._nameChangedCallBack = options.nameChangedCallBack
	self._cancelCallBack = options.cancelCallBack

	-- This part is for Arena:
	-- If user has no name bound, force until he selects a name and no outbound click works
	self._arena = options.arena or false
end

function QUIDialogChangeName:viewDidAppear()
	QUIDialogChangeName.super.viewDidAppear(self)
	g_NickName:setVisible(true)
end 

function QUIDialogChangeName:viewWillDisappear()
	QUIDialogChangeName.super.viewWillDisappear(self)
	g_NickName:setVisible(false)
end 

function QUIDialogChangeName.onEdit(event, editbox)
    if event == "began" then
	    g_NickName:setText("")
	    g_NickName:setFontColor(display.COLOR_WHITE)

    elseif event == "changed" then

    elseif event == "ended" then
        -- 输入结束
    elseif event == "return" then
        -- 从输入框返回
    end
end

-- If name is not changed, just close the dialog
-- If name was not changed before(empty), no token consume prompt poped up
-- If name was changed before(not empty), pop up prompt
function QUIDialogChangeName:_onTriggerConfirm()
	app.sound:playSound("common_confirm")
	local newName = g_NickName:getText()

	if self:_invalidNames(newName) then
		app.tip:floatTip(QUIDialogChangeName.NO_INPUT_ERROR)
		return
	end

	if newName == self._oldName then
		self:_onTriggerCancel()
		return
	end

	g_NickName:setVisible(false)
	if self._oldName == self:_freeNameChanged() then
		app:getClient():changeNickName(newName, function (data)
				if self._nameChangedCallBack then
					self._nameChangedCallBack(newName)
				end
				self._oldName = newName
				self:_onTriggerClose()
			end)
		g_NickName:setVisible(true)
	else
		app:alert({content=string.format(self:_tokenConsumePrompt(), self:_tokenConsumeNumber()),
					title="系统提示",
					callBack=function ()
						g_NickName:setVisible(true)
					end,
					comfirmBack=function ()
						app:getClient():changeNickName(newName, function (data)
							if self._nameChangedCallBack then
								self._nameChangedCallBack(newName)
							end
							self._oldName = newName
							self:_onTriggerClose()
						end)
					end}, false)
	end
end

function QUIDialogChangeName:_freeNameChanged()
	return ""
end

function QUIDialogChangeName:_invalidNames(newName)
	return newName == "" or newName == QUIDialogChangeName.DEFAULT_PROMPT
end

function QUIDialogChangeName:_tokenConsumePrompt()
	return "改名需消耗%d符石，是否仍要改名"
end

function QUIDialogChangeName:_tokenConsumeNumber()
	return 100
end

function QUIDialogChangeName:_onTriggerRandomName()
	app.sound:playSound("common_item")
    g_NickName:setText("")
    g_NickName:setFontColor(display.COLOR_WHITE)

    local newName = self:_getRandomName()
    g_NickName:setText(newName)
end

function QUIDialogChangeName:_getRandomName()
	local namePlayers = QStaticDatabase:sharedDatabase():getNamePlayers()
	local firstPart = {}
	local secondPart = {}
	local thirdPart = {}
	for k, names in pairs(namePlayers) do
		table.insert(firstPart, names.part_1)
		table.insert(secondPart, names.part_2)
		table.insert(thirdPart, names.part_3)
	end

	local namePart1 = firstPart[math.random(#firstPart)]
	local namePart2 = secondPart[math.random(#secondPart)]
	local namePart3 = thirdPart[math.random(#thirdPart)]

	return namePart1 .. namePart2 .. namePart3
end

function QUIDialogChangeName:_backClickHandler()
	-- For Arena, no outbound click triggers dialog disappear
	if not self._arena then
    	self:_onTriggerClose()
    end
end

function QUIDialogChangeName:_onTriggerClose()
	self:playEffectOut()
end

function QUIDialogChangeName:_onTriggerCancel()
	-- Arena doesn't allow user to cancal naming
	if self._arena then
		if self._cancelCallBack ~= nil then
			self._cancelCallBack()
		end
	else
		app.sound:playSound("common_cancel")
		self:_onTriggerClose()
	end
end

function QUIDialogChangeName:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogChangeName
