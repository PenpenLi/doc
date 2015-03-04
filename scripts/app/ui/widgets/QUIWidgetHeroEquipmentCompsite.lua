--
-- Author: wkwang
-- Date: 2014-10-10 19:59:30
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroEquipmentCompsite = class("QUIWidgetHeroEquipmentCompsite", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetItemsBox = import(".QUIWidgetItemsBox")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUIWidgetHeroEquipmentCompsite.COMPOSITE = "COMPOSITE"
QUIWidgetHeroEquipmentCompsite.EVENT_CLICK = "EVENT_CLICK"
QUIWidgetHeroEquipmentCompsite.SELECT_ITEM = "SELECT_ITEM"

function QUIWidgetHeroEquipmentCompsite:ctor(options)
	local ccbFile = "ccb/Widget_ItemCombining.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerComposite", 				callback = handler(self, QUIWidgetHeroEquipmentCompsite._onTriggerComposite)},
	}
	QUIWidgetHeroEquipmentCompsite.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
end

function QUIWidgetHeroEquipmentCompsite:onExit()
	QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetItemsBox.EVENT_CLICK, self._onTriggerSelect, self)
end

function QUIWidgetHeroEquipmentCompsite:setInfo(itemId)
	self._itemId = itemId
	local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(itemId)
	self._ccbOwner.tf_name:setString(itemInfo.name)
	self._ccbOwner.tf_need_num:setString("消耗 x "..itemInfo.smithereens_num)
	self._ccbOwner.tf_money:setString(itemInfo.composition_cost)

	if self._icon == nil then
		self._icon = QUIWidgetItemsBox.new()
		self._ccbOwner.node_icon:addChild(self._icon)
	end
	self._icon:setGoodsInfo(itemId, ITEM_TYPE.ITEM, 0)

	if self._icon1 == nil then
		self._icon1 = QUIWidgetItemsBox.new()
		QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetItemsBox.EVENT_CLICK, self._onTriggerSelect, self)
		self._ccbOwner.node_icon1:addChild(self._icon1)
	end
	self._icon1:setGoodsInfo(itemInfo.smithereens_id, ITEM_TYPE.ITEM, remote.items:getItemsNumByID(itemInfo.smithereens_id), true)

	if self._icon2 == nil then
		self._icon2 = QUIWidgetItemsBox.new()
		self._ccbOwner.node_icon2:addChild(self._icon2)
	end
	self._icon2:setGoodsInfo(itemId, ITEM_TYPE.ITEM, 0)

	self._isHave = remote.items:getItemIsHaveNumByID(itemInfo.smithereens_id, itemInfo.smithereens_num)
end

function QUIWidgetHeroEquipmentCompsite:_onTriggerComposite()
	if self._isHave == false then
		app.tip:floatTip("碎片不足")
	else
		local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(self._itemId)
		if itemInfo.composition_cost > remote.user.money then
			app.tip:floatTip("合成所需金钱不足")
		else
			self:dispatchEvent({name = QUIWidgetHeroEquipmentCompsite.COMPOSITE})
		end
	end
end

function QUIWidgetHeroEquipmentCompsite:_onTriggerOK()
	self:dispatchEvent({name = QUIWidgetHeroEquipmentCompsite.EVENT_CLICK})
end

function QUIWidgetHeroEquipmentCompsite:_onTriggerSelect(event)
	self:dispatchEvent({name = QUIWidgetHeroEquipmentCompsite.SELECT_ITEM, itemId = event.itemID})
end

return QUIWidgetHeroEquipmentCompsite