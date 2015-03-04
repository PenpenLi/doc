--[[
    Class name QSBPlayAnimation
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBPlayAnimation = class("QSBPlayAnimation", QSBAction)

local QActor = import("...models.QActor")

function QSBPlayAnimation:_execute(dt)
	if self._isAnimationPlaying == true then
		return
	end

	local animations = self:_getAttackAnimationNames()
	if table.nums(animations) == 0 then
		self:finished()
		return
	end

	self._attacker:playSkillAnimation(animations, self._options.is_loop)

	if self._options.is_loop ~= true then
		local count = table.nums(animations)
		self._endAnimationName = animations[1]
		self._isAnimationPlaying = true

		self._eventListener = cc.EventProxy.new(self._attacker)
		self._eventListener:addEventListener(QActor.ANIMATION_ENDED, handler(self, self._onAnimationEnded))

    	local haste = self._attacker:getMaxHaste()
	    if self:isAffectedByHaste() == false then
	        haste = 0.0
	    end

		local actorView = app.scene:getActorViewFromModel(self._attacker)
		actorView:setAnimationScale(1.0 + haste, self)
	else
		self:finished()
	end
end

function QSBPlayAnimation:_getAttackAnimationNames()
    local name = (self._options.animation or self._skill:getActorAttackAnimation())
    local animations = {}
    local actorView = app.scene:getActorViewFromModel(self._attacker)
    if actorView ~= nil and string.len(name) ~= 0 then
    	if actorView:getSkeletonActor():canPlayAnimation(name) == true then
    		table.insert(animations, name)
		end
		-- if self._options.is_loop ~= true then
		-- 	table.insert(animations, ANIMATION.STAND)
		-- end
    end

    return animations
end

function QSBPlayAnimation:_onAnimationEnded(event)
	if event.animationName == self._endAnimationName then
		self:finished()
		self._eventListener:removeAllEventListeners()

		local actorView = app.scene:getActorViewFromModel(self._attacker)
		actorView:setAnimationScale(1.0, self)
	end
end

function QSBPlayAnimation:_onCancel()
    if self._eventListener ~= nil then
		self._eventListener:removeAllEventListeners()
	end

	local actorView = app.scene:getActorViewFromModel(self._attacker)
	if self._options.reload_on_cancel then
		actorView:reloadSkeleton()
		actorView:getSkeletonActor():resetActorWithAnimation(ANIMATION.STAND, true)
	end
	actorView:setAnimationScale(1.0, self)
end

function QSBPlayAnimation:_onRevert()
	local actorView = app.scene:getActorViewFromModel(self._attacker)
	if self._options.reload_on_cancel then
		actorView:reloadSkeleton()
		actorView:getSkeletonActor():resetActorWithAnimation(ANIMATION.STAND, true)
	end
	actorView:setAnimationScale(1.0, self)
end

return QSBPlayAnimation