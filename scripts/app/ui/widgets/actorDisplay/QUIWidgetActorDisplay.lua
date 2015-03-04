
local QUIWidget = import("..QUIWidget")
local QUIWidgetActorDisplay = class("QUIWidgetActorDisplay", QUIWidget)

local QUIWidgetSkeletonActor = import(".QUIWidgetSkeletonActor")
local QUIDBDirector = import(".QUIDBDirector")

function QUIWidgetActorDisplay:ctor(actorId, options)
	QUIWidgetActorDisplay.super.ctor(self, nil, nil, options)

	self._actor = QUIWidgetSkeletonActor.new(actorId)
	self:addChild(self._actor)
end

function QUIWidgetActorDisplay:onEnter()
	self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()
    self._actor:retain()
end

function QUIWidgetActorDisplay:onExit()
	self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
	self:stopDisplay()
	self._actor:release()
	
end

function QUIWidgetActorDisplay:isActorPlaying()
	if self._director ~= nil then
		return true
	else
		return false
	end
end

function QUIWidgetActorDisplay:stopDisplay()
	if self._director ~= nil then
		self._director:cancel()
		self._director = nil
	end
end

function QUIWidgetActorDisplay:displayWithBehavior(behaviorName)
	if behaviorName == nil then
		return
	end

	self:stopDisplay()

	self._director = QUIDBDirector.new(self._actor, behaviorName)

end

function QUIWidgetActorDisplay:_onFrame(dt)
	if self._director ~= nil then
		if self._director:isFinished() == true then
			self._director = nil
			self._actor:playAnimation(ANIMATION.STAND)
		else
			self._director:visit(dt)
		end
	end
end

return QUIWidgetActorDisplay