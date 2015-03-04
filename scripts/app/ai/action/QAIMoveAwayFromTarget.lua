
local QAIAction = import("..base.QAIAction")
local QAIMoveAwayFromTarget = class("QAIMoveAwayFromTarget", QAIAction)

function QAIMoveAwayFromTarget:ctor( options )
    QAIMoveAwayFromTarget.super.ctor(self, options)
    self:setDesc("远离目标的方向移动")
end

function QAIMoveAwayFromTarget:_evaluate(args)
    local actor = args.actor
    if actor == nil or actor:isDead() == true then
        return false
    end

    if self._target_position == nil then
        local target = actor:getTarget()
        if target == nil then 
            return false
        end
    end

    return true
end

function QAIMoveAwayFromTarget:_execute(args)
    local actor = args.actor
    local target = actor:getTarget()
    local options = self:getOptions()
    local distance = options.distance or 6
    if self._target_position == nil then
        local actorpos = actor:getPosition()
        local targetpos = target:getPosition()

        local pos = (actorpos.x > targetpos.x) and {x = actorpos.x + distance * global.pixel_per_unit, y = actorpos.y} or {x = actorpos.x - distance * global.pixel_per_unit, y = actorpos.y}
        self._target_position = pos
    end

    if q.is2PointsClose(self._target_position, actor:getPosition()) then
        self._target_position = nil
        return false
    else
        app.grid:moveActorTo(actor, self._target_position)
        return true
    end
end

return QAIMoveAwayFromTarget