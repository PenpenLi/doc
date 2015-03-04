
local QAIAction = import("..base.QAIAction")
local QAIDPSARENA = class("QAIDPSARENA", QAIAction)

function QAIDPSARENA:ctor( options )
    QAIDPSARENA.super.ctor(self, options)
    self:setDesc("")

    if not QAIDPSARENA.TARGET_ORDER then
        local TARGET_ORDER = {}
        if options.target_order then
            for _, obj in pairs(options.target_order) do
                TARGET_ORDER[obj.actor_id] = obj.order
            end
        end

        QAIDPSARENA.TARGET_ORDER = TARGET_ORDER
    end

    self:createRegulator(5)
end

function QAIDPSARENA:_evaluate(args)
    if not args.actor then
        return false
    end

    if not self._target_order then
        self._target_order = QAIDPSARENA.TARGET_ORDER[args.actor:getActorID()]
        if not self._target_order then
            self._target_order = {1,2,3,4}
        end
    end

    if not self._targets then
        local enemies = app.battle:getMyEnemies(args.actor)
        local target = nil
        local arr = {}
        for index, enemy in ipairs(enemies) do
            arr[#enemies + 1 - index] = enemy
        end
        self._targets = arr
    end

    return true
end

function QAIDPSARENA:_pickTarget(actor)
    if app.battle:isInSunwell() then
        if actor:getTarget() then
            return
        end
    elseif app.battle:isInArena() then
        if actor:getTarget() and actor:isAttacking() then
            return
        end
    end

    local target = nil
    for _, index in ipairs(self._target_order) do
        local enemy = self._targets[index]
        if enemy and not enemy:isDead() then
            target = enemy
            break
        end
    end

    if target and actor:getTarget() ~= target then
        actor:setTarget(target)
    end
end

function QAIDPSARENA:_blink(actor)
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
        local forbid_length = math.ceil(ny / 3)
        local dist_max = 3 / 6 * nx
        local weights = {}
        local index = 1
        for i = 1, nx do
            for j = 1, ny do
                weights[index] = 0

                if (i < forbid_length and j > ny - forbid_length)
                    or (i > nx - forbid_length and j > ny - forbid_length) then
                    weights[index] = -999999
                end

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

function QAIDPSARENA:_charge(actor)
    if actor:isRanged() or self._chargeSkill == false then
        return
    end

    local chargeSkill = self._chargeSkill

    if chargeSkill == nil then
        for _, skill in pairs(actor:getActiveSkills()) do
            if skill:getSkillType() == skill.ACTIVE and skill:getTriggerCondition() == skill.TRIGGER_CONDITION_DRAG_ATTACK then
                chargeSkill = skill
                break
            end
        end

        if chargeSkill == nil then
            self._chargeSkill = false
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

function QAIDPSARENA:_attack(actor)
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

function QAIDPSARENA:_execute(args)
    local actor = args.actor

    if self._regulator() then
        self:_pickTarget(actor)

        if actor:isForceAuto() then
            if not (app.battle:isInSunwell() and actor:getType() == ACTOR_TYPES.HERO) then
                if self:_blink(actor) then
                    return true
                end
                if self:_charge(actor) then
                    return true
                end
            end

            if self:_attack(actor) then
                return true
            end
        end
    end

    return true
end


return QAIDPSARENA