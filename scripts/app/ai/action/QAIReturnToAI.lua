
local QAIAction = import("..base.QAIAction")
local QAIReturnToAI = class("QAIReturnToAI", QAIAction)

function QAIReturnToAI:ctor( options )
    QAIReturnToAI.super.ctor(self, options)
    self:setDesc("交由AI接管")
end

--[[
在满足一定条件下，将人工操作过的英雄交回给AI处理。
针对近攻和远攻的不同类型，交回AI的条件不一样。
--]]
function QAIReturnToAI:_execute(args)
    local actor = args.actor

    if actor.lastBusy == nil then
        actor.lastBusy = app.battle:getTime()
    end

    -- 如果其他任务还没完成，则不交回AI
    if not actor:isIdle() then 
        -- 用lastBusy让这里的逻辑变的简单一些
        -- 这里要求QAIReturnToAI在人物变成手动模式后执行至少一次，这个要求一般都会满足
        actor.lastBusy = app.battle:getTime()
        return false
    end

    -- 如果玩家不是让英雄移动到某个位置，而是让其攻击敌人，则不交回AI
    if actor:getManualMode() ~= actor.STAY then return false end

    if actor:isRanged() then
        -- 针对远攻英雄，立即交给AI去处理
        actor:setManualMode(actor.AUTO)
        return true
    end

    if actor:isForceAuto() and not actor:isWalking() then
        -- 针对开启了自动攻击的英雄，立即交给AI去处理
        actor:setManualMode(actor.AUTO)
        return true
    end

    -- 针对近攻英雄，则需要一定条件才能加回战斗，否则太危险
    local hp_above = self:getOptions().hp_above_for_melee
    local wait_time = self:getOptions().wait_time_for_melee

    if actor:getHp() / actor:getMaxHp() < hp_above then return false end
    if app.battle:getTime() - actor.lastBusy < wait_time then return false end

    actor:setManualMode(actor.AUTO)
    return true
end

return QAIReturnToAI