--
-- Author: wkwang
-- Date: 2014-10-29 21:07:15
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetBackpackDetail = class("QUIWidgetBackpackDetail", QUIWidget)

local QUIWidgetBackpackHeroFrame = import("..widgets.QUIWidgetBackpackHeroFrame")
local QUIWidgetBackpackMonsterFrame = import("..widgets.QUIWidgetBackpackMonsterFrame")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetBackpackDetail:ctor(options)
	local ccbFile = "ccb/Widget_PacksackItemInfo_client.ccbi"
	local callBacks = {}

	QUIWidgetBackpackDetail.super.ctor(self, ccbFile, callBacks, options)

	self._itemId = options.itemId
	self._height = 0
	self._barHeight = -46
	self._gap = -10
	self._heroHeight = -70
	self._monsterHeight = -100
	local heros = {}
	local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(self._itemId)
	if itemConfig.type == ITEM_CATEGORY.EQUIPMENT then
		local haveHeros = remote.herosUtil:getHaveHeroKey()
		for _,value in pairs(haveHeros) do
			local wearEquipTbl = remote.herosUtil:checkHerosEquipmentByID(value)
			for _,itemInfo in pairs(wearEquipTbl) do
				if itemInfo.itemID == self._itemId then
					table.insert(heros, value)
				end
			end
		end
	end
	if #heros ~= 0 then
		self._ccbOwner.node_hero:setVisible(true)
		self._height = self._barHeight + self._gap + self._heroHeight/2
		for index,value in pairs(heros) do
			local heroFrame = QUIWidgetBackpackHeroFrame.new({actorId = value})
			heroFrame:setPositionY(self._height)
			if index % 2 == 0 then
				heroFrame:setPositionX(78)
				self._height = self._height + self._heroHeight
			else
				heroFrame:setPositionX(-189)
			end
			self:addChild(heroFrame)
		end
	else
		self._ccbOwner.node_hero:setVisible(false)
	end

	if self._height ~= 0 then
		self._height = self._height + self._heroHeight/2 + self._gap
	end
	self._ccbOwner.node_dungeon:setPositionY(self._height)
	self._height = self._height + self._barHeight + self._gap + self._heroHeight/2
	if itemConfig.approach ~= nil then
		self._ccbOwner.tf_drop_info:setString(itemConfig.approach)
	else
		self._ccbOwner.tf_drop_info:setString("")
		local dropInfo = remote.instance:getDropInfoByItemId(self._itemId, DUNGEON_TYPE.ALL)
	    self._pageHeight = 0
		for index,value in pairs(dropInfo) do
			local item = QUIWidgetBackpackMonsterFrame.new(value)
			item:setPositionY(self._height)
			if index % 2 == 0 then
				item:setPositionX(111)
				self._height = self._height + self._monsterHeight
			else
				item:setPositionX(-166)
			end
			self:addChild(item)
		end
	end
end

function QUIWidgetBackpackDetail:getTotalHeight()
	return self._height
end


return QUIWidgetBackpackDetail