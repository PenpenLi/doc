
local QOneTrackView = class("QOneTrackView", function()
    return display.newNode()
end)

function QOneTrackView:ctor( actor )
	self._actor = actor
    self._interval = nil

    self:setVisible(false)
    self:setNodeEventEnabled(true)

    local _actorEventProxy = cc.EventProxy.new(actor, self)
    self._actorEventProxy = _actorEventProxy

    do
        local ccbProxy = CCBProxy:create()
        local ccbOwner = {}
        self._nodeSkillBuff = CCBuilderReaderLoad("Widget_Battle_Buff.ccbi", ccbProxy, ccbOwner)
        self._owner = ccbOwner
        self._owner.sprite_icon:setTexture(CCTextureCache:sharedTextureCache():addImage(self._actor:getIcon()))
        self:addChild(self._nodeSkillBuff)
	end
end

function QOneTrackView:onEnter()
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()

    self._actorEventProxy:addEventListener(self._actor.ONE_TRACK_START_EVENT, handler(self, self.onActorEvent))
    self._actorEventProxy:addEventListener(self._actor.ONE_TRACK_END_EVENT, handler(self, self.onActorEvent))
end

function QOneTrackView:onExit()
    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)

    self._actorEventProxy:removeEventListener(self._actor.ONE_TRACK_START_EVENT, handler(self, self.onActorEvent))
    self._actorEventProxy:removeEventListener(self._actor.ONE_TRACK_END_EVENT, handler(self, self.onActorEvent))
end

function QOneTrackView:_updateIcon()
    local actorView = app.scene:getActorViewFromModel(self._actor)
    if actorView == nil then
        return
    end
    if actorView:isFlipX() then
        self:setPosition(0 - self._actor:getRect().size.width / 2 , self:getPositionY())
        self:setScaleX(-1)
        local scale = self._owner.sprite_icon:getScaleX()
        self._owner.sprite_icon:setScaleX(-1 * math.abs(scale))
        self._owner.sprite_icon:setPositionX(0 + self._owner.sprite_icon:getContentSize().width / 2)
    else
        self:setPosition(0 + self._actor:getRect().size.width / 2 , self:getPositionY())
        self:setScaleX(1)
        local scale = self._owner.sprite_icon:getScaleX()
        self._owner.sprite_icon:setScaleX(1 * math.abs(scale))
        self._owner.sprite_icon:setPositionX(0)
    end
    self._owner.sprite_icon:setTexture(CCTextureCache:sharedTextureCache():addImage(self._target:getIcon()))
end

function QOneTrackView:_updateAnimation()
    if self._interval and self._lastPlayTime then
        if q.time() - self._lastPlayTime > self._interval then
            -- self._lastTimePlay = nil
            -- self._nodeSkillBuff:removeFromParentAndCleanup(true)
            -- self._nodeSkillBuff = nil
            -- do
            --     local ccbProxy = CCBProxy:create()
            --     local ccbOwner = {}
            --     self._nodeSkillBuff = CCBuilderReaderLoad("Widget_Battle_Buff.ccbi", ccbProxy, ccbOwner)
            --     self._owner = ccbOwner
            --     self._owner.sprite_icon:setTexture(CCTextureCache:sharedTextureCache():addImage(self._target:getIcon()))
            --     self:addChild(self._nodeSkillBuff)
            -- end
            -- local animationManager = tolua.cast(self._nodeSkillBuff:getUserObject(), "CCBAnimationManager")
            -- if animationManager ~= nil then 
            --     animationManager:runAnimationsForSequenceNamed("Default Timeline")
            --     self._lastTimePlay = q.time()
            -- end
        end
    end
end

function QOneTrackView:_onFrame(dt)
	if self._actor == nil or self._actor:isDead() then
		self:setVisible(false)
		return
	end

	if self._target == nil or self._target:isDead() then
		self:setVisible(false)
		return
	end

    self:_updateAnimation()
    self:_updateIcon()
	self:setVisible(true)
end

function QOneTrackView:onActorEvent(event)
	local _target, _interval
	if event.name == self._actor.ONE_TRACK_START_EVENT then
		_target = event.track_target
        self._interval = event.interval
	elseif event.name == self._actor.ONE_TRACK_END_EVENT then
		_target = nil
	end
	if _target then
		self._target = _target
        self:_updateIcon()
		self:setVisible(true)

        local animationManager = tolua.cast(self._nodeSkillBuff:getUserObject(), "CCBAnimationManager")
        if animationManager ~= nil then 
            animationManager:runAnimationsForSequenceNamed("Default Timeline")
            self._lastPlayTime = q.time()
        end
	end
	self._target = _target
end

return QOneTrackView