--
-- Author: wkwang
-- Date: 2014-11-11 14:35:59
--
local QTask = class("QTask")

local QStaticDatabase = import("..controllers.QStaticDatabase")
local QUIViewController = import("..ui.QUIViewController")

QTask.TASK_COMPLETE = 100	--标志任务完成并上交
QTask.TASK_DONE = 99		--标志任务完成没上交
QTask.TASK_NONE = 0		--标志任务完成没上交

QTask.EVENT_DONE = "EVENT_DONE"
QTask.EVENT_TIME_DONE = "EVENT_TIME_DONE"

function QTask:ctor()
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
	self._dailyTask = {}

	self:registerHandlerFun("100100", handler(self, self.dungeonEveryday)) --副本终结者
	self:registerHandlerFun("100200", handler(self, self.dungeonEliteEveryday)) --精英副本终结者
	self:registerHandlerFun("100300", handler(self, self.skillEveryday)) --勤修苦练
	self:registerHandlerFun("100400", handler(self, self.luckydrawEveryday)) --酒馆畅饮
	self:registerHandlerFun("100500", handler(self, self.exchangeMoneyEveryday)) --点石成金
	self:registerHandlerFun("100600", handler(self, self.timeMachineEveryday)) --传送达人
	self:registerHandlerFun("100700", handler(self, self.goldBattleEveryday)) --试炼高手
	self:registerHandlerFun("100800", handler(self, self.arenaBattleEveryday)) --勇者精神

	self:registerHandlerFun("100000", handler(self, self.mealTimesEveryday)) --午间能量豪礼
	self:registerHandlerFun("100001", handler(self, self.mealTimesEveryday)) --晚间能量豪礼
	self:registerHandlerFun("100002", handler(self, self.mealTimesEveryday)) --午夜能量豪礼
end

function QTask:init()
	local taskConfig = QStaticDatabase:sharedDatabase():getTask()
	for _,task in pairs(taskConfig) do
		task.index = tostring(task.index)
		if task.module == "每日任务" then
			self:getDailyTaskById(task.index, true) --防止为空
			self._dailyTask[task.index].config = task
			if self._dailyTask[task.index].state == nil then
				self._dailyTask[task.index].state = QTask.TASK_NONE
			end
			if self._dailyTask[task.index].isShow == nil then
				self._dailyTask[task.index].isShow = true
			end
		end
	end

	self._userEventProxy = cc.EventProxy.new(remote.user)
    self._userEventProxy:addEventListener(remote.user.EVENT_USER_PROP_CHANGE, handler(self, self.checkAllTask))
end

--获取每日任务列表
function QTask:getDailyTask()
	return self._dailyTask
end

--获取任务信息通过任务ID
function QTask:getDailyTaskById(taskId, isCreat)
	if self._dailyTask[taskId] == nil and isCreat == true then
		self._dailyTask[taskId] = {}
	end
	return self._dailyTask[taskId]
end

--检查任务完成时间如果在刷新时间之前将所有任务重置
function QTask:checkTaskTime()
	if self._updateTime == nil then
		self._updateTime = q.serverTime()
		return 
	end
	if self._updateTime < q.refreshTime(global.freshTime.task_freshTime) then
		for _,taskInfo in pairs(self._dailyTask) do
			taskInfo.state = QTask.TASK_NONE
		end
	end
	self._updateTime = q.serverTime()
end

--更新任务完成
function QTask:updateComplete(data)
	self:checkTaskTime()
	for id,value in pairs(data) do
		value = tostring(value)
		self:getDailyTaskById(value) --防止为空
		self._dailyTask[value].state = QTask.TASK_COMPLETE
		self._dailyTask[value].isShow = false
	end
end

--[[
	注册任务的检查函数
]]
function QTask:registerHandlerFun(taskId, handlerFun)
	taskInfo = self:getDailyTaskById(taskId, true)
	taskInfo.handlerFun = handlerFun
end

--检查所有任务是否完成
function QTask:checkAllTask()
	self:checkTaskTime()
	local haveDone = false
	for _,taskInfo in pairs(self._dailyTask) do
		if self:checkTaskById(taskInfo.config.index) == true then
			haveDone = true
		end 
	end
	if haveDone == true then
		self:dispatchEvent({name = QTask.EVENT_DONE})
	end
	return haveDone
end

--检查任务是否完成通过ID
function QTask:checkTaskById(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	if taskInfo.state == QTask.TASK_DONE then
		return true
	end
	if taskInfo.state == QTask.TASK_COMPLETE then
		return false
	end
	if taskInfo.handlerFun ~= nil then
		return taskInfo.handlerFun(taskId)
	end
	return false
end

--[[
	任务处理函数区块
]]

--根据配置中的Num判定是否完成
function QTask:taskDoneForNum(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	if remote.user.level == nil then
		taskInfo.isShow = false --用户数据还没有则不做判断
		return false
	else
	 	taskInfo.isShow = (taskInfo.config.display_level <= remote.user.level)
	 end
	if taskInfo.stepNum >= (taskInfo.config.num or 0) and (taskInfo.config.display_level <= remote.user.level) then
		taskInfo.state = QTask.TASK_DONE
		return true
	end
	return false
end

--点石成金
function QTask:exchangeMoneyEveryday(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	taskInfo.stepNum = remote.user:getPropForKey("todayMoneyBuyCount")
	return self:taskDoneForNum(taskId)
end

--酒馆畅饮
function QTask:luckydrawEveryday(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	taskInfo.stepNum = remote.user:getPropForKey("todayLuckyDrawAnyCount")
	return self:taskDoneForNum(taskId)
end

--副本终结者
function QTask:dungeonEveryday(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	taskInfo.stepNum = remote.user:getPropForKey("c_todayNormalPass") + remote.user:getPropForKey("c_todayElitePass")
	return self:taskDoneForNum(taskId)
end

--精英副本终结者
function QTask:dungeonEliteEveryday(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	if #remote.instance.eliteInfo == 0 or remote.instance.eliteInfo[1].isLock == false then
		taskInfo.isShow = false
		return false
	else
		taskInfo.isShow = true
	end
	taskInfo.stepNum = remote.user:getPropForKey("c_todayElitePass")
	return self:taskDoneForNum(taskId)
end

--勤修苦练
function QTask:skillEveryday(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	taskInfo.stepNum = remote.user:getPropForKey("todaySkillImprovedCount")
	return self:taskDoneForNum(taskId)
end

--传送达人
function QTask:timeMachineEveryday(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	taskInfo.stepNum = remote.user:getPropForKey("todayActivity1_1Count") + remote.user:getPropForKey("todayActivity2_1Count")
	return self:taskDoneForNum(taskId)
end

--试练高手
function QTask:goldBattleEveryday(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	taskInfo.stepNum = remote.user:getPropForKey("todayActivity3_1Count") + remote.user:getPropForKey("todayActivity4_1Count")
	return self:taskDoneForNum(taskId)
end

--勇者精神
function QTask:arenaBattleEveryday(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	taskInfo.stepNum = remote.user:getPropForKey("todayArenaFightCount")
	return self:taskDoneForNum(taskId)
end

--用餐时间领取体力
--这里开启一个计时器

function QTask:mealTimesEveryday()
	local fristTaskInfo = self:getDailyTaskById("100000")
	fristTaskInfo.isShow = false
	local secondTaskInfo = self:getDailyTaskById("100001")
	secondTaskInfo.isShow = false
	local thirdTaskInfo = self:getDailyTaskById("100002")
	thirdTaskInfo.isShow = false

	local result = self:mealTimesEverydayById("100000")
	local taskInfo = self:getDailyTaskById("100000")
	if taskInfo.timeHandler ~= nil then
		return result
	end
	
	local result = self:mealTimesEverydayById("100001")
	local taskInfo = self:getDailyTaskById("100001")
	if taskInfo.timeHandler ~= nil then
		return result
	end
	
	local result = self:mealTimesEverydayById("100002")
	local taskInfo = self:getDailyTaskById("100002")
	if taskInfo.timeHandler ~= nil then
		return result
	end

	return false
end

function QTask:mealTimesEverydayById(taskId)
	local taskInfo = self:getDailyTaskById(taskId)
	if taskInfo.state == QTask.TASK_COMPLETE then
		if taskInfo.timeHandler  ~= nil then
			scheduler.unscheduleGlobal(taskInfo.timeHandler)
			taskInfo.timeHandler = nil
		end
		return false
	end
	local timeList = string.split(taskInfo.config.num,";")
	local startTime = string.split(timeList[1],":")
	local endTime = string.split(timeList[2],":")
	startTime = q.getTimeForHMS(startTime[1], startTime[2], startTime[3])
	endTime = q.getTimeForHMS(endTime[1], endTime[2], endTime[3])
	local currTime = q.serverTime()
	--在吃饭之前 
	if currTime < startTime then
		if taskInfo.timeHandler == nil then
			taskInfo.timeHandler = scheduler.performWithDelayGlobal(function ()
				taskInfo.timeHandler = nil
				self:mealTimesEveryday()
				self:dispatchEvent({name = QTask.EVENT_TIME_DONE})
			end,(startTime-currTime))
		end
		taskInfo.isShow = true
		return false
	end
	--在吃饭之中
	if currTime >= startTime and currTime <= endTime then
		if taskInfo.timeHandler == nil then
			taskInfo.timeHandler = scheduler.performWithDelayGlobal(function ()
				taskInfo.timeHandler = nil
				self:mealTimesEveryday()
				self:dispatchEvent({name = QTask.EVENT_TIME_DONE})
			end,(endTime-currTime))
		end
		taskInfo.isShow = true
		if taskInfo.state ~= QTask.TASK_COMPLETE then
			taskInfo.state = QTask.TASK_DONE
			return true
		end
	end
	--吃饭之后
	if currTime > endTime then
		taskInfo.state = QTask.TASK_NONE
		taskInfo.isShow = false
	end
	return false
end

--[[
	任务的快捷链接
]]
function QTask:quickLink(taskId)
	if taskId == "100500" then
		app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBuyVirtual",
      options = {typeName=ITEM_TYPE.MONEY}})
	elseif taskId == "100400" then
		app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogTreasureChestDraw"})
	elseif taskId == "100100" then
		app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogInstance"})
	elseif taskId == "100200" then
		app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogInstance", options={instanceType = DUNGEON_TYPE.ELITE}})
	elseif taskId == "100300" then
		app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogHeroOverview"}, {transitionClass = "QUITransitionDialogHeroOverview"})
	elseif taskId == "100600" then
		app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogTimeMachine"})
	elseif taskId == "100700" then
		app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogGoldBattle"})
	elseif taskId == "100800" then
  		remote.arena:openArena()
	end
end

return QTask