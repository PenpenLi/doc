--[[
    英雄的特殊技能
--]]

local QModelBase = import(".QModelBase")
local QSkill = class("QSkill", QModelBase)

local QTimer = import("..utils.QTimer")
local QStaticDatabase = import("..controllers.QStaticDatabase")

QSkill.DEFAULT_BULLET_SPEED = 1500

-- skill type
QSkill.MANUAL = "manual"
QSkill.ACTIVE = "active"
QSkill.PASSIVE = "passive"

-- target type
-- single range
QSkill.SELF = "self"
QSkill.TARGET = "target"
-- multiple range
QSkill.ENEMY = "enemy"
QSkill.TEAMMATE = "teammate"
QSkill.TEAMMATE_AND_SELF = "teammate_and_self"

-- range type
QSkill.SINGLE = "single"
QSkill.MULTIPLE = "multiple"

-- zone type
QSkill.ZONE_FAN = "fan"
QSkill.ZONE_RECT = "rect"

-- sector center type
QSkill.CENTER_SELF = "self"
QSkill.CENTER_TARGET = "target"

-- damage type
QSkill.PHYSICAL = "physical"
QSkill.MAGIC = "magic"

-- buff target type
QSkill.BUFF_SELF = "self"
QSkill.BUFF_TARGET = "target"
QSkill.BUFF_MAIN_TARGET = "main_target"
QSkill.BUFF_OTHER_TARGET = "other_target"

-- attack type
QSkill.ATTACK = "attack"
QSkill.TREAT = "treat"
QSkill.ASSIST = "assist"

-- hit type
QSkill.HIT = "hit"
QSkill.STRIKE = "strike"
QSkill.CRITICAL = "critical"

-- passive skill triggrt type
QSkill.TRIGGER_TYPE_BUFF = "buff"
QSkill.TRIGGER_TYPE_ATTACK = "attack"
QSkill.TRIGGER_TYPE_COMBO = "combo"
QSkill.TRIGGER_TYPE_CD_REDUCE = "cd_reduce"

-- passive skill triggrt condition
QSkill.TRIGGER_CONDITION_HIT = "hit"
QSkill.TRIGGER_CONDITION_SKILL = "skill"
QSkill.TRIGGER_CONDITION_SKILL_CRITICAL = "skill_critical"
QSkill.TRIGGER_CONDITION_SKILL_ATTACK = "skill_attack"
QSkill.TRIGGER_CONDITION_SKILL_ATTACK_CRITICAL = "skill_attack_critical"
QSkill.TRIGGER_CONDITION_SKILL_TREAT = "skill_treat"
QSkill.TRIGGER_CONDITION_SKILL_TREAT_CRITICAL = "skill_treat_critical"
QSkill.TRIGGER_CONDITION_DRAG = "drag"
QSkill.TRIGGER_CONDITION_DRAG_ATTACK = "drag_attack"
QSkill.TRIGGER_CONDITION_DRAG_OR_DRAG_ATTACK = "drag_or_drag_attack"

-- skill event
QSkill.EVENT_SKILL_DISABLE = "qskill.event_skill_disable"
QSkill.EVENT_SKILL_ENABLE = "qskill.event_skill_enable"

QSkill.REMOVE_ALL = "all"

-- *********************** Skill ***********************
QSkill.schema = clone(cc.mvc.ModelBase.schema)
QSkill.schema["name"]           = {"string", ""} -- 字符串类型，没有默认值
QSkill.schema["local_name"]     = {"string", ""}
QSkill.schema["level"]          = {"number", 1}
QSkill.schema["money_cost"]     = {"number", 0}
QSkill.schema["hero_level"]     = {"number", 1}
QSkill.schema["type"]           = {"string", ""}
QSkill.schema["attack_type"]    = {"string", ""}
QSkill.schema["hit_type"]       = {"string", "hit"}
-- 一般伤害
QSkill.schema["damage_type"]    = {"string", ""}
QSkill.schema["damage_p"]       = {"number", 1}
QSkill.schema["physical_damage"] = {"number", 1}
QSkill.schema["magic_damage"]   = {"number", 1}
QSkill.schema["damage_split"]   = {"boolean", false}
-- passive skill 
QSkill.schema["addition_type_1"]    = {"string", ""}
QSkill.schema["addition_value_1"]   = {"number", 0}
QSkill.schema["addition_type_2"]    = {"string", ""}
QSkill.schema["addition_value_2"]   = {"number", 0}
QSkill.schema["addition_type_3"]    = {"string", ""}
QSkill.schema["addition_value_3"]   = {"number", 0}
-- 击打触发的buff
QSkill.schema["buff_id_1"]            = {"string", ""}
QSkill.schema["buff_target_type_1"]   = {"string", ""}
QSkill.schema["buff_id_2"]            = {"string", ""}
QSkill.schema["buff_target_type_2"]   = {"string", ""}
-- 击打触发的buff end
QSkill.schema["trap_id"]            = {"string", ""}
-- trigger value
QSkill.schema["trigger_condition"]          = {"string", ""}
QSkill.schema["trigger_probability"]        = {"number", 1}
QSkill.schema["trigger_type"]               = {"string", ""}
QSkill.schema["trigger_buff_id"]            = {"string", ""}
QSkill.schema["trigger_buff_target_type"]   = {"string", ""}
QSkill.schema["trigger_skill_id"]           = {"string", ""}
QSkill.schema["trigger_skill_as_current"]   = {"boolean", false}
QSkill.schema["trigger_combo_points"]       = {"number", 0}
QSkill.schema["can_remove_buff"]            = {"boolean", false}
QSkill.schema["battle_force"]               = {"number", 0}

-- *********************** Skill Cast ***********************
QSkill.schema["prjor"]          = {"number", 0}
QSkill.schema["interval"]       = {"number", 1} -- 数值类型，默认值 1
QSkill.schema["first_cd"]       = {"number", -1} -- 数值类型，默认值 -1
QSkill.schema["arena_first_cd"] = {"number", -1} -- 数值类型，默认值 -1
QSkill.schema["cd"]             = {"number", 1} -- 数值类型，默认值 1
QSkill.schema["arena_cd"]       = {"number", -1} -- 数值类型，默认值 1 
QSkill.schema["or_cond_1"]      = {"string", ""} -- 技能的或条件
QSkill.schema["and_cond_1"]     = {"string", ""} -- 技能的与条件
QSkill.schema["range_type"]     = {"string"} -- 作用域类型(单体/群体)
QSkill.schema["target_type"]    = {"string", "target"}
QSkill.schema["target_id"]      = {"string", ""}
QSkill.schema["distance"]       = {"number", 1}
QSkill.schema["distance_tolerance"] = {"number", 0}
QSkill.schema["distance_minimum"]   = {"number", 0}
QSkill.schema["zone_type"]      = {"string", "fan"} -- 群体域时域的形状(rect/fan)
QSkill.schema["rect_width"]     = {"number", 0}
QSkill.schema["rect_height"]    = {"number", 0}
QSkill.schema["sector_center"]  = {"string", "target"} -- 以谁为释放中心(自己/目标)
QSkill.schema["sector_radius"]  = {"number", 0}
QSkill.schema["sector_degree"]  = {"number", 360}
QSkill.schema["cancel_while_move"]      = {"boolean", true}
QSkill.schema["stop_moving"]            = {"boolean", false}
QSkill.schema["allow_moving"]           = {"boolean", false}
QSkill.schema["is_select_actor"]        = {"boolean", false}

-- *********************** Skill Animation ***********************
QSkill.schema["actor_attack_animation"] = {"string", ""}
QSkill.schema["attack_effect"]      = {"string", ""}
QSkill.schema["bullet_effect"]      = {"string", ""}
QSkill.schema["bullet_speed"]      = {"number", QSkill.DEFAULT_BULLET_SPEED}
QSkill.schema["hit_effect"]         = {"string", ""}
QSkill.schema["second_hit_effect"]  = {"string", ""}
QSkill.schema["behavior_status"]    = {"string", ""}
QSkill.schema["skill_behavior"]     = {"string", ""}

-- *********************** Skill Display ***********************
QSkill.schema["icon"]           = {"string", ""}
QSkill.schema["description"]    = {"string", ""}
QSkill.schema["description_2"]  = {"string", ""}

-- *********************** Skill Description ***********************
QSkill.schema["description_1"]  = {"string", ""}
QSkill.schema["addition_float"] = {"string", ""}

-- **********************************************
QSkill.schema["auto_target"]    = {"boolean", false}
QSkill.schema["is_affected_by_haste"] = {"boolean", false}
QSkill.schema["is_zone_follow"] = {"boolean", false} -- 群体域是否要跟随actor
QSkill.schema["addition_on"]        = {"boolean", false}
QSkill.schema["status"]             = {"string", ""}
-- 额外伤害区域，额外伤害将在可用时代替一般伤害区域
QSkill.schema["bonus_damage_cond"]    = {"string", ""}
QSkill.schema["bonus_damage"]         = {"number", 1}
QSkill.schema["bonus_damage_p"]       = {"number", 1}
QSkill.schema["bonus_physical_damage"] = {"number", 1}
QSkill.schema["bonus_magic_damage"]   = {"number", 1}
-- buff condition
QSkill.schema["buff_1_or_cond_1"]     = {"string", ""}
QSkill.schema["buff_1_or_cond_2"]     = {"string", ""}
QSkill.schema["buff_1_and_cond_1"]    = {"string", ""}
QSkill.schema["buff_1_and_cond_2"]    = {"string", ""}
QSkill.schema["buff_2_or_cond_1"]     = {"string", ""}
QSkill.schema["buff_2_or_cond_2"]     = {"string", ""}
QSkill.schema["buff_2_and_cond_1"]    = {"string", ""}
QSkill.schema["buff_2_and_cond_2"]    = {"string", ""}
-- 技能使用条件 = [[cd] and [and_cond_1] and ... and [and_con_n]] or [or_cond_1] or .. or [or_cond_m]
QSkill.schema["condition_1"]        = {"string", ""} -- 技能的使用条件，deprecated
QSkill.schema["condition_value_1"]  = {"number", 0} -- 技能的使用条件值，deprecated
-- 连击点数相关属性
QSkill.schema["combo_points_need"]  = {"boolean", false} -- 是否需要连击点数
QSkill.schema["combo_points_gain"]  = {"number", 0} -- 释放完获得的连击点数
-- 移除不良buff
QSkill.schema["remove_status"]      = {"string", ""} -- 释放时移除提供状态的buff

function QSkill:ctor(id, properties, actor)
    local skillInfo = QStaticDatabase.sharedDatabase():getSkillByID(id)
    assert(skillInfo ~= nil, "skill id: " .. id .. " does not exist!")

    local prop = skillInfo
    if properties ~= nil then
        prop = clone(prop)
        table.merge(prop, properties)
    else
        printError("creating QSkill with empty property set, id:" .. id)
    end

    QSkill.super.ctor(self, prop)

    if self:get("first_cd") < 0 then
        self:set("first_cd", self:get("cd"))
    end

    if self:get("arena_first_cd") < 0 then
        self:set("arena_first_cd", self:get("cd"))
    end

    if self:get("arena_cd") < 0 then
        self:set("arena_cd", self:get("cd"))
    end

    self._actor = actor
    self._cdTimer = QTimer.new()
    self._ready = true

    self._remove_status = {}
    for _, status in ipairs(string.split(self:get("remove_status"), ";")) do
        self._remove_status[status] = true
    end

    self._isUsed = false

    self._cd_progress = 0

    self:_prepareAdditionEffects()

    self._cache = {}
end

function QSkill:resetState()
    self:resetCoolDown()
    self._isUsed = false
end

function QSkill:getName()
    return self:get("name")
end

function QSkill:getLocalName()
    return self:get("local_name")
end

function QSkill:getSkillLevel()
    return self:get("level")
end

function QSkill:getIcon()
    return self:get("icon")
end

function QSkill:isTalentSkill()
    -- if we can find it from talent table, then it's talent skill, otherwise it is not
    local key = "isTalentSkill"
    if self._cache[key] == nil then
        self._cache[key] = false
        if self._actor:getTalentSkill() == self or self._actor:getTalentSkill2() == self then
            self._cache[key] = true
        end
    end

    return self._cache[key]
end

function QSkill:getDamagePercent()
    return self:get("damage_p")
end

function QSkill:getBonusDamagePercent()
    return self:get("bonus_damage_p")
end

function QSkill:getZoneType()
    return self:get("zone_type")
end

function QSkill:isZoneFollow()
    return self:get("is_zone_follow")
end

function QSkill:getRectWidth()
    return self:get("rect_width")
end

function QSkill:getRectHeight()
    return self:get("rect_height")
end

-- 以谁为释放中心(自己/目标)
function QSkill:getSectorCenter()
    return self:get("sector_center")
end

function QSkill:getSectorRadius()
    return self:get("sector_radius")
end

function QSkill:getSectorDegree()
    return self:get("sector_degree")
end

function QSkill:getTargetType()
    return self:get("target_type")
end

function QSkill:getTargetID()
    return self:get("target_id")
end

function QSkill:isNeedATarget()
    if (self:getRangeType() == QSkill.SINGLE and self:getTargetType() ~= QSkill.SELF) 
        or (self:getRangeType() == QSkill.MULTIPLE and self:getZoneType() == QSkill.ZONE_FAN and self:getSectorCenter() == QSkill.CENTER_TARGET) then 
        local actor = self:getActor()
        local target = actor:getTarget()
        if self:get("auto_target") and not target then
            local actor_position = actor:getPosition()
            local enemies = app.battle:getMyEnemies(actor)
            for _, enemy in ipairs(enemies) do
                if not enemy:isDead() and self:isInSkillRange(actor_position, enemy:getPosition()) then
                    if app.grid then
                        local area = app.grid:getRangeArea()
                        local pos = enemy:getPosition()
                        if pos.x >= area.left and pos.x <= area.right and pos.y >= area.bottom and pos.y <= area.top then
                            return false
                        end
                    end
                end
            end
        end
        return true
    end
    return false
end

-- 作用域类型(单体/群体)
function QSkill:getRangeType()
    return self:get("range_type")
end

function QSkill:getDamageSplit()
    return self:get("damage_split")
end

function QSkill:isBonusDamageConditionMet()
    local cond = self:get("bonus_damage_cond")
    if cond == nil or cond == "" then
        return false
    end
    return self:_calculateCondition(cond)
end

function QSkill:getPhysicalDamage()
    return self:get("physical_damage")
end

function QSkill:getMagicDamage()
    return self:get("magic_damage")
end

function QSkill:getBonusPhysicalDamage()
    return self:get("bonus_physical_damage")
end

function QSkill:getBonusMagicDamage()
    return self:get("bonus_magic_damage")
end

function QSkill:getDamageType()
    return self:get("damage_type")
end

function QSkill:getAttackType()
    local attackType = self:get("attack_type")
    if string.len(attackType) <= 0 then
        assert(false, "The attack type of skill:" .. self:getId() .. " is not exist")
    end
    return attackType
end

function QSkill:getHitType()
    return self:get("hit_type")
end

function QSkill:getAttackDistanceMinimum()
    return self:get("distance_minimum") * global.pixel_per_unit
end

function QSkill:getAttackDistance()
    return self:get("distance") * global.pixel_per_unit
end

function QSkill:getAttackDistanceTolerance()
    return self:get("distance_tolerance") * global.pixel_per_unit
end

function QSkill:getSkillRange(isIncludeTolerance)
    local minmum = self:getAttackDistanceMinimum()
    local maxmum = self:getAttackDistance()
    if isIncludeTolerance == true then
        maxmum = maxmum + self:getAttackDistanceTolerance()
    end

    return minmum, maxmum
end

function QSkill:getActorAttackAnimation()
    return self:get("actor_attack_animation")
end

function QSkill:getAttackEffectID()
    local effectID = self:get("attack_effect")
    if string.len(effectID) == 0 then
        effectID = nil
    end
    return effectID
end

function QSkill:getBulletEffectID()
    local effectID = self:get("bullet_effect")
    if string.len(effectID) == 0 then
        effectID = nil
    end
    return effectID
end

function QSkill:getBulletSpeed()
    return self:get("bullet_speed")
end

function QSkill:getHitEffectID()
    local effectID = self:get("hit_effect")
    if string.len(effectID) == 0 then
        effectID = nil
    end
    return effectID
end

function QSkill:getSecondHitEffectID()
    local effectID = self:get("second_hit_effect")
    if string.len(effectID) == 0 then
        effectID = nil
    end
    return effectID
end

function QSkill:getInterval()
    return self:get("interval")
end

function QSkill:getCdTime()
    local cd = 0
    if self._isUsed == false then
        self._isUsed = true
        if app.battle:isPVPMode() and app.battle:isInArena() then
            cd = self:get("arena_first_cd")
        elseif app.battle:isPVPMode() and app.battle:isInSunwell() then
            cd = self:get("cd")
        else
            cd = self:get("first_cd")
        end
    else
        if app.battle:isPVPMode() and app.battle:isInArena() then
            cd = self:get("arena_cd")
        else
            cd = self:get("cd")
        end
    end
    return cd
end

function QSkill:getBuffId1()
    return self:get("buff_id_1")
end

function QSkill:getBuffId2()
    return self:get("buff_id_2")
end

function QSkill:getBuffTargetType1()
    return self:get("buff_target_type_1")
end

function QSkill:getBuffTargetType2()
    return self:get("buff_target_type_2")
end

function QSkill:isBuffConditionMet1()
    local orconds = {}
    local andconds = {}

    local orresults = {}
    local andresults = {}

    local max = 2
    local index = 1
    while index <= max do
        local orcond = self:get("buff_1_or_cond_" .. index)
        if orcond ~= nil and orcond ~= "" then
            table.insert(orconds, orcond)
            index = index + 1
        else
            index = index + 1
        end
    end
    local index = 1
    while index <= max do
        local andcond = self:get("buff_1_and_cond_" .. index)
        if andcond ~= nil and andcond ~= "" then
            table.insert(andconds, andcond)
            index = index + 1
        else
            index = index + 1
        end
    end

    for _, cond in ipairs(orconds) do
        table.insert(orresults, self:_calculateCondition(cond))
    end
    for _, cond in ipairs(andconds) do
        table.insert(andresults, self:_calculateCondition(cond))
    end

    local met = true
    for _, result in ipairs(andresults) do
        met = met and result
    end
    for _, result in ipairs(orresults) do
        met = met or result
    end

    return met
end

function QSkill:isBuffConditionMet2()
    local orconds = {}
    local andconds = {}

    local orresults = {}
    local andresults = {}

    local max = 2
    local index = 1
    while index <= max do
        local orcond = self:get("buff_2_or_cond_" .. index)
        if orcond ~= nil and orcond ~= "" then
            table.insert(orconds, orcond)
            index = index + 1
        else
            index = index + 1
        end
    end
    local index = 1
    while index <= max do
        local andcond = self:get("buff_2_and_cond_" .. index)
        if andcond ~= nil and andcond ~= "" then
            table.insert(andconds, andcond)
            index = index + 1
        else
            index = index + 1
        end
    end

    for _, cond in ipairs(orconds) do
        table.insert(orresults, self:_calculateCondition(cond))
    end
    for _, cond in ipairs(andconds) do
        table.insert(andresults, self:_calculateCondition(cond))
    end

    local met = true
    for _, result in ipairs(andresults) do
        met = met and result
    end
    for _, result in ipairs(orresults) do
        met = met or result
    end

    return met
end

function QSkill:getTrapId()
    local trapId = self:get("trap_id")
    if string.len(trapId) <= 0 then
        return nil
    end
    return trapId
end

function QSkill:getSkillBehaviorName()
    local name = self:get("skill_behavior")
    if string.len(name) <= 0 then
        return nil
    end
    return name
end

function QSkill:getSkillType()
    local skillType = self:get("type")
    if string.len(skillType) <= 0 then
        assert(false, "The type of skill:" .. self:getId() .. " is not exist")
    end
    return skillType
end

function QSkill:getSkillPriority()
    return self:get("prjor")
end

function QSkill:getActor()
    return self._actor
end

function QSkill:isReady()
    if not self._ready then return false end

    if not self:isNeedComboPoints() or self:getActor():getComboPoints() > 0 then
        return true
    else 
        return false
    end
end

function QSkill:isTreatSkill()
    return (self:get("attack_type") == "treat")
end

function QSkill:isBulletSkill()
    if self:getBulletEffectID() == nil then
        return false
    end
    return true
end

function QSkill:isRemoteSkill()
    local distance = self:getAttackDistance()
    return (distance >= global.ranged_attack_distance * global.pixel_per_unit)
end

function QSkill:getTriggerType()
    if string.len(self._additionEffects.trigger_type) == 0 then
        return nil
    end
    return self._additionEffects.trigger_type
end

function QSkill:getTriggerCondition()
    if string.len(self._additionEffects.trigger_condition) == 0 then
        return nil
    end
    return self._additionEffects.trigger_condition
end

function QSkill:getTriggerProbability()
    return self._additionEffects.trigger_probability
end

function QSkill:getTriggerBuffId()
    if string.len(self._additionEffects.trigger_buff_id) == 0 then
        return nil
    end
    return self._additionEffects.trigger_buff_id
end

function QSkill:getTriggerBuffTargetType()
    if string.len(self._additionEffects.trigger_buff_target_type) == 0 then
        return nil
    end
    return self._additionEffects.trigger_buff_target_type
end

function QSkill:getTriggerSkillId()
    if string.len(self._additionEffects.trigger_skill_id) == 0 then
        return nil
    end
    return self._additionEffects.trigger_skill_id
end

function QSkill:getTriggerSkillAsCurrent()
    return self._additionEffects.trigger_skill_as_current
end

function QSkill:getTriggerComboPoints()
    return self:get("trigger_combo_points")
end

function QSkill:canRemoveBuff()
    return self._additionEffects.can_remove_buff
end

function QSkill:isCancelWhileMove()
    return self._additionEffects.cancel_while_move
end

function QSkill:isStopMoving()
    return self._additionEffects.stop_moving
end

function QSkill:isAllowMoving()
    return self._additionEffects.allow_moving
end

function QSkill:isSelectActor()
    return self:get("is_select_actor")
end

function QSkill:getStatus()
    return self:get("status")
end

function QSkill:getBehaviorStatus()
    return self:get("behavior_status")
end

function QSkill:isRemoveStatus(status)
    return status ~= nil and status ~= "" and (self._remove_status[QSkill.REMOVE_ALL] or self._remove_status[status])
end

function QSkill:getAdditionValueWithKey(key)
    if key == nil then
        return nil
    end

    return self._additionEffects[key]
end

function QSkill:_prepareAdditionEffects()
    self._additionEffects = {
        -- 触发效果(攻击和受击时有几率触发)
        trigger_condition = nil, -- skill or hit
        trigger_probability = 0,
        trigger_type = nil, -- buff or attack
        trigger_buff_id = nil,
        trigger_buff_target_type = nil,
        trigger_skill_id = nil,
        trigger_skill_as_current = false,
        -- 特殊效果
        can_remove_buff = false, -- 能取消某些buff
        cancel_while_move = true, -- 移动时技能自动撤销
        stop_moving = false, -- 释放时停止移动
        allow_moving = false, -- 释放时，stop_moving为true时，是否允许移动
        -- 特殊机制
        duration_time = 0,  -- 持续时间
        interval_time = 0,  -- 间隔时间
    }

    -- table.merge(self._additionEffects, clone(global.additions))

    self:_setAdditionEffect(self:get("addition_type_1"), self:get("addition_value_1"))
    self:_setAdditionEffect(self:get("addition_type_2"), self:get("addition_value_2"))
    self:_setAdditionEffect(self:get("addition_type_3"), self:get("addition_value_3"))
    self:_setAdditionEffect("trigger_condition", self:get("trigger_condition"))
    self:_setAdditionEffect("trigger_probability", self:get("trigger_probability"))
    self:_setAdditionEffect("trigger_type", self:get("trigger_type"))
    self:_setAdditionEffect("trigger_buff_id", self:get("trigger_buff_id"))
    self:_setAdditionEffect("trigger_buff_target_type", self:get("trigger_buff_target_type"))
    self:_setAdditionEffect("trigger_skill_id", self:get("trigger_skill_id"))
    self:_setAdditionEffect("trigger_skill_as_current", self:get("trigger_skill_as_current"))
    self:_setAdditionEffect("can_remove_buff", self:get("can_remove_buff"))
    self:_setAdditionEffect("cancel_while_move", self:get("cancel_while_move"))
    self:_setAdditionEffect("stop_moving", self:get("stop_moving"))
    self:_setAdditionEffect("allow_moving", self:get("allow_moving"))

    self._additionEffects.trigger_probability = self._additionEffects.trigger_probability * 100

end

function QSkill:_setAdditionEffect(prop, value)
    if prop ~= nil and string.len(prop) > 0 then
        self._additionEffects[prop] = value
    end
end

function QSkill:_setEffectValueToBoolean(key)
    if key == nil or self._additionEffects[key] == nil then
        return
    end

    if type(self._additionEffects[key]) == "boolean" then
        return
    end

    if self._additionEffects[key] == 0 then
        self._additionEffects[key] = false
    else
        self._additionEffects[key] = true
    end
end

function QSkill:coolDown()
    if not self._ready then 
        return 
    end

    self._cd_time = self:getCdTime()
    self._cd_progress = 0.0
    self:_startCd()
end

function QSkill:reduceCoolDownTime(time)
    if self._ready == true then
        return
    end

    if time == nil or time <= 0 then
        return
    end

    self._cdTimer.onTimer(time)
end

function QSkill:resetCoolDown()
    if not self._ready then 
        self._cdTimer:stop()
        self._cdTimer:removeCountdown(QDEF.EVENT_CD_CHANGED)
        self._ready = true
    end
end

function QSkill:pauseCoolDown()
    self._cdTimer:pause()
end

function QSkill:resumeCoolDown()
    self._cdTimer:resume()
end

function QSkill:getCDProgress()
    return self._cd_progress
end

function QSkill:_startCd()
    self._ready = false

    self:dispatchEvent({name = QDEF.EVENT_CD_STARTED, skill = self})

    self._cdTimer:addEventListener(QDEF.EVENT_CD_CHANGED, handler(self, self._onCdChanged))
    self._cdTimer:addCountdown(QDEF.EVENT_CD_CHANGED, 600, 0.1)
    self._cdTimer:start()
end

function QSkill:_stopCd()
    self._ready = true

    self:dispatchEvent({name = QDEF.EVENT_CD_CHANGED, skill = self, cd_progress = 0})
    self:dispatchEvent({name = QDEF.EVENT_CD_STOPPED, skill = self})

    self._cdTimer:stop()
    self._cdTimer:removeCountdown(QDEF.EVENT_CD_CHANGED)
end

function QSkill:_onCdChanged(event)
    event.skillId = self:getId()

    local actor = self:getActor()

    local cd_time = self._cd_time
    local cd_progress = self._cd_progress
    local haste = self._actor:getMaxHaste()
    cd_progress = cd_progress + (1 + haste) * event.dt / cd_time * app.battle:getTimeGear()
    self._cd_progress = cd_progress

    if self._cd_progress >= 1 then
        self:_stopCd()
    end
    
    event.skill = self
    event.cd_progress = cd_progress
    self:dispatchEvent(event)
end

function QSkill:isInSkillRange(startPosition, targetPosition, isIncludeTolerance)
    assert(startPosition ~= nil, "QSkill:isInSkillRange startPosition is nil")
    assert(targetPosition ~= nil, "QSkill:isInSkillRange targetPosition is nil")

    local deltaX = startPosition.x - targetPosition.x
    local deltaY = (startPosition.y - targetPosition.y) * 2
    deltaY = math.max(deltaY, (global.melee_distance_y + 1) * 24 * 0.6)
    local distance = deltaX * deltaX + deltaY * deltaY

    local minmum, maxmum = self:getSkillRange(isIncludeTolerance)
    minmum = minmum * minmum
    maxmum = maxmum * maxmum

    -- target should in outer rect and not in inner rect
    if distance <= maxmum then
        if minmum <= 0 or distance > minmum then
            return true
        end
    end
    return false
end

function QSkill:_calculateCondition(cond)
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

function QSkill:forceReadyAndConditionMet(met)
    self._forceMet = met

    if met == false then
        self:dispatchEvent({name = QSkill.EVENT_SKILL_DISABLE, skill = self})
    elseif met == true then
        self:dispatchEvent({name = QSkill.EVENT_SKILL_ENABLE, skill = self})
    else
        self:dispatchEvent({name = QSkill.EVENT_SKILL_ENABLE, skill = self})
    end
end

-- 把cd冷却与所有的与或条件一起考虑的"condition是否met"
function QSkill:isReadyAndConditionMet()
    if type(self._forceMet) == "boolean" then
        return self._forceMet
    end

    if self:isNeedComboPoints() and self:getActor():getComboPoints() <= 0 then
        return false
    end

    local orconds = {}
    local andconds = {}

    local orresults = {}
    local andresults = {}

    local index = 1
    local max = 1
    while index <= max do
        local orcond = self:get("or_cond_" .. index)
        if orcond ~= nil and orcond ~= "" then
            table.insert(orconds, orcond)
            index = index + 1
        else
            index = index + 1
        end
    end
    local index = 1
    while index <= max do
        local andcond = self:get("and_cond_" .. index)
        if andcond ~= nil and andcond ~= "" then
            table.insert(andconds, andcond)
            index = index + 1
        else
            index = index + 1
        end
    end

    for _, cond in ipairs(orconds) do
        table.insert(orresults, self:_calculateCondition(cond))
    end
    for _, cond in ipairs(andconds) do
        table.insert(andresults, self:_calculateCondition(cond))
    end

    local met = self:isReady()
    for _, result in ipairs(andresults) do
        met = met and result
    end
    for _, result in ipairs(orresults) do
        met = met or result
    end

    return met
end

function QSkill:isAffectedByHaste()
    return self:get("is_affected_by_haste")
end

function QSkill:getComboPointsGain()
    return self:get("combo_points_gain")
end

function QSkill:isNeedComboPoints()
    return self:get("combo_points_need")
end

function QSkill:isAdditionOn()
    return self:get("addition_on")
end

function QSkill:setInheritedDamage(inherited_damage)
    self._inherited_damage = inherited_damage
end

function QSkill:getInHeritedDamage()
    return self._inherited_damage
end

function QSkill:getBattleForce()
    return self:get("battle_force")
end

return QSkill
