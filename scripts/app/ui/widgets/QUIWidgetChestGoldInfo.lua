--
-- Author: wkwang
-- Date: 2014-08-06 18:58:49
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetChestGoldInfo = class("QUIWidgetChestGoldInfo", QUIWidget)
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")

QUIWidgetChestGoldInfo.EVENT_BACK = "EVENT_BACK"

function QUIWidgetChestGoldInfo:ctor(options)
	local ccbFile = "ccb/Widget_TreasureChestDtraw_GoldNextPage.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerBack", callback = handler(self, QUIWidgetChestGoldInfo._onTriggerBack)},
			{ccbCallbackName = "onTriggerBuyOne", callback = handler(self, QUIWidgetChestGoldInfo._onTriggerBuyOne)},
			{ccbCallbackName = "onTriggerBuyTen", callback = handler(self, QUIWidgetChestGoldInfo._onTriggerBuyTen)},
		}
	QUIWidgetChestGoldInfo.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    self:init()
end

function QUIWidgetChestGoldInfo:onExit()
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end	
end

function QUIWidgetChestGoldInfo:init()
    self:_resetAll()
    self._freeGoldCount = 0
	local config = QStaticDatabase:sharedDatabase():getConfiguration()
	
	self._goldCount = 1 -- 黄金宝箱的次数
	self._goldTime = config.ADVANCE_LUCKY_DRAW_TIME.value or 0 -- 黄金宝箱的CD时间
	self._goldCost = config.ADVANCE_LUCKY_DRAW_TOKEN_COST.value or 0 -- 黄金宝箱购买所需代币数量
	self._goldTenCost = config.ADVANCE_LUCKY_DRAW_10_TIMES_TOKEN_COST.value or 0 -- 黄金宝箱购买所需代币数量
	self._goldCurrTime = 0

	self._lastTime = (remote.user.luckyDrawAdvanceRefreshedAt or 0)/1000
	self._CDTime = self._goldTime * 60 * 60
	local currTime = q.serverTime()

	self._ccbOwner.tf_gold_ten_money:setString(self._goldTenCost)
	
	if (currTime - self._lastTime) >= self._CDTime then
		self._freeGoldCount = 1
		self:showFree()
	else
		self._freeGoldCount = 0
		self:showBuy()
	end	
end

function QUIWidgetChestGoldInfo:setIsFrist(b)
	self._isFrist = b
end

function QUIWidgetChestGoldInfo:fristBuyHandler()
	if self._isFrist == true then
		remote.flag:set(remote.flag.FLAG_FRIST_GOLD_CHEST, 1)
	end
end

function QUIWidgetChestGoldInfo:showFree()
	self._ccbOwner.node_free:setVisible(true)
end

function QUIWidgetChestGoldInfo:showBuy()
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

function QUIWidgetChestGoldInfo:_resetAll()
	self._ccbOwner.tf_gold_time:setString("")
	self._ccbOwner.tf_gold_money:setString("")
	self._ccbOwner.node_free:setVisible(false)
	self._ccbOwner.tf_gold_ten_money:setString("")
end

function QUIWidgetChestGoldInfo:_onTriggerBack()
	self:dispatchEvent({name = QUIWidgetChestGoldInfo.EVENT_BACK})
end

function QUIWidgetChestGoldInfo:_onTriggerBuyOne()
	self._oldHeros = clone(remote.herosUtil:getHaveHeroKey())
	if self:_checkMoney(self._goldCost) == true then
		local oldMoney = remote.user.token
		app:getClient():luckyDrawAdvance(1, function(data)
				remote.user:addPropNumForKey("addupLuckydrawAdvanceCount")
				if oldMoney ~= remote.user.token then
					self:fristBuyHandler()
				end  
        self:checkMainPageRedTip()
				self:init()
				remote.items:getRewardItemsTips(data.prizes, self._oldHeros, self._goldCost, handler(self, self._onTriggerBuyOne), ITEM_TYPE.TOKEN_MONEY, self._freeGoldCount)
				QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTutorialEvent.EVENT_GOLD_BUYONE})
			end)
	end
end

function QUIWidgetChestGoldInfo:_onTriggerBuyTen()
	self._oldHeros = clone(remote.herosUtil:getHaveHeroKey())
	if self:_checkMoney(self._goldTenCost) == true then
		app:getClient():luckyDrawAdvance(10, function(data)
				remote.user:addPropNumForKey("addupLuckydrawAdvanceCount", 10)  
        self:checkMainPageRedTip()
				self:init()
				remote.items:getRewardItemsTips(data.prizes, self._oldHeros, self._goldTenCost, handler(self, self._onTriggerBuyTen), ITEM_TYPE.TOKEN_MONEY, self._freeGoldCount)
			end)
	end
end

function QUIWidgetChestGoldInfo:_checkMoney(cost)
	if self._freeGoldCount <= 0 and remote.user.token < cost then
		app:alert({content="符石不足，赶快去充值吧！",title="系统提示",callBack=nil,comfirmBack = nil})
		return false
	end
	return true
end

function QUIWidgetChestGoldInfo:checkMainPageRedTip()
    local page = app:getNavigationController():getTopPage()
    page:_checkRedTip()
end

return QUIWidgetChestGoldInfo