--[[
    Class name QSBTeleportToTargetBehind
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBTeleportToTargetBehind = class("QSBTeleportToTargetBehind", QSBAction)

function QSBTeleportToTargetBehind:_execute(dt)
	local target = self._attacker:getTarget()
	local view = app.scene:getActorViewFromModel(target)
	if self._attacker ~= nil and target ~= nil and self._attacker:isDead() == false and target:isDead() == false and view ~= nil then
		local pos = clone(target:getPosition())
	    local distance = (self._attacker:getRect().size.width + target:getRect().size.width) / 2
		if view:getDirection() == view.DIRECTION_RIGHT then
			pos.x = pos.x - distance
		else
			pos.x = pos.x + distance
		end
		app.grid:setActorTo(self._attacker, pos, true)

		if self._options.verify_flip then
			app.scene:getActorViewFromModel(self._attacker):_verifyFlip()
		end
	end
	self:finished()
end

return QSBTeleportToTargetBehind
