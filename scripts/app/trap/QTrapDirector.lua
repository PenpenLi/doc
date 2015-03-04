
local QTrapDirector = class("QTrapDirector")

local QBaseEffectView = import("..views.QBaseEffectView")
local QTrap = import("..models.QTrap")
local QStaticDatabase = import("..controllers.QStaticDatabase")

-- state
QTrapDirector.standby = 0
QTrapDirector.start = 1
QTrapDirector.execute = 2
QTrapDirector.finish = 3
QTrapDirector.complete = 4
QTrapDirector.canceled = 5

function QTrapDirector:ctor(trapId, position, actorType, actor)
	assert(trapId ~= nil, "trap director should have a trap instance")
	assert(position ~= nil, "trap director must have a position to put it down")
	assert(actorType ~= nil, "shoud give a actor type to find damage target")

	self._trap = QTrap.new(trapId, position, actor)
	self._actorType = actorType
	self._state = QTrapDirector.standby
	self._actor = actor

	self._trapEventListener = cc.EventProxy.new(self._trap)
    self._trapEventListener:addEventListener(QTrap.TRIGGER, handler(self, self._onTrapTrigger))

	self:_start()
end

function QTrapDirector:getTrap()
	return self._trap
end

function QTrapDirector:isTragInfluenceActor(actor)
	if actor == nil then
		return false
	end

	if actor:isImmuneTrap(self._trap) then
		return false
	end

	if self._trap:getDamageTarget() == QTrap.ENEMY and actor:getType() == self._actorType then
		return false
	elseif self._trap:getDamageTarget() == QTrap.TEAMMATE and actor:getType() ~= self._actorType then
		return false
	end

	local position = actor:getPosition()

	local radius = self._trap:getRange()
	local center = self._trap:getPosition()
    local deltaX = position.x - center.x
    local deltaY = (position.y - center.y) * 2
    local distance = deltaX * deltaX + deltaY * deltaY
    if distance < radius * radius then
        return true
    end

    return false
end

function QTrapDirector:_start()
	self._state = QTrapDirector.start
	local startEffectId = self._trap:getStartEffectId()
	local executeEffectId = self._trap:getExecuteEffectId()
	local areaEffectId = self._trap:getAreaEffectId()
	local finishEffectId = self._trap:getFinishEffectId()

	-- create effect node from config file
	if startEffectId ~= nil then
		local frontEffect, backEffect = QBaseEffectView.createEffectByID(startEffectId)
		if frontEffect ~= nil then
			self._startEffect = frontEffect
		elseif backEffect ~= nil then
			self._startEffect = backEffect
		end
		if self._startEffect ~= nil then
			self._isStartEffectOnGround = QStaticDatabase.sharedDatabase():getEffectIsLayOnTheGroundByID(startEffectId)
		end
	end
		
	if executeEffectId ~= nil then
		local frontEffect, backEffect = QBaseEffectView.createEffectByID(executeEffectId)
		if frontEffect ~= nil then
			self._executeEffect = frontEffect
		elseif backEffect ~= nil then
			self._executeEffect = backEffect
		end
		if self._executeEffect ~= nil then
			self._isExecuteEffectOnGround = QStaticDatabase.sharedDatabase():getEffectIsLayOnTheGroundByID(executeEffectId)
		end
	end

	if areaEffectId ~= nil then
		local frontEffect, backEffect = QBaseEffectView.createEffectByID(areaEffectId)
		if frontEffect ~= nil then
			self._areaEffect = frontEffect
		elseif backEffect ~= nil then
			self._areaEffect = backEffect
		end
		if self._areaEffect ~= nil then
			self._isAreaEffectOnGround = QStaticDatabase.sharedDatabase():getEffectIsLayOnTheGroundByID(areaEffectId)
		end
	end

	if finishEffectId ~= nil then
		local frontEffect, backEffect = QBaseEffectView.createEffectByID(finishEffectId)
		if frontEffect ~= nil then
			self._finishEffect = frontEffect
		elseif backEffect ~= nil then
			self._finishEffect = backEffect
		end
		if self._finishEffect ~= nil then
			self._isFinishEffectOnGround = QStaticDatabase.sharedDatabase():getEffectIsLayOnTheGroundByID(finishEffectId)
		end
	end

	self:_retainEffect()

	-- play start effect
	if self._startEffect ~= nil then
		self._startEffect:setPosition(self._trap:getPosition().x, self._trap:getPosition().y)
        app.scene:addEffectViews(self._startEffect, {isGroundEffect = self._isStartEffectOnGround})
        self._startEffect:playAnimation(EFFECT_ANIMATION, false)
        self._startEffect:playSoundEffect(false)
        self._startEffect:afterAnimationComplete(function()
            app.scene:removeEffectViews(self._startEffect)
            if self._state ~= QTrapDirector.canceled then
            	self._trap:start()
            	self:_playExecuteEffect()
            end
        end)
	else
		self._trap:start()
		self:_playExecuteEffect()
	end

	if DISPLAY_TRAP_RANGE == true then
		local radius = self._trap:getRange()
		local center = self._trap:getPosition()
        local bottomLeft = ccp(center.x - radius, center.y - radius * 0.5)
        local topRight = ccp(center.x + radius, center.y + radius * 0.5)
        app.scene:displayRect(bottomLeft, topRight, self._trap:getDuration(), display.COLOR_MAGENTA_C4F)
	end
end

function QTrapDirector:_playExecuteEffect()
	self._state = QTrapDirector.execute

	if self._executeEffect ~= nil then
		self._executeEffect:setPosition(self._trap:getPosition().x, self._trap:getPosition().y + 1)
	    app.scene:addEffectViews(self._executeEffect, {isGroundEffect = self._isExecuteEffectOnGround})
	    self._executeEffect:playAnimation(EFFECT_ANIMATION, true)
	    self._executeEffect:playSoundEffect(false)
	end

	if self._areaEffect ~= nil then
	    self._areaEffect:setPosition(self._trap:getPosition().x, self._trap:getPosition().y + 1)
	    app.scene:addEffectViews(self._areaEffect, {isGroundEffect = self._isAreaEffectOnGround})
	    self._areaEffect:playAnimation(EFFECT_ANIMATION, true)
	    self._areaEffect:playSoundEffect(false)
	end
end

function QTrapDirector:visit(dt)
	if self._state ~= QTrapDirector.execute then
		return
	end

	self._trap:visit(dt)

	if self._trap:isEnded() == true then
		-- stop and remove execute effect
		if self._executeEffect ~= nil then
			self._executeEffect:stopAnimation()
			app.scene:removeEffectViews(self._executeEffect)
		end
		if self._areaEffect ~= nil then
			self._areaEffect:stopAnimation()
			app.scene:removeEffectViews(self._areaEffect)
		end

		self._state = QTrapDirector.finish
		-- play finish effect
		if self._finishEffect ~= nil then
			self._finishEffect:setPosition(self._trap:getPosition().x, self._trap:getPosition().y)
	        app.scene:addEffectViews(self._finishEffect, {isGroundEffect = self._isFinishEffectOnGround})
	        self._finishEffect:playAnimation(EFFECT_ANIMATION, false)
	        self._finishEffect:playSoundEffect(false)
	        self._finishEffect:afterAnimationComplete(function()
	            app.scene:removeEffectViews(self._finishEffect)
	            self:_complete()
	        end)
		else
			self:_complete()
		end

	end
end

function QTrapDirector:_complete()
	if self._trapEventListener ~= nil then
		self._trapEventListener:removeAllEventListeners()
		self._trapEventListener = nil
	end
	self._state = QTrapDirector.complete

	self:_releaseEffect()
end

function QTrapDirector:isExecute()
	return (self._state == QTrapDirector.execute)
end

function QTrapDirector:isCompleted()
	return (self._state == QTrapDirector.complete)
end

function QTrapDirector:cancel()
	local stateBefore = self._state
	self._state = QTrapDirector.canceled
	if stateBefore == QTrapDirector.start and self._startEffect ~= nil then
		self._startEffect:stopAnimation()
	elseif stateBefore == QTrapDirector.execute then
		if self._executeEffect ~= nil then
			self._executeEffect:stopAnimation()
			app.scene:removeEffectViews(self._executeEffect)
		end
		if self._areaEffect ~= nil then
			self._areaEffect:stopAnimation()
			app.scene:removeEffectViews(self._areaEffect)
		end
	elseif stateBefore == QTrapDirector.finish and self._finishEffect ~= nil then
		self._finishEffect:stopAnimation()
	end

	self:_releaseEffect()
end

function QTrapDirector:_retainEffect()
	if self._startEffect ~= nil then
		self._startEffect:retain()
	end
	
	if self._executeEffect ~= nil then
		self._executeEffect:retain()
	end

	if self._finishEffect ~= nil then
		self._finishEffect:retain()
	end

	if self._areaEffect ~= nil then
		self._areaEffect:retain()
	end
end

function QTrapDirector:_releaseEffect()
	if self._startEffect ~= nil then
		self._startEffect:release()
		self._startEffect = nil
	end
	
	if self._executeEffect ~= nil then
		self._executeEffect:release()
		self._executeEffect = nil
	end

	if self._finishEffect ~= nil then
		self._finishEffect:release()
		self._finishEffect = nil
	end

	if self._areaEffect ~= nil then
		self._areaEffect:release()
		self._areaEffect = nil
	end
end


function QTrapDirector:_onTrapTrigger()
	if app.battle:isPausedBetweenWave() == true then
		return
	end
	
	local radius = self._trap:getRange()
	assert(radius > 0, "trap: " .. self._trap:getId() .. " range should large then 0")
	radius = radius * radius

	local actors = nil
	if self._trap:getDamageTarget() == QTrap.EVERYONE then
		actors = {}
		table.merge(actors, app.battle:getMyTeammatesWithType(self._actorType))
		table.merge(actors, app.battle:getMyEnemiesWithType(self._actorType))

	elseif self._trap:getDamageTarget() == QTrap.ENEMY then
		actors = app.battle:getMyEnemiesWithType(self._actorType)

	elseif self._trap:getDamageTarget() == QTrap.TEAMMATE then
		actors = app.battle:getMyTeammatesWithType(self._actorType)

	else
		assert(false, "trap: " .. self._trap:getId() .. "is for teammate or enemy or both of then, but current target type is " .. self._trap:getDamageType())
	end
	
	local targets = {}
	local center = self._trap:getPosition()
	local y_ratio = self._trap:getYRatio()
	for _, actor in ipairs(actors) do
	    local pos = actor:getPosition()
	    local deltaX = pos.x - center.x
	    local deltaY = (pos.y - center.y) * y_ratio
	    local distance = deltaX * deltaX + deltaY * deltaY
	    if distance < radius then
	    	table.insert(targets, actor)
	    end
	end

	local damage = self._trap:getDamageEachTime()
	local absorb = 0
	local tip = ""
	local damageType = self._trap:getDamageType()
	for _, target in ipairs(targets) do
		if damageType == QTrap.TREAT then
			target:increaseHp(damage)
		elseif damageType == QTrap.ATTACK  then
		    -- 战场伤害系数
		    damage = damage * app.battle:getDamageCoefficient()
			if damage > 0 then
				_, damage, absorb = target:decreaseHp(damage)
			end
		else
			assert(false, "Trap damage type is limit in attack and treat. But " .. self._trap:getId() .. "'s damage type is " .. damageType)
		end
        if absorb > 0 then
            tip = "吸收 "
            target:dispatchEvent({name = target.UNDER_ATTACK_EVENT, isTreat = false, tip = tip .. tostring(absorb)})
            tip = ""
        end
		target:dispatchEvent({name = target.UNDER_ATTACK_EVENT, isTreat = (damageType == QTrap.TREAT), tip = tostring(damage)})
	end
	
end

return QTrapDirector