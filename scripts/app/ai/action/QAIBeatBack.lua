
local QAIAction = import("..base.QAIAction")
local QAIBeatBack = class("QAIBeatBack", QAIAction)

function QAIBeatBack:ctor( options )
    QAIBeatBack.super.ctor(self, options)
    self:setDesc("反击敌人")
end

--[[
进行反击，不需要反击的情况下返回false：
这个反击策略主要用于英雄空闲的时候。还有一个反击策略用于英雄不是空闲的时候。
1. 如果没有被人攻击过则不需要反击
2. 如果攻击者已经被打死则不需要反击
--]]
function QAIBeatBack:_execute(args)
    local actor = args.actor

    local attacker = actor:getLastAttacker()
    if attacker == nil or attacker:isDead() then return false end

    if self:getOptions().without_move then
        local actorWidth = actor:getRect().size.width / 2
        local targetWidth = attacker:getRect().size.width / 2
        local _, skillRange = actor:getTalentSkill():getSkillRange(false)

        local dx = math.abs(actor:getPosition().x - attacker:getPosition().x)
        local dy = math.abs(actor:getPosition().y - attacker:getPosition().y)

        if dx - actorWidth - targetWidth >= skillRange or dy >= skillRange * 0.6 then
        	return false
        end
    end

    actor:setTarget(attacker)

    return QAIBeatBack.super._execute(self, args)
end

return QAIBeatBack