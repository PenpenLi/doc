

local QUIDBAction = import(".QUIDBAction")
local QUIDBPlayEffect = class("QUIDBPlayEffect", QUIDBAction)

local QUIWidgetSkeletonEffect = import("..QUIWidgetSkeletonEffect")

function QUIDBPlayEffect:_execute(dt)
	if self._isAnimationPlaying == true then
		return
	end

	if self._options.effect_id == nil or string.len(self._options.effect_id) == 0 then
		self:finished()
		return
	end

	local frontEffect, backEffect = QUIWidgetSkeletonEffect.createEffectByID(self._options.effect_id, {time_scale = self._options.time_scale})

	if self._widgetActor:attachEffect(self._options.effect_id, frontEffect, backEffect) == false then
		self:finished()
		return
	end

	self._isFrontEffectFinished = false
	self._isBackEffectFinished = false 

	if frontEffect ~= nil then
		frontEffect:playAnimation(EFFECT_ANIMATION, false)
		frontEffect:playSoundEffect(false)
		frontEffect:afterAnimationComplete(function()
			self._isFrontEffectFinished = true
			self._widgetActor:getSkeletonView():detachNodeToBone(frontEffect)
			self:_checkIsFinished()
		end)
	else
		self._isFrontEffectFinished = true
	end

	if backEffect ~= nil then
		backEffect:playAnimation(EFFECT_ANIMATION, false)
		backEffect:playSoundEffect(false)
		backEffect:afterAnimationComplete(function()
			self._isBackEffectFinished = true
			self._widgetActor:getSkeletonView():detachNodeToBone(backEffect)
			self:_checkIsFinished()
		end)
	else
		self._isBackEffectFinished = true
	end

	self._frontEffect = frontEffect
	if self._frontEffect ~= nil then
		self._frontEffect:retain()
	end

	self._backEffect = backEffect
	if self._backEffect ~= nil then
		self._backEffect:retain()
	end

	self._isAnimationPlaying = true
end

function QUIDBPlayEffect:_checkIsFinished()
	if self._isFrontEffectFinished == true and self._isBackEffectFinished == true then
		self:finished()
	end
end

function QUIDBPlayEffect:_onCancel()
	if self._frontEffect ~= nil then
		self._frontEffect:stopAnimation()
		self._frontEffect:stopSoundEffect()
		self._widgetActor:getSkeletonView():detachNodeToBone(self._frontEffect)
		self._frontEffect:release()
		self._frontEffect = nil
    end

    if self._backEffect ~= nil then
		self._backEffect:stopAnimation()
		self._backEffect:stopSoundEffect()
		self._widgetActor:getSkeletonView():detachNodeToBone(self._backEffect)
		self._backEffect:release()
		self._backEffect = nil
    end
end

return QUIDBPlayEffect