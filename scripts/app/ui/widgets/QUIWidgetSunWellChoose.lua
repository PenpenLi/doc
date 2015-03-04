--
-- Author: Your Name
-- Date: 2015-01-29 18:13:49
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetSunWellChoose = class("QUIWidgetSunWellChoose", QUIWidget)
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetUserHead = import("..widgets.QUIWidgetUserHead")
local QUIWidgetHeroSmallFrameHasState = import("..widgets.QUIWidgetHeroSmallFrameHasState")

QUIWidgetSunWellChoose.EVENT_CLICK = "EVENT_CLICK"

function QUIWidgetSunWellChoose:ctor(options)
	local ccbFile = "ccb/Widget_SunWell_Choose.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerBattle", callback = handler(self, QUIWidgetSunWellChoose._onTriggerBattle)},
    }
	QUIWidgetSunWellChoose.super.ctor(self, ccbFile, callBacks, options)
	cc.GameObject.extend(self)
	self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self._ccbOwner.sp_hard1:setVisible(false)
	self._ccbOwner.sp_hard2:setVisible(false)
	self._ccbOwner.sp_hard3:setVisible(false)

	self._head = QUIWidgetUserHead.new()
    self._head:setUserLevelVisible(false)
    self._ccbOwner.node_head:addChild(self._head)
end

function QUIWidgetSunWellChoose:setInfo(info, dungeonIndex, hardIndex)
	self._info = {info = info, dungeonIndex = dungeonIndex, hardIndex = hardIndex}
	self._ccbOwner["sp_hard"..hardIndex]:setVisible(true)
	local force = 0
	if info.heros ~= nil then
		remote.teams:sortTeam(info.heros)
		for index,value in pairs(info.heros) do
			force = force + value.force
			local heroContent = self._ccbOwner["hero"..index]
			if heroContent ~= nil then
				local head = QUIWidgetHeroSmallFrameHasState.new()
				head:setHeroInfo(value)
				head:setButtonEnabled(false)
				heroContent:addChild(head)
			end
		end
	end
	self._ccbOwner.tf_force:setString(force)
	local sunwellMoney = 0
	local rewards = QStaticDatabase:sharedDatabase():getSunwellAwardsByIndex(dungeonIndex)
	if rewards ~= nil then
		for _,value in pairs(rewards) do
			if value.enemy_power == hardIndex then
				sunwellMoney = value.victory_sunwell_money or 0
			end
		end
	end
	self._ccbOwner.tf_money:setString(sunwellMoney)
	self._ccbOwner.tf_user_name:setString(info.name)
	self._head:setUserAvatar(info.avatar)
	self._info.sunwellMoney = sunwellMoney
end

function QUIWidgetSunWellChoose:getInfo()
	return self._info
end

function QUIWidgetSunWellChoose:_onTriggerBattle()
	self:dispatchEvent({name = QUIWidgetSunWellChoose.EVENT_CLICK})
end

return QUIWidgetSunWellChoose