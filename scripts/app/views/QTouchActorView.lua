--[[
    Class name QTouchActorView 
    Create by julian 
    This class is a handle some touch stuff
--]]

local QBaseActorView = import(".QBaseActorView")
local QTouchActorView = class("QTouchActorView", QBaseActorView)

local QNotificationCenter = import("..controllers.QNotificationCenter")

QTouchActorView.EVENT_ACTOR_TOUCHED_BEGIN = "EVENT_ACTOR_TOUCHED_BEGIN"
QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_INSIDE = "EVENT_ACTOR_TOUCHED_MOVED_INSIDE"
QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_OUTSIDE = "EVENT_ACTOR_TOUCHED_MOVED_OUTSIDE"
QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_REINSIDE = "EVENT_ACTOR_TOUCHED_MOVED_REINSIDE"
QTouchActorView.EVENT_ACTOR_TOUCHED_END = "EVENT_ACTOR_TOUCHED_END"
QTouchActorView.EVENT_ACTOR_TOUCHED_CANCELLED = "EVENT_ACTOR_TOUCHED_CANCELLED"

--[[
    member of QTouchActorView:
    _canTouchBegin: whether the actor can be touch at begin. default value is false
--]]

--[[
--]]
function QTouchActorView:ctor(actor, skeletonView)
    QTouchActorView.super.ctor(self, actor, skeletonView)
    self._canTouchBegin = false
    self._isTouchMoved = false
    self._canTouchReinside = false

    if DISPLAY_ACTOR_RECT == true then
        local rect = self:getModel():getBoundingBox()
        local vertices = {}
        table.insert(vertices, {rect.origin.x, rect.origin.y})
        table.insert(vertices, {rect.origin.x, rect.origin.y + rect.size.height})
        table.insert(vertices, {rect.origin.x + rect.size.width, rect.origin.y + rect.size.height})
        table.insert(vertices, {rect.origin.x + rect.size.width, rect.origin.y})
        local param = {
            fillColor = ccc4f(0.0, 0.0, 0.0, 0.0),
            borderWidth = 1,
            borderColor = ccc4f(1.0, 0.0, 0.0, 1.0)
        }
        local drawNode = CCDrawNode:create()
        drawNode:clear()
        drawNode:drawPolygon(vertices, param) -- red color
        self:addChild(drawNode)
    end

    if DISPLAY_ACTOR_CORE_RECT == true then
        local rect = self:getModel():getCoreBoundingBox()
        local vertices = {}
        table.insert(vertices, {rect.origin.x, rect.origin.y})
        table.insert(vertices, {rect.origin.x, rect.origin.y + rect.size.height})
        table.insert(vertices, {rect.origin.x + rect.size.width, rect.origin.y + rect.size.height})
        table.insert(vertices, {rect.origin.x + rect.size.width, rect.origin.y})
        local param = {
            fillColor = ccc4f(0.0, 0.0, 0.0, 0.0),
            borderWidth = 1,
            borderColor = ccc4f(1.0, 1.0, 0.0, 1.0)
        }
        local drawNode = CCDrawNode:create()
        drawNode:clear()
        drawNode:drawPolygon(vertices, param) -- yellow color
        self:addChild(drawNode)
    end
end

function QTouchActorView:onEnter()
    QTouchActorView.super.onEnter(self)

    self:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self:setTouchSwallowEnabled(true)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self.onTouch))
end

function QTouchActorView:onExit()
    QTouchActorView.super.onExit(self)
    
    self:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
end

--[[
    enable or disable listen to touch event
    enable: bool value
--]]
function QTouchActorView:setEnableTouchEvent( enable )
    if enable == true then
        self:setTouchEnabled( true )
    else
        self:setTouchEnabled( false )
    end
end

--[[
    handle touch event
--]]
function QTouchActorView:onTouch(event)
    if app.battle:isPVPMode() then
        if app.battle:isInArena() then
            app.tip:floatTip("竞技场中只能自动战斗!") 
            return
        elseif app.battle:isPVPMode() then
            if not app.battle:isSunwellAllowControl() then
                app.tip:floatTip("决战太阳之井中不允许操作英雄走动和集火!") 
                return
            end
        end
    end

    local scale = BATTLE_SCREEN_WIDTH / UI_DESIGN_WIDTH
    if event.x ~= nil then
        event.x = event.x * scale
    end
    if event.y ~= nil then
        event.y = event.y * scale
    end

    if event.name == "began" then
        return self:onTouchBegin(event.name, event.x, event.y)
    elseif event.name == "moved" then
        self:onTouchMoved(event.name, event.x, event.y)
    elseif event.name == "ended" then
        self:onTouchEnd(event.name, event.x, event.y)
    elseif event.name == "cancelled" then
        self:onTouchCancelled(event.name, event.x, event.y)
    end
end

function QTouchActorView:onTouchBegin( event, x, y )
    self._isTouchMoved = false
    self._canTouchReinside = false
    if self._canTouchBegin == false or self:getModel():isDead() == true then
        self:setTouchSwallowEnabled(false)
    elseif self:isTouchMoveOnMe(x, y) == false then
        self:setTouchSwallowEnabled(false)
    else
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchActorView.EVENT_ACTOR_TOUCHED_BEGIN, actorView = self, positionX = x, positionY = y})
        self:setTouchSwallowEnabled(true)
    end

    return true
end

function QTouchActorView:onTouchMoved( event, x, y )
    if self._canTouchBegin == false then
        return
    end

    if self:isTouchMoveOnMe(x, y) == true then
        if self._canTouchReinside == true then
            QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_REINSIDE, actorView = self, positionX = x, positionY = y})
        else
            QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_INSIDE, actorView = self, positionX = x, positionY = y})
        end
    else 
        self._canTouchReinside = true
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_OUTSIDE, actorView = self, positionX = x, positionY = y})
    end
    self._isTouchMoved = true
end

function QTouchActorView:onTouchEnd( event, x, y )
    if self._canTouchBegin == false then
        return
    end
    
    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchActorView.EVENT_ACTOR_TOUCHED_END, isMoved = self._isTouchMoved, actorView = self, positionX = x, positionY = y})
end

function QTouchActorView:onTouchCancelled( event, x, y )
    -- CCMessageBox("ONTOUCHCANCELLED", "")

    if self._canTouchBegin == false then
        return
    end
    
    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchActorView.EVENT_ACTOR_TOUCHED_CANCELLED, isMoved = self._isTouchMoved, actorView = self, positionX = x, positionY = y})
end

--[[
    touchPoint: a CCPoint value contain the touch point
    return true when touch point in actor or false when not.
--]]
function QTouchActorView:isTouchMoveOnMe( x, y )
    local rect = self:getModel():getBoundingBox()
    if rect:containsPoint(ccp(x, y)) then
        return true
    end
    return false
end

function QTouchActorView:isTouchMoveOnMeDeeply( x, y )
    local rect = self:getModel():getCoreBoundingBox()
    if rect:containsPoint(ccp(x, y)) then
        return true
    end
    return false
end

function QTouchActorView:getTouchWeight( x, y, coefficient )
    local rect = self:getModel():getBoundingBox()
    if rect:containsPoint(ccp(x, y)) == false then
        return 0
    end

    local halfWidth = rect.size.width * 0.5
    local halfHeight = rect.size.height * 0.5
    local center = ccp(rect.origin.x + halfWidth, rect.origin.y + halfHeight)
    local percentX = math.abs(x - center.x) / halfWidth
    local percentY = math.abs(y - center.y) / halfHeight

    return  ( coefficient * (1.0 - math.sqrt((percentX * percentX + percentY * percentY) * 0.5)) )
end

function QTouchActorView:_onFrame(dt)
    QTouchActorView.super._onFrame(self, dt)

    local scale = UI_DESIGN_WIDTH / BATTLE_SCREEN_WIDTH
    local rect = self:getModel():getCoreBoundingBox()
    local x, y = self:getPosition()
    self:setCascadeBoundingBox(CCRect((x - rect.size.width * 0.5) * scale, y * scale, rect.size.width * scale, rect.size.height * scale))
end

return QTouchActorView