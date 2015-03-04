--
-- Author: Your Name
-- Date: 2014-06-05 15:22:02
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetHeroEquipment = class("QUIWidgetHeroEquipment",QUIWidget)

local QRemote = import("...models.QRemote")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetEquipmentBox = import(".QUIWidgetEquipmentBox")

function QUIWidgetHeroEquipment:ctor(options)
	QUIWidgetHeroEquipment.super.ctor(self)
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
	self._equipBoxs = {}
	self._isAllWear = false
end


function QUIWidgetHeroEquipment:onEnter()
    -- self._remoteProxy = cc.EventProxy.new(remote)
    -- self._remoteProxy:addEventListener(QRemote.HERO_UPDATE_EVENT, handler(self, self._onEvent))
end

function QUIWidgetHeroEquipment:onExit()
	self:removeBoxEvent()
 --    self._remoteProxy:removeAllEventListeners()
end

--设置UI
function QUIWidgetHeroEquipment:setUI(equipBoxs)
	self:removeBoxEvent()
	self._equipBoxs = equipBoxs
	self:addBoxEvent()
end

--设置英雄
function QUIWidgetHeroEquipment:setHero(actorId)
	self._actorId = actorId
	self:refreshBox()
end

--是否穿戴所有装备
function QUIWidgetHeroEquipment:getIsAllWear()
	return self._isAllWear
end

--刷新装备显示
function QUIWidgetHeroEquipment:refreshBox()
	self:_removeAll()
	self._hero = remote.herosUtil:getHeroByID(self._actorId)
	self._heroItems = self._hero.equipments or {}
	local heroEquipments = remote.herosUtil:getHeroEquipmentForBreakthrough(self._actorId)
	local itemID = 0
	local itemInfo = {}
	local isHaveItem = false
	local isComposite = false
	local isWear = false
	self._isAllWear = true
	for _,box in pairs(self._equipBoxs) do 
		itemID = heroEquipments[box:getType()]
		isWear = remote.herosUtil:checkIsWear(self._actorId, itemID)
		itemInfo = QStaticDatabase:sharedDatabase():getItemByID(itemID)
		isHaveItem,isComposite = remote.items:getItemIsHaveNumByID(itemID,1)
		if isWear then
			box:setColor(EQUIPMENT_QUALITY[itemInfo.colour])
		else
			box:setColor("normal")
			self._isAllWear = false
		end
		box:setEquipmentInfo(itemInfo,isWear)
		if isWear == false then
			if isHaveItem == true then
				local isGreen = false
				if itemInfo.level <= self._hero.level then
					isGreen = true
				end
				box:showState(isGreen, isComposite)
				if box.showNoEquip ~= nil then
					box:showNoEquip(false)
				end
			else
				local isCanDrop = remote.items:getItemIsCanDrop(itemID)
				box:showDrop(isCanDrop)
				if box.showNoEquip ~= nil then
					box:showNoEquip(not isCanDrop)
				end
			end
		end
	end
end

function QUIWidgetHeroEquipment:addBoxEvent()
	for _,box in pairs(self._equipBoxs) do 
		if box.addEventListener then
			box:addEventListener(QUIWidgetEquipmentBox.EVENT_EQUIPMENT_BOX_CLICK, handler(self, self._onEvent))
		end
	end
end

function QUIWidgetHeroEquipment:removeBoxEvent()
	if self._equipBoxs then
		for _,box in pairs(self._equipBoxs) do 
			if box.removeAllEventListeners then
				box:removeAllEventListeners()
			end
		end
	end
end

function QUIWidgetHeroEquipment:_onEvent(event)
	if event.name == QUIWidgetEquipmentBox.EVENT_EQUIPMENT_BOX_CLICK then
		self:dispatchEvent(event)

	elseif event.name == QRemote.HERO_UPDATE_EVENT then
		if self._actorId ~= nil then
			self:setHero(self._actorId)
		end
	end
end

function QUIWidgetHeroEquipment:_removeAll()
	if self._equipBoxs == nil then return end

	for _,box in pairs(self._equipBoxs) do 
		box:resetAll()
	end
end

return QUIWidgetHeroEquipment