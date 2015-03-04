
local QAIAction = import("..base.QAIAction")
local QAIHEALTH = class("QAIHEALTH", QAIAction)

function QAIHEALTH:ctor( options )
    QAIHEALTH.super.ctor(self, options)
    self:setDesc("")

    self:createRegulator(5)
end

function QAIHEALTH:_evaluate(args)
    if not args.actor or not args.actor:isForceAuto() then
        return false
    end

    return true
end

function QAIHEALTH:_execute(args)
    local actor = args.actor

    if actor:isManualMode() then
        return false
    end

    local manualSkill = actor:getManualSkills()[next(actor:getManualSkills())]
    if manualSkill == nil then
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
        elseif manualSkill:isInSkillRange(actor:getPosition(), target:getPosition(), false) == false then
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

    -- 检查血量，有人血量
    local teammates = app.battle:getMyTeammates(actor, true)
    local mostInjured = nil
    local mostInjuredPercent = 1.0
    local averageInjuredPercent = 0.0
    for _, mate in ipairs(teammates) do
        local injuredPercent = mate:getHp() / mate:getMaxHp()
        averageInjuredPercent = averageInjuredPercent + injuredPercent
        if injuredPercent <= 0.8 then
            if mostInjuredPercent > injuredPercent then
                mostInjured = mate
                mostInjuredPercent = injuredPercent
            end
        end
    end
    averageInjuredPercent  = averageInjuredPercent / #teammates 

    if skill:getRangeType() ~= skill.MULTIPLE then
        if mostInjured == nil then
            return false
        end
        actor:setTarget(mostInjured)
    else
        if mostInjured == nil and averageInjuredPercent * #teammates > (#teammates - 0.5) then
            return false
        end
    end

    actor:attack(manualSkill, true)

    return true
end

return QAIHEALTH