
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroHeadStar = class("QUIWidgetHeroHeadStar", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetHeroHeadStar:ctor(options)
	local ccbFile = "ccb/Widget_HeroHeadStar.ccbi"
	QUIWidgetHeroHeadStar.super.ctor(self,ccbFile,callBacks,options)
end

function QUIWidgetHeroHeadStar:setHero(actorId)
	-- local characher = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
	-- for i=1,5,1 do
	-- 	self._ccbOwner["node_hero_star_"..i]:setVisible(false)
	-- end
	-- if characher.star == 1 then
	-- 	self._ccbOwner.node_hero_star_1:setVisible(true)
	-- elseif characher.star == 2 then
	-- 	self._ccbOwner.node_hero_star_2:setVisible(true)
	-- elseif characher.star == 3 then
	-- 	self._ccbOwner.node_hero_star_3:setVisible(true)
	-- elseif characher.star == 4 then
	-- 	self._ccbOwner.node_hero_star_4:setVisible(true)
	-- elseif characher.star == 5 then
	-- 	self._ccbOwner.node_hero_star_5:setVisible(true)
	-- end
end

function QUIWidgetHeroHeadStar:setStar(star)
	star = star + 1
	for i=1,5,1 do
		self._ccbOwner["node_hero_star_"..i]:setVisible(false)
	end
	if star == 1 then
		self._ccbOwner.node_hero_star_1:setVisible(true)
	elseif star == 2 then
		self._ccbOwner.node_hero_star_2:setVisible(true)
	elseif star == 3 then
		self._ccbOwner.node_hero_star_3:setVisible(true)
	elseif star == 4 then
		self._ccbOwner.node_hero_star_4:setVisible(true)
	elseif star == 5 then
		self._ccbOwner.node_hero_star_5:setVisible(true)
	end
end

return QUIWidgetHeroHeadStar
