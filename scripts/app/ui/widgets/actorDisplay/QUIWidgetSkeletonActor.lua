

local QUIWidget = import("..QUIWidget")
local QUIWidgetSkeletonActor = class("QUIWidgetSkeletonActor", QUIWidget)

local QStaticDatabase = import("....controllers.QStaticDatabase")
local QSkeletonViewController = import("....controllers.QSkeletonViewController")

QUIWidgetSkeletonActor.ANIMATION_FINISHED_EVENT = "ANIMATION_FINISHED_EVENT"

function QUIWidgetSkeletonActor:ctor(actorId, options)
	-- add 
	cc.GameObject.extend(self)
	self:addComponent("components.behavior.EventProtocol"):exportMethods()

	QUIWidgetSkeletonActor.super.ctor(self, nil, nil, options)

	self._actorId = actorId
	self._actorDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self._actorId)
	self._actorView = QSkeletonViewController:sharedSkeletonViewController():createSkeletonActorWithFile( self._actorDisplay.actor_file)
	self._actorView:setSkeletonScaleX(self._actorDisplay.actor_scale)
	self._actorView:setSkeletonScaleY(self._actorDisplay.actor_scale)
	self:addChild(self._actorView)

	self:playAnimation(ANIMATION.STAND)
end

function QUIWidgetSkeletonActor:onCleanup()
    QSkeletonViewController:sharedSkeletonViewController():removeSkeletonActor(self._actorView)
    self._actorView = nil
end

function QUIWidgetSkeletonActor:onEnter()
	self._actorView:connectAnimationEventSignal(handler(self, self._onActorAnimationEvent))
end

function QUIWidgetSkeletonActor:onExit()
	self._actorView:disconnectAnimationEventSignal()
end

function QUIWidgetSkeletonActor:getSkeletonView()
    return self._actorView
end

function QUIWidgetSkeletonActor:_onActorAnimationEvent(eventType, trackIndex, animationName, loopCount)
    if eventType == SP_ANIMATION_END or eventType == SP_ANIMATION_COMPLETE then
    	self:dispatchEvent({name = self.ANIMATION_FINISHED_EVENT, trackIndex = trackIndex, animationName = animationName, loopCount = loopCount})
    end

    if eventType == SP_ANIMATION_END or eventType == SP_ANIMATION_COMPLETE then
        
    elseif eventType == SP_ANIMATION_START then
        self._currentAnimation = animationName
    end
end

function QUIWidgetSkeletonActor:resetActor()
	self._actorView:resetActorWithAnimation(ANIMATION.STAND, true)
end

function QUIWidgetSkeletonActor:playAnimation(animation, isLoop)
	if animation == nil then
		return
	end

    if isLoop == nil then
        isLoop = false
    end

	if isLoop == false and (animation == ANIMATION.STAND or animation == ANIMATION.WALK) then
		isLoop = true
	end

	self._actorView:playAnimation(animation, isLoop)
	self._currentAnimation = animation
end

function QUIWidgetSkeletonActor:attachEffect(effectID, frontEffect, backEffect)
	if effectID == nil then
		return false
	end

	if frontEffect == nil and backEffect == nil then
		return false
	end

	local dummy = QStaticDatabase.sharedDatabase():getEffectDummyByID(effectID)
    local isFlipWithActor = QStaticDatabase.sharedDatabase():getEffectIsFlipWithActorByID(effectID)
    if frontEffect ~= nil then
    	self:_attachEffectToDummy(dummy, frontEffect, false, isFlipWithActor)
    end
    if backEffect ~= nil then
    	self:_attachEffectToDummy(dummy, backEffect, true, isFlipWithActor)
    end

    return true
end

function QUIWidgetSkeletonActor:_attachEffectToDummy(dummy, effectView, isBackSide, isFlipWithActor)
    if effectView == nil then
        return
    end

    dummy = dummy or DUMMY.BOTTOM
    if dummy == DUMMY.BOTTOM or dummy == DUMMY.TOP or dummy == DUMMY.CENTER then
        self._actorView:attachNodeToBone(nil, effectView, isBackSide, isFlipWithActor)
        local actorScale = self._actorDisplay.actor_scale
        if effectView:getSkeletonView() ~= nil then
            local skeletonPositionX, skeletonPositionY = effectView:getSkeletonView():getPosition()
            if dummy == DUMMY.TOP then
                if isFlipWithActor == true then
                    skeletonPositionY = skeletonPositionY + self._actorDisplay.selected_rect_height
                else
                    skeletonPositionY = skeletonPositionY + self._actorDisplay.selected_rect_height * actorScale
                end
            elseif dummy == DUMMY.CENTER then
                if isFlipWithActor == true then
                    skeletonPositionY = skeletonPositionY + self._actorDisplay.selected_rect_height * 0.5
                else
                    skeletonPositionY = skeletonPositionY + self._actorDisplay.selected_rect_height * 0.5 * actorScale
                end
            end
            effectView:getSkeletonView():setPosition(skeletonPositionX, skeletonPositionY)
        end
    else
        if self._actorView:isBoneExist(dummy) == false then
            assert(false, "Bone node not found: <" .. dummy .. "> does not exist in the bone provided by <" .. self._actorDisplay.id .. "> (character_displa) provides. The effect is <" .. effectView._effectID .. ".".. effectView._frontAndBack .. ">")
        end
        self._actorView:attachNodeToBone(dummy, effectView, isBackSide, isFlipWithActor)
    end

end

return QUIWidgetSkeletonActor
