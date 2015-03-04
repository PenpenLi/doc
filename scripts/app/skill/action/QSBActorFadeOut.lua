--[[
    Class name QSBActorFadeOut
    Create by julian 
--]]


local QSBAction = import(".QSBAction")
local QSBActorFadeOut = class("QSBActorFadeOut", QSBAction)

local QActor = import("...models.QActor")

function QSBActorFadeOut:_execute(dt)
	if self._isExecuting == true then
		return
	end

	local actor = self._attacker
	if self._options.is_target == true then
		actor = self._target
	end

	if actor == nil then
		return self:finished()
	end

	local actorView = app.scene:getActorViewFromModel(actor)
	if actorView == nil then
		return self:finished()
	end

	-- 初始状态记录
	self._original_opacity = actorView:getOpacity()
	self._actorView = actorView

	local duration = self._options.duration or 0.25

	local arr = CCArray:create()
    arr:addObject(CCFadeOut:create(duration))
    arr:addObject(CCCallFunc:create(function()
        self:finished()
    end))
    actorView:getSkeletonActor():runAction(CCSequence:create(arr))

    self._isExecuting = true

end

function QSBActorFadeOut:_onCancel()
	self:_onRevert()
end

function QSBActorFadeOut:_onRevert()
	if self._original_opacity ~= nil and self._actorView ~= nil and self._actorView.getSkeletonActor ~= nil then
		self._actorView:getSkeletonActor():stopAllActions()
		self._actorView:getSkeletonActor():setOpacity(self._original_opacity)
		self._original_opacity = nil
		self._actorView = nil
	end
end

return QSBActorFadeOut