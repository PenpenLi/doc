--
-- Author: Your Name
-- Date: 2014-05-20 15:26:35
--
local QRectAnimationUI = class("QRectAnimationUI", function()
    return display.newNode()
end)

function QRectAnimationUI:ctor(maskView)
	self._maskView = maskView
	self:addChild(maskView)
	self:setNodeEventEnabled(true)
end

function QRectAnimationUI:onEnter()
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()
end

function QRectAnimationUI:onExit()
    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
end

function QRectAnimationUI:_onFrame(dt)
    if self._lastUpdate == nil then return end

    local speed = 1 -- 每秒消退血条的速度 1 = 100%
    local hang = 0.2 -- 在开始消退动画前停顿的时间

	if (app.battle:getTime() - self._lastUpdate - hang) < 0 then return end --停顿期

    local cur = self._lastPercent + (app.battle:getTime() - self._lastUpdate - hang) * speed * self._drict

    if self._drict > 0 and cur > self._percent then
        cur = self._percent
        self._lastUpdate = nil
    elseif self._drict < 0 and cur < self._percent then
        cur = self._percent
        self._lastUpdate = nil
	end

    self._maskView:update(cur)
end

function QRectAnimationUI:updateForAnimation(percent)
	self._lastUpdate = app.battle:getTime()
	self._lastPercent = self._maskView:getPercent()
	self._percent = percent
	if self._percent >= self._lastPercent then
		self._drict = 1
	elseif self._percent < self._lastPercent then
		self._drict = -1
	end
end

return QRectAnimationUI