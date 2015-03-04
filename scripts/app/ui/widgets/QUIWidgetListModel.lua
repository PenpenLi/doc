--
-- Author: Your Name
-- Date: 2014-05-08 16:07:32
--

local QUIWidget = import(".QUIWidget")
local QUIWidgetListModel = class("QUIWidgetListModel", QUIWidget)

local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIDialogSystemPrompt = import("..dialogs.QUIDialogSystemPrompt")
local QUIWidgetHeroInformationStar = import("..widgets.QUIWidgetHeroInformationStar")
local QUIWidgetHeroInformation = import("..widgets.QUIWidgetHeroInformation")
local QSkeletonViewController = import("...controllers.QSkeletonViewController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QHeroModel = import("...models.QHeroModel")

QUIWidgetListModel.EVENT_ON_PERSS = "EVENT_ON_PERSS"

function QUIWidgetListModel:ctor(options)
	local ccbFile = "ccb/Widget_list3.ccbi"
	local callBacks = {
	{ccbCallbackName = "onPress", callback = handler(self, QUIWidgetListModel._onPress)}
	}
	QUIWidgetListModel.super.ctor(self,ccbFile,callBacks,options)

	self._star = QUIWidgetHeroInformationStar.new()
    self._ccbOwner.node_star:addChild(self._star:getView())

    self._information = QUIWidgetHeroInformation.new()
    self._information:setBattleForceVisible(false)
    self._ccbOwner.node_mide:setPositionY(self._ccbOwner.node_mide:getPositionY() + 100)
    self._ccbOwner.node_mide:addChild(self._information:getView())
end

function QUIWidgetListModel:onExit()
	self:clearAll()
end

function QUIWidgetListModel:setHero(hero)
	self._heroModel = QHeroModel.new(hero)
	self._information:setBattleForceVisible(false)
	local characherConfig = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(hero.actorId)
    self._star:showStar(hero.grade)
	self._star:setVisible(true)
    if characherConfig ~= nil then
        self._information:setAvatar(hero.actorId, 1)
    end
end

function QUIWidgetListModel:clearAll()
	self._star:setVisible(false)
	self._information:removeAvatar()
	self._information:setBattleForceVisible(false)
end

return QUIWidgetListModel