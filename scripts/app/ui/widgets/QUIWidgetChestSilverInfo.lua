--
-- Author: wkwang
-- Date: 2014-08-06 18:58:49
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetChestSilverInfo = class("QUIWidgetChestSilverInfo", QUIWidget)
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")

QUIWidgetChestSilverInfo.EVENT_BACK = "EVENT_BACK"

function QUIWidgetChestSilverInfo:ctor(options)
	local ccbFile = "ccb/Widget_TreasureChestDtraw_SilverNext.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerBack", callback = handler(self, QUIWidgetChestSilverInfo._onTriggerBack)},
			{ccbCallbackName = "onTriggerBuyOne", callback = handler(self, QUIWidgetChestSilverInfo._onTriggerBuyOne)},
			{ccbCallbackName = "onTriggerBuyTen", callback = handler(self, QUIWidgetChestSilverInfo._onTriggerBuyTen)},
		}
	QUIWidgetChestSilverInfo.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    self:init()
end

function QUIWidgetChestSilverInfo:onExit()
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end	
end

function QUIWidgetChestSilverInfo:init()
    self:_resetAll()
	local config = QStaticDatabase:sharedDatabase():getConfiguration()
	self._silverCount = config.LUCKY_DRAW_COUNT.value or 0 -- 白银宝箱的次数
	self._silverTime = config.LUCKY_DRAW_TIME.value or 0 -- 白银宝箱的CD时间
	self._silverCost = config.LUCKY_DRAW_MONEY_COST.value or 0 -- 白银宝箱购买所需金钱数量
	self._silverTenCost = config.LUCKY_DRAW_10_TIMES_MONEY_COST.value or 0 -- 白银宝箱购买所需金钱数量
	self._silverCurrTime = 0

	self._freeSilverCount = remote.user.todayLuckyDrawFreeCount or 0
	self._lastTime = (remote.user.luckyDrawRefreshedAt or 0)/1000
	self._CDTime = self._silverTime * 60
	local currTime = q.serverTime()

	self._ccbOwner.tf_silver_ten_money:setString(self._silverTenCost)
	
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

function QUIWidgetChestSilverInfo:setIsFrist(b)
	self._isFrist = b
end

function QUIWidgetChestSilverInfo:fristBuyHandler()
	if self._isFrist == true then
		remote.flag:set(remote.flag.FLAG_FRIST_SILVER_CHEST, 1)
	end
end

function QUIWidgetChestSilverInfo:showFree()
	self._ccbOwner.node_free:setVisible(true)
	self._ccbOwner.tf_silver_free:setString(self._freeSilverCount.."/"..self._silverCount)
end

function QUIWidgetChestSilverInfo:showBuy()
	self._ccbOwner.tf_silver_money:setString(self._silverCost)
	
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end	
	if self._freeSilverCount > 0 then
		self._timeFun = function ()
			local offsetTime = q.serverTime() - self._lastTime
			if offsetTime < self._CDTime then
				local date = q.timeToHourMinuteSecond(self._CDTime - offsetTime)
				self._ccbOwner.tf_silver_time:setString(date.." 后免费")
			else
				self:init()
			end
			self._timeHandler = scheduler.performWithDelayGlobal(self._timeFun,1)
		end
		self._timeFun()
	else
		self._ccbOwner.tf_silver_time:setString("今日免费次数已用完")
	end
end

function QUIWidgetChestSilverInfo:_resetAll()
	self._ccbOwner.tf_silver_time:setString("")
	self._ccbOwner.tf_silver_money:setString("")
	self._ccbOwner.node_free:setVisible(false)
	self._ccbOwner.tf_silver_free:setString("")
	self._ccbOwner.tf_silver_ten_money:setString("")
end

function QUIWidgetChestSilverInfo:_onTriggerBack()
	self:dispatchEvent({name = QUIWidgetChestSilverInfo.EVENT_BACK})
end

function QUIWidgetChestSilverInfo:_onTriggerBuyOne()
	self._oldHeros = clone(remote.herosUtil:getHaveHeroKey())
	if self._ccbOwner.node_free:isVisible() == true or self:_checkMoney(self._silverCost) == true then
		local oldMoney = remote.user.money
		app:getClient():luckyDraw(1, function(data)
					remote.user:addPropNumForKey("addupLuckydrawCount")
					if oldMoney ~= remote.user.money then
						self:fristBuyHandler()
					end
          self:checkMainPageRedTip()
					self:init()
					remote.items:getRewardItemsTips(data.prizes, self._oldHeros, self._silverCost, handler(self, self._onTriggerBuyOne), ITEM_TYPE.MONEY)
				end)
	end
end

function QUIWidgetChestSilverInfo:_onTriggerBuyTen()
	self._oldHeros = clone(remote.herosUtil:getHaveHeroKey())
	if self:_checkMoney(self._silverTenCost) == true then
		app:getClient():luckyDraw(10, function(data)
					remote.user:addPropNumForKey("addupLuckydrawCount", 10)  
					self:checkMainPageRedTip()
					self:init()
					remote.items:getRewardItemsTips(data.prizes, self._oldHeros, self._silverTenCost, handler(self, self._onTriggerBuyTen), ITEM_TYPE.MONEY)
				end)
	end
end

function QUIWidgetChestSilverInfo:_checkMoney(cost)
	if remote.user.money < cost then
		app:alert({content="金钱不足，现在就去购买？",title="系统提示", comfirmBack = function(data)
				app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBuyVirtual", options = {typeName=ITEM_TYPE.MONEY}})
			end, callBack = function ()
			end})
		return false
	end
	return true
end

function QUIWidgetChestSilverInfo:checkMainPageRedTip()
    local page = app:getNavigationController():getTopPage()
    page:_checkRedTip()
end

return QUIWidgetChestSilverInfo