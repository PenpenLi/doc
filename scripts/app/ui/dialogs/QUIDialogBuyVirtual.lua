--
-- Author: Your Name
-- Date: 2014-07-24 10:58:34
--
local QUIDialog = import(".QUIDialog")
local QUIDialogBuyVirtual = class("QUIDialogBuyVirtual", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetBuyVirtualLog = import("..widgets.QUIWidgetBuyVirtualLog")
local QUIWidgetAnimationPlayer = import("..widgets.QUIWidgetAnimationPlayer")
local QVIPUtil = import("...utils.QVIPUtil")

function QUIDialogBuyVirtual:ctor(options)
	local ccbFile = "ccb/Dialog_Buy.ccbi";
	local callBacks = {
		{ccbCallbackName = "onTriggerBuy", callback = handler(self, QUIDialogBuyVirtual._onTriggerBuy)},
		{ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogBuyVirtual._onTriggerClose)},
		{ccbCallbackName = "onTriggerBuyAgain", callback = handler(self, QUIDialogBuyVirtual._onTriggerBuyAgain)},
		{ccbCallbackName = "onTriggerVIP", callback = handler(self, QUIDialogBuyVirtual._onTriggerVIP)},
	}
	QUIDialogBuyVirtual.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true --是否动画显示

	self._typeName = options.typeName
	if options.enough == nil then
		self._enough = true
	else
		self._enough = options.enough
	end
	self._ccbOwner.tf_1:setString("")
	self._ccbOwner.tf_2:setString("")
	self._ccbOwner.tf_buy:setString("")
	self._ccbOwner.tf_need_num:setString("")
	self._ccbOwner.tf_receive_num:setString("")
	self._ccbOwner.tf_tips:setString("")
	self._ccbOwner.node_title_money:setVisible(false)
	self._ccbOwner.node_title_energy:setVisible(false)
	self._ccbOwner.icon_energy:setVisible(false)
	self._ccbOwner.icon_money:setVisible(false)
	self._ccbOwner.node_energy:setVisible(false)
	self._ccbOwner.node_money:setVisible(false)
	self._ccbOwner.btn_buyAgain:setVisible(false)
	self._ccbOwner.btn_buy:setVisible(false)
	self._ccbOwner.btn_VIP_Info:setVisible(false)
	-- scheduler.performWithDelayGlobal(handler(self,self.refreshInfo),0)
	self:refreshInfo()
	self._isAnimation = false
	-- self:getView():setVisible(false)
end

function QUIDialogBuyVirtual:viewWillDisappear()
    QUIDialogBuyVirtual.super.viewDidAppear(self)
    if self._delayHandler ~= nil then
		scheduler.unscheduleGlobal(self._delayHandler)	
	end
end

function QUIDialogBuyVirtual:refreshInfo()
	self._totalNum = 0
	self._num = 0
	local config = QStaticDatabase:sharedDatabase():getTokenConsumeByType(self._typeName)
	self._buyCount = 0
	if config ~= nil then
		self._totalNum = QVIPUtil:getBuyVirtualCount(self._typeName)
		if self._typeName == ITEM_TYPE.MONEY then
			self._ccbOwner.btn_buyAgain:setVisible(true)
			self._ccbOwner.btn_buy:setVisible(true)
			if remote.user.todayMoneyBuyLastTime ~= nil and q.refreshTime(global.freshTime.buyMoney_freshTime) > remote.user.todayMoneyBuyLastTime then
				self._buyCount = 0
			else
				self._buyCount = remote.user.todayMoneyBuyCount or 0
			end
		elseif self._typeName == ITEM_TYPE.ENERGY then
			self._ccbOwner.btn_buy:setVisible(true)
			self._ccbOwner.btn_buy:setPositionX(0)
			if remote.user.todayEnergyBuyLastTime ~= nil and q.refreshTime(global.freshTime.buyEnergy_freshTime) > remote.user.todayEnergyBuyLastTime then
				self._buyCount = 0
			else
				self._buyCount = remote.user.todayEnergyBuyCount or 0
			end
		end
		self._num = self._totalNum - self._buyCount
	end
	local config = QStaticDatabase:sharedDatabase():getTokenConsume(self._typeName,self._buyCount+1)
	if config == nil then
		config = QStaticDatabase:sharedDatabase():getTokenConsume(self._typeName,self._buyCount)
	end
	self._needNum = config.token_cost
	self._reveiveNum = config.return_count
	if self._typeName == ITEM_TYPE.MONEY then
		local teamExpLvlConfig = QStaticDatabase:sharedDatabase():getTeamConfigByTeamLevel(remote.user.level)
		if teamExpLvlConfig ~= nil and self._reveiveNum ~= nil then
			self._reveiveNum = self._reveiveNum * teamExpLvlConfig.token_to_money
		end
		self:setMoneyInfo()
	elseif self._typeName == ITEM_TYPE.ENERGY then
		self:setEnergyInfo()
	end

	if self._num <= 0 then
		self:showVIPButton()
	end
end

function QUIDialogBuyVirtual:showVIPButton()
	self._ccbOwner.btn_buy:setVisible(false)
	self._ccbOwner.btn_buyAgain:setVisible(false)
	self._ccbOwner.btn_VIP_Info:setVisible(true)
end

function QUIDialogBuyVirtual:setMoneyInfo()
	self:getView():setVisible(true)
	self._ccbOwner.icon_money:setVisible(true)
	self._ccbOwner.node_money:setVisible(true)
	self._ccbOwner.node_title_money:setVisible(true)
	self._ccbOwner.tf_1:setString("金钱购买")
	self._ccbOwner.tf_2:setString("用少量符石购买大量金钱")
	self._ccbOwner.tf_buy:setString("（今日可购买次数"..self._num.."/"..self._totalNum.."）")
	self._ccbOwner.tf_need_num:setString(self._needNum)
	self._ccbOwner.tf_receive_num:setString(math.floor(self._reveiveNum))
	self._ccbOwner.tf_tips:setString("每日可购买金钱次数在凌晨4点刷新")
end

function QUIDialogBuyVirtual:tipsMoneyInfo()
	app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	local content = ""
	if self._enough == false then
		content = "金钱不足，今日购买金钱次数已达上限，提升VIP等级获取更多购买次数！"
	else
		content = "今日购买金钱次数已达上限！"
	end
	app:alert({content=content,title="系统提示",callBack=nil,comfirmBack=nil})
end

function QUIDialogBuyVirtual:setEnergyInfo()
	self:getView():setVisible(true)
	self._ccbOwner.icon_energy:setVisible(true)
	self._ccbOwner.node_energy:setVisible(true)
	self._ccbOwner.node_title_energy:setVisible(true)
	self._ccbOwner.tf_1:setString("体力购买")
	self._ccbOwner.tf_2:setString("用少量符石购买大量体力")
	self._ccbOwner.tf_buy:setString("（今日可购买次数"..self._num.."/"..self._totalNum.."）")
	self._ccbOwner.tf_need_num:setString(self._needNum)
	self._ccbOwner.tf_receive_num:setString(math.floor(self._reveiveNum))
	self._ccbOwner.tf_tips:setString("每日可购买体力次数在凌晨4点刷新")
end

function QUIDialogBuyVirtual:tipsEnergyInfo()
	app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	local content = ""
	if self._enough == false then
		content = "体力不足，今日购买体力次数已达上限，提升VIP等级获取更多购买次数！"
	else
		content = "今日购买体力次数已达上限！"
	end
	app:alert({content=content,title="系统提示",callBack=nil,comfirmBack=nil})
end

function QUIDialogBuyVirtual:animationBuySucc()
	self:refreshInfo()
	local animationFun = function ()
		local effectPlayer = QUIWidgetAnimationPlayer.new()
	    local startP = self._ccbOwner.node_money:convertToWorldSpaceAR(ccp(0,0))
	    startP = self:getView():convertToNodeSpaceAR(startP)
		effectPlayer:setPosition(startP.x, startP.y)
		self:getView():addChild(effectPlayer)
		effectPlayer:playAnimation("ccb/Widget_TiliBuy.ccbi",function(ccbOwner)
			end,function(name)
			local page = app:getNavigationController():getTopPage()
			local endP = ccp(0,0)
			local moveSp = nil
			if self._typeName == ITEM_TYPE.MONEY then
				moveSp = display.newSprite(ICON_URL.MONEY)
				endP = page._topRegion[1]._ccbOwner.sprite_gold:convertToWorldSpaceAR(ccp(0,0))
			else
				moveSp = display.newSprite(ICON_URL.ENERGY)
				endP = page._topRegion[3]._ccbOwner.sprite_gold:convertToWorldSpaceAR(ccp(0,0))
			end
			moveSp:setScale(0.5)
			moveSp:setPosition(startP.x, startP.y)
			self:getView():addChild(moveSp)
			endP = self:getView():convertToNodeSpaceAR(endP)
			local arr = CCArray:create()
			arr:addObject(CCMoveTo:create(0.2, endP))
			arr:addObject(CCCallFunc:create(function()
					self:getView():removeChild(moveSp)
					local effectPlayer = QUIWidgetAnimationPlayer.new()
					effectPlayer:setPosition(endP.x, endP.y)
					self:getView():addChild(effectPlayer)
					effectPlayer:playAnimation("ccb/Widget_TiliBuy.ccbi")
				end))
			local seq = CCSequence:create(arr)
			moveSp:runAction(seq)
		end)
	end	
	if self._animationCount == nil or self._animationCount == 0 then
		self._animationCount = 1
	else
		self._animationCount = self._animationCount + 1
	end

	if self._delayFun == nil then
		self._delayFun = function ()
			self._animationCount = self._animationCount - 1
			if self._animationCount > 0 then
				animationFun()
				self._delayHandler = scheduler.performWithDelayGlobal(self._delayFun, 0.15)
			end
		end
	end

	if self._animationCount == 1 then
		animationFun()
		self._delayHandler = scheduler.performWithDelayGlobal(self._delayFun, 0.15)
	end
end

--TODO: check the maximum continuous money consume @qinyuanji
function QUIDialogBuyVirtual:buyAgain()
	local token_cost = nil
	local receive = 0
	local count = self._buyCount
	local count2 = 0
	local teamExpLvlConfig = QStaticDatabase:sharedDatabase():getTeamConfigByTeamLevel(remote.user.level)
	while true do
		count = count + 1
		local config = QStaticDatabase:sharedDatabase():getTokenConsume(ITEM_TYPE.MONEY, count)
		if config ~= nil then
			if (token_cost == nil or token_cost == config.token_cost) and count2 < self._num then
				if token_cost == nil then token_cost = config.token_cost end
				if receive == nil then 
					receive = config.return_count * teamExpLvlConfig.token_to_money
				end
				count2 = count2 + 1
			else
				break
			end
		else
			break
		end
	end
	local token = token_cost * count2
	if token > remote.user.token then
		app:alert({content="符石不足，赶快去充值吧！",title="系统提示",callBack=nil,comfirmBack=nil}, false)
	else
		for i=1,count2,1 do
			self:buyMoney()
		end
	end
end

--添加购买记录
function QUIDialogBuyVirtual:addLog(cost, receive, crit)
	if self.log == nil then
		self.log = QUIWidgetBuyVirtualLog.new()
		self._ccbOwner.node_log:addChild(self.log)
		local posX = self:getChildView():getPositionX()
		local posY = self:getChildView():getPositionY() + 30
		self:getChildView():runAction(CCMoveTo:create(0.3,ccp(posX,posY)))
	end
	self.log:addLog(cost, receive, crit)
end

--添加购买记录
function QUIDialogBuyVirtual:buyMoney()
	app:getClient():buyMoney(function(data)
		remote.user:addPropNumForKey("addupBuyMoneyCount")
		remote.user:update({todayMoneyBuyLastTime = q.time()})
		local config = QStaticDatabase:sharedDatabase():getTokenConsume(ITEM_TYPE.MONEY, data.todayMoneyBuyCount)
		local teamExpLvlConfig = QStaticDatabase:sharedDatabase():getTeamConfigByTeamLevel(remote.user.level)
		self:addLog(config.token_cost, math.floor(config.return_count * teamExpLvlConfig.token_to_money * data.buyMoneyYield), data.buyMoneyYield)
		self:animationBuySucc()
    end)
end

function QUIDialogBuyVirtual:_onTriggerBuyAgain()
  	app.sound:playSound("common_confirm")
  	app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBuyVirtualAgain",
      options = {typeName = ITEM_TYPE.MONEY, count = self._buyCount, remainingCount = self._num, callBack = handler(self, self.buyAgain)}},{isPopCurrentDialog = false})
end

function QUIDialogBuyVirtual:_onTriggerClose()
  	app.sound:playSound("common_cancel")
	self:playEffectOut()
end

function QUIDialogBuyVirtual:_onTriggerBuy()
  	app.sound:playSound("common_confirm")
	if self._typeName == ITEM_TYPE.MONEY then
		self:buyMoney()
	elseif self._typeName == ITEM_TYPE.ENERGY then
		app:getClient():buyEnergy(function(data)
			remote.user:addPropNumForKey("addupBuyEnergyCount")
      		self:animationBuySucc()
			remote.user:update({todayEnergyBuyLastTime = q.time()})
        end)
	end
end

function QUIDialogBuyVirtual:_onTriggerVIP()
	app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogVip"})
end

function QUIDialogBuyVirtual:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogBuyVirtual:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogBuyVirtual