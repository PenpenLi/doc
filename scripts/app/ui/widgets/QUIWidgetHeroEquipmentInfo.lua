--
-- Author: wkang
-- Date: 2015-03-03 14:44:55
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroEquipmentInfo = class("QUIWidgetHeroEquipmentInfo", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetItemDropInfoCell = import("..widgets.QUIWidgetItemDropInfoCell")

function QUIWidgetHeroEquipmentInfo:ctor(options)
	local ccbFile = "ccb/Widget_HeroEquipment_info_client.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerWear", callback = handler(self, QUIWidgetHeroEquipmentInfo._onTriggerWear)},
		}
	QUIWidgetHeroEquipmentInfo.super.ctor(self,ccbFile,callBacks,options)

	self._dropWidth = self._ccbOwner.sheet_layout:getContentSize().width
	self._dropHeight = self._ccbOwner.sheet_layout:getContentSize().height
	self._dropContent = CCNode:create()

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._dropWidth,self._dropHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
	layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
	ccclippingNode:setStencil(layerColor)
	ccclippingNode:addChild(self._dropContent)

	self._ccbOwner.sheet:addChild(ccclippingNode)
	
	self._touchLayer = QUIGestureRecognizer.new()
	self._totalHeight = 0
end

function QUIWidgetHeroEquipmentInfo:onEnter()
	QUIWidgetHeroEquipmentInfo.super.onEnter(self)
    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(remote.HERO_UPDATE_EVENT, handler(self, self.onEvent))
    
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:attachToNode(self._ccbOwner.sheet,self._dropWidth, self._dropHeight, 0, -self._dropHeight, handler(self, self.onTouchEvent))
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIWidgetHeroEquipmentInfo:onExit()
	QUIWidgetHeroEquipmentInfo.super.onExit(self)
	self._remoteProxy:removeAllEventListeners()
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
end

function QUIWidgetHeroEquipmentInfo:setInfo(actorId, itemId)
	self._itemId = itemId
	self._actorId = actorId
	self:refreshInfo()
	local equipment = remote.herosUtil:getWearByItem(self._actorId, self._itemId)
	if equipment ~= nil then
		self._ccbOwner.node_have:setVisible(true)
		self._ccbOwner.node_wear:setVisible(true)
		self:showItemProp()
		self._ccbOwner.tf_strong_level:setString("LV."..equipment.level)
		-- self._ccbOwner.sp_magic todo 附魔等级显示
	elseif remote.items:getItemsNumByID(self._itemId) > 0 then
		self:showItemProp()
		self._ccbOwner.node_have:setVisible(true)
		self._ccbOwner.node_no_wear:setVisible(true)
		local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(self._itemId)
		local heroInfo = remote.herosUtil:getHeroByID(self._actorId)
		if itemConfig.level > heroInfo.level then
			self._ccbOwner.tf_level:setString("需求英雄等级："..itemConfig.level)
			self._ccbOwner.tf_level:setVisible(true)
			self._ccbOwner.tf_bind:setVisible(false)
			self._ccbOwner.button_wear:setVisible(false)
		else
			self._ccbOwner.tf_level:setVisible(false)
			self._ccbOwner.tf_bind:setVisible(true)
			self._ccbOwner.button_wear:setVisible(true)
		end
	else
		self._ccbOwner.node_drop:setVisible(true)
		self:showDropInfo()
	end
end

function QUIWidgetHeroEquipmentInfo:showDropInfo()
	if self._dropItems == nil then
		self._dropItems = {}
	else
		for _,item in pairs(self._dropItems) do
			item:setVisible(false)
		end
	end
	self._totalHeight = 0
	self:moveTo(0,false)

	local dropInfo = remote.instance:getDropInfoByItemId(self._itemId, DUNGEON_TYPE.ALL)
	self._dropItem = {}
	table.sort(dropInfo,function (a,b)
	    if a.map.isLock == true and b.map.isLock == false then
	        return true
	    end
	    if a.map.isLock == false and b.map.isLock == true then
	        return false
	    end
	    if a.map.dungeon_type == DUNGEON_TYPE.NORMAL and b.map.dungeon_type ~= DUNGEON_TYPE.NORMAL then
	        return true
	    end
	    if a.map.dungeon_type ~= DUNGEON_TYPE.NORMAL and b.map.dungeon_type == DUNGEON_TYPE.NORMAL then
	        return false
	    end
	    return a.map.id < b.map.id
	end)
	for _,value in pairs(dropInfo) do
		local item = self:getDropItem()
		item:setVisible(true)
		item:showInfo(value.map, value.dungeon)
		item:setPositionY(-self._totalHeight)
	    self._totalHeight = self._totalHeight + item:getContentSize().height
	end
end

function QUIWidgetHeroEquipmentInfo:getDropItem()
	for _,item in pairs(self._dropItems) do
		if item:isVisible() == false then
			return item
		end
	end
	local item = QUIWidgetItemDropInfoCell.new()
	self._dropContent:addChild(item)
	self._dropItems[#self._dropItems+1] = item
	return item
end


function QUIWidgetHeroEquipmentInfo:refreshInfo()
	self._ccbOwner.node_have:setVisible(false)
	self._ccbOwner.node_no_wear:setVisible(false)
	self._ccbOwner.node_wear:setVisible(false)
	self._ccbOwner.node_drop:setVisible(false)

	if self._itemBox == nil then
		self._itemBox = QUIWidgetItemsBox.new()
		self._ccbOwner.node_icon:addChild(self._itemBox)
	end
	self._itemBox:setGoodsInfo(self._itemId, ITEM_TYPE.ITEM, 0)
	local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(self._itemId)
	self._ccbOwner.tf_item_name:setString(itemConfig.name)
end

--显示装备的属性
function QUIWidgetHeroEquipmentInfo:showItemProp()
	self._index = 1
	local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(self._itemId)
	for i=1,8,1 do
		self._ccbOwner["tf_name"..i]:setString("")
		self._ccbOwner["tf_value"..i]:setString("")
	end
	self:setTFValue("生        命", math.floor(itemInfo.hp or 0))
	self:setTFValue("攻        击", math.floor(itemInfo.attack or 0))
	self:setTFValue("命        中", math.floor(itemInfo.hit_rating or 0))
	self:setTFValue("闪        避", math.floor(itemInfo.dodge_rating or 0))
	self:setTFValue("暴        击", math.floor(itemInfo.critical_rating or 0))
	self:setTFValue("格        挡", math.floor(itemInfo.block_rating or 0))
	self:setTFValue("急        速", math.floor(itemInfo.haste_rating or 0))
	self:setTFValue("物        抗", math.floor(itemInfo.armor_physical or 0))
	self:setTFValue("魔        抗", math.floor(itemInfo.armor_magic or 0))
end

function QUIWidgetHeroEquipmentInfo:setTFValue(name, value)
	if self._index > 8 then return end
	if value ~= nil then
		if type(value) ~= "number" or value > 0 then
			self._ccbOwner["tf_name"..self._index]:setString(name)
			self._ccbOwner["tf_value"..self._index]:setString("＋"..value)
			self._index = self._index + 1
		end
	end
end

function QUIWidgetHeroEquipmentInfo:onTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
		self:moveTo(event.distance.y, true)
  	elseif event.name == "began" then
  		self:_removeAction()
  		self._startY = event.y
  		self._pageY = self._dropContent:getPositionY()
    elseif event.name == "moved" then
    	local offsetY = self._pageY + event.y - self._startY
        if math.abs(event.y - self._startY) > 10 then
            self._isMove = true
        end
		self:moveTo(offsetY, false)
	elseif event.name == "ended" then
    	scheduler.performWithDelayGlobal(function ()
    		self._isMove = false
    		end,0)
    end
end

function QUIWidgetHeroEquipmentInfo:_removeAction()
	if self._actionHandler ~= nil then
		self._dropContent:stopAction(self._actionHandler)		
		self._actionHandler = nil
	end
end

function QUIWidgetHeroEquipmentInfo:moveTo(posY, isAnimation)
	if isAnimation == false then
		self._dropContent:setPositionY(posY)
		return 
	end
	local contentY = self._dropContent:getPositionY()
	local targetY = 0
	if self._totalHeight <= self._dropHeight then
		targetY = 0
	elseif contentY + posY > self._totalHeight - self._dropHeight then
		targetY = self._totalHeight - self._dropHeight
	elseif contentY + posY < 0 then
		targetY = 0
	else
		targetY = contentY + posY
	end
	self:_contentRunAction(0, targetY)
end

function QUIWidgetHeroEquipmentInfo:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    											self:_removeAction()
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._dropContent:runAction(ccsequence)
end

function QUIWidgetHeroEquipmentInfo:onEvent(event)
	if event ~= nil then
		if event.name == remote.HERO_UPDATE_EVENT then
			self:setInfo(self._actorId, self._itemId)
		end
	end
end

-- 穿装备
function QUIWidgetHeroEquipmentInfo:_onTriggerWear()
	app:getClient():useItemForHero(self._itemId, self._actorId)

end

return QUIWidgetHeroEquipmentInfo