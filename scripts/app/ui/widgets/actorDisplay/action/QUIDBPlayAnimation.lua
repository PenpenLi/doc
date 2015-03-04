

local QUIDBAction = import(".QUIDBAction")
local QUIDBPlayAnimation = class("QUIDBPlayAnimation", QUIDBAction)

function QUIDBPlayAnimation:_execute(dt)
	if self._isAnimationPlaying == true then
		return
	end

	self._animationName = self._options.animation
	self._isLoop = self._options.is_loop
	self._widgetActor:playAnimation(self._animationName, self._isLoop)
	self._isAnimationPlaying = true

	if self._animationName == ANIMATION.STAND or self._animationName == ANIMATION.WALK then
		self:finished()
	else
		self._eventProxy = cc.EventProxy.new(self._widgetActor)
    	self._eventProxy:addEventListener(self._widgetActor.ANIMATION_FINISHED_EVENT, handler(self, self._onAnimationEnded))
	end
end

function QUIDBPlayAnimation:_onAnimationEnded(event)
	if event.animationName == self._animationName then
		self._eventProxy:removeAllEventListeners()
		self._eventProxy = nil
		self:finished()
	end
end

function QUIDBPlayAnimation:_onCancel()
	if  self._eventProxy ~= nil then
        self._eventProxy:removeAllEventListeners()
        self._eventProxy = nil
    end
end

return QUIDBPlayAnimation