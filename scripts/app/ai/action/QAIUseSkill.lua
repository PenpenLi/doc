
local QAIAction = import("..base.QAIAction")
local QAIUseSkill = class("QAIUseSkill", QAIAction)

function QAIUseSkill:ctor( options )
    QAIUseSkill.super.ctor(self, options)
    self:setDesc("使用技能")
end

function QAIUseSkill:_evaluate(args)
    return true
end

function QAIUseSkill:useSkillForActor(actor, skillId)
    if actor == nil or actor:isDead() == true then
        return false
    end

    if skillId == nil then
        return false
    end

    local skill = actor:getSkillWithId(skillId)
    if skill == nil then
        return false
    end

    if skill:getSkillType() == skill.PASSIVE then
        return true
    end

    if skill:isNeedATarget() == true then
        if actor:getTarget() == nil or actor:getTarget():isDead() == true then
            return false
        end
    end

    actor:attack(skill)

    return true
end

function QAIUseSkill:_execute(args)
    return self:useSkillForActor(args.actor, self._options.skill_id)
end

return QAIUseSkill