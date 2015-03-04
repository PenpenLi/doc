--
-- Author: wkwang
-- Date: 2014-10-29 15:20:04
--
local QUIDialog = import("..QUIDialog")
local QUIDialogBackpackSell = class("QUIDialogBackpackSell", QUIDialog)

local QUIWidgetItemsBox =  import("..widgets.QUIWidgetItemsBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogBackpackSell:ctor(options)
	local ccbFile = "ccb/Dialog_PacksackSell.ccbi"
	local callBacks = {
		{ccbCallbackName = "onPlus", 				callback = handler(self, QUIDialogBackpackSell._onPlus)},
		{ccbCallbackName = "onSub", 				callback = handler(self, QUIDialogBackpackSell._onSub)},
		{ccbCallbackName = "onMax", 				callback = handler(self, QUIDialogBackpackSell._onMax)},
		{ccbCallbackName = "onTriggerOK", 				callback = handler(self, QUIDialogBackpackSell._onTriggerOK)},
		{ccbCallbackName = "onTriggerClose", 				callback = handler(self, QUIDialogBackpackSell._onTriggerClose)},
	}
	QUIDialogBackpackSell.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true

	self._itemId = options.itemId
	self._itemNum = remote.items:getItemsNumByID(self._itemId)
	self._itemConfig = QStaticDatabase:sharedDatabase():getItemByID(self._itemId)

	self._sellNum = 1
	self._maxNum = self._itemNum
	self._minNum = 1

	if self._itemIcon == nil then
		self._itemIcon = QUIWidgetItemsBox.new()
		self._ccbOwner.node_icon:removeAllChildren()
		self._ccbOwner.node_icon:addChild(self._itemIcon)
	end
	self._itemIcon:resetAll()
	self._itemIcon:setGoodsInfo(self._itemId, ITEM_TYPE.ITEM, 0)
	self._ccbOwner.tf_name:setString(self._itemConfig.name)
	self._ccbOwner.tf_num:setString(self._itemNum)
	self._ccbOwner.tf_sell_money:setString(self._itemConfig.selling_price)
	self:countMoney()
end

function QUIDialogBackpackSell:countMoney()
	self._ccbOwner.tf_item_num:setString(self._sellNum.."/"..self._maxNum)
	self._ccbOwner.tf_get_money:setString(self._sellNum * self._itemConfig.selling_price)
end

function QUIDialogBackpackSell:_onPlus()
	app.sound:playSound("common_increase")
	if self._sellNum < self._maxNum then
		self._sellNum = self._sellNum + 1
		self:countMoney()
	end
end

function QUIDialogBackpackSell:_onSub()
	app.sound:playSound("common_increase")
	if self._sellNum > self._minNum then
		self._sellNum = self._sellNum - 1
		self:countMoney()
	end
end

function QUIDialogBackpackSell:_onMax()
	app.sound:playSound("common_increase")
	if self._sellNum ~= self._maxNum then
		self._sellNum = self._maxNum
		self:countMoney()
	end
end

function QUIDialogBackpackSell:_onTriggerOK()
	app.sound:playSound("common_confirm")
  	local sellItem = {{type = self._itemId, count = self._sellNum}}
	app:getClient():sellItem(sellItem,function (data)
			self:_onTriggerClose()
		end)
end

function QUIDialogBackpackSell:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogBackpackSell:_onTriggerClose()
	app.sound:playSound("common_close")
    self:playEffectOut()
end

function QUIDialogBackpackSell:viewAnimationOutHandler()
    self:removeSelfFromParent()
end

function QUIDialogBackpackSell:removeSelfFromParent()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogBackpackSell