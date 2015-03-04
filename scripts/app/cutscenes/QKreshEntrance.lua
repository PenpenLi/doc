
local QEntranceBase = import(".QEntranceBase")
local QKreshEntrance = class("QKreshEntrance", QEntranceBase)

local QNotificationCenter = import("..controllers.QNotificationCenter")

function QKreshEntrance:ctor(name, options)
	QKreshEntrance.super.ctor(self, name, options)

	-- charactor display id
	local guardianId = 140002
	local kreshId = 140505

	self._guardian1 = self:_createActorView(guardianId)
	self._guardian2 = self:_createActorView(guardianId)
	self._kresh = self:_createActorView(kreshId)

	self:_addSkeletonView(self._guardian1)
	self:_addSkeletonView(self._guardian2)
	self:_addSkeletonView(self._kresh)
end

function QKreshEntrance:exit()
	self:_removeActorView(self._guardian1)
	self:_removeActorView(self._guardian2)
	self:_removeActorView(self._kresh)

   	QKreshEntrance.super.exit(self)
end

function QKreshEntrance:getKreshPosition()
	if self._kresh == nil then
		return 0, 0
	end

	return self._kresh:getPosition()
end

function QKreshEntrance:getKreshSkeletonView()
	return self._kresh
end

function QKreshEntrance:startAnimation()
	self._guardian1:setPosition(570, 400)
	self._guardian2:setPosition(820, 400)
	self._kresh:setPosition(1600, 350)

	self:_setAuardian1Timeline()
	self:_setAuardian2Timeline()
	self:_setKreshAnimation()
end

function QKreshEntrance:_setAuardian1Timeline()
	self._guardian1:flipActor()

	-- 攻击恐龙
	local arr = CCArray:create()

	arr:addObject(CCCallFunc:create(function()
		self._guardian1:playAnimation("attack01", false)
		self._guardian1:appendAnimation(ANIMATION.STAND, true)
	end))
	arr:addObject(CCDelayTime:create(1.5))

	arr:addObject(CCCallFunc:create(function()
		self._guardian1:playAnimation("attack01", false)
		self._guardian1:appendAnimation(ANIMATION.STAND, true)
	end))
	arr:addObject(CCDelayTime:create(1.2))

	arr:addObject(CCDelayTime:create(0.75))

	arr:addObject(CCDelayTime:create(2.0))

	-- 受惊吓
	arr:addObject(CCCallFunc:create(function()
		self._guardian1:stopAnimation()
		local effect = self:_createEffectAndAttachToActor("psychic_scream_4", self._guardian1)
		if effect.front then
			effect.front.view:playAnimation(EFFECT_ANIMATION, true)
		end
		if effect.back then
			effect.back.view:playAnimation(EFFECT_ANIMATION, true)
		end
		self._guardian1.exclemationEffect = effect
	end))

	-- 逃跑
	arr:addObject(CCDelayTime:create(0.5))
	arr:addObject(CCCallFunc:create(function()
		self._guardian1:flipActor()
		self._guardian1:playAnimation("attack24", true)
	end))
	arr:addObject(CCMoveTo:create(3, ccp(-100, 550)))

    self._guardian1:runAction(CCSequence:create(arr))
end

function QKreshEntrance:_setAuardian2Timeline()
	-- 攻击恐龙
	local arr = CCArray:create()
	arr:addObject(CCCallFunc:create(function()
		self._guardian2:playAnimation(ANIMATION.STAND, true)
	end))
	arr:addObject(CCDelayTime:create(0.75))

	arr:addObject(CCCallFunc:create(function()
		self._guardian2:playAnimation("attack02", false)
		self._guardian2:appendAnimation(ANIMATION.STAND, true)
	end))
	arr:addObject(CCDelayTime:create(1.5))

	arr:addObject(CCCallFunc:create(function()
		self._guardian2:playAnimation("attack01", false)
		self._guardian2:appendAnimation(ANIMATION.STAND, true)
	end))
	arr:addObject(CCDelayTime:create(1.2))

	-- 向后跳
	arr:addObject(CCCallFunc:create(function()
		self._guardian2:flipActor()
	end))
	arr:addObject(CCDelayTime:create(0.5))
	arr:addObject(CCCallFunc:create(function()
		self._guardian2:playAnimation("attack23", false)
		self._guardian2:appendAnimation(ANIMATION.STAND, true)
	end))
	arr:addObject(CCDelayTime:create(0.3))
	arr:addObject(CCMoveTo:create(0.4, ccp(590, 300)))
	arr:addObject(CCDelayTime:create(0.4))
	arr:addObject(CCDelayTime:create(0.35))

	-- 受惊吓
	arr:addObject(CCCallFunc:create(function()
		self._guardian2:stopAnimation()
		local effect = self:_createEffectAndAttachToActor("psychic_scream_4", self._guardian2)
		if effect.front then
			effect.front.view:playAnimation(EFFECT_ANIMATION, true)
		end
		if effect.back then
			effect.back.view:playAnimation(EFFECT_ANIMATION, true)
		end
		self._guardian2.exclemationEffect = effect
	end))

	-- 逃跑
	arr:addObject(CCDelayTime:create(0.5))
	arr:addObject(CCCallFunc:create(function()
		self._guardian2:flipActor()
		self._guardian2:playAnimation("attack24", true)
	end))
	arr:addObject(CCMoveTo:create(3, ccp(-100, 150)))

	self._guardian2:runAction(CCSequence:create(arr))
end

function QKreshEntrance:_setKreshAnimation()
	-- 乌龟入场
	local arr = CCArray:create()
	arr:addObject(CCDelayTime:create(1.25))
	arr:addObject(CCCallFunc:create(function()
		self._kresh:playAnimation("attack06", false)
		self._kresh:appendAnimation("attack04", true)
	end))
	arr:addObject(CCDelayTime:create(1.5))
	arr:addObject(CCCallFunc:create(function()
		local effect = self:_createEffectAndAttachToActor("revolve_1", self._kresh)
		if effect.front then
			effect.front.view:playAnimation(EFFECT_ANIMATION, true)
		end
		if effect.back then
			effect.back.view:playAnimation(EFFECT_ANIMATION, true)
		end
		self._kresh.revolveEffect = effect
	end))
	local _, gridPos = app.grid:_toGridPos(850, 350)
	local screenPos = app.grid:_toScreenPos(gridPos)
	local currentPos = ccp(self._kresh:getPosition())
	local bezierConfig = ccBezierConfig:new()
    bezierConfig.endPosition = ccp(screenPos.x, screenPos.y)
    bezierConfig.controlPoint_1 = ccp(currentPos.x + (screenPos.x - currentPos.x) * 0.333, screenPos.y + 200)
    bezierConfig.controlPoint_2 = ccp(currentPos.x + (screenPos.x - currentPos.x) * 0.667, screenPos.y + 250)
    local bezierTo = CCBezierTo:create(2.0, bezierConfig)
	arr:addObject(CCEaseIn:create(bezierTo, 4))

	arr:addObject(CCCallFunc:create(function()
		local effect = self:_createEffectAndAttachToActor("trample_skum_1", self._kresh)
		if effect.front then
			effect.front.view:setScale(0.5)
			effect.front.view:playAnimation(EFFECT_ANIMATION, true)
		end
		if effect.back then
			effect.back.view:setScale(0.5)
			effect.back.view:playAnimation(EFFECT_ANIMATION, true)
		end
		self._kresh.trampleEffect = effect
	end))

	-- 吓唬恐龙
	arr:addObject(CCCallFunc:create(function()
		local effect = self._kresh.revolveEffect
		if effect.front then
			self._kresh:detachNodeToBone(effect.front)
		end
		if effect.back then
			self._kresh:detachNodeToBone(effect.back)
		end
		self._kresh:playAnimation(ANIMATION.STAND, false)
		self._kresh:playAnimation("attack22", false)
		self._kresh:appendAnimation(ANIMATION.STAND, true)
	end))

	arr:addObject(CCDelayTime:create(0.7))
	arr:addObject(CCCallFunc:create(function()
		local effect = self._kresh.trampleEffect
		if effect.front then
			self._kresh:detachNodeToBone(effect.front)
		end
		if effect.back then
			self._kresh:detachNodeToBone(effect.back)
		end
	end))

	arr:addObject(CCDelayTime:create(3.8))

	arr:addObject(CCCallFunc:create(function()
		QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QEntranceBase.ANIMATION_FINISHED})
	end))

	self._kresh:runAction(CCSequence:create(arr))
end

return QKreshEntrance