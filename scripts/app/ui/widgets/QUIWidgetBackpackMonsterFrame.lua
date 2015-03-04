--
-- Author: Your Name
-- Date: 2014-10-29 20:10:39
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetBackpackMonsterFrame = class("QUIWidgetBackpackMonsterFrame", QUIWidget)

function QUIWidgetBackpackMonsterFrame:ctor(options)
	local ccbFile = "ccb/Widget_PacksackItemInfo2.ccbi"
	local callBacks = {}

	QUIWidgetBackpackMonsterFrame.super.ctor(self, ccbFile, callBacks, options)

	self.map = options.map
	self.dungeon = options.dungeon
	local name = ""
	if self.map.dungeon_isboss == true then
		if self.map.dungeon_type == DUNGEON_TYPE.NORMAL then
			name = "QUIWidgetInstanceNormalBoss"
		else
			name = "QUIWidgetInstanceEliteBoss"
		end
	else
		if self.map.dungeon_type == DUNGEON_TYPE.NORMAL then
			name = "QUIWidgetInstanceNormalMonster"
		else
			name = "QUIWidgetInstanceEliteMonster"
		end
	end

	local widgetClass = import(app.packageRoot .. ".ui.widgets." .. name)
	self._head = widgetClass.new()
	self._ccbOwner.node_icon:addChild(self._head)
	-- self._head = app.widgetCache:getWidgetForName(name, self._ccbOwner.node_icon)
	self._head:setInfo(self.map)
	self._head:hideStar()

	if self.map.dungeon_type == DUNGEON_TYPE.NORMAL then
		self._ccbOwner.node_normal:setVisible(true)
		self._ccbOwner.node_boss:setVisible(false)
		self._ccbOwner.tf_normal_number:setString(self.map.number)
	else
		self._ccbOwner.node_boss:setVisible(true)
		self._ccbOwner.node_normal:setVisible(false)
		self._ccbOwner.tf_boss_number:setString(self.map.number)
	end
end

function QUIWidgetBackpackMonsterFrame:onExit()
	-- app.widgetCache:setWidgetForName(self._head, self._head:getName())
end

return QUIWidgetBackpackMonsterFrame