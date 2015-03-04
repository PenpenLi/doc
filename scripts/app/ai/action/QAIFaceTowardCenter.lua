
local QAIAction = import("..base.QAIAction")
local QAIFaceTowardCenter = class("QAIFaceTowardCenter", QAIAction)

function QAIFaceTowardCenter:ctor( options )
    QAIFaceTowardCenter.super.ctor(self, options)
    self:setDesc("转身面向屏幕中心垂线")
end

function QAIFaceTowardCenter:_evaluate(args)
    return true
end

function QAIFaceTowardCenter:_execute(args)
    local actor = args.actor
    if actor and not actor:isDead() then
        local view = app.scene:getActorViewFromModel(actor)
        if view and math.xor(actor:getPosition().x < BATTLE_AREA.left + BATTLE_AREA.width / 2, view:getDirection() == view.DIRECTION_RIGHT) then
            view:_setFlipX()
        end
    end

    return true
end

return QAIFaceTowardCenter