--
-- Author: Your Name
-- Date: 2014-11-24 16:39:45
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetAchievementItem = class("QUIWidgetAchievementItem", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIWidgetAchievementItem.EVENT_CLICK = "EVENT_CLICK"

function QUIWidgetAchievementItem:ctor(options)
	local ccbFile = "ccb/Widget_Achievement_client.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerClick", 				callback = handler(self, QUIWidgetAchievementItem._onTriggerClick)},
	}

	QUIWidgetAchievementItem.super.ctor(self, ccbFile, callBacks, options)
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    self._iconSize = self._ccbOwner.box_icon:getContentSize()
end


function QUIWidgetAchievementItem:setInfo(info)
	self._achieveInfo = info
	self:resetAll()

	if self._achieveInfo.state == remote.achieve.MISSION_DONE then
		self._ccbOwner.done_banner:setVisible(true)
		self._ccbOwner.sp_done:setVisible(true)
		self._ccbOwner.box_sp_end:setVisible(true)
	else
		self._ccbOwner.normal_banner:setVisible(true)
		if self._achieveInfo.state == remote.achieve.MISSION_COMPLETE then
			self._ccbOwner.sp_complete:setVisible(true)
			self._ccbOwner.box_sp_end:setVisible(true)
		end
	end
	self._ccbOwner.tf_name:setString(self._achieveInfo.config.name)
	self._ccbOwner.tf_desc:setString(self._achieveInfo.config.desc)

	self._positionX = -200.0
	self._gap = 10
	local typeName1 = remote.items:getItemType(self._achieveInfo.config.type_1)
	local typeName2 = remote.items:getItemType(self._achieveInfo.config.type_2)
	self:setIconInfo(typeName1, self._achieveInfo.config.num_1, self._achieveInfo.config.id_1, 1)
	self:setIconInfo(typeName2, self._achieveInfo.config.num_2, self._achieveInfo.config.id_2, 2)
	self:setIconInfo(ITEM_TYPE.ACHIEVE_POINT, self._achieveInfo.config.count, self._achieveInfo.config.id_3, 3)

	self:showAchievementInfo()
	local icon = ""
	local item1 = QStaticDatabase:sharedDatabase():getItemByID(self._achieveInfo.config.id_1)
	local item2 = QStaticDatabase:sharedDatabase():getItemByID(self._achieveInfo.config.id_2)
	if item1 ~= nil and item1.type == ITEM_CATEGORY.SOUL then
		icon = item1.icon
	elseif item2 ~= nil and item2.type == ITEM_CATEGORY.SOUL then
		icon = item2.icon
	elseif typeName1 == ITEM_TYPE.TOKEN_MONEY or typeName2 == ITEM_TYPE.TOKEN_MONEY then
		icon = ICON_URL.ITEM_TOKEN_MONEY
	elseif typeName1 == ITEM_TYPE.TEAM_EXP or typeName2 == ITEM_TYPE.TEAM_EXP then
		icon = ICON_URL.TEAM_EXP
	elseif item1 ~= nil then
		icon = item1.icon
	elseif item2 ~= nil then
		icon = item2.icon
	elseif typeName1 == ITEM_TYPE.MONEY or typeName2 == ITEM_TYPE.MONEY then
		icon = ICON_URL.ITEM_MONEY
	elseif typeName1 == ITEM_TYPE.ENERGY or typeName2 == ITEM_TYPE.ENERGY then
		icon = ICON_URL.ENERGY
	end

	if icon ~= "" then
		local texture = CCTextureCache:sharedTextureCache():addImage(icon)
		self._ccbOwner.box_icon:setTexture(texture)
		self._ccbOwner.box_icon:setVisible(true)
	    local size = texture:getContentSize()
	    local rect = CCRectMake(0, 0, size.width, size.height)
	    self._ccbOwner.box_icon:setTextureRect(rect)
	    self._ccbOwner.box_icon:setScale(self._iconSize.width/size.width)
	end
end

function QUIWidgetAchievementItem:setIconInfo(itemType, value, id, index)
	if index > 3 then return end
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
		self._ccbOwner["sp_icon"..index]:removeAllChildren()
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

function QUIWidgetAchievementItem:resetAll()
	self._ccbOwner.normal_banner:setVisible(false)
	self._ccbOwner.done_banner:setVisible(false)
	self._ccbOwner.sp_icon1:setVisible(false)
	self._ccbOwner.sp_icon2:setVisible(false)
	self._ccbOwner.sp_icon3:setVisible(false)
	self._ccbOwner.sp_done:setVisible(false)
	self._ccbOwner.sp_complete:setVisible(false)
	self._ccbOwner.box_sp_end:setVisible(false)
	self._ccbOwner.tf_name:setString("")
	self._ccbOwner.tf_desc:setString("")
	self._ccbOwner.tf_value1:setString("")
	self._ccbOwner.tf_value2:setString("")
	self._ccbOwner.tf_value3:setString("")
	self._ccbOwner.tf_deal_num:setString("")
end

--[[
	根据不同的任务显示不同的东西
]]
function QUIWidgetAchievementItem:showAchievementInfo()
	if self._achieveInfo.state == remote.achieve.MISSION_DONE or self._achieveInfo.state == remote.achieve.MISSION_COMPLETE then
		return 
	end
	if self._achieveInfo.config.tip ~= nil then
		self._ccbOwner.tf_deal_num:setString(self._achieveInfo.config.tip)
	else
		self._ccbOwner.tf_deal_num:setString(self._achieveInfo.stepNum.."/"..self._achieveInfo.config.num)
	end
end

function QUIWidgetAchievementItem:_onTriggerClick()
	self:dispatchEvent({name = QUIWidgetAchievementItem.EVENT_CLICK, index = self._achieveInfo.config.index})
end

return QUIWidgetAchievementItem