--
-- Author: wkwang
-- Date: 2014-10-13 14:57:18
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroUpgrade = class("QUIWidgetHeroUpgrade", QUIWidget)

local QUIWidgetHeroUpgradeCell = import("..widgets.QUIWidgetHeroUpgradeCell")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetHeroUpgrade:ctor(options)
	local ccbFile = "ccb/Widget_HeroUpgrade.ccbi"
	local callBacks = {}
	QUIWidgetHeroUpgrade.super.ctor(self, ccbFile, callBacks, options)
end

function QUIWidgetHeroUpgrade:onEnter()
end

function QUIWidgetHeroUpgrade:onExit()

end

function QUIWidgetHeroUpgrade:showById(actorId, targetP)
	self._actorId = actorId
	self._targetP = targetP

	local expItems = QStaticDatabase:sharedDatabase():getItemsByProp("exp")

	table.sort( expItems, handler(self,self._sortHero) )

	local _height = 0
	self._ccbOwner.node_gradeCell:removeAllChildren()
	self._itmes = {}
	for k,value in pairs(expItems) do
		local items = QUIWidgetHeroUpgradeCell.new()
		items:setInfo(value, self._actorId)
		items:setPosition(0, _height)
		items:setTargetPosition(self._targetP)
		_height = _height - items:getContentSize().height
		self._ccbOwner.node_gradeCell:addChild(items)
		self._itmes[k] = items
	end
end

function QUIWidgetHeroUpgrade:_sortHero(a,b)
	if a.exp ~= b.exp then
		return a.exp < b.exp
	end
	return a.id < b.id
end

return QUIWidgetHeroUpgrade