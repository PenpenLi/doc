--
-- Author: Your Name
-- Date: 2015-01-15 16:43:00
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetArena = class("QUIWidgetArena", QUIWidget)

local QUIWidgetUserHead = import("..widgets.QUIWidgetUserHead")

QUIWidgetArena.EVENT_USER_HEAD_CLICK = "EVENT_USER_HEAD_CLICK"
QUIWidgetArena.EVENT_BATTLE = "EVENT_BATTLE"

function QUIWidgetArena:ctor(options)
	local ccbFile = "ccb/Widget_Arena.ccbi"
  	local callBacks = {
      {ccbCallbackName = "onPress", callback = handler(self, QUIWidgetArena._onPress)},
      {ccbCallbackName = "onTriggerBattle", callback = handler(self, QUIWidgetArena._onTriggerBattle)},
  }
	QUIWidgetArena.super.ctor(self,ccbFile,callBacks,options)
  	cc.GameObject.extend(self)
  	self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self.head = QUIWidgetUserHead.new()
	self._ccbOwner.node_head:addChild(self.head)

	self._ccbOwner.tf_user_name:setString("")
	self._ccbOwner.tf_rank:setString(0)
	self._ccbOwner.tf_battleforce:setString(0)
end

function QUIWidgetArena:setInfo(info)
	self.info = info
	self.info.heros = self.info.heros or {}
	self.info.force = 0
	for _,hero in pairs(self.info.heros) do
		self.info.force = self.info.force + hero.force
	end
	self.head:setUserAvatar(info.avatar)
	self.head:setUserLevel(info.level)

	self._ccbOwner.tf_user_name:setString(info.name)
	self._ccbOwner.tf_rank:setString(info.rank)
	self._ccbOwner.tf_battleforce:setString(info.force)
end

function QUIWidgetArena:_onTriggerBattle()
	self:dispatchEvent({name = QUIWidgetArena.EVENT_BATTLE, info = self.info})
end

function QUIWidgetArena:_onPress()
	self:dispatchEvent({name = QUIWidgetArena.EVENT_USER_HEAD_CLICK, info = self.info})
end

return QUIWidgetArena