
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroInformation = class("QUIWidgetHeroInformation", QUIWidget)

local QSkeletonViewController = import("...controllers.QSkeletonViewController")
local QUIWidgetAnimationPlayer = import("..widgets.QUIWidgetAnimationPlayer")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetActorDisplay = import(".actorDisplay.QUIWidgetActorDisplay")

QUIWidgetHeroInformation.EVENT_BEGAIN = "HERO_EVENT_BEGAIN"
QUIWidgetHeroInformation.EVENT_END = "HERO_EVENT_END"

function QUIWidgetHeroInformation:ctor(options)
	local ccbFile = "ccb/Widget_HeroInformation.ccbi" 
	local callBacks = {
        {ccbCallbackName = "onTriggerAvatar", callback = handler(self, QUIWidgetHeroInformation._onTriggerAvatar)},}
	QUIWidgetHeroInformation.super.ctor(self, ccbFile, callBacks, options)
	self.actorId = options
	self._effectPlay = false
	self._avatarName = {}
	self._ccbOwner.node_avatar:setScaleX(-1)
end

function QUIWidgetHeroInformation:onEnter()
    self._ccbOwner.sprite_back:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._ccbOwner.sprite_back:setTouchEnabled(true)
    self._ccbOwner.sprite_back:setTouchSwallowEnabled(false)
    self._ccbOwner.sprite_back:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIWidgetHeroInformation._onTouch))
end

function QUIWidgetHeroInformation:onExit()
	self:removeAvatar()
	if self._battleHandler ~= nil then
	    scheduler.unscheduleGlobal(self._battleHandler)
	    self._battleHandler = nil
	end
    self._ccbOwner.sprite_back:setTouchEnabled(false)
    self._ccbOwner.sprite_back:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
end

function QUIWidgetHeroInformation:setAvatar(actorId,scale)
	self.actorId = actorId
    self._heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self.actorId)
    self._heroCharacter = QStaticDatabase:sharedDatabase():getCharacterByID(self.actorId)
    scale = self._heroDisplay.actor_scale * scale
	self:removeAvatar()
	self._avatar = QUIWidgetActorDisplay.new(self.actorId)

	--动作表
	self._avatarName = {}
	self._totalRate = 0
	local actionStr = self._heroCharacter.information_action
	local actionArr = string.split(actionStr, ";")
	if actionArr ~= false then
		for _,value in pairs(actionArr) do
			local arr = string.split(value, ":")
			self._totalRate = self._totalRate + tonumber(arr[2])
			table.insert(self._avatarName, {name = arr[1], rate = tonumber(arr[2])})
		end
	end

	self._avatar:setScale(scale)
	self._ccbOwner.node_avatar:addChild(self._avatar)
end

function QUIWidgetHeroInformation:setBattleForceVisible(b)
	self._ccbOwner.node_battleForce:setVisible(b)
end

--设置战斗力显示
function QUIWidgetHeroInformation:setBattleForce(value)
	self._battleForce = value
	self._ccbOwner.tf_force:setString(value)
end

--显示特效
function QUIWidgetHeroInformation:avatarPlayAnimation(value, isPalySound)
	if self._avatar ~= nil then
		self._avatar:displayWithBehavior(value)
		if isPalySound ~= nil or isPalySound == true then
			self:playSound(value)
		end
	end
end

function QUIWidgetHeroInformation:playSound(value)
	if self._avatarSound ~= nil then
		audio.stopSound(self._avatarSound)
		self._avatarSound = nil
	end
	if value == ANIMATION_EFFECT.VICTORY then
    	self._avatarSound = audio.playSound( self._heroDisplay.cheer,false)
    elseif value == ANIMATION_EFFECT.WALK then
    	self._avatarSound = audio.playSound( self._heroDisplay.walk,false)
	end
end

--升级效果
function QUIWidgetHeroInformation:playLevelUp()
	app.sound:playSound("hero_up")
	if self._effectShow == nil then
		self._effectShow = QUIWidgetAnimationPlayer.new()
		self:addChild(self._effectShow)
	end
	self._effectShow:playAnimation("ccb/effects/HeroUpgarde.ccbi")
	self:avatarPlayAnimation(ANIMATION_EFFECT.VICTORY)
end

--显示战斗力特效
function QUIWidgetHeroInformation:battleForceAnimation(value)
    self._runTime = 1
    self._targetBattleForce = value
    self._forcePreNum = math.floor((self._targetBattleForce - self._battleForce) / (self._runTime*60))
    self._startTime = q.time()
	self._battleFun = function ()
		if q.time() - self._startTime > self._runTime then
			if self._battleHandler ~= nil then
                scheduler.unscheduleGlobal(self._battleHandler)
                self._battleHandler = nil
            end
            self._battleForce = self._targetBattleForce
        else
            if self._battleForce > self._targetBattleForce then
            	self._battleForce = self._targetBattleForce
            else
                self._battleForce = self._battleForce + self._forcePreNum
            end
        end
		self._ccbOwner.tf_force:setString(self._battleForce)
	end
	if self._battleHandler == nil then
		self._battleHandler = scheduler.scheduleGlobal(handler(self,self._battleFun),0)
	end
end

--显示特效
function QUIWidgetHeroInformation:playPropEffect(value)
	if self._effectTbl == nil then
		self._effectTbl = {}
	end
	table.insert(self._effectTbl, value)
	self._timeDelay = 0.3
	if (2/#self._effectTbl) < self._timeDelay then
		self._timeDelay = 2/#self._effectTbl
	end
	if self._effectPlay == false then
		self._effectPlay = true
		self._handler = scheduler.performWithDelayGlobal(handler(self,self._playPropEffect),self._timeDelay)
	end
end

function QUIWidgetHeroInformation:_playPropEffect()
	if self._effectTbl == nil or #self._effectTbl == 0 then
		self._effectPlay = false
		if self._handler ~= nil then
			scheduler.unscheduleGlobal(self._handler)
			self._handler = nil
		end
		return 
	else
		self._handler = scheduler.performWithDelayGlobal(handler(self,self._playPropEffect),self._timeDelay)
	end
	local value = self._effectTbl[1]
	table.remove(self._effectTbl,1)

	local effect = QUIWidgetAnimationPlayer.new()
	effect:setPosition(0,20)
	self:addChild(effect)
	effect:playAnimation("ccb/Widget_tips.ccbi", function(ccbOwner)
				ccbOwner.tf_value:setString(value)
            end,function()
            	effect:removeFromParentAndCleanup(true)
            end)
	-- local tf = ui.newTTFLabel({text = value, font = global.font_default, size = 24, color = ccc3(81,255, 0)})
	-- tf:setPosition(0,20)
	-- self:addChild(tf)
	-- local arr = CCArray:create()
	-- arr:addObject(CCMoveTo:create(1.2, ccp(0,120)))
	-- arr:addObject(CCCallFunc:create(function()
	-- 		self:removeChild(tf)
	-- 	end))
	-- local seq = CCSequence:create(arr)
	-- tf:runAction(seq)
end

function QUIWidgetHeroInformation:_onTouch(event)
  if event.name == "began" then
   QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetHeroInformation.EVENT_BEGAIN , eventTarget = self, actorId = self.actorId})
    return true
  elseif event.name == "ended" or event.name == "cancelled" then
   QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetHeroInformation.EVENT_END , eventTarget = self})
    return true
  end
end

--[[
	更换英雄Avatar
]]
function QUIWidgetHeroInformation:_onTriggerAvatar()
	if #self._avatarName == 0 or self._totalRate == 0 then return end
	local num = math.random(self._totalRate)
	local rate = 0
	local actionName = nil
	for _,value in pairs(self._avatarName) do
		if num < (rate + value.rate) then
			actionName = value.name
			break
		end
		rate = rate + value.rate
	end
	if actionName ~= nil then
		self:avatarPlayAnimation(actionName, true)
	end
end

function QUIWidgetHeroInformation:removeAvatar()
	if self._avatar ~= nil then
		self._ccbOwner.node_avatar:removeAllChildren()
		self._avatar = nil
	end
end

return QUIWidgetHeroInformation