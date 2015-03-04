--
-- Author: wkwang
-- Date: 2014-08-06 18:58:49
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetChestGold = class("QUIWidgetChestGold", QUIWidget)
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QRemote = import("...models.QRemote")

QUIWidgetChestGold.EVENT_VIEW = "EVENT_VIEW"

function QUIWidgetChestGold:ctor(options)
	local ccbFile = "ccb/Widget_TreasureChestDtraw_Gold.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerView", callback = handler(self, QUIWidgetChestGold._onTriggerView)},
		}
	QUIWidgetChestGold.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    self:init()
end

function QUIWidgetChestGold:onEnter()
    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(QRemote.USER_UPDATE_EVENT, handler(self, self.onEvent))
end

function QUIWidgetChestGold:onExit()
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end
    self._remoteProxy:removeAllEventListeners()
end

function QUIWidgetChestGold:init()
    self:_resetAll()
	local config = QStaticDatabase:sharedDatabase():getConfiguration()
	
	self._goldCount = 1 -- 黄金宝箱的次数
	self._goldTime = config.ADVANCE_LUCKY_DRAW_TIME.value or 0 -- 黄金宝箱的CD时间
	self._goldCost = config.ADVANCE_LUCKY_DRAW_TOKEN_COST.value or 0 -- 黄金宝箱购买所需代币数量
	self._goldTenCost = config.ADVANCE_LUCKY_DRAW_10_TIMES_TOKEN_COST.value or 0 -- 黄金宝箱购买所需代币数量

	self._goldCurrTime = 0

	self._lastTime = (remote.user.luckyDrawAdvanceRefreshedAt or 0)/1000
	self._CDTime = self._goldTime * 60 * 60
	local currTime = q.serverTime()

	if (currTime - self._lastTime) >= self._CDTime then
		self:showFree()
	else
		self:showBuy()
	end	
end

function QUIWidgetChestGold:showFree()
	self._ccbOwner.tf_free_money:setString("免费")
end

function QUIWidgetChestGold:showBuy()
	self._ccbOwner.tf_gold_money:setString(self._goldCost)
	
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end
	self._timeFun = function ()
		self._timeHandler = nil
		local offsetTime = q.serverTime() - self._lastTime
		if offsetTime < self._CDTime then
			self._timeHandler = scheduler.performWithDelayGlobal(self._timeFun,1)
			local date = q.timeToHourMinuteSecond(self._CDTime - offsetTime)
			self._ccbOwner.tf_gold_time:setString(date.." 后免费")
		else
			self:init()
		end
	end
	self._timeFun()
end

function QUIWidgetChestGold:setIsFrist(b)
	self._ccbOwner.node_no_frist:setVisible(not b)
	self._ccbOwner.node_frist:setVisible(b)
end

function QUIWidgetChestGold:_resetAll()
	self._ccbOwner.tf_gold_money:setString("")
	self._ccbOwner.tf_free_money:setString("")

	self._ccbOwner.tf_gold_time:setString("")
end

function QUIWidgetChestGold:onEvent()
	self:init()
end

function QUIWidgetChestGold:_onTriggerView()
	self:dispatchEvent({name = QUIWidgetChestGold.EVENT_VIEW})
end

return QUIWidgetChestGold