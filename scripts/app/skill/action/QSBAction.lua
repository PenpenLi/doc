--[[
    Class name QSBAction
    Create by julian 
--]]


local QSBNode = import("..QSBNode")
local QSBAction = class("QSBAction", QSBNode)

function QSBAction:ctor(director, attacker, target, skill, options)
    QSBAction.super.ctor(self, director, attacker, target, skill, options)
end

function QSBAction:isAffectedByHaste()
	local skill = self._skill
	return skill:isTalentSkill() or skill:isAffectedByHaste()
end

return QSBAction