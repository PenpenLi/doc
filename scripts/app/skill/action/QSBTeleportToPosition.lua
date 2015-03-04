--[[
    Class name QSBTeleportToPosition
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBTeleportToPosition = class("QSBTeleportToPosition", QSBAction)

local QActor = import("...models.QActor")

function QSBTeleportToPosition:ctor(director, attacker, target, skill, options )
    QSBTeleportToPosition.super.ctor(self, director, attacker, target, skill, options)
    
    self._dragPosition = attacker:getDragPosition()
end

function QSBTeleportToPosition:_execute(dt)
	if self._attacker ~= nil then
		local targetPosition = self._dragPosition
		if targetPosition.x < BATTLE_AREA.left then targetPosition.x = BATTLE_AREA.left end
	    if targetPosition.x > BATTLE_AREA.right then targetPosition.x = BATTLE_AREA.right end
	    if targetPosition.y < BATTLE_AREA.bottom then targetPosition.y = BATTLE_AREA.bottom end
	    if targetPosition.y > BATTLE_AREA.top then targetPosition.y = BATTLE_AREA.top end
		app.grid:setActorTo(self._attacker, targetPosition, true)
	end
	self:finished()
end

return QSBTeleportToPosition
