--[[
    Class name QSBSummonMonsters
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBSummonMonsters = class("QSBSummonMonsters", QSBAction)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QSBSummonMonsters:_execute(dt)
    local wave = self:getOptions().wave or -1
	
    if type(wave) ~= "number" or wave >= 0 then
        wave = -1
    end

    app.battle:summonMonsters(wave, self._attacker)

    self:finished()
end

return QSBSummonMonsters