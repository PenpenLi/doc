--
-- Author: Your Name
-- Date: 2014-06-11 17:55:02
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetHeroEquipmentSmallBox = class("QUIWidgetHeroEquipmentSmallBox", QUIWidget)

function QUIWidgetHeroEquipmentSmallBox:ctor(options)
	local ccbFile = "ccb/Widget_EquipmentGrid.ccbi"
	local callBacks = {}
	QUIWidgetHeroEquipmentSmallBox.super.ctor(self, ccbFile, callBacks, options)

	self:resetAll()
	-- self:getView():setScale(0.3)
end

--设置装备类型
function QUIWidgetHeroEquipmentSmallBox:setType(type)
	self._type = type
end

--获取装备类型
function QUIWidgetHeroEquipmentSmallBox:getType()
	return self._type
end

function QUIWidgetHeroEquipmentSmallBox:setEquipmentInfo(itemInfo,isWear)
	if itemInfo ~= nil and isWear then
		self._itemInfo = itemInfo
		local icon = display.newSprite(self._itemInfo.icon)
		local size = icon:getContentSize()
		local scale = self._ccbOwner.node_icon_bg:getContentSize().width/size.width
		icon:setScale(scale)
		self._ccbOwner.node_icon:addChild(icon)
	end
end

--不要去掉
function QUIWidgetHeroEquipmentSmallBox:setColor(name)
end

function QUIWidgetHeroEquipmentSmallBox:showState(isGreen, isComposite)
	self._ccbOwner.node_icon:removeAllChildren()
	if isGreen == true then
		self._ccbOwner.sprite_greenplus:setVisible(true)
	else
		self._ccbOwner.sprite_yellowplus:setVisible(true)
	end
end

function QUIWidgetHeroEquipmentSmallBox:showDrop(isCanDrop)
	if isCanDrop == true then
		self._ccbOwner.sprite_buleplus:setVisible(true)
	end
end

--全部置空
function QUIWidgetHeroEquipmentSmallBox:resetAll()
	self._ccbOwner.sprite_yellowplus:setVisible(false)
	self._ccbOwner.sprite_greenplus:setVisible(false)
	self._ccbOwner.sprite_buleplus:setVisible(false)
	self._ccbOwner.node_icon:removeAllChildren()
end

return QUIWidgetHeroEquipmentSmallBox