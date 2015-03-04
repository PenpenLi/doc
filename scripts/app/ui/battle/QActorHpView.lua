
local QActorHpView = class("QActorHpView", function()
    return display.newNode()
end)

local QRectUiMask = import(".QRectUiMask")

function QActorHpView:ctor(actor)
    self._actor = actor

    self._foreground = QRectUiMask.new()

    if actor:getType() == ACTOR_TYPES.HERO then
        self._background = CCSprite:create(global.ui_hp_background_hero)
        self._foreground:addChild(CCSprite:create(global.ui_hp_foreground_hero))
    else 
        self._background = CCSprite:create(global.ui_hp_background_npc)
        self._foreground:addChild(CCSprite:create(global.ui_hp_foreground_npc))
    end

    self._middleground = QRectUiMask.new()
    local redBar = CCSprite:create(global.ui_hp_background_tmp)
    self._middleground:addChild(redBar)

    self:addChild(self._background)
    self:addChild(self._middleground) -- 用于血条消退动画的中间层
    self:addChild(self._foreground)

    self:setVisible(false)

    self:setCascadeOpacityEnabled(true)
    self._foreground:setCascadeOpacityEnabled(true)
    self._middleground:setCascadeOpacityEnabled(true)

    -- 用于血条消退的动画
    self:setNodeEventEnabled(true)
    self._percent = 1
end

function QActorHpView:onEnter()
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()
end

function QActorHpView:onExit()
    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
end

function QActorHpView:_onFrame(dt)
    if self._lastUpdate == nil then return end

    local speed = 2 -- 每秒消退血条的速度 1 = 100%
    local hang = 0.2 -- 在开始消退动画前停顿的时间

    local cur = self._lastPercent - (app.battle:getTime() - self._lastUpdate - 0.2) * speed 
    if cur > self._lastPercent then return end -- 尚在停顿期内

    if cur < self._percent then
        -- 已经消退到当前血条，停止动画
        cur = self._percent
        -- 重置时间等待下次掉血
        self._lastUpdate = nil
    end

    self._middleground:update(cur)
end

function QActorHpView:update(percent)
    self._foreground:update(percent)

    -- 记录上次更新的时间和当前的percent，用于血条消退的动画
    if self._lastUpdate == nil then
        self._lastUpdate = app.battle:getTime()
        self._lastPercent = self._percent
        self._middleground:update(self._percent)
    end

    self._percent = percent

    if self._fadeOutHandler ~= nil then
        scheduler.unscheduleGlobal(self._fadeOutHandler)
    end

    self:stopAllActions()

    self._fadeOutHandler = scheduler.performWithDelayGlobal(function()
            self._fadeOutHandler = nil
            local node = tolua.cast(self, "CCNode")
            if node ~= nil then
            -- 如果关卡退出了，这里依然有可能执行到，因此需要校验node是否依然有效
                node:runAction(CCFadeOut:create(global.ui_hp_hide_fadeout_time))
            end
    end, global.ui_hp_hide_delay_time)

    self:setVisible(true)
    self:setOpacity(255)
end

return QActorHpView