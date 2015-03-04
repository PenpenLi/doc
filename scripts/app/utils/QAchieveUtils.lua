--
-- Author: wkwang
-- Date: 2014-11-15 18:17:28
-- 成就类
--
local QAchieveUtils = class("QAchieveUtils")

local QStaticDatabase = import("..controllers.QStaticDatabase")

QAchieveUtils.MISSION_COMPLETE = 100	--标志任务完成并上交
QAchieveUtils.MISSION_DONE = 99	--标志任务完成并上交
QAchieveUtils.MISSION_NONE = 0	--标志任务没有任何进展

QAchieveUtils.EVENT_UPDATE = "EVENT_UPDATE"
QAchieveUtils.EVENT_STATE_UPDATE = "EVENT_STATE_UPDATE"

QAchieveUtils.DEFAULT = "DEFAULT" --默认的推荐类型
QAchieveUtils.TYPE_HERO = "TYPE_HERO" --英雄相关
QAchieveUtils.TYPE_INSTANCE = "TYPE_INSTANCE" --副本相关
QAchieveUtils.TYPE_ARENA = "TYPE_ARENA" --竞技场相关
QAchieveUtils.TYPE_USER = "TYPE_USER" --玩家基本属性

function QAchieveUtils:ctor()
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
	self._achieves = {}
	self._achievesFuns = {}
	self.achieveDone = false
	self.achievePoint = 0

	self._heroList = {"英雄召唤", "英雄升级", "英雄突破", "英雄升2星", "英雄升3星", "英雄升4星", "英雄升5星"}
	self._instanceList = {"通关副本", "满星通关副本", "通关关卡", "副本星级"}
	self._arenaList = {"竞技场挑战次数", "竞技场排名"}
	self._userList = {"战队等级", "符石换金", "购买体力", "购买银宝箱", "购买金宝箱", "累计充值", "累计普通副本通关次数", "累计精英副本通关次数"}

	self:registerHandlerFun("英雄召唤", handler(self, self.heroCompositeHandler))
	self:registerHandlerFun("英雄升级", handler(self, self.heroUpGradeHandler))
	self:registerHandlerFun("英雄突破", handler(self, self.heroBreakthroughHandler))
	self:registerHandlerFun("英雄升2星", handler(self, self.heroGradeStarHandler))
	self:registerHandlerFun("英雄升3星", handler(self, self.heroGradeStarHandler))
	self:registerHandlerFun("英雄升4星", handler(self, self.heroGradeStarHandler))
	self:registerHandlerFun("英雄升5星", handler(self, self.heroGradeStarHandler))

	self:registerHandlerFun("通关副本", handler(self, self.instancePassHandler))
	self:registerHandlerFun("满星通关副本", handler(self, self.instanceAllStarHandler))
	self:registerHandlerFun("通关关卡", handler(self, self.dungeonPassHandler))
	self:registerHandlerFun("副本星级", handler(self, self.instanceStarHandler))
	self:registerHandlerFun("累计普通副本通关次数", handler(self, self.instancePassCountHandler))
	self:registerHandlerFun("累计精英副本通关次数", handler(self, self.eliteInstancePassCountHandler))

	self:registerHandlerFun("竞技场挑战次数", handler(self, self.arenaBattleCountHandler))
	self:registerHandlerFun("竞技场排名", handler(self, self.arenaBattleTopRankHandler))

	self:registerHandlerFun("战队等级", handler(self, self.teamLevelHandler))
	self:registerHandlerFun("符石换金", handler(self, self.buyMoneyHandler))
	self:registerHandlerFun("购买体力", handler(self, self.buyEnergyHandler))
	self:registerHandlerFun("购买银宝箱", handler(self, self.buySliverHandler))
	self:registerHandlerFun("购买金宝箱", handler(self, self.buyGoldHandler))
	self:registerHandlerFun("累计充值", handler(self, self.buyTokenHandler))

end

--初始化成就
function QAchieveUtils:init()
	local achieveConfig = QStaticDatabase:sharedDatabase():getTask()
	for _,achieve in pairs(achieveConfig) do
		achieve.index = tostring(achieve.index)
		if achieve.module == "成就" then
			local achieveInfo = self:getAchieveById(achieve.index, true)
			achieveInfo.config = achieve
			if achieveInfo.state == nil then
				achieveInfo.state = QAchieveUtils.MISSION_NONE
				achieveInfo.stepNum = 0
			end
			if achieveInfo.isShow == nil then
				achieveInfo.isShow = false
			end
			self._achieves[achieve.index] = achieveInfo
		end
	end

	--默认第一个成就是可以显示
	for _,achieveInfo in pairs(self._achieves) do
		if self:getPreAchieveById(achieveInfo.config.index) == nil then
			achieveInfo.isShow = true
		end
	end

	self._remoteEventProxy = cc.EventProxy.new(remote)
    self._remoteEventProxy:addEventListener(remote.HERO_UPDATE_EVENT, handler(self, self.updateAchievesForHero))
    self._remoteEventProxy:addEventListener(remote.DUNGEON_UPDATE_EVENT, handler(self, self.updateAchievesForDungeon))

	self._userEventProxy = cc.EventProxy.new(remote.user)
    self._userEventProxy:addEventListener(remote.user.EVENT_USER_PROP_CHANGE, handler(self, self.updateAchievesForUser))
end

--获取成就列表通过类型
function QAchieveUtils:getAchieveListByType(type)
	local list = {}
	local label = ""
	if type == QAchieveUtils.TYPE_HERO then
		label = "英雄"
	elseif type == QAchieveUtils.TYPE_INSTANCE then
		label = "副本"
	elseif type == QAchieveUtils.TYPE_ARENA then
		label = "竞技场"
	elseif type == QAchieveUtils.TYPE_USER then
		label = "其他"
	end

	for _,achieveInfo in pairs(self._achieves) do
		if type ~= QAchieveUtils.DEFAULT and achieveInfo.isShow == true then
			if achieveInfo.config.label == label then
				table.insert(list, achieveInfo)
			end
		else
			if achieveInfo.config.display_level <= remote.user.level and achieveInfo.isShow == true  and achieveInfo.state ~= QAchieveUtils.MISSION_COMPLETE then
				table.insert(list, achieveInfo)
			end
		end
	end
	table.sort(list,function (a,b)
			if a.state ~= b.state then
	        	if a.state == remote.task.TASK_DONE or b.state == remote.task.TASK_COMPLETE then
	        		return true
        		elseif b.state == remote.task.TASK_DONE or a.state == remote.task.TASK_COMPLETE then
        			return false
	        	end
	        end
	        return a.config.index < b.config.index
        end)
	return list
end

--[[
	更新成就完成
	如果某成就已经完成则该成就的下一个成就变为可显示
]]
function QAchieveUtils:updateComplete(data)
	local completeList = data or {}
	local isUpdate = false
	self.achievePoint = 0
	for _,value in pairs(completeList) do
		value = tostring(value)
		if value ~= "" and self._achieves[value] ~= nil then
			-- self:getAchieveById(value, false) --防止为空
			self._achieves[value].state = QAchieveUtils.MISSION_COMPLETE
			self.achievePoint = self.achievePoint + self._achieves[value].config.count
			local nextAchieveInfo = self:getNextAchieveById(value)
			if nextAchieveInfo ~= nil then
				nextAchieveInfo.isShow = true
			end
			isUpdate = true
		end
	end
	if isUpdate == true then
		self:dispatchEvent({name = QAchieveUtils.EVENT_UPDATE})
		self:checkAllAchieve()
	end
end

--根据ID获取前一个成就配置
function QAchieveUtils:getPreAchieveById(id)
	local achieveInfo = self:getAchieveById(id)
	local preAchieveInfo = self:getAchieveById(tostring(tonumber(achieveInfo.config.index) - 1))
	if preAchieveInfo ~= nil and preAchieveInfo.config.category == achieveInfo.config.category then
		return preAchieveInfo
	end
	return nil
end

--根据ID获取后一个成就配置
function QAchieveUtils:getNextAchieveById(id)
	local achieveInfo = self:getAchieveById(id)
	local preAchieveInfo = self:getAchieveById(tostring(tonumber(achieveInfo.config.index) + 1))
	if preAchieveInfo ~= nil and preAchieveInfo.config.category == achieveInfo.config.category then
		return preAchieveInfo
	end
	return nil
end

--根据category获取该类别的所有成就
function QAchieveUtils:getAchieveListByCategory(category)
	local list = {}
	for _,achieveInfo in pairs(self._achieves) do
		if achieveInfo.config.category == category then
			table.insert(list, achieveInfo)
		end
	end
	return list
end

--获取成就信息通过成就ID
function QAchieveUtils:getAchieveById(id, isCreat)
	if self._achieves[id] == nil and isCreat == true then
		self._achieves[id] = {}
	end
	return self._achieves[id]
end

--检查是否有完成的成就 如果有则中断检查 抛出事件
function QAchieveUtils:checkAllAchieve()
	for _,achieveInfo in pairs(self._achieves) do
		if achieveInfo.state == QAchieveUtils.MISSION_DONE then
			self:setAchieveDone(true)
			return true
		end
	end
	self:setAchieveDone(false)
	return false
end

--检查某类别下的成就是否完成
function QAchieveUtils:checkAchieveDoneForType(type)
	local label = ""
	if type == QAchieveUtils.TYPE_HERO then
		label = "英雄"
	elseif type == QAchieveUtils.TYPE_INSTANCE then
		label = "副本"
	elseif type == QAchieveUtils.TYPE_ARENA then
		label = "竞技场"
	elseif type == QAchieveUtils.TYPE_USER then
		label = "其他"
	end

	if type ~= QAchieveUtils.DEFAULT then
		for _,achieveInfo in pairs(self._achieves) do
			if achieveInfo.config.label == label and achieveInfo.state == QAchieveUtils.MISSION_DONE then
				return true
			end
		end
	else
		for _,achieveInfo in pairs(self._achieves) do
			if achieveInfo.config.display_level <= remote.user.level and achieveInfo.isShow == true and achieveInfo.state == QAchieveUtils.MISSION_DONE then
				return true
			end
		end
	end
	return false
end

--设置是否有成就完成
function QAchieveUtils:setAchieveDone(isDone)
	if self.achieveDone ~= isDone then
		self.achieveDone = isDone
		self:dispatchEvent({name = QAchieveUtils.EVENT_STATE_UPDATE})
	end
end

-----------------------------------------------------------------成就处理模块------------------------------------------------------------------

--[[
	注册成就的检查函数
]]
function QAchieveUtils:registerHandlerFun(category, handlerFun)
	self._achievesFuns[category] = handlerFun
end

-- 更新英雄相关成就
function QAchieveUtils:updateAchievesForHero()
	self:updateAchievesForType(QAchieveUtils.TYPE_HERO)
end

-- 更新副本相关成就
function QAchieveUtils:updateAchievesForDungeon()
	self:updateAchievesForType(QAchieveUtils.TYPE_INSTANCE)
end

-- 更新用户属性相关成就
function QAchieveUtils:updateAchievesForUser()
	self:updateAchievesForType(QAchieveUtils.TYPE_USER)
	self:updateAchievesForType(QAchieveUtils.TYPE_ARENA)
end

--[[
	通过自定义类别成就处理
]]
function QAchieveUtils:updateAchievesForType(type)
	local list = {}
	if type == QAchieveUtils.TYPE_HERO then
		list = self._heroList
	elseif type == QAchieveUtils.TYPE_INSTANCE then
		list = self._instanceList
	elseif type == QAchieveUtils.TYPE_ARENA then
		list = self._arenaList
	elseif type == QAchieveUtils.TYPE_USER then
		list = self._userList
	end
	for _,category in pairs(list) do
		self._achievesFuns[category](category)
	end
end

--根据配置中的Num判定是否完成
function QAchieveUtils:achieveDoneForNum(id)
	local achieveInfo = self:getAchieveById(id)
	if achieveInfo.state ~= QAchieveUtils.MISSION_COMPLETE then
		if achieveInfo.stepNum >= (achieveInfo.config.num or 0) then
			achieveInfo.state = QAchieveUtils.MISSION_DONE
			achieveInfo.isShow = true
			self:setAchieveDone(true)
			return true
		end
	end
	return false
end

--英雄召唤
function QAchieveUtils:heroCompositeHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = #remote.herosUtil:getHaveHeroKey()
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--英雄升级
function QAchieveUtils:heroUpGradeHandler(category)
	local list = self:getAchieveListByCategory(category)
	local conNum = 0
	local stepNum = 0
	local heroList = remote.herosUtil:getHaveHeroKey()
	for _,achieveInfo in pairs(list) do
		if conNum ~= achieveInfo.config.condition then
			conNum = achieveInfo.config.condition
			stepNum = 0
			for _,actorId in pairs(heroList) do
				local heroInfo = remote.herosUtil:getHeroByID(actorId)
				if heroInfo.level >= conNum then
					stepNum = stepNum + 1
				end
			end
		end
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--英雄突破
function QAchieveUtils:heroBreakthroughHandler(category)
	local list = self:getAchieveListByCategory(category)
	local conNum = 0
	local stepNum = 0
	local heroList = remote.herosUtil:getHaveHeroKey()
	for _,achieveInfo in pairs(list) do
		if conNum ~= achieveInfo.config.condition then
			conNum = achieveInfo.config.condition
			stepNum = 0
			for _,actorId in pairs(heroList) do
				local heroInfo = remote.herosUtil:getHeroByID(actorId)
				if heroInfo.breakthrough >= conNum then
					stepNum = stepNum + 1
				end
			end
		end
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--英雄升星
function QAchieveUtils:heroGradeStarHandler(category)
	local list = self:getAchieveListByCategory(category)
	local conNum = 0
	local stepNum = 0
	local heroList = remote.herosUtil:getHaveHeroKey()
	for _,achieveInfo in pairs(list) do
		if conNum ~= achieveInfo.config.condition then
			conNum = achieveInfo.config.condition
			stepNum = 0
			for _,actorId in pairs(heroList) do
				local heroInfo = remote.herosUtil:getHeroByID(actorId)
				if heroInfo.grade >= conNum then
					stepNum = stepNum + 1
				end
			end
		end
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--通关副本
function QAchieveUtils:instancePassHandler(category)
	local list = self:getAchieveListByCategory(category)
	local condition = ""
	local stepNum = 0
	for _,achieveInfo in pairs(list) do
		if condition ~= achieveInfo.config.condition then
			condition = achieveInfo.config.condition
			stepNum = 0
			local instanceList = remote.instance:getInstancesById(condition)
			for _,dungeonInfo in pairs(instanceList) do
				if dungeonInfo.info ~= nil and dungeonInfo.info.lastPassAt ~= nil and dungeonInfo.info.lastPassAt > 0 then
					stepNum = stepNum + 1
				end
			end
		end
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--满星通关副本
function QAchieveUtils:instanceAllStarHandler(category)
	local list = self:getAchieveListByCategory(category)
	local condition = ""
	local stepNum = 0
	for _,achieveInfo in pairs(list) do
		if condition ~= achieveInfo.config.condition then
			condition = achieveInfo.config.condition
			stepNum = 0
			local instanceList = remote.instance:getInstancesById(condition)
			for _,dungeonInfo in pairs(instanceList) do
				if dungeonInfo.info ~= nil and dungeonInfo.info.star ~= nil then
					stepNum = stepNum + dungeonInfo.info.star
				end
			end
		end
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--通关关卡
function QAchieveUtils:dungeonPassHandler(category)
	local list = self:getAchieveListByCategory(category)
	local condition = ""
	local stepNum = 0
	local isPass = true
	for _,achieveInfo in pairs(list) do
		if condition ~= achieveInfo.config.condition then
			condition = achieveInfo.config.condition
			stepNum = 0
			isPass = remote.instance:checkIsPassByDungeonId(condition)
		end
		if isPass == true then
			stepNum = achieveInfo.config.num
		end
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--副本星级
function QAchieveUtils:instanceStarHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("c_allStarCount")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--累计普通副本通关次数
function QAchieveUtils:instancePassCountHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("addupDungeonPassCount")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--累计精英副本通关次数
function QAchieveUtils:eliteInstancePassCountHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("addupDungeonElitePassCount")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--竞技场挑战次数
function QAchieveUtils:arenaBattleCountHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("addupArenaFightCount")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--竞技场排名
function QAchieveUtils:arenaBattleTopRankHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("arenaTopRank") or 0
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		local achieveInfo = self:getAchieveById(achieveInfo.config.index)
		if achieveInfo.state ~= QAchieveUtils.MISSION_COMPLETE then
			if achieveInfo.stepNum > 0 and achieveInfo.stepNum <= (achieveInfo.config.num or 0) then
				achieveInfo.state = QAchieveUtils.MISSION_DONE
				achieveInfo.isShow = true
				self:setAchieveDone(true)
			end
		end
	end
end

--战队等级
function QAchieveUtils:teamLevelHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("level")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--符石换金
function QAchieveUtils:buyMoneyHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("addupBuyMoneyCount")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--购买体力
function QAchieveUtils:buyEnergyHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("addupBuyEnergyCount")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--购买银宝箱
function QAchieveUtils:buySliverHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("addupLuckydrawCount")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--购买金宝箱
function QAchieveUtils:buyGoldHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("addupLuckydrawAdvanceCount")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

--累计充值
function QAchieveUtils:buyTokenHandler(category)
	local list = self:getAchieveListByCategory(category)
	local stepNum = remote.user:getPropForKey("addupPurchasedToken")
	for _,achieveInfo in pairs(list) do
		achieveInfo.stepNum = stepNum
		self:achieveDoneForNum(achieveInfo.config.index)
	end
end

return QAchieveUtils