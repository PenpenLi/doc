--[[
    Class name QSBApplyBuff
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBApplyBuff = class("QSBApplyBuff", QSBAction)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QSBApplyBuff:_execute(dt)
	local actor = self._attacker
	if self._options.is_target == true then
		actor = self._target
	end

	if actor ~= nil and self._options.buff_id ~= nil then
		local buffInfo = QStaticDatabase.sharedDatabase():getBuffByID(self._options.buff_id)
	    if buffInfo == nil then
	        printError("buff id: %s does not exist!", self._options.buff_id)
	    else
	    	actor:applyBuff(self._options.buff_id, self._attacker)
	    	self._director:addBuffId(self._options.buff_id, actor)
	    end
	end
	self:finished()
end

return QSBApplyBuff