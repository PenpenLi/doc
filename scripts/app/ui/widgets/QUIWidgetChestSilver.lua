--
-- Author: wkwang
-- Date: 2014-08-06 18:58:49
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetChestSilver = class("QUIWidgetChestSilver", QUIWidget)
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QRemote = import("...models.QRemote")

QUIWidgetChestSilver.EVENT_VIEW = "EVENT_VIEW"

function QUIWidgetChestSilver:ctor(options)
	local ccbFile = "ccb/Widget_TreasureChestDtraw_Silver.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerView", callback = handler(self, QUIWidgetChestSilver._onTriggerView)},
		}
	QUIWidgetChestSilver.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    self:init()
end

function QUIWidgetChestSilver:onEnter()
    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(QRemote.USER_UPDATE_EVENT, handler(self, self.onEvent))
end

function QUIWidgetChestSilver:onExit()
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end
	self._remoteProxy:removeAllEventListeners()
end

function QUIWidgetChestSilver:init()
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end
    self:_resetAll()
	local config = QStaticDatabase:sharedDatabase():getConfiguration()
	self._silverCount = config.LUCKY_DRAW_COUNT.value or 0 -- 白银宝箱的次数
	self._silverTime = config.LUCKY_DRAW_TIME.value or 0 -- 白银宝箱的CD时间
	self._silverCost = config.LUCKY_DRAW_MONEY_COST.value or 0 -- 白银宝箱购买所需金钱数量
	self._silverCurrTime = 0

	self._freeSilverCount = remote.user.todayLuckyDrawFreeCount or 0
	self._lastTime = (remote.user.luckyDrawRefreshedAt or 0)/1000
	self._CDTime = self._silverTime * 60

	local currTime = q.serverTime()
	if q.refreshTime(global.freshTime.silver_freshTime) > self._lastTime then
		self._freeSilverCount = self._silverCount
	else
		self._freeSilverCount = self._silverCount - self._freeSilverCount
	end
	
	if self._freeSilverCount == self._silverCount or (self._freeSilverCount > 0 and (currTime - self._lastTime) >= self._CDTime) then
		self:showFree()
	else
		self:showBuy()
	end	
end

function QUIWidgetChestSilver:showFree()
	self._ccbOwner.tf_free_money:setString("免费")
	self._ccbOwner.tf_silver_time:setString("免费次数："..self._freeSilverCount.."/"..self._silverCount)
end

function QUIWidgetChestSilver:showBuy()
	self._ccbOwner.tf_silver_money:setString(self._silverCost)
	
	if self._freeSilverCount > 0 then
		self._timeFun = function ()
			if self._timeHandler ~= nil then
				scheduler.unscheduleGlobal(self._timeHandler)
				self._timeHandler = nil
			end
			local offsetTime = q.serverTime() - self._lastTime
			if offsetTime < self._CDTime then
				self._timeHandler = scheduler.performWithDelayGlobal(self._timeFun,1)
				local date = q.timeToHourMinuteSecond(self._CDTime - offsetTime)
				self._ccbOwner.tf_silver_time:setString(date.." 后免费")
			else
				self:init()
			end
		end
		self._timeFun()
	else
		self._ccbOwner.tf_silver_time:setString("今日免费次数已用完")
	end
end

function QUIWidgetChestSilver:setIsFrist(b)
	self._ccbOwner.node_no_frist:setVisible(not b)
	self._ccbOwner.node_frist:setVisible(b)
end

function QUIWidgetChestSilver:_resetAll()
	self._ccbOwner.tf_silver_money:setString("")
	self._ccbOwner.tf_free_money:setString("")

	self._ccbOwner.tf_silver_time:setString("")
end

function QUIWidgetChestSilver:onEvent()
	self:init()
end

function QUIWidgetChestSilver:_onTriggerView()
	self:dispatchEvent({name = QUIWidgetChestSilver.EVENT_VIEW})
end

return QUIWidgetChestSilver