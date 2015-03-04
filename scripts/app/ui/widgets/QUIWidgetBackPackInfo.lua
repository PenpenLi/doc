--
-- Author: wkwang
-- Date: 2014-10-29 11:06:39
--
local QUIWidget = import("..widgets/QUIWidget")
local QUIWidgetBackPackInfo = class("QUIWidgetBackPackInfo", QUIWidget)

local QUIWidgetItemsBox =  import("..widgets.QUIWidgetItemsBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("...controllers.QUIViewController")

function QUIWidgetBackPackInfo:ctor(options)
	local ccbFile = "ccb/Widget_Packsack.ccbi"
	local callbacks = {
       {ccbCallbackName = "onTriggerSell", callback = handler(self, QUIWidgetBackPackInfo._onTriggerSell)},
       {ccbCallbackName = "onTriggerDetail", callback = handler(self, QUIWidgetBackPackInfo._onTriggerDetail)},
}
	QUIWidgetBackPackInfo.super.ctor(self, ccbFile, callbacks, options)

	self:resetAll()
end

function QUIWidgetBackPackInfo:resetAll()
	if self._icon ~= nil then
	    self._icon:resetAll()
	end
	self._ccbOwner.tf_name:setString("")
	self._ccbOwner.tf_num:setString("")
	self._ccbOwner.tf_introduce:setString("")
	self._ccbOwner.tf_money:setString("")
end

function QUIWidgetBackPackInfo:refreshInfo()
	self:setItemId(self._itemId)
end

function QUIWidgetBackPackInfo:setItemId(itemId)
	self._itemId = itemId
	self._itemNum = remote.items:getItemsNumByID(itemId)

	if self._itemNum == 0 then
		self:setVisible(false)
		return
	end

	if self._icon == nil then
		self._ccbOwner.node_icon:removeAllChildren()
		self._icon = QUIWidgetItemsBox.new()
		self._ccbOwner.node_icon:addChild(self._icon)
	end
    self._icon:resetAll()
	local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(itemId)
	self._icon:setGoodsInfo(itemId, ITEM_TYPE.ITEM, 0)
	self._ccbOwner.tf_name:setString(itemConfig.name)
	self._ccbOwner.tf_num:setString(self._itemNum)

	self.detailStr = ""
	self._index = 1
	self:setTFValue("生        命", math.floor(itemConfig.hp or 0))
	self:setTFValue("攻        击", math.floor(itemConfig.attack or 0))
	self:setTFValue("命        中", math.floor(itemConfig.hit_rating or 0))
	self:setTFValue("闪        避", math.floor(itemConfig.dodge_rating or 0))
	self:setTFValue("暴        击", math.floor(itemConfig.critical_rating or 0))
	self:setTFValue("格        挡", math.floor(itemConfig.block_rating or 0))
	self:setTFValue("急        速", math.floor(itemConfig.haste_rating or 0))
	self:setTFValue("物        抗", math.floor(itemConfig.armor_physical or 0))
	self:setTFValue("魔        抗", math.floor(itemConfig.armor_magic or 0))
	
	if self.detailStr == "" then
		self._ccbOwner.tf_introduce:setString(itemConfig.description or "")
	else
		self._ccbOwner.tf_introduce:setString(self.detailStr)
	end
	self._ccbOwner.tf_money:setString(itemConfig.selling_price)

	self:effectIn(self._icon.icon)
	self:effectIn(self._ccbOwner.tf_name)
	self:effectIn(self._ccbOwner.tf_num)
	self:effectIn(self._ccbOwner.tf_introduce)
	self:effectIn(self._ccbOwner.tf_money)
	
end

function QUIWidgetBackPackInfo:setTFValue(name, value)
	if self._index > 4 then return end
	if value ~= nil then
		if type(value) ~= "number" or value > 0 then
			self.detailStr = self.detailStr .. name.."          ＋"..value.."\n"
			-- self._ccbOwner["tf_name"..self._index]:setString(name)
			-- self._ccbOwner["tf_value"..self._index]:setString("＋"..value)
			self._index = self._index + 1
		end
	end
end

function QUIWidgetBackPackInfo:effectIn(node)
	node:setOpacity(0)
	node:runAction(CCFadeIn:create(0.3))
end

function QUIWidgetBackPackInfo:_onTriggerDetail()
	app.sound:playSound("common_small")
	app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBackpackDetail", options = {itemId=self._itemId}})
end

function QUIWidgetBackPackInfo:_onTriggerSell()
	app.sound:playSound("common_small")
	if self._itemNum > 0 then
		app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBackpackSell", options = {itemId=self._itemId}})
	end
end

return QUIWidgetBackPackInfo