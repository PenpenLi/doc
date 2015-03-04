--[[
    Class name QSBBullet
    Create by julian 
--]]

local QSBAction = import(".QSBAction")
local QSBBullet = class("QSBBullet", QSBAction)

local QSkill = import("...models.QSkill")
local QBullet = import("...models.QBullet")

QSBBullet.TIME_INTERVAL = 1.0 / 30

function QSBBullet:_execute(dt)
	if self._skill:getBulletEffectID() == nil and self._options.effect_id == nil then
		self:finished()
        return
	end

    -- get targets
    if self._skill:getRangeType() == QSkill.MULTIPLE then
        self._targets = self._attacker:getMultipleTargetWithSkill(self._skill, self._target)
        if #self._targets == 0 then
            self:finished()
            return
        end
    else
        if self._target then
            self._targets = {self._target}
        else
            self._targets = {self._attacker:getTarget()}
        end
    end

    -- create bullet
    local bullet = QBullet.new(self._attacker, self._targets, self._skill, self._options)
    app.battle:addBullet(bullet)

    self:finished()
end

function QSBBullet:_onCancel()

end

return QSBBullet