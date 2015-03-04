--[[
    Class name QSBLockTarget
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBLockTarget = class("QSBLockTarget", QSBAction)

local QActor = import("...models.QActor")

function QSBLockTarget:_execute(dt)
	if self._options.is_lock_target == true then
		self._attacker:lockTarget()
	else
		self._attacker:unlockTarget()
	end
    self:finished()
end

function QSBLockTarget:_onCancel()
	self:_onRevert()
end

function QSBLockTarget:_onRevert()
	if self._options.is_lock_target == true then
		self._attacker:unlockTarget()
	else
		self._attacker:lockTarget()
	end
end

return QSBLockTarget