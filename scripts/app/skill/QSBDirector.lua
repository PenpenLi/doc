
--[[
    Class name QSBDirector
    Create by julian 
--]]

local QSBDirector = class("QSBDirector")

local QSBNode = import(".QSBNode")
local QFileCache = import("..utils.QFileCache")
local QSkeletonViewController = import("..controllers.QSkeletonViewController")
local QNotificationCenter = import("..controllers.QNotificationCenter")

function QSBDirector:ctor(attacker, target, skill, options)
	self._attacker = attacker
	self._target = target
	self._skill = skill
    if self._target ~= nil then
        self._targetPosition = self._target:getPosition()
    end

    self._skillBehavior = nil
    self._behaviorName = skill:getSkillBehaviorName()
	if self:_createSkillBehavior(self._behaviorName) == false then
		assert(false, self._skill:getName() ..  " can not find a skill behavior named after" .. tostring(self._behaviorName))
		return
	end

    -- something for cancle
    self._attackerBuffIds = {}
    self._targetBuffIds = {}
    self._loopEffectIds = {}
    self._soundEffects = {}

	self._isSkillFinished = false
end

function QSBDirector:isSkillFinished()
	return self._isSkillFinished
end

function QSBDirector:_createSkillBehavior(name)
	if name == nil then
		return false
	end

    local config = QFileCache.sharedFileCache():getSkillConfigByName(name)
    if config ~= nil then
        self._skillBehavior = self:_createSkillBehaviorNode(config)
    end

	return (self._skillBehavior ~= nil)
end

function QSBDirector:_createSkillBehaviorNode(config)
	if config == nil or type(config) ~= "table" then
        return nil
    end

    local skillClass = QFileCache.sharedFileCache():getSkillClassByName(config.CLASS)
    local options = clone(config.OPTIONS)
    local node = skillClass.new(self, self._attacker, self._target, self._skill, options)

    local args = config.ARGS
    if args ~= nil then
        for k, v in pairs(args) do
            local child = self:_createSkillBehaviorNode(v)
            if child ~= nil then
                node:addChild(child)
            end
        end
    end

    return node
end

function QSBDirector:visit(dt)
    if self._isSkillFinished == true then
        return
    end

    if self._attacker:isDead() == true and not self._attacker:isDoingDeadSkill() then
        self:cancel()
        return
    end

    if self._skillBehavior:getState() == QSBNode.STATE_FINISHED then
    	self._isSkillFinished = true
    elseif self._skillBehavior:getState() == QSBNode.STATE_EXECUTING then
    	self._skillBehavior:visit(dt)
    elseif self._skillBehavior:getState() == QSBNode.STATE_WAIT_START then
    	self._skillBehavior:start()
        self._skillBehavior:visit(0)
    end
end

function QSBDirector:cancel()

    if self._attacker:isDead() == false then
        for _, buffId in ipairs(self._attackerBuffIds) do
            self._attacker:removeBuffByID(buffId)
        end
    end

--  assert(self._target ~= nil, "QSBDirector:cancel() _target is nil!")
    if self._target and self._target:isDead() == false then
        for _, buffId in ipairs(self._targetBuffIds) do
            self._target:removeBuffByID(buffId)
        end
    end

    self._skillBehavior:cancel()
    if self._skillBehavior.revert then 
        self._skillBehavior:revert()
    end
    if self._attacker:isAttacking() == true then
        self._attacker:onAttackFinished(true)
    end

    if self._isVisibleSceneBlackLayer == true and app.scene:getBackgroundOverLayer():isVisible() == true then
        app.scene:visibleBackgroundLayer(false, self._showActor)
    end

    if self._actorScale ~= nil and self._actorScale ~= 1.0 then
        local actorView = app.scene:getActorViewFromModel(self._attacker)
        if actorView ~= nil then
            actorView:setScale(1.0)
        end
    end

    for _, loopEffectId in ipairs(self._loopEffectIds) do
        self._attacker:stopSkillEffect(loopEffectId)
    end

    if self._isActorKeepAnimation == true then
        local actorView = app.scene:getActorViewFromModel(self._attacker)
        if actorView ~= nil and self._attacker:isDead() == false then
            actorView:setIsKeepAnimation(false)
            actorView:getSkeletonActor():resetActorWithAnimation(ANIMATION.STAND, true)
        end
    end

    for _, soundEffect in ipairs(self._soundEffects) do
        if soundEffect:isLoop() == true then
            soundEffect:stop()
        end
    end

    if self._isInBulletTime == true then
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QNotificationCenter.EVENT_BULLET_TIME_TURN_OFF, actor = self._attacker})
    end

    self._isSkillFinished = true
end

function QSBDirector:getTargetPosition()
    return self._targetPosition
end

function QSBDirector:getTarget()
    return self._target
end

function QSBDirector:setTarget(target)
    self._target = target
end

function QSBDirector:getSkill()
    return self._skill
end

function QSBDirector:addBuffId(buffId, actor)
    if buffId ~= nil and actor ~= nil then
        if actor == self._attacker then
            table.insert(self._attackerBuffIds, buffId)
        else
            table.insert(self._targetBuffIds, buffId)
        end
    end
end

function QSBDirector:removeBuffId(buffId)
    if buffId ~= nil and actor ~= nil then
        if actor == self._attacker then
            table.removebyvalue(self._attackerBuffIds, buffId)
        else
            table.removebyvalue(self._targetBuffIds, buffId)
        end
    end
end

function QSBDirector:setVisibleSceneBlackLayer(visible, actor)
    self._isVisibleSceneBlackLayer = visible
    if self._isVisibleSceneBlackLayer == true then
        self._showActor = actor
    else
        self._showActor = nil
    end
end

function QSBDirector:setIsPlayLoopEffect(effectID)
    table.insert(self._loopEffectIds, effectID)
end

function QSBDirector:setActorKeepAnimation(isKeep)
    self._isActorKeepAnimation = isKeep
end

function QSBDirector:setActorScale(scale)
    self._actorScale = scale
end

function QSBDirector:setIsInBulletTime(isInBulletTime)
    self._isInBulletTime = isInBulletTime
end

function QSBDirector:isInBulletTime()
    return self._isInBulletTime
end

function QSBDirector:addSoundEffect(soundEffect)
    if soundEffect ~= nil then
        table.insert(self._soundEffects, soundEffect)
    end
end

function QSBDirector:stopSoundEffectById(id)
    if id == nil then
        return
    end
    
    for _, soundEffect in ipairs(self._soundEffects) do
        if soundEffect:getSoundId() == id then
            soundEffect:stop()
        end
    end
end

return QSBDirector