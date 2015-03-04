--
-- Author: Your Name
-- Date: 2014-10-29 19:45:38
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetBackpackHeroFrame = class("QUIWidgetBackpackHeroFrame", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")

function QUIWidgetBackpackHeroFrame:ctor(options)
	local ccbFile = "ccb/Widget_PacksackItemInfo.ccbi"
	local callBacks = {}

	QUIWidgetBackpackHeroFrame.super.ctor(self, ccbFile, callBacks, options)

	local actorId = options.actorId
	local heroInfo = remote.herosUtil:getHeroByID(actorId)
	local heroIcon = QUIWidgetHeroHead.new({})
	local database = QStaticDatabase:sharedDatabase()
	local heroConfig = database:getCharacterDisplayByActorID(actorId)
	heroIcon:setTouchEnabled(false)
	heroIcon:setScale(0.5)
	heroIcon:setLevel(0)
	heroIcon:setHero(actorId, heroInfo.level)
	self._ccbOwner.node_icon:removeAllChildren()
	self._ccbOwner.node_icon:addChild(heroIcon)
	self._ccbOwner.tf_name:setString(heroConfig.name)
	
	local breakthroughLevel,color = remote.herosUtil:getBreakThrough(heroInfo.breakthrough)
	if breakthroughLevel > 0 then
		self._ccbOwner.tf_breakthrough:setColor(BREAKTHROUGH_COLOR[color])
	end
	self._ccbOwner.tf_breakthrough:setString((breakthroughLevel == 0 and "" or ("+"..breakthroughLevel)))
	self._ccbOwner.tf_breakthrough:setPositionX(self._ccbOwner.tf_name:getPositionX() + self._ccbOwner.tf_name:getContentSize().width + 10)
end

return QUIWidgetBackpackHeroFrame