--
-- Author: wkwang
-- Date: 2015-03-04 17:08:35
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroEquipmentEvolution = class("QUIWidgetHeroEquipmentEvolution", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetHeroEquipmentEvolution:ctor(options)
	local ccbFile = "ccb/Widget_HeroEquipment_Evolution.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerEvolution", callback = handler(self, QUIWidgetHeroEquipmentEvolution._onTriggerEvolution)},
		}
	QUIWidgetHeroEquipmentEvolution.super.ctor(self,ccbFile,callBacks,options)

end

function QUIWidgetHeroEquipmentEvolution:setInfo(actorId, itemId)
	self._items = {}
	self._itemId = itemId
	self._actorId = actorId
	self:showInfoByItemId(self._itemId)
end

function QUIWidgetHeroEquipmentEvolution:showInfoByItemId(selectItemId)
	self._selectItemId = selectItemId
	local isFind = false
	for index,itemId in pairs(self._items) do
		if isFind == true then
			self._items[index] = nil
		elseif itemId == self._selectItemId then
			isFind = true
		end
	end
	if isFind == false then
		self._items[#self._items + 1] = self._selectItemId
	end
	self:showNode()
	self:showSelectInfo()
end

function QUIWidgetHeroEquipmentEvolution:showNode()
	self._ccbOwner.node_icon:removeAllChildren()
	local totalNum = #self._items
	local posX = 0
	local gap = 10
	local offsetX = self._ccbOwner.node_icon:getPositionX()
    CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ui/HeroSystem.plist")
    local spriteFrameName = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("Equipment_jinhua_arraw.png")
	for index,itemId in pairs(self._items) do
		local itemBox = QUIWidgetItemsBox.new()
		itemBox:setGoodsInfo(itemId, ITEM_TYPE.ITEM, 0)
		itemBox:setPositionX(posX)
		self._ccbOwner.node_icon:addChild(itemBox)
		if index == totalNum then
			self._ccbOwner.sp_select:setPositionX(posX + offsetX)
		end
		posX = posX + itemBox:getContentSize().width/2 + gap
		if index < totalNum then
			local sp = CCSprite:createWithSpriteFrame(spriteFrameName)
			sp:setPositionX(posX)
			posX = posX + gap
			self._ccbOwner.node_icon:addChild(sp)
		end
	end
end

function QUIWidgetHeroEquipmentEvolution:showSelectInfo()
	local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(self._selectItemId)
	self._ccbOwner.tf_name:setString(itemConfig.name)
	self._ccbOwner.tf_num:setString(remote.items:getItemsNumByID(self._selectItemId))
end

function QUIWidgetHeroEquipmentEvolution:_onTriggerEvolution()
	
end

return QUIWidgetHeroEquipmentEvolution