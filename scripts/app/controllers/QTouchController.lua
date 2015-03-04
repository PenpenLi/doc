
local QTouchController = class("QTouchController", function()
    return display.newNode()
end)

local QBaseActorView = import("..views.QBaseActorView")
local QTouchActorView = import("..views.QTouchActorView")
local QBaseEffectView = import("..views.QBaseEffectView")
local QNotificationCenter = import(".QNotificationCenter")
local QBattleManager = import(".QBattleManager")

QTouchController.EVENT_TOUCH_END_FOR_SELECT = "EVENT_TOUCH_END_FOR_SELECT"
QTouchController.EVENT_TOUCH_END_FOR_MOVE = "EVENT_TOUCH_END_FOR_MOVE"
QTouchController.EVENT_TOUCH_END_FOR_ATTACK = "EVENT_TOUCH_END_FOR_ATTACK"

QTouchController.FLASH_EFFECT_FILE = "cricle_2"

function QTouchController:ctor( option )
    self._circle = CCSprite:create(global.ui_drag_line_circle)
    self._circle:setScaleX(0.5)
    self._circle:setScaleY(0.25)
    self:addChild(self._circle)
    self._circle:setVisible(false)

    self._flashEffect = QBaseEffectView.new(QTouchController.FLASH_EFFECT_FILE, nil)
    self:addChild(self._flashEffect, -2)
    self._flashEffect:setVisible(false)

    self._touchEpsilon = 5.0

    self:setNodeEventEnabled(true)
end

function QTouchController:onEnter()
    self:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
    -- self:setCascadeBoundingBox(CCRect(BATTLE_AREA.left, BATTLE_AREA.bottom, BATTLE_AREA.width, BATTLE_AREA.height))
    self:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self:setTouchSwallowEnabled(false)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self.onTouch))
end

function QTouchController:onExit()
    self:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
end

function QTouchController:enableTouchEvent()
    self._disableSelfAndNoticeDrag = false
    self._selectActorView = nil
    self._selectActorViewTemp = nil
    self._selectTempIsEnemy = false
    self._heroViews = nil
    self._enemyViews = nil

    self:setTouchEnabled( true )

    self._eventProxy = cc.EventProxy.new(app.battle)
    self._eventProxy:addEventListener(QBattleManager.HERO_CLEANUP, handler(self, self._onHeroCleanup))
end

function QTouchController:disableTouchEvent()
    self._selectActorView = nil
    self._selectActorViewTemp = nil
    self._heroViews = nil
    self._enemyViews = nil

    self:setTouchEnabled( false )

    if self._eventProxy ~= nil then
        self._eventProxy:removeAllEventListeners()
        self._eventProxy = nil
    end
end

function QTouchController:_onHeroCleanup(event)
    if self._selectActorView ~= nil then
        if self._selectActorView:getModel() == event.hero then
            self._selectActorView = nil
        end
    end 
end

function QTouchController:setSelectActorView(actorView)
    if self._selectActorView ~= actorView then
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchController.EVENT_TOUCH_END_FOR_SELECT, oldSelectView = self._selectActorView, newSelectView = actorView})
        self._selectActorView = actorView
    end
end

function QTouchController:getSelectActorView()
    return self._selectActorView
end

function QTouchController:onTouch(event)
    if app.battle:isPVPMode() then
        if app.battle:isInArena() then
            app.tip:floatTip("竞技场中只能自动战斗!") 
            return
        elseif app.battle:isInSunwell() then
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
        self:onTouchEnd(event.name, event.x, event.y)
    end
end

function QTouchController:onTouchBegin( event, x, y )
    self._heroViews = app.scene:getHeroViews()
    self._enemyViews = app.scene:getEnemyViews()
    
    local actorViews = {}
    local heroes = app.battle:getHeroes()
    for i, view in ipairs(self._heroViews) do
        for _, hero in ipairs(heroes) do
            if hero == view:getModel() then
                table.insert(actorViews, view)
                break
            end
        end
    end

    local enemies = app.battle:getEnemies()
    for i, view in ipairs(self._enemyViews) do
        for _, enemy in ipairs(enemies) do
            if enemy == view:getModel() then
                table.insert(actorViews, view)
                break
            end
        end
    end

    local sortedActorView = q.sortNodeZOrder(actorViews, true)
    self._selectActorViewTemp = QBattle.getTouchingActor(sortedActorView, x, y)

    self._selectTempIsEnemy = false
    if self._selectActorViewTemp ~= nil then
        for i, view in ipairs(self._enemyViews) do
            if self._selectActorViewTemp == view then
                self._selectTempIsEnemy = true
                break
            end
        end
    else
        if self._selectActorView ~= nil then
            self._circle:setPosition(ccp(x, y))
            self._circle:setVisible(true)
        end
    end

    self._disableSelfAndNoticeDrag = false

    self._beginPointX = x
    self._beginPointY = y

    return true
end

function QTouchController:onTouchMoved( event, x, y )
    if self._disableSelfAndNoticeDrag == false then
        if math.abs(self._beginPointX - x) < self._touchEpsilon and math.abs(self._beginPointY - y) < self._touchEpsilon then
            return
        end
    end

    if self._selectActorViewTemp ~= nil then
        self._circle:setVisible(false)
        self._disableSelfAndNoticeDrag = true
        return
    end

    if self._selectActorView == nil then
        return
    end

    if self._disableSelfAndNoticeDrag == false then
        self._circle:setVisible(false)
        self._disableSelfAndNoticeDrag = true
        local posX, posY = self._selectActorView:getPosition()
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchActorView.EVENT_ACTOR_TOUCHED_BEGIN, actorView = self._selectActorView, positionX = posX, positionY = posY})
    end

    self._selectActorView:onTouchMoved(event, x, y)

end

function QTouchController:onTouchEnd( event, x, y )
    self._touch_end = true

    self._circle:setVisible(false)

    if self._disableSelfAndNoticeDrag == true then
        if self._selectActorView ~= nil then
            self._selectActorView:onTouchEnd(event, x, y)
        end
        self._selectActorViewTemp = nil
        return
    end

    if self._selectActorViewTemp == nil then
        -- touch and move
        if self._selectActorView ~= nil then
            self:_flashMoveEffect(ccp(x, y))
            QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchController.EVENT_TOUCH_END_FOR_MOVE, heroView = self._selectActorView, positionX = x, positionY = y})
        end
        return
    end

    local actorViews = {}
    for i, view in ipairs(self._heroViews) do
        table.insert(actorViews, view)
    end

    for i, view in ipairs(self._enemyViews) do
        table.insert(actorViews, view)
    end

    local sortedActorView = q.sortNodeZOrder(actorViews, true)
    local selectActorView = QBattle.getTouchingActor(sortedActorView, x, y)

    if selectActorView ~= self._selectActorViewTemp then
        return
    end

    if self._selectActorView ~= nil then
        for i, view in ipairs(self._heroViews) do
            if view == self._selectActorViewTemp then
                -- select hero
                self:setSelectActorView(self._selectActorViewTemp)
                self._selectActorViewTemp = nil
                break
            end
        end
        if self._selectActorViewTemp ~= nil then
            for i, view in ipairs(self._enemyViews) do
                if view == self._selectActorViewTemp then
                    -- attack touched enemy
                    for i, view in ipairs(self._heroViews) do
                        if view:getModel():isHealth() == false then
                           QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchController.EVENT_TOUCH_END_FOR_ATTACK, heroView = view, targetView = self._selectActorViewTemp})
                        end
                    end
                    self._selectActorViewTemp:invisibleSelectCircle(QBaseActorView.TARGET_CIRCLE)
                    self._selectActorViewTemp:getModel():onMarked()
                    self._selectActorViewTemp = nil
                else
                    view:getModel():onUnMarked()
                end
            end
        end
    else
        if self._selectTempIsEnemy == true then
            for i, view in ipairs(self._heroViews) do
                if view:getModel():isHealth() == false then
                    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchController.EVENT_TOUCH_END_FOR_ATTACK, heroView = view, targetView = self._selectActorViewTemp})
                end
            end
            self._selectActorViewTemp:invisibleSelectCircle(QBaseActorView.TARGET_CIRCLE)
            self._selectActorViewTemp:getModel():onMarked()
        else
            self:setSelectActorView(self._selectActorViewTemp)
        end
        self._selectActorViewTemp = nil
    end
    
end

function QTouchController:_flashMoveEffect(position)
    self._flashEffect:setVisible(true)
    self._flashEffect:setPosition(position)
    self._flashEffect:playAnimation(EFFECT_ANIMATION)
    self._flashEffect:afterAnimationComplete(function()
        self._flashEffect:setVisible(false)
    end)
end

function QTouchController:isTouchEnded()
    local result = self._touch_end
    self._touch_end = nil
    return result
end

return QTouchController