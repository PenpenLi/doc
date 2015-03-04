--
-- Author: Your Name
-- Date: 2014-11-15 12:19:29
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetDailyTaskCell = class("QUIWidgetDailyTaskCell", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNavigationController = import("...controllers.QNavigationController")

QUIWidgetDailyTaskCell.EVENT_QUICK_LINK = "EVENT_QUICK_LINK"
QUIWidgetDailyTaskCell.EVENT_CLICK = "EVENT_CLICK"

function QUIWidgetDailyTaskCell:ctor(options)
	local ccbFile = "ccb/Widget_DailyMission_client.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerGo", 				callback = handler(self, QUIWidgetDailyTaskCell._onTriggerGo)},
		{ccbCallbackName = "onTriggerClick", 				callback = handler(self, QUIWidgetDailyTaskCell._onTriggerClick)},
	}
	QUIWidgetDailyTaskCell.super.ctor(self,ccbFile,callBacks,options)
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

end

function QUIWidgetDailyTaskCell:setInfo(info)
	self._taskInfo = info
	self:resetAll()

	if self._taskInfo.state == remote.task.TASK_DONE then
		self._ccbOwner.done_banner:setVisible(true)
		self._ccbOwner.sp_done:setVisible(true)
	else
		self._ccbOwner.normal_banner:setVisible(true)
	end
	self._ccbOwner.tf_name:setString(self._taskInfo.config.name)
	self._ccbOwner.tf_desc:setString(self._taskInfo.config.desc)

	self._positionX = -200.0
	self._gap = 10
	self:setIconInfo(self._taskInfo.config.type_1, self._taskInfo.config.num_1, self._taskInfo.config.id_1, 1)
	self:setIconInfo(self._taskInfo.config.type_2, self._taskInfo.config.num_2, self._taskInfo.config.id_2, 2)

	self:showTaskInfo()
	if self._taskInfo.config.icon ~= nil then
		self._ccbOwner.box_icon:setTexture(CCTextureCache:sharedTextureCache():addImage(self._taskInfo.config.icon))
		self._ccbOwner.box_icon:setVisible(true)
	end
end

function QUIWidgetDailyTaskCell:setIconInfo(itemType, value, id, index)
	if index > 2 then return end
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
		elseif itemType == ITEM_TYPE.ITEM then
			local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(id)
			respath = itemInfo.icon
		end
	end

	if respath ~= nil then
		local icon = nil
		if itemType == ITEM_TYPE.ITEM then
			icon = QUIWidgetItemsBox.new()
			icon:setGoodsInfo(id, ITEM_TYPE.ITEM, 0)
		else
			icon = CCSprite:create()
			icon:setTexture(CCTextureCache:sharedTextureCache():addImage(respath))
		end
		self._ccbOwner["sp_icon"..index]:setVisible(true)
		self._ccbOwner["sp_icon"..index]:addChild(icon)

		self._positionX = self._positionX + self._ccbOwner["sp_icon"..index]:getScaleX() * icon:getContentSize().width/2 
		self._ccbOwner["sp_icon"..index]:setPositionX(self._positionX)
		self._positionX = self._positionX + self._ccbOwner["sp_icon"..index]:getScaleX() * icon:getContentSize().width/2 + self._gap
	end

	if value ~= nil then
		self._ccbOwner["tf_value"..index]:setString("x "..value)
		self._ccbOwner["tf_value"..index]:setPositionX(self._positionX)
		self._positionX = self._positionX + self._ccbOwner["tf_value"..index]:getContentSize().width + self._gap
	end
end

function QUIWidgetDailyTaskCell:resetAll()
	self._ccbOwner.normal_banner:setVisible(false)
	self._ccbOwner.done_banner:setVisible(false)
	self._ccbOwner.tf_name:setString("")
	self._ccbOwner.tf_desc:setString("")
	self._ccbOwner.tf_time:setVisible(false)
	self._ccbOwner.sp_done:setVisible(false)
	self._ccbOwner.tf_value1:setString("")
	self._ccbOwner.tf_value2:setString("")
	self._ccbOwner.box_sp_end:setVisible(false)
	self._ccbOwner.box_icon:setVisible(false)
	self._ccbOwner.sp_icon1:setVisible(false)
	self._ccbOwner.sp_icon2:setVisible(false)
	self._ccbOwner.btn_go:setVisible(false)
	self._ccbOwner.tf_deal_num:setString("")
end

--[[
	根据不同的任务显示不同的东西
]]
function QUIWidgetDailyTaskCell:showTaskInfo()
	if self._taskInfo.state == remote.task.TASK_DONE or self._taskInfo.state == remote.task.TASK_COMPLETE then
		return 
	end
	if self._taskInfo.config.index == "100000" or self._taskInfo.config.index == "100001" or self._taskInfo.config.index == "100002" then
		self._ccbOwner.tf_time:setVisible(true)
	else
		self._ccbOwner.tf_deal_num:setString((self._taskInfo.stepNum or 0).."/"..self._taskInfo.config.num)
		self._ccbOwner.btn_go:setVisible(true)
	end
end

function QUIWidgetDailyTaskCell:_onTriggerGo()
	self:dispatchEvent({name = QUIWidgetDailyTaskCell.EVENT_QUICK_LINK, index = self._taskInfo.config.index})
end

function QUIWidgetDailyTaskCell:_onTriggerClick()
	if self._taskInfo.state == remote.task.TASK_DONE then
		-- app:getClient():dailyTaskComplete(self._taskInfo.config.index)
		self:dispatchEvent({name = QUIWidgetDailyTaskCell.EVENT_CLICK, index = self._taskInfo.config.index})
	end
end

return QUIWidgetDailyTaskCell