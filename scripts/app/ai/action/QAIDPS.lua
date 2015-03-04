
local QAIAction = import("..base.QAIAction")
local QAIDPS = class("QAIDPS", QAIAction)

function QAIDPS:ctor( options )
    QAIDPS.super.ctor(self, options)
    self:setDesc("")
end

function QAIDPS:_evaluate(args)
    if not args.actor or not args.actor:isForceAuto() then
        return false
    end

    return true
end

function QAIDPS:_blink(actor)
    if not actor:isRanged() or self._blinkSkill == false then
        return
    end

    local blinkSkill = self._blinkSkill

    if blinkSkill == nil then
        for _, skill in pairs(actor:getActiveSkills()) do
            if skill:getSkillType() == skill.ACTIVE and skill:getTriggerCondition() == skill.TRIGGER_CONDITION_DRAG then
                blinkSkill = skill
                break
            end
        end

        if blinkSkill == nil then
            self._blinkSkill = false
            return
        else
            self.blinkSkill = blinkSkill
        end
    end

    if not actor:canAttack(blinkSkill) then
        return false
    end

    local enemies = app.battle:getMyEnemies(actor)
    local beingattacked = false
    for _, enemy in ipairs(enemies) do
        if not enemy:isRanged() then
            if enemy:isAttacking() and enemy:getCurrentSkillTarget() == actor then
                beingattacked = true
                break
            end
        end
    end

    if beingattacked then
        local positions = {}
        for _, enemy in ipairs(enemies) do
            if not enemy:isRanged() then
                local _, gridPos = app.grid:_toGridPos(enemy:getPosition().x, enemy:getPosition().y)
                table.insert(positions, gridPos)
            end
        end
        local nx, ny = app.grid._nx, app.grid._ny
        local dist_max = 3 / 6 * nx
        local weights = {}
        local index = 1
        for i = 1, nx do
            for j = 1, ny do
                weights[index] = 0
                index = index + 1
            end
        end
        for _, pos in ipairs(positions) do
            local index = 1
            for i = 1, nx do
                for j = 1, ny do
                    weights[index] = weights[index] + math.min(q.distOf2Points(pos, {x = i, y = j}), dist_max)
                    index = index + 1
                end
            end
        end
        local weight = 0
        local candidates = {}
        local index = 1
        for i = 1, nx do
            for j = 1, ny do
                if weight > weights[index] then
                elseif weight == weights[index] then
                    table.insert(candidates, {x = i, y = j})
                else
                    weight = weights[index]
                    candidates = {}
                    table.insert(candidates, {x = i, y = j})
                end
                index = index + 1
            end
        end
        if #candidates > 0 then
            local screenPos = app.grid:_toScreenPos(candidates[math.random(1, #candidates)])
            actor._dragPosition = screenPos
            actor._targetPosition = screenPos
            actor:attack(blinkSkill)
        end
        candidates = nil
    end
end

function QAIDPS:_charge(actor)
    local chargeSkill = self._chargeSkill

    if chargeSkill == nil then
        for _, skill in pairs(actor:getActiveSkills()) do
            if skill:getSkillType() == skill.ACTIVE and skill:getTriggerCondition() == skill.TRIGGER_CONDITION_DRAG_ATTACK then
                chargeSkill = skill
                break
            end
        end

        if chargeSkill == nil then
            return
        else
            self._chargeSkill = chargeSkill
        end
    end

    if not actor:canAttack(chargeSkill) then
        return false
    end

    if chargeSkill:isNeedATarget() then
        local target = actor:getTarget()
        if target == nil or target:isDead() then
            return false
        elseif chargeSkill:isInSkillRange(actor:getPosition(), target:getPosition(), false) == false then
            return false
        end
    end

    actor:attack(chargeSkill, true)

    return true
end

function QAIDPS:_attack(actor)
    local manualSkill = actor:getManualSkills()[next(actor:getManualSkills())]
    if manualSkill == nil then
        return false
    end

    -- 检查自动释放的连击点数
    if manualSkill:isNeedComboPoints() and actor:getComboPoints() < actor:getComboPointsAuto() then
        return false
    end

    -- 检查技能是否能够使用
    if not actor:canAttack(manualSkill) then
        return false
    end

    if manualSkill:isNeedATarget() then
        local target = actor:getTarget()
        if target == nil or target:isDead() then
            return false
        elseif manualSkill:getRangeType() == manualSkill.SINGLE and manualSkill:isInSkillRange(actor:getPosition(), target:getPosition(), false) == false then
            return false
        end
    end

    local skill = manualSkill
    if skill:getRangeType() == skill.MULTIPLE and skill:isNeedATarget() == false then
        local targets = actor:getMultipleTargetWithSkill(skill)
        if #targets < 1 then
            return false
        end
    end

    actor:attack(manualSkill, true)

    return true
end

function QAIDPS:_execute(args)
    local actor = args.actor

    -- if self:_charge(actor) then
    --     return true
    -- end

    -- if self:_blink(actor) then
    --     return true
    -- end

    if self:_attack(actor) then
        return true
    end

    return false
end

-- dps      需要做的事情优先等级，保命｛躲避aoe--躲避近战攻击，可以使用闪现等快速逃脱技能｝-释放伤害技能{对多目标释放aoe技能--对单体目标释放单体技能}
-- health   需要做的事情优先等级，群体治疗｛群体血量少于一定程度时释放群体治疗技能｝-保命{[同dps保命]--自己血量少于一定比例时治疗自己}-治疗t-治疗血少的角色
-- t        需要做的事情优先等级，拉仇恨｛寻找被攻击的非t英雄，嘲讽其攻击者｝-保命｛血量低时躲避aoe｝

-- local function QAIDPS:_avoidAOE() 
--     -- 检索trap

--     -- 检索敌方正在释放的aoe技能

--     -- 寻找出最近的脱离地点

--     -- 闪现过去，或者走过去
-- end

-- local function QAIDPS:_avoidMeleeAttack() 
--     -- 检索攻击自己的近战

--     -- 反方向闪现，或者走过去
-- end

function QAIDPS:_attackMultiple() 
    -- 寻找自己的可以释放的aoe技能
    local skill
    if skill:getRangeType() ~= skill.MULTIPLE then
        return false
    end

    if skill:isNeedATarget() then

    else
        local targets = actor:getMultipleTargetWithSkill(skill)
        if #targets >= 1 then

        end
    end

    -- 寻找可以释放的中心目标（可能是任何场上任何角色），评估效果

    -- 对达到标准的最高效果的中心目标释放
end

-- local function QAIDPS:_findBestTarget()
--     -- 寻找有效血量最低的目标
-- end

function QAIDPS:_attackSingle() 
    -- 寻找可以释放的单体技能

    -- 释放单体伤害技能
end

function QAIDPS:_treatMultiple() 
    -- 寻找可以释放的群体治疗技能

    -- 寻找可以释放的中心目标（可能是任何场上的角色），评估效果

    -- 对达到标准的最高效果的中心目标释放
end

function QAIDPS:_treatSingle() 
    -- 寻找有效血量最低的目标

    -- 释放单体治疗技能
end

function QAIDPS:_attackHatred() 
    -- 寻找当前没在攻击自己的敌人，设置其为目标
end

-- local function QAIDPS:_tauntMultiple() 
--     -- 寻找当前没在攻击自己的敌人

--     -- 释放群体嘲讽技能
-- end

-- local function QAIDPS:_tauntSingle() 

-- end


return QAIDPS