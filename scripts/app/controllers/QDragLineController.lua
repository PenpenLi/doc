--[[
    Class name QDragLineController 
    Create by julian 
    This controller of handle drag line stuff.
--]]
local QDragLineController = class("QDragLineController", function()
    return display.newNode()
end)

local QBaseActorView = import("..views.QBaseActorView")
local QTouchActorView = import("..views.QTouchActorView")
local QBaseEffectView = import("..views.QBaseEffectView")
local QNotificationCenter = import(".QNotificationCenter")
local QStaticDatabase = import("..controllers.QStaticDatabase")

QDragLineController.EVENT_DRAG_LINE_END_FOR_MOVE = "EVENT_DRAG_LINE_END_FOR_MOVE"
QDragLineController.EVENT_DRAG_LINE_END_FOR_ATTACK = "EVENT_DRAG_LINE_END_FOR_ATTACK"

QDragLineController.FLASH_EFFECT_FILE = "cricle_3"

--[[
    member of QDragLineController:
    _line: a CCSprite instance that display the drag line. default the line is hide
    _hero: 
    _targets: 
--]]

--[[
    options is a table value. Valid key below:
--]]
function QDragLineController:ctor( option )
    self._layer = display.newLayer()
    self:addChild(self._layer)

    self._line = CCSprite:create(global.ui_drag_line_green)
    self._line:setVisible(false)
    self._line:setAnchorPoint(ccp(0.0, 0.5))
    self._line:setScaleY(0.5)
    self:addChild(self._line)

    self._circle = CCSprite:create(global.ui_drag_line_circle)
    self._circle:setScaleX(1.0)
    self._circle:setScaleY(0.5)
    self:addChild(self._circle)
    self._circle:setVisible(false)

    self._flashEffect = QBaseEffectView.new(QDragLineController.FLASH_EFFECT_FILE, nil)
    self:addChild(self._flashEffect, -2)
    self._flashEffect:setVisible(false)

    self._enableDrag = false

    self:setNodeEventEnabled(true)

    if QDragLineController.DRAG_HERO_SLOW_DOWN_COEFFICIENT == nil then
        local coefficient = 0.2
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.DRAG_HERO_SLOW_DOWN_COEFFICIENT ~= nil and globalConfig.DRAG_HERO_SLOW_DOWN_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.DRAG_HERO_SLOW_DOWN_COEFFICIENT.value 
        end
        QDragLineController.DRAG_HERO_SLOW_DOWN_COEFFICIENT = coefficient
    end
    if QDragLineController.DRAG_HERO_SLOW_DOWN_DURATION == nil then
        local coefficient = 3
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.DRAG_HERO_SLOW_DOWN_DURATION ~= nil and globalConfig.DRAG_HERO_SLOW_DOWN_DURATION.value ~= nil then
            coefficient = globalConfig.DRAG_HERO_SLOW_DOWN_DURATION.value 
        end
        QDragLineController.DRAG_HERO_SLOW_DOWN_DURATION = coefficient
    end
end

function QDragLineController:onEnter()
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()
end

function QDragLineController:onExit()
    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
end

function QDragLineController:enableDragLine(heroView, startTouchPosition)
    if heroView == nil then 
        return
    end

    self._enableDrag = true
    self._canSelect = true
    self._isDraged = false
    self._startTouchPosition = startTouchPosition
    self._canTreatHeroSelf = false
    self._selectCountDown = 0.0

    self._heroView = heroView
    self._targetViews = nil
    self:_refreshTarget()
    self._selectTargetView = nil
    self._lastSelectTargetView = nil

    self._line:stopAllActions()
    self._line:setScaleX(0)
    self._line:setScaleY(0.5)
    self._line:setVisible(true)

    self._circle:setVisible(false)
    self._circle:stopAllActions()
    self._circle:setOpacity(255)

    self._touchPosition = ccp(self._heroView:getPosition())

    QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_INSIDE, self.onTouchActorViewEvent, self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_OUTSIDE, self.onTouchActorViewEvent, self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_REINSIDE, self.onTouchActorViewEvent, self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_END, self.onTouchActorViewEvent, self)

    app.battle:setTimeGear(QDragLineController.DRAG_HERO_SLOW_DOWN_COEFFICIENT)
    self._time_gear_start_time = q.time()
end

function QDragLineController:isSameWithTouchStartPosition(pos)
    if self._startTouchPosition == nil then
        return false 
    end
    return (math.abs(pos.x - self._startTouchPosition.x) < 15 and math.abs(pos.y - self._startTouchPosition.y) < 15)
end

--[[
    hide drag line and release actorView
--]]
function QDragLineController:disableDragLine(no_flash)
    -- if self._targetViews ~= nil then
    --     for i, actor in ipairs(self._targetViews) do
    --         actor:visibleSelectCircle(QBaseActorView.HIDE_CIRCLE)
    --     end
    -- end
    if self._selectTargetView ~= nil then
        if self._heroView:getModel():isHealth() == true then
            self._selectTargetView:invisibleSelectCircle(QBaseActorView.HEALTH_CIRCLE)
        else
            self._selectTargetView:invisibleSelectCircle(QBaseActorView.TARGET_CIRCLE)
        end
    else
        if self._isDraged == true and not no_flash then
            self:_flashMoveEffect(self._touchPosition)
        end
    end

    self._enableDrag = false
    self._heroView = nil
    self._targetViews = nil
    self._selectTargetView = nil
    self._lastSelectTargetView = nil
    self._lastDragFrame = nil
    self._startTouchPosition = nil

    local arr = CCArray:create()
    arr:addObject(CCScaleTo:create(0.04, self._line:getScaleX(), self._line:getScaleY() * 2.0))
    arr:addObject(CCScaleTo:create(0.06, self._line:getScaleX(), 0.0))
    arr:addObject(CCCallFunc:create(function()
        self._line:setVisible(false)
    end))
    self._line:runAction(CCSequence:create(arr))

    if not no_flash then
        self._circle:runAction(CCFadeOut:create(0.1))
    end

    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_INSIDE, self.onTouchActorViewEvent, self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_OUTSIDE, self.onTouchActorViewEvent, self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_REINSIDE, self.onTouchActorViewEvent, self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_END, self.onTouchActorViewEvent, self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_CANCELLED, self.onTouchActorViewEvent, self)

    app.battle:setTimeGear(1.0)
end

function QDragLineController:onTouchActorViewEvent(event)
    if self._enableDrag == false then
        return
    end

    if event == nil or event.actorView ~= self._heroView then
        return
    end

    local eventName = event.name

    -- re-compute touch position in battle area
    self._touchPosition = ccp(event.positionX, event.positionY)
    if self._touchPosition.x < BATTLE_AREA.left then
        self._touchPosition.x = BATTLE_AREA.left
    elseif self._touchPosition.x > BATTLE_AREA.left + BATTLE_AREA.width then
        self._touchPosition.x = BATTLE_AREA.left + BATTLE_AREA.width
    end

    if self._touchPosition.y < BATTLE_AREA.bottom then
        self._touchPosition.y = BATTLE_AREA.bottom
    elseif self._touchPosition.y > BATTLE_AREA.bottom + BATTLE_AREA.height then
        self._touchPosition.y = BATTLE_AREA.bottom + BATTLE_AREA.height
    end

    -- handle event
    if eventName == QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_INSIDE then
        self:_targetVisibleSelectCircle()
        self:_dragLineTo()

    elseif eventName == QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_OUTSIDE then
        self._canSelect = true
        self._isDraged = true
        self:_traceDragLine(false) 

    elseif eventName == QTouchActorView.EVENT_ACTOR_TOUCHED_MOVED_REINSIDE then
        self._canTreatHeroSelf = true
        self._canSelect = true
        self._isDraged = true
        self:_traceDragLine(self._heroView:getModel():isHealth())

    elseif eventName == QTouchActorView.EVENT_ACTOR_TOUCHED_END then
        if event.isMoved == true then
            if self._selectTargetView == nil then
                QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QDragLineController.EVENT_DRAG_LINE_END_FOR_MOVE, heroView = self._heroView, positionX = self._touchPosition.x, positionY = self._touchPosition.y})
            else
                QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QDragLineController.EVENT_DRAG_LINE_END_FOR_ATTACK, heroView = self._heroView, targetView = self._selectTargetView})
            end
        end
        self:disableDragLine()
    elseif eventName == eventName == QTouchActorView.EVENT_ACTOR_TOUCHED_CANCELLED then
        self:disableDragLine()
    end
end

function QDragLineController:_onFrame(dt)
    if self._enableDrag == false then
        return
    end

    if not self._heroView or not self._heroView.getModel or self._heroView:getModel():isDead() == true then
        self:disableDragLine(true)
        return
    end

    self:_refreshTarget()
    self:_traceDragLine((self._heroView:getModel():isHealth() and self._canTreatHeroSelf == true))

    if self._canSelect == false then
        self._selectCountDown = self._selectCountDown - CCDirector:sharedDirector():getDeltaTime()
        if self._selectCountDown <= 0.0 then
            self._canSelect = true
        end
    end

    if self._time_gear_start_time and q.time() - self._time_gear_start_time > QDragLineController.DRAG_HERO_SLOW_DOWN_DURATION then
        app.battle:setTimeGear(1.0)
        self._time_gear_start_time = nil
    end
end

function QDragLineController:_refreshTarget()
    local actorViews = nil
    if self._heroView:getModel():isHealth() then
        actorViews = app.scene:getHeroViews()
    else
        actorViews = app.scene:getEnemyViews()
    end

    local targetViews = {}
    for k, other in ipairs(actorViews) do
        if self._heroView ~= other and other:getModel():isDead() == false then
            table.insert(targetViews, other)
        end
    end

    if table.nums(targetViews) > 0 then
        self._targetViews = q.sortNodeZOrder(targetViews, true)
    else
        self._targetViews = {}
    end
end

function QDragLineController:_targetVisibleSelectCircle()
    if self._lastSelectTargetView == self._selectTargetView then
        return
    end

    if self._targetViews == nil or table.nums(self._targetViews) <= 0 then
        return
    end
    for i, actor in ipairs(self._targetViews) do
        actor:visibleSelectCircle(QBaseActorView.HIDE_CIRCLE)
    end
    if self._selectTargetView ~= nil then
        if self._heroView:getModel():isHealth() then
            self._selectTargetView:visibleSelectCircle(QBaseActorView.HEALTH_CIRCLE)
        else
            self._selectTargetView:visibleSelectCircle(QBaseActorView.TARGET_CIRCLE)
        end
    end
end

function QDragLineController:_dragLineTo()
    local positionX = self._touchPosition.x
    local positionY = self._touchPosition.y
    if self._selectTargetView == nil then
        if self._isDraged == true then
            self:_visibleCircle(true, ccp(positionX, positionY))
        end
    else
        self:_visibleCircle(false)
        positionX = self._selectTargetView:getPositionX()
        positionY = self._selectTargetView:getPositionY()
    end
    local startPosX, startPosY = self._heroView:getPosition()
    local deltaX = positionX - startPosX
    local deltaY = positionY - startPosY
    local scaleX = math.sqrt(deltaX * deltaX + deltaY * deltaY)

    self._line:setPosition(ccp(startPosX, startPosY))
    self._line:setScaleX(scaleX)
    -- －1.0 time to dgree because of cocos2d rotation is clockwise
    self._line:setRotation(math.deg(-1.0*math.atan2(deltaY, deltaX)))
end

function QDragLineController:_traceDragLine(includeSelfHero)

    if self._canSelect == true then
        local targetViews = {}
        if self._targetViews ~= nil then
            table.merge(targetViews, self._targetViews)
        end
        if includeSelfHero == true then
            table.insert(targetViews, self._heroView)
        end
        self._lastSelectTargetView = self._selectTargetView
        self._selectTargetView = QBattle.getTouchingActor(targetViews, self._touchPosition.x, self._touchPosition.y)
        if self._selectTargetView ~= nil then
            self._canSelect = false
            self._selectCountDown = 2.0
        end
    end

    local color = nil
    if self._selectTargetView ~= nil then
        if self._selectTargetView ~= self._lastSelectTargetView then
            if self._heroView:getModel():isHealth() then
                self._line:setTexture(CCTextureCache:sharedTextureCache():addImage(global.ui_drag_line_white))
            else
                printInfo("set texture global.ui_drag_line_yellow")
                self._line:setTexture(CCTextureCache:sharedTextureCache():addImage(global.ui_drag_line_yellow))
            end
            self._line:stopAllActions()
            local arr = CCArray:create()
            arr:addObject(CCScaleTo:create(0.1, self._line:getScaleX(), 0.5 * 1.5))
            arr:addObject(CCScaleTo:create(0.05, self._line:getScaleX(), 0.5))
            self._line:runAction(CCSequence:create(arr))
        end
    else
        local texture = CCTextureCache:sharedTextureCache():addImage(global.ui_drag_line_green)
        if self._line:getTexture() ~= texture then
            printInfo("set texture global.ui_drag_line_green")
            self._line:setTexture(CCTextureCache:sharedTextureCache():addImage(global.ui_drag_line_green))
            self._line:stopAllActions()
            self._line:setScaleY(0.5)
        end
       
    end

    self:_targetVisibleSelectCircle()
    self:_dragLineTo()
end

function QDragLineController:_visibleCircle(visible, position)
    self._circle:setVisible(visible)
    if position ~= nil then
         self._circle:setPosition(position)
    end
end

function QDragLineController:_flashMoveEffect(position)
    self._flashEffect:setVisible(true)
    self._flashEffect:setPosition(position)
    self._flashEffect:playAnimation(EFFECT_ANIMATION)
    self._flashEffect:afterAnimationComplete(function()
        self._flashEffect:setVisible(false)
    end)
end

return QDragLineController