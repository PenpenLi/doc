--
-- Author: Your Name
-- Date: 2014-11-28 15:12:46
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogTimeMachine = class("QUIDialogTimeMachine", QUIDialog)
local QNavigationController = import("...controllers.QNavigationController")
local QUIViewController = import("..QUIViewController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QSkeletonViewController = import("...controllers.QSkeletonViewController")

QUIDialogTimeMachine.BOOTY_BAY = "activity1_1" --藏宝海湾
QUIDialogTimeMachine.GOLD_TEST = "activity2_1" --黄金试练
QUIDialogTimeMachine.EVERY_SECOND = 1
QUIDialogTimeMachine.CD_ERRORTEXT = "冷却时间内无法挑战"

function QUIDialogTimeMachine:ctor(options)
	local ccbFile = "ccb/Dialog_TimeMachine.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerClickFristHandler", callback = handler(self, QUIDialogTimeMachine._onTriggerClickFristHandler)},
		{ccbCallbackName = "onTriggerClickSecondHandler", callback = handler(self, QUIDialogTimeMachine._onTriggerClickSecondHandler)},

	}
	QUIDialogTimeMachine.super.ctor(self,ccbFile,callBacks,options)
	app:getNavigationController():getTopPage():setManyUIVisible()

	self:initPage()
	self._bootyBayCD = 0
	self._dwarfCellarCD = 0

	local config = remote.activityInstance:getInstanceListById(QUIDialogTimeMachine.BOOTY_BAY)
	self.bootyBayLeftCount = config[1].attack_num - remote.activityInstance:getAttackCountByType(config[1].instance_id)
	config = remote.activityInstance:getInstanceListById(QUIDialogTimeMachine.GOLD_TEST)
	self.dwarfLeftCount = config[1].attack_num - remote.activityInstance:getAttackCountByType(config[1].instance_id)
end

function QUIDialogTimeMachine:viewDidAppear()
	QUIDialogTimeMachine.super.viewDidAppear(self)
	self:addBackEvent()
	self:showCD()

	if self._dwarfCellarCD > 0 or self._bootyBayCD > 0 then
    	self._everySecond = scheduler.scheduleGlobal(handler(self, QUIDialogTimeMachine._onSecond), QUIDialogTimeMachine.EVERY_SECOND)
    end
end

function QUIDialogTimeMachine:viewWillDisappear()
  	QUIDialogTimeMachine.super.viewWillDisappear(self)
	self:removeBackEvent()
	if self.goblin_animation ~= nil then
  		self.goblin_animation:stopAnimation()
      	QSkeletonViewController.sharedSkeletonViewController():removeSkeletonActor(self.goblin_animation)
      	self.goblin_animation = nil
  	end
	if self.drunken_animation ~= nil then
  		self.drunken_animation:stopAnimation()
      	QSkeletonViewController.sharedSkeletonViewController():removeSkeletonActor(self.drunken_animation)
      	self.drunken_animation = nil
  	end

  	if self._everySecond ~= nil then
  		scheduler.unscheduleGlobal(self._everySecond)
  	end
end

function QUIDialogTimeMachine:initPage()
	self:setInfoByinstanceId(QUIDialogTimeMachine.BOOTY_BAY, 1)
	self:setInfoByinstanceId(QUIDialogTimeMachine.GOLD_TEST, 2)
	self:checkStateByinstanceId(QUIDialogTimeMachine.BOOTY_BAY, 1)
	self:checkStateByinstanceId(QUIDialogTimeMachine.GOLD_TEST, 2)

	local config = QStaticDatabase:sharedDatabase():getConfiguration()
	self._cdConfig = config.DUNGEON_ACTIVITIES_CD.value
end

-- @qinyuanji
-- Show CD time if there is for any activities
function QUIDialogTimeMachine:showCD()
	-- Booty bay
	local bootyBayLatest = 0
	for index = 1, 6 do
		local bootBayCD = remote.instance:dungeonLastPassAt("booty_bay_" .. tostring(index))
		if bootBayCD > bootyBayLatest then
			bootyBayLatest = bootBayCD 
		end
	end
	
	if bootyBayLatest > 0 and math.floor((q.serverTime()*1000 - bootyBayLatest)/1000) < self._cdConfig and self.bootyBayLeftCount > 0 then
		self._bootyBayCD = self._cdConfig - math.floor((q.serverTime()*1000 - bootyBayLatest)/1000)
		self._ccbOwner["booty_bay_cd_text"]:setString(q.timeToHourMinuteSecond(self._bootyBayCD) .. "后")
	else
		self._ccbOwner["activity1"]:setVisible(false)
	end

	-- Dwarf Cellar
	local dwarfCellarLatest = 0
	for index = 1, 6 do
		local dwarfCellarCD = remote.instance:dungeonLastPassAt("dwarf_cellar_" .. tostring(index))
		if dwarfCellarCD > dwarfCellarLatest then
			dwarfCellarLatest = dwarfCellarCD
		end
	end

	if dwarfCellarLatest > 0 and math.floor((q.serverTime()*1000 - dwarfCellarLatest)/1000) < self._cdConfig and self.dwarfLeftCount > 0 then
		self._dwarfCellarCD = self._cdConfig - math.floor((q.serverTime()*1000 - dwarfCellarLatest)/1000)
		self._ccbOwner["dwarf_cellar_cd_text"]:setString(q.timeToHourMinuteSecond(self._dwarfCellarCD) .. "后")
	else
		self._ccbOwner["activity2"]:setVisible(false)
	end
end

function QUIDialogTimeMachine:_onSecond(dt)
	self._bootyBayCD = self._bootyBayCD - 1
	self._ccbOwner["booty_bay_cd_text"]:setString(q.timeToHourMinuteSecond(self._bootyBayCD) .. "后")
		
	self._dwarfCellarCD = self._dwarfCellarCD - 1
	self._ccbOwner["dwarf_cellar_cd_text"]:setString(q.timeToHourMinuteSecond(self._dwarfCellarCD) .. "后")

	if self._bootyBayCD <= 0 then
		self._ccbOwner["activity1"]:setVisible(false)
	end
	if self._dwarfCellarCD <= 0 then
		self._ccbOwner["activity2"]:setVisible(false)
	end	
end

-- 设置界面中的信息
function QUIDialogTimeMachine:setInfoByinstanceId(instanceId, index)
	local list = remote.activityInstance:getInstanceListById(instanceId)
	if #list > 0 then
		self._ccbOwner["tf_name_"..index]:setString(list[1].instance_name)
		self._ccbOwner["tf_name_disable_"..index]:setString(list[1].instance_name)
	end

	if instanceId == QUIDialogTimeMachine.BOOTY_BAY then
  		self.goblin_animation = QSkeletonViewController.sharedSkeletonViewController():createSkeletonActorWithFile("goblin_bomb")
  		self.goblin_animation:scale(1.2)
  		self._ccbOwner["node_avatar_"..index]:addChild(self.goblin_animation)
		-- self._ccbOwner.node_avatar_1
	elseif instanceId == QUIDialogTimeMachine.GOLD_TEST then
  		self.drunken_animation = QSkeletonViewController.sharedSkeletonViewController():createSkeletonActorWithFile("drunken_dwarf")
  		self.drunken_animation:scale(1.2)
  		self._ccbOwner["node_avatar_"..index]:addChild(self.drunken_animation)
	end
end

--设置界面中的按钮是否可点
function QUIDialogTimeMachine:checkStateByinstanceId(instanceId, index)
	local animation = nil

	if instanceId == QUIDialogTimeMachine.BOOTY_BAY then
  		animation = self.goblin_animation
	elseif instanceId == QUIDialogTimeMachine.GOLD_TEST then
  		animation = self.drunken_animation
	end

	if remote.activityInstance:checkIsOpenForInstanceId(instanceId) == true then
		self._ccbOwner["node_title_disable_"..index]:setVisible(false)
		self._ccbOwner["node_title_"..index]:setVisible(true)
		self._ccbOwner["bj"..index]:setHighlighted(false)
		self._ccbOwner["bj"..index]:setEnabled(true)
		self._ccbOwner["btn"..index]:setVisible(false)
		self._ccbOwner["activity"..index]:setVisible(true)
		makeNodeFromGrayToNormal(animation)
  		animation:playAnimation(ANIMATION.STAND, true)
	else
		self._ccbOwner["node_title_disable_"..index]:setVisible(true)
		self._ccbOwner["node_title_"..index]:setVisible(false)
		self._ccbOwner["bj"..index]:setHighlighted(true)
		self._ccbOwner["bj"..index]:setEnabled(false)
		self._ccbOwner["btn"..index]:setVisible(true)
		self._ccbOwner["activity"..index]:setVisible(false)
		makeNodeFromNormalToGray(animation)
  		animation:stopAnimation()
	end
end

-- 对话框退出
function QUIDialogTimeMachine:onTriggerBackHandler(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- 对话框退出
function QUIDialogTimeMachine:onTriggerHomeHandler(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

-- 进入第一个副本
function QUIDialogTimeMachine:_onTriggerClickFristHandler(tag, menuItem)
	if remote.activityInstance:checkIsOpenForInstanceId(QUIDialogTimeMachine.BOOTY_BAY) == true then
		if self._bootyBayCD > 0 then
			app.tip:floatTip(QUIDialogTimeMachine.CD_ERRORTEXT)
			return 
		end
		app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogActivityInstance",
			options = {instanceId = QUIDialogTimeMachine.BOOTY_BAY}})
	else
		app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogActivityTips",
			options = {instanceId = QUIDialogTimeMachine.BOOTY_BAY}})
	end
end

-- 进入第二个副本
function QUIDialogTimeMachine:_onTriggerClickSecondHandler(tag, menuItem)
	if remote.activityInstance:checkIsOpenForInstanceId(QUIDialogTimeMachine.GOLD_TEST) == true then
		if self._dwarfCellarCD > 0 then
			app.tip:floatTip(QUIDialogTimeMachine.CD_ERRORTEXT)
			return
		end
		app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogActivityInstance",
			options = {instanceId = QUIDialogTimeMachine.GOLD_TEST}})
	else
		app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogActivityTips",
			options = {instanceId = QUIDialogTimeMachine.GOLD_TEST}})
	end
end

function QUIDialogTimeMachine:_tipsTouchHandler()
	self._ccbOwner.node_tips:setVisible(false)
end

return QUIDialogTimeMachine