
local QUIWidget = import(".QUIWidget")
local QUIWidgetHeroSmallFrame = class("QUIWidgetHeroSmallFrame", QUIWidget)

local QUIWidgetHeroHead = import(".QUIWidgetHeroHead")
local QHeroModel = import("...models.QHeroModel")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroProfessionalIcon = import(".QUIWidgetHeroProfessionalIcon")
local QUIWidgetHeroEquipmentSmallBox = import(".QUIWidgetHeroEquipmentSmallBox")
local QUIWidgetHeroEquipment = import(".QUIWidgetHeroEquipment")
local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUIWidgetHeroSmallFrame.EVENT_HERO_FRAMES_CLICK = "EVENT_HERO_FRAMES_CLICK"
QUIWidgetHeroSmallFrame.EVENT_HERO_FRAMES_DOWN = "EVENT_HERO_FRAMES_DOWN"
QUIWidgetHeroSmallFrame.EVENT_HERO_FRAMES_MOVE = "EVENT_HERO_FRAMES_MOVE"
QUIWidgetHeroSmallFrame.EVENT_HERO_FRAMES_END = "EVENT_HERO_FRAMES_END"

function QUIWidgetHeroSmallFrame:ctor(options)
	local ccbFile = "ccb/Widget_TeamArangement.ccbi"
	local callBacks = {{ccbCallbackName = "onTriggerHeroOverview", 				callback = handler(self, self._onTriggerHeroOverview)}}
	QUIWidgetHeroSmallFrame.super.ctor(self,ccbFile,callBacks,options)

	self._heroHead = QUIWidgetHeroHead.new({})
	self._heroHead:setTouchEnabled(false)
	self._ccbOwner.node_hero_head:addChild(self._heroHead:getView())

	self._ccbOwner.node_hp:setVisible(false)
	self._ccbOwner.node_dead:setVisible(false)
end

function QUIWidgetHeroSmallFrame:getName()
	return "QUIWidgetHeroSmallFrame"
end

function QUIWidgetHeroSmallFrame:getHero()
	return self._actorId
end

function QUIWidgetHeroSmallFrame:setHero(actorId,selectTable)
	self._actorId = actorId
	self._selectTable = selectTable
	self._hero = remote.herosUtil:getHeroByID(self._actorId)
	self:setHeroInfoBySelf(self._hero)
end

function QUIWidgetHeroSmallFrame:setHeroInfoBySelf(heroInfo)
	local database = QStaticDatabase:sharedDatabase()
	self._heroModel = app:createHero(self._hero)

	--设置战斗力
	self._ccbOwner.tf_force:setString(self._heroModel:getBattleForce())

	-- 设置头像显示
	self._heroHead:setHero(self._hero.actorId, self._hero.level)

	local isFind = false
	if self._selectTable ~= nil then
		for _,value in pairs(self._selectTable) do
			if value == self._hero.actorId then
				isFind = true
				break
			end
		end
	end

	if isFind == true then
		self:selected()
	else
		self:unselected()
	end
	self:removeFight()
end

--刷新当前信息显示
function QUIWidgetHeroSmallFrame:refreshInfo()
	self:setHero(self._actorId, self._selectTable)
end

function QUIWidgetHeroSmallFrame:selected()
	self._ccbOwner.node_hero_select:setVisible(true)
	self._ccbOwner.btn_hero_head:setVisible(false)
end

function QUIWidgetHeroSmallFrame:unselected()
	self._ccbOwner.node_hero_select:setVisible(false)
end

function QUIWidgetHeroSmallFrame:setFramePos(pos)
	self._pos = pos
end

function QUIWidgetHeroSmallFrame:getHead()
	return self._heroHead
end

function QUIWidgetHeroSmallFrame:getContentSize()
	return self._ccbOwner.bg:getContentSize()
end

function QUIWidgetHeroSmallFrame:showEquipment()
end

function QUIWidgetHeroSmallFrame:showBattleForce()
	self._ccbOwner.node_hero_battleForce:setVisible(true)
end

function QUIWidgetHeroSmallFrame:removeBattleForce()
	self._ccbOwner.node_hero_battleForce:setVisible(false)
end

function QUIWidgetHeroSmallFrame:showFight()
	self._isFight = true
	self._ccbOwner.node_hero_fight:setVisible(true)
end

function QUIWidgetHeroSmallFrame:removeFight()
	self._isFight = false
	self._ccbOwner.node_hero_fight:setVisible(false)
end

function QUIWidgetHeroSmallFrame:setButtonEnabled(b)
	self._ccbOwner.btn_team:setEnabled(b)
end

--event callback area--
function QUIWidgetHeroSmallFrame:_onTriggerHeroOverview(tag, menuItem)
	local position = self:convertToWorldSpaceAR(ccp(0,0))
	QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetHeroSmallFrame.EVENT_HERO_FRAMES_CLICK, hero = self._hero, pos = self._pos, position = position})
end

return QUIWidgetHeroSmallFrame
