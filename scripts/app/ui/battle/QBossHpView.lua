
local QBossHpView = class("QBossHpView", function()
    return display.newNode()
end)

local QRectUiMask = import(".QRectUiMask")
local QActor = import("...models.QActor")

function QBossHpView:ctor()
    local proxy = CCBProxy:create()
    self._owner = {}

    local node = CCBuilderReaderLoad("ccb/Battle_Widget_BossHealth.ccbi", proxy, self._owner)
    self:addChild(node)

    self._foreground = QRectUiMask.new()
    self._foreground:setFromLeftToRight(false)
    local hpForeground = self._owner.Sprite_BossHealthFG
    local positionX, positionY = hpForeground:getPosition()
    hpForeground:retain()
    hpForeground:removeFromParent()
    self._foreground:addChild(hpForeground)
    self._foreground:setPosition(positionX, positionY)
    hpForeground:setPosition(0.0, 0.0)
    hpForeground:release()

    self._background = QRectUiMask.new()
    self._background:setFromLeftToRight(false)
    local hpBackground = self._owner.Sprite_BossHealthBG    
    hpBackground:retain()
    hpBackground:removeFromParent()
    self._background:addChild(hpBackground)
    self._background:setPosition(positionX, positionY)
    hpBackground:setPosition(0.0, 0.0)
    hpBackground:release()

    self._owner.Node_BossHealth:addChild(self._background) -- 用于血条消退动画的中间层
    self._owner.Node_BossHealth:addChild(self._foreground) 

    self:setNodeEventEnabled(true)
    -- 用于血条消退的动画

    self._percent = 1
end

function QBossHpView:onEnter()
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()
end

function QBossHpView:onExit()
    if self._actor ~= nil and self._actorEventProxy ~= nil then
        self._actorEventProxy:removeEventListener(QActor.HP_CHANGED_EVENT, self._onHpChanged, self)
    end

    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
    if self._actorEventProxy ~= nil then
        self._actorEventProxy:removeAllEventListeners()
    end
end

function QBossHpView:setActor(actor)

    if self._actor ~= nil and self._actorEventProxy ~= nil then
        self._actorEventProxy:removeAllEventListeners()
    end

    self._actor = actor
    if actor ~= nil then
        self._owner.Sprite_BossIcon:setTexture(CCTextureCache:sharedTextureCache():addImage(self._actor:getIcon()))
        self:updateHpBar()
        self._actorEventProxy = nil
        self._actorEventProxy = cc.EventProxy.new(self._actor)
        self._actorEventProxy:addEventListener(QActor.HP_CHANGED_EVENT, handler(self, self._onHpChanged))
    end
end

function QBossHpView:getActor()
    return self._actor
end

function QBossHpView:_onFrame(dt)
    if self._lastUpdate == nil then return end

    local speed = 2 -- 每秒消退血条的速度 1 = 100%
    local hang = 0.2 -- 在开始消退动画前停顿的时间

    local cur = self._lastPercent - (q.time() - self._lastUpdate - 0.2) * speed 
    if cur > self._lastPercent then return end -- 尚在停顿期内

    if cur < self._percent then
        -- 已经消退到当前血条，停止动画
        cur = self._percent
        -- 重置时间等待下次掉血
        self._lastUpdate = nil
    end

    self._background:update(cur)
end

function QBossHpView:_onHpChanged(event)
    self:updateHpBar()
end

function QBossHpView:updateHpBar()
    if self._actor == nil or self._actor:isDead() == true then
        return
    end

    local percent = self._actor:getHp() / self._actor:getMaxHp()

    self._foreground:update(percent)

    -- 记录上次更新的时间和当前的percent，用于血条消退的动画
    if self._lastUpdate == nil then
        self._lastUpdate = q.time()
        self._lastPercent = self._percent
        self._background:update(self._percent)
    end

    self._percent = percent

    self:stopAllActions()
end

return QBossHpView