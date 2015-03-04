
local QAIAction = import("..base.QAIAction")
local QAIStopMoving = class("QAIStopMoving", QAIAction)

function QAIStopMoving:ctor( options )
    QAIStopMoving.super.ctor(self, options)
    self:setDesc("让ai停止移动")
end

function QAIStopMoving:_execute( args )
    local actor = args.actor

    actor:stopMoving()
    actor:setTarget(nil)
    local pos = actor:getPosition()
    app.grid:setActorTo(actor, pos)

    return true
end

return QAIStopMoving