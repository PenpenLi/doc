--[[
    QNpcActorView 
--]]

local QTouchActorView = import(".QTouchActorView")
local QNpcActorView = class("QNpcActorView", QTouchActorView)

function QNpcActorView:ctor(actor, skeletonView)
    QNpcActorView.super.ctor(self, actor, skeletonView)
end

function QNpcActorView:onEnter()
    QNpcActorView.super.onEnter(self)
    self:setEnableTouchEvent(true)
end

function QNpcActorView:onExit()
    QNpcActorView.super.onExit(self)
    self:setEnableTouchEvent(false)
end

return QNpcActorView