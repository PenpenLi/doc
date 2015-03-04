
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetEquipmentBox = class("QUIWidgetEquipmentBox", QUIWidget)

QUIWidgetEquipmentBox.EVENT_EQUIPMENT_BOX_CLICK = "EVENT_EQUIPMENT_BOX_CLICK"

function QUIWidgetEquipmentBox:ctor(options)
	local ccbFile = "ccb/Widget_EquipmentBox.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerTouch", callback = handler(self, QUIWidgetEquipmentBox._onTriggerTouch)},
		}
	QUIWidgetEquipmentBox.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self:resetAll()
end

function QUIWidgetEquipmentBox:getName()
	return "QUIWidgetEquipmentBox"
end

--设置装备类型
function QUIWidgetEquipmentBox:setType(type)
	self._type = type
end

function QUIWidgetEquipmentBox:setSize(size)
	local selfSize = self._ccbOwner.node_kuang:getContentSize()
	self._ccbView:setScaleX(size.width/selfSize.width)
	self._ccbView:setScaleY(size.height/selfSize.height)
end

--获取装备类型
function QUIWidgetEquipmentBox:getType()
	return self._type
end

--获取装备类型
function QUIWidgetEquipmentBox:getItemId()
	if self._itemInfo ~= nil then
		return self._itemInfo.id
	end
	return nil
end

function QUIWidgetEquipmentBox:setEquipmentInfo(itemInfo, isWear)
	if itemInfo ~= nil then
		self._itemInfo = itemInfo
		local icon = display.newSprite(self._itemInfo.icon)
		if isWear == false then
			makeNodeFromNormalToGray(icon)
			icon:setOpacity(0.4*255)
		end
		self._ccbOwner.node_icon:addChild(icon)
		local iconSize = icon:getContentSize()
		local selfSize = self._ccbOwner.node_kuang:getContentSize()
		icon:setScaleX(selfSize.width*self._ccbOwner.node_kuang:getScaleX()/iconSize.width)
		icon:setScaleY(selfSize.height*self._ccbOwner.node_kuang:getScaleY()/iconSize.height)
	end
end

function QUIWidgetEquipmentBox:setColor(name)
	self:_hideAllColor()
	if self._ccbOwner["node_"..name] then
		self._ccbOwner["node_"..name]:setVisible(true)
	end
end

function QUIWidgetEquipmentBox:showState(isGreen, isComposite)
	if isGreen == true then
		self._ccbOwner.sprite_greenplus:setVisible(true)
		if isComposite == true then
			self._ccbOwner.tf_composite_green:setVisible(true)
		else
			self._ccbOwner.tf_wear_green:setVisible(true)
	 	end 
	else
		self._ccbOwner.sprite_yellowplus:setVisible(true)
		if isComposite == true then
			self._ccbOwner.tf_composite_yellow:setVisible(true)
		else
			self._ccbOwner.tf_wear_yellow:setVisible(true)
	 	end
	end
end

function QUIWidgetEquipmentBox:showDrop(isCanDrop)
	if isCanDrop == true then
		self._ccbOwner.sprite_buleplus:setVisible(true)
		self._ccbOwner.tf_drop_yellow:setVisible(true)
	end
end

--没有装备
function QUIWidgetEquipmentBox:showNoEquip(b)
	self._ccbOwner.node_no:setVisible(b)
end

--全部置空
function QUIWidgetEquipmentBox:resetAll()
	self._itemInfo = nil
	self:_hideAllColor() 
	self._ccbOwner.sprite_yellowplus:setVisible(false)
	self._ccbOwner.sprite_greenplus:setVisible(false)
	self._ccbOwner.sprite_buleplus:setVisible(false)
	self._ccbOwner.tf_composite_green:setVisible(false)
	self._ccbOwner.tf_composite_yellow:setVisible(false)
	self._ccbOwner.tf_wear_green:setVisible(false)
	self._ccbOwner.tf_wear_yellow:setVisible(false)
	self._ccbOwner.tf_drop_yellow:setVisible(false)
	self._ccbOwner.node_no:setVisible(false)
	self._ccbOwner.node_icon:removeAllChildren()
end

function QUIWidgetEquipmentBox:_hideAllColor()
	local names = {"white", "green", "purple", "orange", "normal", "blue"}
	for i = 1, 6, 1 do
		self._ccbOwner["node_"..names[i]]:setVisible(false)
	end
end

function QUIWidgetEquipmentBox:_onTriggerTouch()
	if self._itemInfo then
		self:dispatchEvent({name = QUIWidgetEquipmentBox.EVENT_EQUIPMENT_BOX_CLICK, info = self._itemInfo})
	end
end

return QUIWidgetEquipmentBox