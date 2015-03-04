--[[
    Class name QSBImmuneCharge
    Create by julian 
--]]

local QSBAction = import(".QSBAction")
local QSBImmuneCharge = class("QSBGhost", QSBAction)

function QSBImmuneCharge:_execute(dt)
    local actor = self._attacker
    local view = app.scene:getActorViewFromModel(actor)

    if self._options.enter then
        actor._immune_charge = true
        view:setVisible(false)
    else
        actor._immune_charge = false
        view:setVisible(true)
    end

    self:finished()
end

function QSBImmuneCharge:_onCancel()
    local actor = self._attacker
    local view = app.scene:getActorViewFromModel(actor)
    actor._immune_charge = false
    view:setVisible(true)
end

function QSBImmuneCharge:_onRevert()
    local actor = self._attacker
    local view = app.scene:getActorViewFromModel(actor)
    actor._immune_charge = false
    view:setVisible(true)
end

return QSBImmuneCharge