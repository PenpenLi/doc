--
-- Author: Your Name
-- Date: 2014-05-08 10:37:22
--

local QUIWidget = import(".QUIWidget")
local QUIWidgetInstance = class("QUIWidgetInstance", QUIWidget)
local QUIWidgetInstanceHead = import("..widgets.QUIWidgetInstanceHead")


function QUIWidgetInstance:ctor(options)
	local ccbFile = options.data[1].file
	local callBacks = {
    }
	QUIWidgetInstance.super.ctor(self, ccbFile, callBacks, options)
	cc.GameObject.extend(self)
	self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self._data = options.data

	self._heads = {}
	self:showMapInfo()
end

function QUIWidgetInstance:onExit()
	-- for _,value in pairs(self._heads) do
	-- 	value:removeEventListenersByEvent(QUIWidgetInstanceHead.EVENT_CITY_CLICK)
	-- 	app.widgetCache:setWidgetForName(value,value:getName())
	-- end
	self._heads = {}
end

function QUIWidgetInstance:addHeadEvent()
	for _,value in pairs(self._heads) do
		value:addEventListener(QUIWidgetInstanceHead.EVENT_CITY_CLICK, handler(self,self.dispatchEvent))
	end
end

function QUIWidgetInstance:showMapInfo()
	self._lastBoss = nil
	for _,value in pairs(self._data) do
		local name = ""
		if value.dungeon_isboss == true then
			if value.dungeon_type == DUNGEON_TYPE.NORMAL then
				name = "QUIWidgetInstanceNormalBoss"
			else
				name = "QUIWidgetInstanceEliteBoss"
			end
		else
			if value.dungeon_type == DUNGEON_TYPE.NORMAL then
				name = "QUIWidgetInstanceNormalMonster"
			else
				name = "QUIWidgetInstanceEliteMonster"
			end
		end
		local node = self._ccbOwner["node"..#self._heads+1]
		if node ~= nil then
			local widgetClass = import(app.packageRoot .. ".ui.widgets." .. name)
			local head = widgetClass.new()
			node:addChild(head)
			-- local head = app.widgetCache:getWidgetForName(name,node)
			head:setInfo(value)
			table.insert(self._heads, head)
			if value.dungeon_isboss == true and value.dungeon_type == DUNGEON_TYPE.ELITE then
				self._lastBoss = head
				self._lastBoss:isGoldBoss(false)
			end
		end
	end
	if self._lastBoss ~= nil then
		self._lastBoss:isGoldBoss(true)
	end

	self:addHeadEvent()
end

function QUIWidgetInstance:setLastDungeon(id)
	for index,value in pairs(self._heads) do
		if value:getDungeonId() == id then
			value:selected()
			return value
		end
	end
end

return QUIWidgetInstance