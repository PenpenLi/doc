--[[
    Class name QSBHitTarget
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBHitTarget = class("QSBHitTarget", QSBAction)

local QActor = import("...models.QActor")

function QSBHitTarget:_execute(dt)
	local target = self._target
	if self._options.current_target then
		self._attacker:getTarget() 
	end
	
	if self._options.is_range_hit == true then
		local is_zone_follow = self._skill:isZoneFollow()
		if is_zone_follow and target then
			self._attacker:onHit(self._skill, target, target:getPosition(), self._options.delay_per_hit)
		else
			self._attacker:onHit(self._skill, target, self._director:getTargetPosition(), self._options.delay_per_hit)
		end
	else
		self._attacker:onHit(self._skill, target, nil, self._options.delay_per_hit)
	end

	self:finished()
end

return QSBHitTarget