
local QSBAction = import(".QSBAction")
local QSBShowActor = class("QSBShowActor", QSBAction)

function QSBShowActor:_execute(dt)
	if app.battle:isPVPMode() and self._attacker:getType() == ACTOR_TYPES.NPC then
		self:finished()
		return
	end

	local actor = nil
	if self._options.is_attacker == true then
		actor = self._attacker
	else
		actor = self._target
	end

	if self._options.turn_on == true then
		app.scene:visibleBackgroundLayer(true, actor, self._options.time)
		self._director:setVisibleSceneBlackLayer(true, actor)
	else
		app.scene:visibleBackgroundLayer(false, actor, self._options.time)
		self._director:setVisibleSceneBlackLayer(false)
	end
	self._executed = true
	self:finished()
end

function QSBShowActor:_onCancel()
	self:_onRevert()
end

function QSBShowActor:_onRevert()
	if not self._executed then
		return
	end

	self._executed = nil
	local actor = nil
	if self._options.is_attacker == true then
		actor = self._attacker
	else
		actor = self._target
	end
	if self._options.turn_on == true then
		app.scene:visibleBackgroundLayer(false, actor, 0)
		self._director:setVisibleSceneBlackLayer(false)
	end
end

return QSBShowActor