
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroInformationName = class("QUIWidgetHeroInformationName", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroProfessionalIcon = import("..widgets.QUIWidgetHeroProfessionalIcon")

function QUIWidgetHeroInformationName:ctor(options)
	local ccbFile = "ccb/Widget_HeroInformation_name.ccbi"
	local callBacks = {}
	QUIWidgetHeroInformationName.super.ctor(self, ccbFile, callBacks, options)
	
	self._icon = QUIWidgetHeroProfessionalIcon.new()
	self._ccbOwner.node_icon:addChild(self._icon:getView())
	
	self._ccbOwner.label_name = setShadow(self._ccbOwner.label_name)
end

function QUIWidgetHeroInformationName:setHeroIcon(hero)
	self._icon:setHero(hero.actorId)
	local characher = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(hero.actorId)
	self._ccbOwner.label_name:setString(characher.name)

	self._ccbOwner.green:setVisible(false)
	self._ccbOwner.blue:setVisible(false)
	self._ccbOwner.purple:setVisible(false)
	
	local breakthroughLevel,color = remote.herosUtil:getBreakThrough(hero.breakthrough)
	if breakthroughLevel > 0 then
		self._ccbOwner.label_plusnumber:setColor(BREAKTHROUGH_COLOR[color])
	end
	if self._ccbOwner[color] ~= nil then
		self._ccbOwner[color]:setVisible(true)
	end
	self._ccbOwner.label_plusnumber:setString((breakthroughLevel == 0 and "" or (" +"..breakthroughLevel)))
	self._ccbOwner.label_plusnumber:setPositionX(self._ccbOwner.label_name:getPositionX() + self._ccbOwner.label_name:getContentSize().width)
end

return QUIWidgetHeroInformationName