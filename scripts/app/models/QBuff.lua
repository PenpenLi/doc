--[[
    英雄的BUFF
]]

local QModelBase = import(".QModelBase")
local QBuff = class("QBuff", QModelBase)

local QStaticDatabase = import("..controllers.QStaticDatabase")

QBuff.TRIGGER = "TRIGGER_BUFF"

-- aura buff
QBuff.ENEMY = "enemy"
QBuff.TEAMMATE = "teammate"
QBuff.TEAMMATE_AND_SELF = "teammate_and_self"

-- hit buff target type
QBuff.BUFF_SELF = "self"
QBuff.BUFF_TARGET = "target"

-- buff trigger type
QBuff.TRIGGER_TYPE_BUFF = "buff"
QBuff.TRIGGER_TYPE_ATTACK = "attack"
QBuff.TRIGGER_TYPE_COMBO = "combo"
QBuff.TRIGGER_TYPE_CD_REDUCE = "cd_reduce"

-- buff trigger condition
QBuff.TRIGGER_CONDITION_HIT = "hit"
QBuff.TRIGGER_CONDITION_DODGE = "dodge"
QBuff.TRIGGER_CONDITION_BLOCK = "block"
QBuff.TRIGGER_CONDITION_MISS = "miss"
QBuff.TRIGGER_CONDITION_SKILL = "skill"
QBuff.TRIGGER_CONDITION_SKILL_CRITICAL = "skill_critical"
QBuff.TRIGGER_CONDITION_SKILL_ATTACK = "skill_attack"
QBuff.TRIGGER_CONDITION_SKILL_ATTACK_CRITICAL = "skill_attack_critical"
QBuff.TRIGGER_CONDITION_SKILL_TREAT = "skill_treat"
QBuff.TRIGGER_CONDITION_SKILL_TREAT_CRITICAL = "skill_treat_critical"
-- QBuff.TRIGGER_CONDITION_DRAG = "drag"
-- QBuff.TRIGGER_CONDITION_DRAG_ATTACK = "drag_attack"
QBuff.TRIGGER_CONDITION_TICK = "tick"

QBuff.IMMUNE_ALL = "all"

-- buff trigger target
QBuff.TRIGGER_TARGET_SELF = "self"
QBuff.TRIGGER_TARGET_TEAMMATE = "teammate"
QBuff.TRIGGER_TARGET_TEAMMATE_AND_SELF = "teammate_and_self"
QBuff.TRIGGER_TARGET_ENEMY = "enemy"

-- 定义属性
QBuff.schema = clone(cc.mvc.ModelBase.schema)
QBuff.schema["name"]                                = {"string"} -- 字符串类型，没有默认值
QBuff.schema["is_aura"]                             = {"boolean", false} -- 是否是光环
QBuff.schema["aura_radius"]                         = {"number", 30} -- 光环半径，24pixel为一个单位
QBuff.schema["aura_target_type"]                    = {"string", "teammate_and_self"} -- 光环影响的对象
QBuff.schema["aura_target_effece_id"]               = {"string", ""} -- 光环影响到的对象身上的对象（受到interval_time的ticking的影响）
QBuff.schema["duration"]                            = {"number", 0}
QBuff.schema["interval_time"]                       = {"number", 0}
QBuff.schema["influence_with_attack"]               = {"boolean", false}
QBuff.schema["influence_coefficient"]               = {"number", 0}
QBuff.schema["effect_type_1"]                       = {"string", ""}
QBuff.schema["effect_type_2"]                       = {"string", ""}
QBuff.schema["effect_type_3"]                       = {"string", ""}
QBuff.schema["effect_value_1"]                      = {"number", 0}
QBuff.schema["effect_value_2"]                      = {"number", 0}
QBuff.schema["effect_value_3"]                      = {"number", 0}
QBuff.schema["effect_condition"]                    = {"string", ""}
QBuff.schema["time_stop"]                           = {"boolean", false}
QBuff.schema["can_control_move"]                    = {"boolean", true}
QBuff.schema["can_use_skill"]                       = {"boolean", true}
QBuff.schema["can_be_removed_with_skill"]           = {"boolean", false}
QBuff.schema["can_be_removed_with_hit"]             = {"boolean", false}
QBuff.schema["replace_character"]                   = {"number", -1}
QBuff.schema["replace_ai"]                          = {"string", ""}
QBuff.schema["color"]                               = {"string", "255,255,255"}
QBuff.schema["begin_effect_id"]                     = {"string", ""}
QBuff.schema["effect_id"]                           = {"string", ""}
QBuff.schema["finish_effect_id"]                    = {"string", ""}
QBuff.schema["status"]                              = {"string", ""}
QBuff.schema["immune_status"]                       = {"string", ""}
QBuff.schema["override_group"]                      = {"string", ""}
QBuff.schema["level"]                               = {"number", 0}
QBuff.schema["trigger_condition"]                   = {"string", ""}
QBuff.schema["trigger_probability"]                 = {"number", 1}
QBuff.schema["trigger_target"]                      = {"string", "self"}
QBuff.schema["trigger_cd"]                          = {"number", 0}
QBuff.schema["trigger_type"]                        = {"string", ""}
QBuff.schema["trigger_buff_id"]                     = {"string", ""}
QBuff.schema["trigger_buff_target_type"]            = {"string", ""}
QBuff.schema["trigger_skill_id"]                    = {"string", ""}
QBuff.schema["trigger_skill_as_current"]            = {"boolean", false}
QBuff.schema["trigger_skill_inherit_percent"]       = {"number", 0}
QBuff.schema["trigger_combo_points"]                = {"number", 0}
QBuff.schema["absorb_damage_value"]                 = {"number", 0}
QBuff.schema["scale_percent"]                       = {"number", 0}

function QBuff:ctor(id, actor, attacker)
    local buffInfo = QStaticDatabase.sharedDatabase():getBuffByID(id)
    assert(buffInfo ~= nil, "buff id: " .. id .. " does not exist!")

    QBuff.super.ctor(self, buffInfo)

    self._passedTime = 0 
    self._lastTriggerTime = nil
    self._immuned = false
    self._actor = actor
    self._attacker = attacker
    self._attackerAttackValue = attacker and attacker:getAttack() or 0
    self._aura_affectees = {}

    self.effects = {
        -- 触发效果(一定的时间间隔内触发一次)
        interval_time = 0, --间隔时间
        physical_damage_value = 0, -- 物理伤害数值
        magic_damage_value = 0, -- 法术伤害数值
        treat_damage_value = 0, -- 治疗伤害数值
        -- 吸收伤害效果
        absorb_damage_value = 0, -- 吸收物理和法术伤害值
        -- 影响触发效果和吸收伤害效果的参数
        influence_with_attack = false, -- 是否受攻击力影响
        -- 特殊控制状态
        time_stop = false, -- 动作立即完全静止
        can_control_move = true, -- 玩家和AI能够控制移动
        can_use_skill = true, -- 能够使用技能
        can_be_removed_with_skill = false, -- 此buff能够被自己释放的技能打断
        can_be_removed_with_hit = false, -- 此buff受攻击时能够被打断
        replace_character = -1, -- 变身
        replace_ai = "", -- 变行为
        -- 状态已经状态免疫
        status = "", -- 该buff是什么状态
        immune_status = {}, -- 该buff能免疫什么状态
        override_group = "",
        level = 0,
    }
    -- 用于压入属性堆栈的effect
    self._effects = {}

    -- table.merge(self.effects, clone(global.additions))

    self:_setEffect(self:get("effect_type_1"), self:get("effect_value_1"))
    self:_setEffect(self:get("effect_type_2"), self:get("effect_value_2"))
    self:_setEffect(self:get("effect_type_3"), self:get("effect_value_3"))

    self.effects.interval_time = self:get("interval_time")
    self.effects.influence_with_attack = self:get("influence_with_attack")
    self.effects.influence_coefficient = self:get("influence_coefficient")
    self.effects.time_stop = self:get("time_stop")
    self.effects.can_control_move = self:get("can_control_move")
    self.effects.can_use_skill = self:get("can_use_skill")
    self.effects.can_be_removed_with_skill = self:get("can_be_removed_with_skill")
    self.effects.can_be_removed_with_hit = self:get("can_be_removed_with_hit")
    self.effects.replace_character = self:get("replace_character")
    self.effects.replace_ai = self:get("replace_ai")
    self.effects.status = self:get("status")
    self.effects.immune_status = string.split(self:get("immune_status"), ";")
    self.effects.override_group = self:get("override_group")
    self.effects.level = self:get("level")
    self.effects.absorb_damage_value = self:get("absorb_damage_value")
    self.effects.effect_condition = self:get("effect_condition")
    self.effects.scale_percent = self:get("scale_percent")

    if self.effects.absorb_damage_value < 0 then
        self.effects.absorb_damage_value = 0
    end

    if self.effects.absorb_damage_value > 0 then
        self._isAbsorbDamage = true
    end

    if self.effects.interval_time > 0 then
        self._executeCount = math.floor(self:get("duration") / self.effects.interval_time)
        self._currentExecute = 0
    end

    -- PVP系数影响
    if app.battle:isPVPMode() then
        if QBuff.ARENA_FINAL_DAMAGE_COEFFICIENT == nil then
            local coefficient = 1
            local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
            if globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT ~= nil and globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT.value ~= nil then
                coefficient = globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT.value 
            end
            QBuff.ARENA_FINAL_DAMAGE_COEFFICIENT = coefficient
        end
        if QBuff.ARENA_TREAT_COEFFICIENT == nil then
            local coefficient = 1
            local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
            if globalConfig.ARENA_TREAT_COEFFICIENT ~= nil and globalConfig.ARENA_TREAT_COEFFICIENT.value ~= nil then
                coefficient = globalConfig.ARENA_TREAT_COEFFICIENT.value 
            end
            QBuff.ARENA_TREAT_COEFFICIENT = coefficient
        end
    end

    local attackValue = self:getAttackerAttackValue()
    local coefficient = self.effects.influence_coefficient + 1
    local combo_points_coefficient = (not attacker or not attacker:getCurrentSkill() or not attacker:getCurrentSkill():isNeedComboPoints()) and 1 or attacker:getComboPointsCoefficient()
    -- TODO 如果是光环的话,物理法术的易伤和减免以及治疗的被治疗效果都应该取自受到影响的各个角色的QActor，而不是统一取自光环owner的QActor
    -- 物理DOT
    self._physical_damage_value = self.effects.physical_damage_value
    if self._physical_damage_value > 0 then 
        if self.effects.influence_with_attack == true then
            self._physical_damage_value = self._physical_damage_value + (attackValue * coefficient)
        end
        self._physical_damage_value = self._physical_damage_value * --[[(1 - self._actor:getArmorPhysicalReduce()) *]] (1 + self._actor:getPhysicalDamagePercentUnderAttack())
        if app.battle:isPVPMode() then
            self._physical_damage_value = self._physical_damage_value * QBuff.ARENA_FINAL_DAMAGE_COEFFICIENT
        end
    end
    self._physical_damage_value = self._physical_damage_value * combo_points_coefficient
    -- 魔法DOT
    self._magic_damage_value = self.effects.magic_damage_value
    if self._magic_damage_value > 0 then
        if self.effects.influence_with_attack == true then
            self._magic_damage_value = self._magic_damage_value + (attackValue * coefficient)
        end
        self._magic_damage_value = self._magic_damage_value * --[[(1 - self._actor:getArmorMagicReduce()) *]] (1 + self._actor:getMagicDamagePercentUnderAttack())
        if app.battle:isPVPMode() then
            self._magic_damage_value = self._magic_damage_value * QBuff.ARENA_FINAL_DAMAGE_COEFFICIENT
        end
    end
    self._magic_damage_value = self._magic_damage_value * combo_points_coefficient
    -- 魔法HOT
    self._magic_treat_value = self.effects.treat_damage_value
    if self._magic_treat_value > 0 then
        if self.effects.influence_with_attack == true then
            self._magic_treat_value = self._magic_treat_value + (attackValue * 2 * coefficient)
        end
        self._magic_treat_value = self._magic_treat_value * (1 + self._actor:getMagicTreatPercentUnderAttack())
        if app.battle:isPVPMode() then
            self._magic_treat_value = self._magic_treat_value * QBuff.ARENA_TREAT_COEFFICIENT
        end
    end
    self._magic_treat_value = self._magic_treat_value * combo_points_coefficient
    -- 吸收伤害
    self._absorb_damage_value_left = self.effects.absorb_damage_value
    if self._absorb_damage_value_left > 0 then
        if self.effects.influence_with_attack == true then
            self._absorb_damage_value_left = self._absorb_damage_value_left + (attackValue * 2 * coefficient)
        end
        self._absorb_damage_value_left = self._absorb_damage_value_left * (1 + self._actor:getMagicTreatPercentUnderAttack())
        if app.battle:isPVPMode() then
            self._absorb_damage_value_left = self._absorb_damage_value_left * QBuff.ARENA_TREAT_COEFFICIENT
        end
    end
    self._absorb_damage_value_left = self._absorb_damage_value_left * combo_points_coefficient

    if self._physical_damage_value > 0 or self._magic_damage_value > 0 or self._magic_treat_value > 0 or self._absorb_damage_value_left > 0 then
        self._combo_points_coefficient_duration = 1
    else
        self._combo_points_coefficient_duration = combo_points_coefficient
    end

    self._crit = 0
    self._critDamage = 1.0
    if attacker then
        self._crit = attacker:getCrit()
        self._critDamage = attacker:getCritDamage()
    end

    self._affectingAuraActors = {}
end

function QBuff:_setEffectValueToBoolean(key)
    if key == nil or self.effects[key] == nil then
        return
    end

    if type(self.effects[key]) == "boolean" then
        return
    end

    if self.effects[key] == 0 then
        self.effects[key] = false
    else
        self.effects[key] = true
    end
end

function QBuff:getDuration()
    return self:get("duration") * self._combo_points_coefficient_duration
end

function QBuff:getExecuteCount()
    return self._executeCount
end

function QBuff:getCurrentExecuteCount()
    return self._currentExecute
end

function QBuff:getBeginEffectID()
    local effectID = self:get("begin_effect_id")
    if string.len(effectID) == 0 then
        effectID = nil
    end
    return effectID
end

function QBuff:getEffectID()
    local effectID = self:get("effect_id")
    if string.len(effectID) == 0 then
        effectID = nil
    end
    return effectID
end

function QBuff:getFinishEffectID()
    local effectID = self:get("finish_effect_id")
    if string.len(effectID) == 0 then
        effectID = nil
    end
    return effectID
end

function QBuff:getColor()
    local rgb = string.split(self:get("color"), ",")
    if table.nums(rgb) ~= 3 then return nil end

    return ccc3(tonumber(rgb[1]), tonumber(rgb[2]), tonumber(rgb[3]))
end

function QBuff:doTrigger(actor, target)
    local probability = self:getTriggerProbability()
    if probability >= math.random(1, 100) then
        if self:getTriggerType() == QBuff.TRIGGER_TYPE_COMBO then
            local combo_points = self:getTriggerComboPoints()
            actor:gainComboPoints(combo_points)
        end

        self:coolDown()
    end
end

function QBuff:isReady()
    local cd = self:get("trigger_cd")
    if cd <= 0 then
        return true
    end

    local lastTimeTriggered = self._lastTimeTriggered
    return not lastTimeTriggered or q.time() - lastTimeTriggered >= cd 
end

function QBuff:coolDown()
    local cd = self:get("trigger_cd")
    if cd <= 0 then
        return
    end

    self._lastTimeTriggered = q.time()
end

function QBuff:visit(dt)
    self._passedTime = self._passedTime + dt

    if self:isImmuned() then
        return
    end

    -- TICK TRIGGER
    if self:getTriggerCondition() == QBuff.TRIGGER_CONDITION_TICK and self:isReady() then
        self:doTrigger(self:getBuffOwner(), self:getBuffOwner():getTarget())
    end

    -- body enlarge
    local scale = self:get("scale_percent")
    if scale ~= 0 then
        local view = app.scene:getActorViewFromModel(self:getBuffOwner())
        local duration = self:getDuration()
        local half_duration = duration / 2
        local scale_time = half_duration > 0.5 and 0.5 or half_duration
        if self._passedTime < scale_time then
            view:setScale(math.sampler(1.0, 1.0 + scale, self._passedTime / scale_time))
        elseif self._passedTime > duration - scale_time then
            view:setScale(math.sampler(1.0, 1.0 + scale, (duration - self._passedTime) / scale_time))
        else
            view:setScale(1.0 + scale)
        end
    end

    -- buff and aura property effect
    if next(self._effects) then
        local condition_met = self:isConditionMet()
        if self:isAura() then
            local buffOwner = self._actor
            local targetType = self:getAuraTargetType()
            if targetType == QBuff.TRIGGER_TARGET_ENEMY then
                local enemies = app.battle:getMyEnemies(buffOwner)
                for _, actor in ipairs(enemies) do
                    if not actor:isDead() then
                        local affecting = self._affectingAuraActors[actor]
                        if condition_met and self:isAuraAffectActor(actor) then
                            if not affecting then
                                for property_name, value in pairs(self._effects) do
                                    actor:insertPropertyValue(property_name, self, "+", value)
                                end
                                self._affectingAuraActors[actor] = true
                            end
                        else
                            if affecting then
                                for property_name, value in pairs(self._effects) do
                                    actor:removePropertyValue(property_name, self)
                                end
                                self._affectingAuraActors[actor] = nil
                            end
                        end
                    end
                end
            elseif targetType == QBuff.TRIGGER_TARGET_TEAMMATE_AND_SELF then
                local mates = app.battle:getMyTeammates(buffOwner, true)
                for _, actor in ipairs(mates) do 
                    if not actor:isDead() then
                        local affecting = self._affectingAuraActors[actor]
                        if condition_met and self:isAuraAffectActor(actor) then
                            if not affecting then
                                for property_name, value in pairs(self._effects) do
                                    actor:insertPropertyValue(property_name, self, "+", value)
                                end
                                self._affectingAuraActors[actor] = true
                            end
                        else
                            if affecting then
                                for property_name, value in pairs(self._effects) do
                                    actor:removePropertyValue(property_name, self)
                                end
                                self._affectingAuraActors[actor] = nil
                            end
                        end
                    end
                end
            elseif targetType == QBuff.TRIGGER_TARGET_TEAMMATE then
                local mates = app.battle:getMyTeammates(buffOwner, false)
                for _, actor in ipairs(mates) do 
                    if not actor:isDead() then
                        local affecting = self._affectingAuraActors[actor]
                        if condition_met and self:isAuraAffectActor(actor) then
                            if not affecting then
                                for property_name, value in pairs(self._effects) do
                                    actor:insertPropertyValue(property_name, self, "+", value)
                                end
                                self._affectingAuraActors[actor] = true
                            end
                        else
                            if affecting then
                                for property_name, value in pairs(self._effects) do
                                    actor:removePropertyValue(property_name, self)
                                end
                                self._affectingAuraActors[actor] = nil
                            end
                        end
                    end
                end
            end
        end
        if not self:isAura() then
            local actor = self:getBuffOwner()
            if condition_met and not self._affectingBuffOwner then
                for property_name, value in pairs(self._effects) do
                    actor:insertPropertyValue(property_name, self, "+", value)
                end
                self._affectingBuffOwner = true
            elseif not condition_met and self._affectingBuffOwner then
                for property_name, value in pairs(self._effects) do
                    actor:removePropertyValue(property_name, self)
                end
                self._affectingBuffOwner = nil
            end
        end
    end

    if self.effects.interval_time <= 0 then
        return
    end

    -- DOT/HOT
    if self.effects.interval_time > 0 and self._currentExecute < self._executeCount then
        local haste = self:getAttacker() and self:getAttacker():getMaxHaste() or 0
        local coefficient = 1 / (1 + haste)

        if self._lastTriggerTime == nil then
            self._lastTriggerTime = 0.25 - math.random(1, 100) / 200
        end

        if (self._passedTime - self._lastTriggerTime) > self.effects.interval_time * coefficient then
            if self:isAura() then
                if self._aura_affectees then
                    for _, obj in ipairs(self._aura_affectees) do
                        obj.actor:_onBuffTrigger({name = QBuff.TRIGGER, buff = self})
                    end
                    self._aura_affectees = {}
                end

                if self._actor then
                    local buffOwner = self._actor
                    local targetType = self:getAuraTargetType()
                    if targetType == QBuff.TRIGGER_TARGET_ENEMY then
                        for _, actor in ipairs(app.battle:getMyEnemies(buffOwner)) do
                            if self:isAuraAffectActor(actor, true) then
                                -- actor:_onBuffTrigger({name = QBuff.TRIGGER, buff = self})
                                table.insert(self._aura_affectees, {actor = actor, time = self._passedTime})
                            end
                        end
                    elseif targetType == QBuff.TRIGGER_TARGET_TEAMMATE_AND_SELF then
                        for _, actor in ipairs(app.battle:getMyTeammates(buffOwner, true)) do
                            if self:isAuraAffectActor(actor, true) then
                                -- actor:_onBuffTrigger({name = QBuff.TRIGGER, buff = self})
                                table.insert(self._aura_affectees, {actor = actor, time = self._passedTime})
                            end
                        end
                    elseif targetType == QBuff.TRIGGER_TARGET_TEAMMATE then
                        for _, actor in ipairs(app.battle:getMyTeammates(buffOwner, false)) do
                            if self:isAuraAffectActor(actor, true) then
                                -- actor:_onBuffTrigger({name = QBuff.TRIGGER, buff = self})
                                table.insert(self._aura_affectees, {actor = actor, time = self._passedTime})
                            end
                        end
                    end

                    -- 错开光环HOT/DOT的起效时间
                    local standard_interval = self.effects.interval_time / #self._aura_affectees / 3
                    local start_time = 0
                    for index = #self._aura_affectees, 1, -1 do
                        local select_index = math.random(1, index)
                        local obj = self._aura_affectees[select_index]
                        self._aura_affectees[select_index] = self._aura_affectees[index]
                        self._aura_affectees[index] = obj
                        obj.time = obj.time + start_time
                        start_time = start_time + standard_interval
                    end
                end
            else
                self:dispatchEvent({name = QBuff.TRIGGER, buff = self})
            end
            self._currentExecute = self._currentExecute + 1
            self._lastTriggerTime = self.effects.interval_time * coefficient + self._lastTriggerTime
        else
            local index = #self._aura_affectees
            if index > 0 then
                local obj = self._aura_affectees[index]
                if self._passedTime >= obj.time then
                    obj.actor:_onBuffTrigger({name = QBuff.TRIGGER, buff = self})
                    self._aura_affectees[index] = nil
                end
            end
        end
    end
end

function QBuff:isEnded()
    if self._isAbsorbDamage == true then
        if self._absorb_damage_value_left <= 0 then
            if self:getMagicDamageValue() <= 0 and self:getPhysicalDamageValue() <= 0 and self:getMagicTreatValue() <= 0 then
                return true
            end
        end
    end
    return self._passedTime > self:getDuration()
end

function QBuff:onRemove()
    if self:isImmuned() then
        return
    end

    -- body enlarge
    local scale = self:get("scale_percent")
    if scale ~= 0 then
        local view = app.scene:getActorViewFromModel(self:getBuffOwner())
        view:setScale(1.0)
    end

    -- buff and aura property effect
    if self:isAura() and next(self._effects) ~= nil then
        local heroes = app.battle:getHeroes()
        local enemies = app.battle:getEnemies()
        for _, actor in ipairs(heroes) do 
            for property_name, value in pairs(self._effects) do
                actor:removePropertyValue(property_name, self)
            end
        end
        for _, actor in ipairs(enemies) do
            for property_name, value in pairs(self._effects) do
                actor:removePropertyValue(property_name, self)
            end
        end
    end
    if not self:isAura() and next(self._effects) ~= nil and self._affectingBuffOwner then
        local actor = self:getBuffOwner()
        for property_name, value in pairs(self._effects) do
            actor:removePropertyValue(property_name, self)
        end
    end

    self._affectingBuffOwner = nil
    self._affectingAuraActors = {}
end

function QBuff:_setEffect(prop, value)
    if prop ~= nil and string.len(prop) > 0 then
        self.effects[prop] = value

        if prop ~= "treat_damage_value" and prop ~= "physical_damage_value" and prop ~= "magic_damage_value" and prop ~= "absorb_damage_value" then
            self._effects[prop] = value
        end
    end
end

function QBuff:setImmuned(immuned)
    self._immuned = immuned
end

function QBuff:isImmuned()
    return self._immuned
end

function QBuff:getStatus()
    return self.effects.status
end

function QBuff:isImmuneStatus(status)
    if #self.effects.immune_status == 0 or status == nil or status == "" then
        return false
    else
        for _, immune_status in ipairs(self.effects.immune_status) do
            if immune_status == QBuff.IMMUNE_ALL or immune_status == status then
                return true
            end
        end
        return false
    end
end

function QBuff:isImmuneBuff(buff)
    local status = buff:getStatus()
    if #self.effects.immune_status == 0 or status == nil or status == "" then
        return false
    else
        for _, immune_status in ipairs(self.effects.immune_status) do
            if immune_status == QBuff.IMMUNE_ALL or immune_status == status then
                return true
            end
        end
        return false
    end
end

function QBuff:isImmuneSkill(skill)
    local status = skill:getStatus()
    if #self.effects.immune_status == 0 or status == nil or status == "" then
        return false
    else
        for _, immune_status in ipairs(self.effects.immune_status) do
            if immune_status == QBuff.IMMUNE_ALL or immune_status == status then
                return true
            end
        end
        return false
    end
end

function QBuff:isImmuneTrap(trap)
    local status = trap:getStatus()
    if #self.effects.immune_status == 0 or status == nil or status == "" then
        return false
    else
        for _, immune_status in ipairs(self.effects.immune_status) do
            if immune_status == QBuff.IMMUNE_ALL or immune_status == status then
                return true
            end
        end
        return false
    end
end

function QBuff:hasOverrideGroup()
    return self.effects.override_group ~= nil and self.effects.override_group ~= ""
end

function QBuff:canOverride(buff)
    if self.effects.override_group == "" then
        return false, false
    else 
        if self.effects.override_group ~= buff.effects.override_group then 
            return false, false
        elseif self.effects.level >= buff.effects.level then
            return true, true
        else
            return true, false
        end
    end
end

function QBuff:isAura()
    return self:get("is_aura")
end

function QBuff:getAuraRadius()
    return self:get("aura_radius")
end

function QBuff:getAuraTargetType()
    return self:get("aura_target_type")
end

function QBuff:getAuraTargetEffectID()
    return self:get("aura_target_effece_id")
end

function QBuff:isAuraAffectActor(actor, skip_team_check)
    assert(self._actor, "")
    assert(actor, "")
    assert(self:isAura(), "")

    if actor:isImmuneBuff(self) then
        return false
    end

    if not skip_team_check then
        local targetType = self:getAuraTargetType()
        if targetType == QBuff.ENEMY then
            local enemies = app.battle:getMyEnemies(self._actor)
            if not table.indexof(enemies, actor) then
                return false
            end
        elseif targetType == QBuff.TEAMMATE then
            local teammates = app.battle:getMyTeammates(self._actor, false)
            if not table.indexof(teammates, actor) then
                return false
            end
        elseif targetType == QBuff.TEAMMATE_AND_SELF then
            local teammates = app.battle:getMyTeammates(self._actor, true)
            if not table.indexof(teammates, actor) then
                return false
            end
        else
            return false
        end
    end

    -- local radius = self:getAuraRadius() * global.pixel_per_unit
    -- local distance = q.distOf2Points(self._actor:getPosition(), actor:getPosition())
    -- if distance > radius then
    --     return false
    -- end

    return true
end

function QBuff:getBuffOwner()
    return self._actor
end

function QBuff:getAttacker()
    return self._attacker
end

function QBuff:getAttackerAttackValue()
    return self._attackerAttackValue
end

function QBuff:getTriggerType()
    return self:get("trigger_type")
end

function QBuff:getTriggerCondition()
    return self:get("trigger_condition")
end

function QBuff:getTriggerProbability()
    return self:get("trigger_probability") * 100
end

function QBuff:getTriggerTarget()
    return self:get("trigger_target")
end

function QBuff:getTriggerBuffId()
    return self:get("trigger_buff_id")
end

function QBuff:getTriggerBuffTargetType()
    return self:get("trigger_buff_target_type")
end

function QBuff:getTriggerSkillId()
    return self:get("trigger_skill_id")
end

function QBuff:getTriggerSkillAsCurrent()
    return self:get("trigger_skill_as_current")
end

function QBuff:getTriggerSkillInheritPercent()
    return self:get("trigger_skill_inherit_percent")
end

function QBuff:getTriggerComboPoints()
    return self:get("trigger_combo_points")
end

function QBuff:isAbsorbDamage()
    return self._isAbsorbDamage
end

function QBuff:getAbsorbDamageValue()
    return self._absorb_damage_value_left
end

-- 累加时使用
function QBuff:setAbsorbDamageValue(value)
    self._absorb_damage_value_left = value
end

function QBuff:absorbDamageValue(damage_value)
    assert(damage_value >= 0 and damage_value <= self._absorb_damage_value_left, "")

    self._absorb_damage_value_left = self._absorb_damage_value_left - damage_value
end

function QBuff:getPhysicalDamageValue()
    return self._physical_damage_value
end

-- 累加时使用
function QBuff:setPhysicalDamageValue(value)
    self._physical_damage_value = value
end

function QBuff:getMagicDamageValue()
    return self._magic_damage_value
end

-- 累加时使用
function QBuff:setMagicDamageValue(value)
    self._magic_damage_value = value
end

function QBuff:getMagicTreatValue()
    return self._magic_treat_value
end

-- 累加时使用
function QBuff:setMagicTreatValue(value)
    self._magic_treat_value = value
end

function QBuff:getCrit()
    return self._crit
end

function QBuff:getCritDamage()
    return self._critDamage
end

function QBuff:getScalePercent()
    return self.effects.scale_percent
end

function QBuff:isConditionMet()
    if self.effects.effect_condition == "" then
        return true
    else
        return self:_calculateCondition(self.effects.effect_condition)
    end
end

function QBuff:_calculateCondition(cond)
    assert(cond ~= nil and cond ~= "", "")

    local met = false
    local condition = cond
    if condition ~= "" then
        local words = string.split(condition, "_")
        while #words >= 2 do
            met = false
            if words[1] == "probability" then
                local probability = tonumber(words[2])
                if type(probability) == "number" then
                    met = probability * 100 >= math.random(1, 100)
                end
            elseif #words >= 3 then
                -- 角色单词
                local actor = nil
                if words[1] == "target" then
                    actor = self._actor and self._actor:getTarget()
                elseif words[1] == "self" then
                    actor = self._actor
                else
                    met = false
                end
                if actor == nil then
                    break
                end

                -- 比较值
                if words[2] == "hp" then
                    if #words == 5 then
                        local value = nil
                        local value2 = nil
                        value = actor:getHp()
                        value2 = actor:getMaxHp()

                        -- 调整比较值
                        local value_adjust = nil
                        if words[3] == "percent" then
                            value_adjust = value / value2
                        elseif words[3] == "value" then
                            value_adjust = value
                        else
                            met = false
                        end
                        if value_adjust == nil then
                            break
                        end

                        -- 取得条件数值
                        local condition_value = tonumber(words[5])
                        assert(type(condition_value) == "number", "")

                        -- 比较符号
                        if words[4] == "smaller" then
                            met = value_adjust <= condition_value
                        elseif words[4] == "greater" then
                            met = value_adjust >= condition_value
                        else
                            met = false
                        end
                    end
                elseif words[2] == "status" then
                    local status = ""
                    for i = 3, #words do
                        status = status .. words[i]
                        if i ~= #words then
                            status = status .. "_"
                        end
                    end
                    met = actor:isUnderStatus(status)
                else
                    met = false
                end
            end

            break
        end
    end

    return met
end

return QBuff
