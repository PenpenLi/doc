--
-- Author: Your Name
-- Date: 2014-11-17 16:46:12
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogAlertDialyTask = class("QUIDialogAlertDialyTask", QUIDialog)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")

function QUIDialogAlertDialyTask:ctor(options)
 	local ccbFile = "ccb/Dialog_DailyMissionComplete.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogAlertDialyTask._onTriggerConfirm)},
    }
    QUIDialogAlertDialyTask.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = true

    self.taskId = options.index

    self._taskInfo = remote.task:getDailyTaskById(self.taskId)
    if self._taskInfo == nil then
    	self._taskInfo = remote.achieve:getAchieveById(self.taskId)
    end
    self._ccbOwner.tf_title:setString("完成："..self._taskInfo.config.name)

    self._ccbOwner.tf_value1:setString("")
    self._ccbOwner.tf_value2:setString("")

    self._index = 1
    local typeName1 = remote.items:getItemType(self._taskInfo.config.type_1)
    local typeName2 = remote.items:getItemType(self._taskInfo.config.type_2)
	self:setIconInfo(typeName1, self._taskInfo.config.num_1, self._taskInfo.config.id_1)
	self:setIconInfo(typeName2, self._taskInfo.config.num_2, self._taskInfo.config.id_2)
	self:setIconInfo(ITEM_TYPE.ACHIEVE_POINT, self._taskInfo.config.count, self._taskInfo.config.id_3)

	if self._index == 2 then
		self._ccbOwner.item1:setPositionX(-44)
		self._ccbOwner.tf_value1:setPositionX(12)
	end
end

function QUIDialogAlertDialyTask:setIconInfo(itemType, value, id)
	if self._index > 2 then return end
	local respath = nil
	if itemType ~= nil and value ~= nil then
		if itemType == ITEM_TYPE.ENERGY then
			respath = ICON_URL.ENERGY
		elseif itemType == ITEM_TYPE.MONEY then
			respath = ICON_URL.MONEY
		elseif itemType == ITEM_TYPE.TOKEN_MONEY then
			respath = ICON_URL.TOKEN_MONEY
		elseif itemType == ITEM_TYPE.TEAM_EXP then
			respath = ICON_URL.TEAM_EXP
		elseif itemType == ITEM_TYPE.ACHIEVE_POINT then
			respath = ICON_URL.ACHIEVE_POINT
		elseif itemType == ITEM_TYPE.ITEM then
			local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(id)
			respath = itemInfo.icon
		end
	else
		return 
	end

	if respath ~= nil then
		local icon = ""
		if itemType == ITEM_TYPE.ITEM then
			icon = QUIWidgetItemsBox.new()
			icon:setGoodsInfo(id, ITEM_TYPE.ITEM, 0)
		else
			icon = CCSprite:create()
			icon:setTexture(CCTextureCache:sharedTextureCache():addImage(respath))
		end
		if itemType == ITEM_TYPE.TEAM_EXP then
			icon:setScale(0.5)
		end
		self._ccbOwner["item"..self._index]:addChild(icon)
	end

	if value ~= nil then
		self._ccbOwner["tf_value"..self._index]:setString("x "..value)
	end
	self._index = self._index + 1
end

function QUIDialogAlertDialyTask:_onTriggerConfirm()
	self:_onTriggerClose()
	app.sound:playSound("battle_rare_treasure")
	self._isConfirm = true
end

function QUIDialogAlertDialyTask:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogAlertDialyTask:_onTriggerClose()
	self:playEffectOut()
end

function QUIDialogAlertDialyTask:viewAnimationOutHandler()
	app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	if self._isConfirm == true then
		if self._taskInfo.config.module == "成就" then
			app:getClient():achieveComplete(self.taskId)
		elseif self._taskInfo.config.module == "每日任务" then
			app:getClient():dailyTaskComplete(self.taskId, function ()
				remote.user:checkTeamUp()
			end)
		end
	end
end
return QUIDialogAlertDialyTask