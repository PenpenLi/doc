--[[
    Class name QSBRemoveBuff
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBRemoveBuff = class("QSBRemoveBuff", QSBAction)

local QActor = import("...models.QActor")

function QSBRemoveBuff:_execute(dt)
	local actor = self._attacker
	if self._options.is_target == true then
		actor = self._target
	end

	if actor ~= nil and self._options.buff_id ~= nil then
		actor:removeBuffByID(self._options.buff_id)
		self._director:removeBuffId(self._options.buff_id, actor)
	end
	self:finished()
end

return QSBRemoveBuff