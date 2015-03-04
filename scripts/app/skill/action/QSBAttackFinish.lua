--[[
    Class name QSBAttackFinish
    Create by julian 
--]]

local QSBAction = import(".QSBAction")
local QSBAttackFinish = class("QSBAttackFinish", QSBAction)

function QSBAttackFinish:_execute(dt)
	if self._attacker ~= nil then
		self._attacker:onAttackFinished()
	end
	self:finished()
end

return QSBAttackFinish