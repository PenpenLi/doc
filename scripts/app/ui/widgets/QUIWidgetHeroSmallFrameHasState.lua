--
-- Author: wkwang
-- Date: 2015-01-31 10:42:19
--
local QUIWidgetHeroSmallFrame = import("..widgets.QUIWidgetHeroSmallFrame")
local QUIWidgetHeroSmallFrameHasState = class("QUIWidgetHeroSmallFrameHasState", QUIWidgetHeroSmallFrame)
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetHeroSmallFrameHasState:ctor(options)
	QUIWidgetHeroSmallFrameHasState.super.ctor(self, options)
	self._ccbOwner.node_hp:setVisible(true)
	self._ccbOwner.node_dead:setVisible(false)
end

function QUIWidgetHeroSmallFrameHasState:setHero(actorId,selectTable)
	QUIWidgetHeroSmallFrameHasState.super.setHero(self, actorId, selectTable)
	local hp = 0
	self._maxHp = self._heroModel:getMaxHp()
    local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
    if globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT ~= nil and globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT.value ~= nil then
        self._maxHp = self._maxHp * globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT.value 
    end
	local heroInfo = remote.sunWell:getSunwellHeroInfo(self._actorId)
	if heroInfo == nil then
		hp = self._maxHp
		self:getHead():updateCD(1)
	else
		hp = heroInfo.hp
		self:getHead():updateCD(1-(heroInfo.skillCD or 0) * 0.001)
	end

	if hp > self._maxHp then
		hp = self._maxHp
	end
	-- self._ccbOwner.node_dead:setVisible(hp <= 0)
	-- self._ccbOwner.node_hp:setVisible(not (hp <= 0))
	self:showDead(hp)
	self._ccbOwner.sp_hp:setScaleX(hp/self._maxHp)
end

function QUIWidgetHeroSmallFrameHasState:setHeroInfo(heroInfo)
	-- 设置头像显示
	self._heroHead:setHero(heroInfo.actorId, heroInfo.level)
	self:unselected()
	self:removeFight()
	self:removeBattleForce()

	local hp = 0
	local heroModel = app:createHeroWithoutCache(heroInfo)
	local maxHp = heroModel:getMaxHp()
    local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
    if globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT ~= nil and globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT.value ~= nil then
        maxHp = maxHp * globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT.value 
    end
	if heroInfo == nil then
		hp = maxHp
	else
		hp = heroInfo.hp or maxHp
	end

	if hp > maxHp then
		hp = maxHp
	end
	-- self._ccbOwner.node_dead:setVisible(hp <= 0)
	-- self._ccbOwner.node_hp:setVisible(not (hp <= 0))
	self:showDead(hp)
	self._ccbOwner.sp_hp:setScaleX(hp/maxHp)
	self:getHead():updateCD(1- (heroInfo.skillCD or 0) * 0.001)
	self:getHead():setStar(heroInfo.grade+1)
end

function QUIWidgetHeroSmallFrameHasState:showDead(hp)
	if hp <= 0 then
		self._ccbOwner.node_dead:setVisible(true)
		self._ccbOwner.node_hp:setVisible(false)
		makeNodeFromNormalToGray(self:getHead())
	else
		self._ccbOwner.node_dead:setVisible(false)
		self._ccbOwner.node_hp:setVisible(true)
		makeNodeFromGrayToNormal(self:getHead())
	end
end

--event callback area--
function QUIWidgetHeroSmallFrameHasState:_onTriggerHeroOverview(tag, menuItem)
	local heroInfo = remote.sunWell:getSunwellHeroInfo(self._actorId)
	local hp = 0
	if heroInfo == nil then
		hp = self._maxHp
	else
		hp = heroInfo.hp or 0
	end
	if hp > 0 then
		QUIWidgetHeroSmallFrameHasState.super._onTriggerHeroOverview(self, tag, menuItem)
	end
end

return QUIWidgetHeroSmallFrameHasState