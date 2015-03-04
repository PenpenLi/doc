--
-- Author: wkwang
-- Date: 2014-08-26 21:26:37
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetItemDropInfoCell = class("QUIWidgetItemDropInfoCell", QUIWidget)

local QNavigationController = import("...controllers.QNavigationController")
local QUIViewController = import("..QUIViewController")

function QUIWidgetItemDropInfoCell:ctor(options)
	local ccbFile = "ccb/Widget_ItemDropInfo.ccbi"
	local callbacks = {
     		{ccbCallbackName = "onTriggerGoto", callback = handler(self, QUIWidgetItemDropInfoCell._onTriggerGoto)},
  	}
	QUIWidgetItemDropInfoCell.super.ctor(self, ccbFile, callbacks, options)
	if options ~= nil and options.map ~= nil and options.dungeon ~= nil then
		self:showInfo(options.map, options.dungeon)
	end
	self._enabled = true
end

function QUIWidgetItemDropInfoCell:showInfo(map, dungeon)
	self.map = map
	self.dungeon = dungeon
	self._ccbOwner.node_pass:setVisible(false)
	self._ccbOwner.node_no_pass:setVisible(false)
	if self.map.isLock == true and self.map.unlock_team_level <= remote.user.level then
		self._ccbOwner.node_pass:setVisible(true)
	else
		self._ccbOwner.node_no_pass:setVisible(true)
	end

	self._ccbOwner.tf_number:setString(self.map.number)
	if self.map.dungeon_type == DUNGEON_TYPE.NORMAL then
		self._ccbOwner.tf_name:setString(self.dungeon.name)
	else
		self._ccbOwner.tf_name:setString(self.dungeon.name.."(精英)")
	end
end

function QUIWidgetItemDropInfoCell:getContentSize()
	return self._ccbOwner.node_bg:getContentSize()
end

function QUIWidgetItemDropInfoCell:setEnabled(b)
	self._enabled = b
end

function QUIWidgetItemDropInfoCell:_onTriggerGoto()
	if self._enabled == true then
		app.sound:playSound("common_confirm")
		app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogDungeon", 
		 options = {info = self.map}})
	end
end

return QUIWidgetItemDropInfoCell