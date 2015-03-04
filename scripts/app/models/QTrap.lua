
local QModelBase = import(".QModelBase")
local QTrap = class("QTrap", QModelBase)

local QStaticDatabase = import("..controllers.QStaticDatabase")

-- trap damage type
QTrap.ATTACK = "attack"
QTrap.TREAT = "treat"

-- type damage target
QTrap.ENEMY = "enemy"
QTrap.TEAMMATE = "teammate"
QTrap.EVERYONE = "everyone"

QTrap.TRIGGER = "TRIGGER_TRAP"

-- 定义属性
QTrap.schema = clone(cc.mvc.ModelBase.schema)
QTrap.schema["name"]            = {"string", ""}
QTrap.schema["duration"]        = {"number", 0}
QTrap.schema["interval"]        = {"number", 0}
QTrap.schema["range"]           = {"number", 0}
QTrap.schema["damage"]          = {"number", 0}
QTrap.schema["damage_type"]     = {"string", ""}
QTrap.schema["damage_target"]   = {"string", ""}
QTrap.schema["influence_with_attack"]               = {"boolean", false}
QTrap.schema["influence_coefficient"]               = {"number", 1}
QTrap.schema["effect_type_1"]  = {"string", ""}
QTrap.schema["effect_type_2"]  = {"string", ""}
QTrap.schema["effect_type_3"]  = {"string", ""}
QTrap.schema["effect_value_1"] = {"number", 0}
QTrap.schema["effect_value_2"] = {"number", 0}
QTrap.schema["effect_value_3"] = {"number", 0}
QTrap.schema["start_effect"]    = {"string", ""}
QTrap.schema["execute_effect"]  = {"string", ""}
QTrap.schema["area_effect"]     = {"string", ""}
QTrap.schema["finish_effect"]   = {"string", ""}
QTrap.schema["status"]          = {"string", ""}
QTrap.schema["offset_x"]        = {"number", 0}
QTrap.schema["offset_y"]        = {"number", 0}
QTrap.schema["y_ratio"]        = {"number", 2}

function QTrap:ctor(id, position, actor)

    assert(position ~= nil, "invalid position to initailze a trap.")
    self._position = clone(position)

    local trapInfo = QStaticDatabase.sharedDatabase():getTrapByID(id)
    assert(trapInfo ~= nil, "trap id: " .. id .. " does not exist!")

    assert(actor ~= nil, "invalid actor initialize a trap.")
    self._actor = actor

    QTrap.super.ctor(self, trapInfo)

    self.effects = {}
    -- table.merge(self.effects, clone(global.additions))

    self:_setEffect(self:get("effect_type_1"), self:get("effect_value_1"))
    self:_setEffect(self:get("effect_type_2"), self:get("effect_value_2"))
    self:_setEffect(self:get("effect_type_3"), self:get("effect_value_3"))

    self._duration = self:get("duration")
    self._interval = self:get("interval")
    self._executeCount = math.floor(self._duration / self._interval)
    self._status   = self:get("status")
    assert(self._executeCount > 0, "this trap could not be trigger any more, please check duration and interval value.")

    self.effects.status = self._status
    self.effects.influence_with_attack = self:get("influence_with_attack")
    self.effects.influence_coefficient = self:get("influence_coefficient")

    local damage = self:get("damage")
    if self.effects.influence_with_attack then
        damage = damage + (self.effects.influence_coefficient + 1) * self._actor:getAttack()
    end
    self._damageEachTime = math.floor(damage / self._executeCount)
    -- PVP系数影响
    if app.battle:isPVPMode() then
        if self:getDamageType() == QTrap.ATTACK then
            if app.battle:isInArena() then
                if QBuff.ARENA_FINAL_DAMAGE_COEFFICIENT == nil then
                    local coefficient = 1
                    local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
                    if globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT ~= nil and globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT.value ~= nil then
                        coefficient = globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT.value 
                    end
                    QBuff.ARENA_FINAL_DAMAGE_COEFFICIENT = coefficient
                end
                self._damageEachTime = self._damageEachTime * QBuff.ARENA_FINAL_DAMAGE_COEFFICIENT
            elseif app.battle:isInSunwell() then
                if QBuff.SUNWELL_FINAL_DAMAGE_COEFFICIENT == nil then
                    local coefficient = 1
                    local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
                    if globalConfig.SUNWELL_FINAL_DAMAGE_COEFFICIENT ~= nil and globalConfig.SUNWELL_FINAL_DAMAGE_COEFFICIENT.value ~= nil then
                        coefficient = globalConfig.SUNWELL_FINAL_DAMAGE_COEFFICIENT.value 
                    end
                    QBuff.SUNWELL_FINAL_DAMAGE_COEFFICIENT = coefficient
                end
                self._damageEachTime = self._damageEachTime * QBuff.SUNWELL_FINAL_DAMAGE_COEFFICIENT
            end
        elseif self:getDamageType() == QTrap.TREAT then
            if app.battle:isInArena() then
                if QBuff.ARENA_TREAT_COEFFICIENT == nil then
                    local coefficient = 1
                    local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
                    if globalConfig.ARENA_TREAT_COEFFICIENT ~= nil and globalConfig.ARENA_TREAT_COEFFICIENT.value ~= nil then
                        coefficient = globalConfig.ARENA_TREAT_COEFFICIENT.value 
                    end
                    QBuff.ARENA_TREAT_COEFFICIENT = coefficient
                end
                self._damageEachTime = self._damageEachTime * QBuff.ARENA_TREAT_COEFFICIENT
            elseif app.battle:isInSunwell() then
                if QBuff.SUNWELL_TREAT_COEFFICIENT == nil then
                    local coefficient = 1
                    local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
                    if globalConfig.SUNWELL_TREAT_COEFFICIENT ~= nil and globalConfig.SUNWELL_TREAT_COEFFICIENT.value ~= nil then
                        coefficient = globalConfig.SUNWELL_TREAT_COEFFICIENT.value 
                    end
                    QBuff.SUNWELL_TREAT_COEFFICIENT = coefficient
                end
                self._damageEachTime = self._damageEachTime * QBuff.SUNWELL_TREAT_COEFFICIENT
            end
        end
    end

    self._position.x = self._position.x + self:get("offset_x")
    self._position.y = self._position.y + self:get("offset_y")
end

function QTrap:_setEffect(prop, value)
    if prop ~= nil and string.len(prop) > 0 then
        self.effects[prop] = value
    end
end

function QTrap:getDuration()
    return self._duration
end

function QTrap:getRange()
    return self:get("range") * global.pixel_per_unit
end

function QTrap:getDamageType()
    return self:get("damage_type")
end

function QTrap:getDamageTarget()
    return self:get("damage_target")
end

function QTrap:getStartEffectId()
    local effectId = self:get("start_effect")
    if string.len(effectId) == 0 then
        return nil
    end
    return effectId
end

function QTrap:getExecuteEffectId()
    local effectId = self:get("execute_effect")
    if string.len(effectId) == 0 then
        return nil
    end
    return effectId
end

function QTrap:getAreaEffectId()
    local effectId = self:get("area_effect")
    if string.len(effectId) == 0 then
        return nil
    end
    return effectId
end

function QTrap:getFinishEffectId()
    local effectId = self:get("finish_effect")
    if string.len(effectId) == 0 then
        return nil
    end
    return effectId
end

function QTrap:getPosition()
    return self._position
end

function QTrap:getDamageEachTime()
    return self._damageEachTime
end

function QTrap:start()
    self._passedTime = 0 
    self._lastTriggerTime = 0
end

function QTrap:visit(dt)
    self._passedTime = self._passedTime + dt
    if (self._passedTime - self._lastTriggerTime) > self._interval then
        self:dispatchEvent({name = QTrap.TRIGGER, trap = self})
        self._lastTriggerTime = self._interval + self._lastTriggerTime
    end
end

function QTrap:isEnded()
    return (self._passedTime > self._duration)
end

function QTrap:getStatus()
	return self._trap
end

function QTrap:getYRatio()
    return self:get("y_ratio")
end

return QTrap