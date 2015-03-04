
local QAIAction = import("..base.QAIAction")
local QAIAttackClosestEnemy = class("QAIAttackClosestEnemy", QAIAction)

function QAIAttackClosestEnemy:ctor( options )
    QAIAttackClosestEnemy.super.ctor(self, options)
    self:setDesc("攻击最近的敌人")
end

function QAIAttackClosestEnemy:_execute(args)
    local actor = args.actor

    if actor == nil then
        assert(false, "invalid args, actor is nil.")
        return false
    end

    if actor:getTarget() ~= nil and not actor:getTarget():isDead() then
        -- 如果当前已经选择了敌人，则继续保持
        assert(app.grid:hasActor(actor:getTarget()) == true)
        return true
    end

    local enemies = app.battle:getMyEnemies(actor)

    local target = actor:getClosestActor(enemies, self._options.in_battle_area)

    if target == nil then
        return false
    end

    actor:setTarget(target)
    return true
end

return QAIAttackClosestEnemy