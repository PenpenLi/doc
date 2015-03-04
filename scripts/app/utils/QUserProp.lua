--
-- Author: wkwang
-- Date: 2014-11-12 10:08:45
-- 玩家属性类
--  *      "name":"xxxx",                                  // 玩家名称
--  *      "nickName":"xxxx",                              // 玩家昵称
--  *      "avatar":"xxxx",                                // 玩家头像
--  *      "exp":10,                                       // 战队经验
--  *      "level":10,                                     // 战队等级
--  *      "session":"...",                                // 本次登陆session id
--  *      "energyRefreshedAt",                            // 体力刷新时间
--  *      "skillTickets",                                 // 技能券
--  *      “skillTicketsRefreshedAt",                      // 技能券刷新时间
--  *      "money":10,                                     // 玩家金币数量
--  *      "energy":10,                                    // 玩家体力
--  *      "token":10,                                     // 玩家代币
--  *
--  *      "todayMoneyBuyCount":0,                         // 今天金币购买次数
--  *      "todayEnergyBuyCount":0,                        // 今天体力购买次数
--  *      "todaySkillImprovedCount":0,                    // 今天技能升级多少次
--  *
--  *      "todayLuckyDrawAnyCount":5,                     // 今天任意抽奖次数
--  *      "todayLuckyDrawFreeCount":6,                    // 今天免费宝箱次数
--  *      "totalLuckyDrawAdvanceCount":100                // 高级抽奖总次数
--  *      "luckyDrawRefreshedAt":1231231,                 // 普通宝箱最后刷新时间
--  *      “luckyDrawAdvanceRefreshedAt":12312,            // 黄金宝箱最后刷新时间

 -- *      "addupDungeonPassCount":123                     // 累计普通副本通关次数
 -- *      "addupDungeonElitePassCount":123                // 累计精英副本通关次数
 -- *      "addupLuckydrawCount":123                       // 累计普通宝箱次数
 -- *      "addupLuckydrawAdvanceCount":123                // 累计黄金宝箱次数
 -- *      "addupPurchasedToken":123                       // 累计购买了代币数
 -- *      "addupBuyEnergyCount":123                       // 累计购买体力次数
 -- *      "addupBuyMoneyCount":123                        // 累计购买金币次数
--

local QUserProp = class("QUserProp")
local QStaticDatabase = import("..controllers.QStaticDatabase")
local QUIViewController = import("..ui.QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUserProp.EVENT_USER_PROP_CHANGE = "EVENT_USER_PROP_CHANGE"
QUserProp.EVENT_TIME_REFRESH_FOUR = "EVENT_TIME_REFRESH_FOUR"
QUserProp.CHEST_IS_FREE = "CHEST_IS_FREE"

function QUserProp:ctor()
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
	--初始化属性值
	self.props = {}
	table.insert(self.props, "name") --玩家名称
	table.insert(self.props, "userId") --玩家ID
	table.insert(self.props, "nickname") --玩家昵称
	table.insert(self.props, "avatar") --玩家头像
	table.insert(self.props, "exp") --战队经验
	table.insert(self.props, "level") --战队等级
	table.insert(self.props, "isLoginFrist") --标志是否曾经登录过，如果登录过后面的重连则做区服的验证 看不懂的话找徐卿
	table.insert(self.props, "session") --本次登陆session id
	table.insert(self.props, "energyRefreshedAt") --体力刷新时间
	table.insert(self.props, "skillTickets") --技能券
	table.insert(self.props, "skillTicketsRefreshedAt") --技能券刷新时间
	table.insert(self.props, "skillTicketsReset") --技能券购买次数
	table.insert(self.props, "energy") --玩家体力 
	table.insert(self.props, "money") --玩家金币数量
	table.insert(self.props, "arenaMoney") --竞技场代币
	table.insert(self.props, "sunwellMoney") --太阳井代币
	table.insert(self.props, "token") --玩家代币

	table.insert(self.props, "todayMoneyBuyCount") --今天金币购买次数
	table.insert(self.props, "todayEnergyBuyCount") --今天体力购买次数
	table.insert(self.props, "todayMoneyBuyLastTime") --今天金币购买最后一次时间
	table.insert(self.props, "todayEnergyBuyCount") --今天体力购买次数
	table.insert(self.props, "todayEnergyBuyLastTime") --今天体力购买最后一次时间
	table.insert(self.props, "todaySkillImprovedCount") --今天技能升级多少次

	table.insert(self.props, "todayLuckyDrawAnyCount") --今天任意抽奖次数
	table.insert(self.props, "todayLuckyDrawFreeCount") --今天免费宝箱次数
	table.insert(self.props, "totalLuckyDrawAdvanceCount") --高级抽奖总次数
	table.insert(self.props, "luckyDrawRefreshedAt") --普通宝箱最后刷新时间
	table.insert(self.props, "luckyDrawAdvanceRefreshedAt") --黄金宝箱最后刷新时间

	table.insert(self.props, "addupDungeonPassCount") --累计普通副本通关次数
	table.insert(self.props, "addupDungeonElitePassCount") --累计精英副本通关次数
	table.insert(self.props, "addupLuckydrawCount") --累计普通宝箱次数
	table.insert(self.props, "addupLuckydrawAdvanceCount") --累计黄金宝箱次数
	table.insert(self.props, "addupPurchasedToken") --累计购买了代币数
	table.insert(self.props, "addupBuyEnergyCount") --累计购买体力次数
	table.insert(self.props, "addupBuyMoneyCount") --累计购买金币次数

	table.insert(self.props, "todayActivity1_1Count") --今天活动副本1 打斗次数
	table.insert(self.props, "todayActivity2_1Count") --今天活动副本2 打斗次数
	table.insert(self.props, "todayActivity3_1Count") --今天活动副本1 打斗次数
	table.insert(self.props, "todayActivity4_1Count") --今天活动副本2 打斗次数

	table.insert(self.props, "todayArenaFightCount") --竞技场今日战斗次数
	table.insert(self.props, "addupArenaFightCount") --竞技场总共战斗次数
	table.insert(self.props, "arenaTopRank") --竞技场最高排名

	-- 下面是客户端自己添加的属性
	table.insert(self.props, "c_todayNormalPass") --今天普通关卡通关次数
	table.insert(self.props, "c_todayElitePass") --今天精英关卡通关次数
	table.insert(self.props, "c_allStarNormalPass") --三星通关普通副本次数
	table.insert(self.props, "c_allStarElitePass") --三星通关精英副本次数
	table.insert(self.props, "c_allStarCount") --三星通关普通副本次数

	self:updateTime(q.serverTime())
end

--更新属性数据
function QUserProp:update(data, ispatch)
	local isUpdate = false
	for _,propName in pairs(self.props) do
		if data[propName] ~= nil then
			isUpdate = true
			self[propName] = data[propName]
			
			if propName == "energy" then
				self:timerForChange("energy", self.energyRefreshedAt/1000, global.config.energy_refresh_interval, self.energy, global.config.max_energy)
			end
		end
	end
	if data.wallet ~= nil then
		isUpdate = true
		self:update(data.wallet, false)
	end
	if isUpdate == true and ispatch ~= false then
		self:dispatchEvent({name = QUserProp.EVENT_USER_PROP_CHANGE})
		self:checkLuckyDrawFree()
	end
	return isUpdate
end

function QUserProp:updateTime(time)
	if self._timeRefreshHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeRefreshHandler)
		self._timeRefreshHandler = nil
	end
	local currTime = os.date("*t", q.serverTime())
	if currTime.hour >= 4 then
		currTime.day = currTime.day + 1
	end
	currTime.hour = 4
	currTime.min = 0
	currTime.sec = 0
	local refreshTime = os.time(currTime)
	self._timeRefreshHandler = scheduler.performWithDelayGlobal(function()
			self:refreshTimeAtFour()
			self:dispatchEvent({name = QUserProp.EVENT_TIME_REFRESH_FOUR})
			self:updateTime(q.serverTime())
		end,(refreshTime - time))
end

--四点的时候会刷新
function QUserProp:refreshTimeAtFour()
	local updateTbl = {}
	updateTbl["todayActivity1_1Count"] = 0
	updateTbl["todayActivity2_1Count"] = 0
	updateTbl["todayActivity3_1Count"] = 0
	updateTbl["todayActivity4_1Count"] = 0
	self:update(updateTbl)
end

--获取属性数据
function QUserProp:getPropForKey(key)
	return self[key] or 0
end

--属性数量自增
function QUserProp:addPropNumForKey(key, value)
	if value == nil then value = 1 end
	if self[key] == nil then
		self[key] = value
	else
		self[key] = self[key] + value
	end
	self:dispatchEvent({name = QUserProp.EVENT_USER_PROP_CHANGE})
end

--固定时间变化
function QUserProp:timerForChange(name, startTime, stepTime, value, totalValue)
	if self._timeProps == nil then
		self._timeProps = {}
	end
	if self._timeProps[name] == nil then
		self._timeProps[name] = {}
	end

	local currTime = q.serverTime()
	while true do
		if value >= totalValue then
			break
		elseif (currTime - startTime) >= stepTime then
			startTime = startTime + stepTime
			value = value + 1
			self:addPropNumForKey(name)
		else
			startTime = currTime - startTime
			break
		end
	end

	if value >= totalValue then
		if self._timeProps[name] ~= nil then
			self._timeProps[name] = nil
		end
	end

	if table.nums(self._timeProps) == 0 then
		if self._timeHandler ~= nil then
			scheduler.unscheduleGlobal(self._timeHandler)
			self._timeHandler = nil
		end
		return 
	end

	self._timeProps[name].startTime = startTime
	self._timeProps[name].stepTime = stepTime
	self._timeProps[name].value = value
	self._timeProps[name].totalValue = totalValue
	if self._timeHandler == nil then
		self._timeFun = function ()
			for name,propVlaue in pairs(self._timeProps) do
				if propVlaue.value >= propVlaue.totalValue then
					self._timeProps[name] = nil
				elseif propVlaue.startTime < stepTime then
					propVlaue.startTime = propVlaue.startTime + 1
				else
					propVlaue.startTime = 0
					propVlaue.value = propVlaue.value + 1
					self:addPropNumForKey(name)
				end
			end
			if table.nums(self._timeProps) == 0 then
				scheduler.unscheduleGlobal(self._timeHandler)
				self._timeHandler = nil
			end
		end
		self._timeHandler = scheduler.scheduleGlobal(self._timeFun, 1)
	end
end

--检查战队是否升级
function QUserProp:checkTeamUp()
    if remote.oldUser ~= nil and remote.oldUser.level < remote.user.level then
        local options = {}
        local oldUser = remote.oldUser
        remote.oldUser = nil
        options["level"]=oldUser.level
        options["level_new"]=remote.user.level
		local database = QStaticDatabase:sharedDatabase()
        local energy = 0
        local award = 0
		for i = (oldUser.level+1),remote.user.level,1 do
        	local config = database:getTeamConfigByTeamLevel(i)
	        if config ~= nil then
	            energy = energy + config.energy
	            award = award + config.token
	        end
		end
        options["energy"]=remote.user.energy - energy
        options["energy_new"]=remote.user.energy
        options["award"]=award
        app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogTeamUp", options = options}, {isPopCurrentDialog = false})
    end
end

function QUserProp:getSkillTicketConfig()
	local skillCountConfig = QStaticDatabase:sharedDatabase():getTokenConsumeByType("skill")
	if skillCountConfig[self.skillTicketsReset + 1] == nil then
		return skillCountConfig[#skillCountConfig]
	else
		return skillCountConfig[self.skillTicketsReset + 1]
	end
end

--酒馆免费倒计时
function QUserProp:checkLuckyDrawFree()
  self.silverIsFree = false
  self.goldIsFree = false
  local config = QStaticDatabase:sharedDatabase():getConfiguration()
  self._goldTime = config.ADVANCE_LUCKY_DRAW_TIME.value or 0 -- 黄金宝箱的CD时间
  self._goldLastTime = (remote.user.luckyDrawAdvanceRefreshedAt or 0)/1000
  self._goldCDTime = self._goldTime * 60 * 60
  local currTime = q.serverTime()
    
  if (currTime - self._goldLastTime) >= self._goldCDTime then
    self.goldIsFree = true
  else
    self:goldTimeHandler()
  end 
  
  self._silverCount = config.LUCKY_DRAW_COUNT.value or 0 -- 白银宝箱的次数
  self._silverTime = config.LUCKY_DRAW_TIME.value or 0 -- 白银宝箱的CD时间

  self._freeSilverCount = remote.user.todayLuckyDrawFreeCount or 0
  self._silverLastTime = (remote.user.luckyDrawRefreshedAt or 0)/1000
  self._silverCDTime = self._silverTime * 60
  
  if q.refreshTime(global.freshTime.silver_freshTime) > self._silverLastTime then
    self._freeSilverCount = self._silverCount
  else
    self._freeSilverCount = self._silverCount - self._freeSilverCount 
  end

  if self._freeSilverCount == self._silverCount or (self._freeSilverCount > 0 and (currTime - self._silverLastTime) >= self._silverCDTime) then
    self.silverIsFree = true
  else
    self:silverTimeHandler()
  end 
  
end

function QUserProp:goldTimeHandler()
  if self._goldTimeHandler ~= nil then
    scheduler.unscheduleGlobal(self._goldTimeHandler)
    self._goldTimeHandler = nil
  end 
  self._goldTimeFun = function ()
    local offsetTime = q.serverTime() - self._goldLastTime
    if offsetTime < self._goldCDTime then
      self._goldTimeHandler = scheduler.performWithDelayGlobal(self._goldTimeFun,1)
--      local date = q.timeToHourMinuteSecond(self._goldCDTime - offsetTime)
--      printInfo("黄金"..date)
    else
      if self._goldTimeHandler ~= nil then
        scheduler.unscheduleGlobal(self._goldTimeHandler)
      end 
      self.goldIsFree = true
      QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUserProp.CHEST_IS_FREE})  
    end
  end
  self._goldTimeFun()
end

function QUserProp:silverTimeHandler()
  if self._silverTimeHandler ~= nil then
    scheduler.unscheduleGlobal(self._silverTimeHandler)
    self._silverTimeHandler = nil
  end 
  if self._freeSilverCount > 0 then
    self._silverTimeFun = function ()
      local offsetTime = q.serverTime() - self._silverLastTime
      if offsetTime < self._silverCDTime then
        self._silverTimeHandler = scheduler.performWithDelayGlobal(self._silverTimeFun,1)
--        local date = q.timeToHourMinuteSecond(self._silverCDTime - offsetTime)
--        printInfo("白银"..date)
      else
        if self._silverTimeHandler ~= nil then
          scheduler.unscheduleGlobal(self._silverTimeHandler)
        end 
        self.silverIsFree = true
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUserProp.CHEST_IS_FREE})  
      end
    end
    self._silverTimeFun()
  end
end

function QUserProp:getChestState()
  if self.silverIsFree == true or self.goldIsFree == true then
    return true
  else
    return false 
  end
end

function QUserProp:checkPropEnough(propName, needNum)
	local result = true
	if self[propName] == nil then
		result = false
	end
	if self[propName] < needNum then
		result = false
	end
	if result == false then
		local typeName = remote.items:getItemType(propName)
		app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBuyVirtual", options = {typeName=typeName, enough=false}})
	end
	return result
end

return QUserProp