--
-- Author: wkwang
-- Date: 2014-08-18 14:14:49
--
local QUIDialog = import(".QUIDialog")
local QUIDialogDungeon = class("QUIDialogDungeon", QUIDialog)
local QUIWidgetEliteInfoStar = import("..widgets.QUIWidgetEliteInfoStar")
local QUIWidgetMonsterHead = import("..widgets.QUIWidgetMonsterHead")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QUIViewController = import("..QUIViewController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")
local QPromptTips = import("...utils.QPromptTips")
local QTeam = import("...utils.QTeam")
local QUIDialogMystoryStoreAppear = import("..dialogs.QUIDialogMystoryStoreAppear")
local QShop = import("...utils.QShop")
local QVIPUtil = import("...utils.QVIPUtil")

function QUIDialogDungeon:ctor(options)
	local ccbFile = "ccb/Dialog_EliteInfo.ccbi";
	local callBacks = 
	{
		{ccbCallbackName = "onTriggerBuyCount", callback = handler(self, QUIDialogDungeon._onTriggerBuyCount)},
		{ccbCallbackName = "onTriggerConditionInfo", callback = handler(self, QUIDialogDungeon._onTriggerConditionInfo)},
		{ccbCallbackName = "onTriggerTeam", callback = handler(self, QUIDialogDungeon._onTriggerTeam)},
		{ccbCallbackName = "onTriggerQuickFightOne", callback = handler(self, QUIDialogDungeon._onTriggerQuickFightOne)},
		{ccbCallbackName = "onTriggerQuickFightTen", callback = handler(self, QUIDialogDungeon._onTriggerQuickFightTen)},
	}
	QUIDialogDungeon.super.ctor(self,ccbFile,callBacks,options)

	app:getNavigationController():getTopPage():setManyUIVisible()
	
	self.info = options.info
	self.config = QStaticDatabase:sharedDatabase():getDungeonConfigByID(self.info.dungeon_id)
	self._star = QUIWidgetEliteInfoStar.new()
	self._ccbOwner.node_star:addChild(self._star)

	self:showInfo()
end

function QUIDialogDungeon:viewDidAppear()
	QUIDialogDungeon.super.viewDidAppear(self)
	self.prompt = app:promptTips()
	self.prompt:addItemEventListener(self)
	self.prompt:addMonsterEventListener()
	self:addBackEvent()
    self._ruleTouchLayer = CCLayerColor:create(ccc4(0, 0, 0, 0), display.width, display.height)
    self._ruleTouchLayer:setPosition(-display.width/2, -display.height/2)
    self._ruleTouchLayer:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._ruleTouchLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIDialogDungeon._onTriggerConditionInfo))
    self._ruleTouchLayer:setTouchEnabled(true)
    self._ccbOwner.node_rule:addChild(self._ruleTouchLayer, -1)
    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(remote.DUNGEON_UPDATE_EVENT, handler(self, self.showInfo))
end

function QUIDialogDungeon:viewWillDisappear()
  	QUIDialogDungeon.super.viewWillDisappear(self)
 	self.prompt:removeItemEventListener()
    self.prompt:removeMonsterEventListener()
	self:removeBackEvent()
    if self._ruleTouchLayer ~= nil then
        self._ruleTouchLayer:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
        self._ruleTouchLayer:setTouchEnabled(false)
        self._ruleTouchLayer:removeFromParent()
        self._ruleTouchLayer = nil
    end
    self._remoteProxy:removeAllEventListeners()

    if self._actionHandler ~= nil then
    	self._ccbOwner.node_rule:stopAction(self._actionHandler)
    end
end

function QUIDialogDungeon:showInfo()
	local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
	self._ccbOwner.tf_title_name:setString(self.info.number.." "..self.config.name)
	self._ccbOwner.tf_info:setString(self.config.description or "")

	self._fightCount = remote.instance:getFightCountBydungeonId(self.info.dungeon_id)
	self._fightCount = self._fightCount > 0 and self._fightCount or 0
	self._ccbOwner.tf_consume:setString("消耗体力 ："..self.config.energy.."     剩余次数："..self._fightCount.."/"..self.info.attack_num.."")
	if self._fightCount == 0 and self.info.dungeon_type == DUNGEON_TYPE.ELITE then
		self._ccbOwner.btn_buy:setVisible(true)
	else
		self._ccbOwner.btn_buy:setVisible(false)
	end
	self._itemCount = remote.items:getItemsNumByID(global.sao_dang_quan_id) -- 扫荡券

	self._ccbOwner.node_rule:setVisible(false)
	self._ccbOwner.tf_rule:setString(globalConfig.DUNGEON_STAR_README.value)

	local perNum = 10
	if self.info.attack_num < perNum then
		perNum = self.info.attack_num
	end
	local tenBtnTF = "扫荡"..perNum.."次"
	local minimum = self._itemCount
	if self._fightCount < perNum then
		tenBtnTF = "扫荡"..tostring(self._fightCount).."次"
	end
	self._ccbOwner.tf_ten:setString(tenBtnTF)

	self._ccbOwner.label_fightCount:setString(tostring(self._itemCount))

	local isPassed = self.info.info and (self.info.info.lastPassAt or 0) or 0 -- 0 means this dungeon has not passed
	if isPassed ~= 0 and remote.user.level >= tonumber(globalConfig.UNLOCK_RUSH_INSTANCE.value) then --and self._fightCount > 0
		self._ccbOwner.node_saodang:setVisible(true)
	else
		self._ccbOwner.node_saodang:setVisible(false)
	end

	self._ccbOwner.node_star_info:setVisible(false)
	self._ccbOwner.node_star:setVisible(false)

	local isShowStarInfo = remote.instance:checkDungeonIsShowStar(self.info.dungeon_id)
	if isShowStarInfo == false then
		self._ccbOwner.node_star:setVisible(true)
		self._star:showStar(star)
		self._star:stop()
	else
		self._ccbOwner.node_star_info:setVisible(true)
		local dungeonTargetConfig = QStaticDatabase:sharedDatabase():getDungeonTargetByID(self.info.dungeon_id)
		for i=1,3,1 do
			self._ccbOwner["tf_condition"..i]:setString("")
			for _,value in pairs(dungeonTargetConfig) do
				if value.target == i then
					self._ccbOwner["tf_condition"..i]:setString(value.target_text or "")
				end
			end
		end
	end

	self:getMonsterConfig()
	self:getItemConfig()

	if not QVIPUtil:canSweepTenTimes() then
		self._ccbOwner.btn_ten:setVisible(false)
	end
end

--获取关卡掉落信息
function QUIDialogDungeon:getItemConfig()
	self._items = {}
	local dropItems = self.config.drop_item
	local dropItems = string.split(dropItems, ";")
	for _,id in pairs(dropItems) do
        self:_setBoxInfo(id,ITEM_TYPE.ITEM,0)
	end
end

function QUIDialogDungeon:_setBoxInfo(itemID,itemType,num)
	local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(itemID)
	if itemConfig == nil then return end
	local box = QUIWidgetItemsBox.new()
    box:setGoodsInfo(itemID,itemType,num)
    box:setPosition(100 * #self._items, 0)
    box:setScale(0.82)
    box:setPromptIsOpen(true)
    self._ccbOwner.node_items:addChild(box)
	table.insert(self._items, box)
end

--获取怪物配置生成怪物信息
function QUIDialogDungeon:getMonsterConfig()
	local monsterConfig = QStaticDatabase:sharedDatabase():getMonstersById(self.config.monster_id)
	local monsterData = {}
	if #monsterConfig > 0 then
		for i,value in pairs(monsterConfig) do
			local value = clone(value)
			value.npc_index = i
			table.insert(monsterData, value)
		end
		table.sort(monsterData,function (a, b)
				if a.wave ~= b.wave then
					return a.wave > b.wave
				else
					return a.is_boss or false
				end
			end)
		--过滤重复的怪物
		local tempData = {}
		local tempData2 = {}
		for _,value in pairs(monsterData) do
			local npc_id = app:getBattleRandomNpc(self.config.monster_id, value.npc_index, value.npc_id)
			if tempData[npc_id] == nil then
				tempData[npc_id] = 1
				local clone_value = clone(value)
				clone_value.npc_id = npc_id
				table.insert(tempData2,clone_value)
			end
		end
		monsterData = tempData2
	end

	self._monster = {}
	self._monsterX = 0
	local count = 0 
	for _,value in pairs(monsterData) do
		if count < 5 then
			self:generateMonster(value)
			count = count + 1
		end
	end
end

--生成怪物头像
function QUIDialogDungeon:generateMonster(value)
	local index = #self._monster+1
	self._monster[index] = QUIWidgetMonsterHead.new(value, index)
	self._ccbOwner.node_monster:addChild(self._monster[index])
	local perWidth = 0
	if index > 1 then
		perWidth = self._monster[index - 1]:getSize().width
	end
	local size = self._monster[index]:getSize()
	local gap = 2
	local offsetX = (size.width/2 + gap) * (index == 1 and 0 or 1) + perWidth/2
	self._monsterX = self._monsterX + offsetX
	self._monster[index]:setPosition(self._monsterX,0)
end

function QUIDialogDungeon:_teamIsNil()
	app:alert({content="还未设置战队，无法参加战斗！现在就去设置战队？",title="系统提示", comfirmBack=handler(self, self._gotoTeam), callBack = function ()
			end})
end

function QUIDialogDungeon:_handleAvailableNumberNotEnough()
	app:alert({content="本关卡战斗次数已达本日上限！",title="系统提示",callBack=nil,comfirmBack = nil})
end

function QUIDialogDungeon:checkFightCountHandler()
	if self._fightCount > 0 then
		return true
	end
	if self.info.dungeon_type == DUNGEON_TYPE.ELITE then
		local dungeonCountConfig = QStaticDatabase:sharedDatabase():getTokenConsumeByType("dungeon_elite")
		local dungeonCountConfig = dungeonCountConfig[self.info.info.todayReset + 1]
		if dungeonCountConfig == nil then
	    	app.tip:floatTip("本关卡战斗次数已达本日上限！")
		else
			app:alert({content="战斗次数已耗尽，重置需要花费"..dungeonCountConfig.token_cost.."符石是否继续？(今日已购买"..self.info.info.todayReset.."次)", title="系统提示", callBack=nil, comfirmBack = function()
					app:getClient():buyDungeonTicket(self.info.dungeon_id)
				end, callBack = function ()
			end})
		end
	else
    	app.tip:floatTip("本关卡战斗次数已达本日上限！")
	end
	return false
end

function QUIDialogDungeon:_gotoTeam()
	-- app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogTeamArrangement", options = {info = self.info, battleButtonVisible = false}})
end

--扫荡
function QUIDialogDungeon:_quickBattle(count)
	if remote.teams == nil or remote.teams._teams == nil or remote.teams._teams[QTeam.INSTANCE_TEAM] == nil then
		self:_teamIsNil()
		return 
	end
	local config = clone(self.config)

	if self:checkFightCountHandler() == false then
		return
	end

  	local oldLevel = remote.user.level
	app:getClient():dungeonFightQuick(self.info.dungeon_id, count,
		function(data)
			local dungeonInfo = remote.instance:getDungeonById(self.info.dungeon_id)
			if dungeonInfo.dungeon_type == DUNGEON_TYPE.NORMAL then
				remote.user:addPropNumForKey("addupDungeonPassCount", count)
			elseif dungeonInfo.dungeon_type == DUNGEON_TYPE.ELITE then
				remote.user:addPropNumForKey("addupDungeonElitePassCount", count)
			end
    		local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
			if data.shops ~= nil then
			  	for _, value in pairs(data.shops) do 
		            if value.id == tonumber(QShop.GOBLIN_SHOP) and oldLevel >= unlockVlaue["UNLOCK_SHOP_1"].value then
		                app.tip:addUnlockTips(QUIDialogMystoryStoreAppear.FIND_GOBLIN_SHOP)
		            elseif value.id == tonumber(QShop.BLACK_MARKET_SHOP) and oldLevel >= unlockVlaue["UNLOCK_SHOP_2"].value then
		                app.tip:addUnlockTips(QUIDialogMystoryStoreAppear.FIND_BLACK_MARKET_SHOP)
		            end
	          	end
			end
			app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogEliteBattleAgain", 
				options = {dungeon = config, awards = data.batchAwards, info = self.info, config = self.config}},{isPopCurrentDialog = false})
			self:showInfo()
		end,nil)
end

function QUIDialogDungeon:onTriggerBackHandler(tag)
	self:_onTriggerBack()
end

function QUIDialogDungeon:onTriggerHomeHandler(tag)
	self:_onTriggerHome()
end

function QUIDialogDungeon:_onTriggerBack(tag)
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    local options = self:getOptions()
    if options.fromController ~= nil then
    	options.fromController:popViewController(QNavigationController.POP_TOP_CONTROLLER)
    end
end

function QUIDialogDungeon:_onTriggerHome(tag)
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
    local options = self:getOptions()
    if options.fromController ~= nil then
    	options.fromController:popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
    end
end

function QUIDialogDungeon:_onTriggerTeam(tag)
	app.sound:playSound("common_item")
	if self:checkFightCountHandler() == false then
		return
	end
	local options = self:getOptions()
    app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogTeamArrangement",
     options = {info = self.info, fromController = options.fromController}})
end

function QUIDialogDungeon:_onTriggerQuickFightOne(tag)
	if self:checkFightCountHandler() == false then
		return
	end
	if self._itemCount == 0 then
		if not QVIPUtil:canUseTokenSweep() then
			app:alert({content="扫荡劵不足，升级至vip"..QVIPUtil:getUseTokenSweepUnlockLevel().."可解锁“符石扫荡关卡”功能，是否充值？", title="系统提示", confirmText="查看VIP", comfirmBack = function()
					app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogVip"})
				end, callBack = function ()
				end})
		else
			self._alert = app:alert({content="扫荡劵已用完，扫荡需消耗1个符石",title="提示", comfirmBack=function()
				if remote.user.token < 1 then
					app:alert({content="符石不足，赶快去充值吧！",title="系统提示",callBack=nil,comfirmBack = nil})
				else
					self:_quickBattle(1)
				end
			end, callBack = function ()
				end})
		end
	else
		self:_quickBattle(1)
	end
end

function QUIDialogDungeon:_onTriggerQuickFightTen(tag)
	if self:checkFightCountHandler() == false then
		return
	end
	local count = 10
	if count > self._fightCount then
		count = self._fightCount
	end

	if self._itemCount >= count then
		self:_quickBattle(count)
	else
		if not QVIPUtil:canUseTokenSweep() then
			app:alert({content="扫荡劵不足，升级至vip"..QVIPUtil:getUseTokenSweepUnlockLevel().."可解锁“符石扫荡关卡”功能，是否充值？", title="系统提示", confirmText="查看VIP", comfirmBack = function()
					app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogVip"})
				end, callBack = function ()
				end})
		else
			self._alert = app:alert({content="扫荡劵不足，扫荡需消耗" .. tonumber(count) .."个符石",title="提示", comfirmBack=function()
				if remote.user.token < count then
					app:alert({content="符石不足，赶快去充值吧！",title="系统提示",callBack=nil,comfirmBack = nil})
				else
					self:_quickBattle(count)
				end
			end, callBack = function ()
				end})
		end
	end
end

function QUIDialogDungeon:_onTriggerConditionInfo()
	if self._actionHandler == nil then
		app.sound:playSound("common_others")
		local scale = 1
		local isHide = not self._ccbOwner.node_rule:isVisible()
		if self._ccbOwner.node_rule:isVisible() == true  then
			scale = 0.2
		else
			self._ccbOwner.node_rule:setScale(0.2)
			self._ccbOwner.node_rule:setVisible(true)
		end
	  	local actionArrayIn = CCArray:create()
	  	actionArrayIn:addObject(CCScaleTo:create(0.1, scale))
	  	actionArrayIn:addObject(CCCallFunc:create(function ()
			self._ccbOwner.node_rule:setVisible(isHide)
		    self._actionHandler = nil
	  	end))
	  	local ccsequence = CCSequence:create(actionArrayIn)
	  	self._actionHandler = self._ccbOwner.node_rule:runAction(ccsequence)
  	end
end

function QUIDialogDungeon:_onTriggerBuyCount()
	local dungeonCountConfig = QStaticDatabase:sharedDatabase():getTokenConsumeByType("dungeon_elite")
	local dungeonConfig = dungeonCountConfig[self.info.info.todayReset + 1]
	if dungeonConfig == nil then
		dungeonConfig = dungeonCountConfig[#dungeonCountConfig]
	end

    if self.info.info.todayReset >= QVIPUtil:getResetEliteDungeonCount() then
		app:alert({content="今日已重置精英关卡"..self.info.info.todayReset.."次。\n重置精英关卡次数不足，提升VIP等级可获得更多次数", title="系统提示", confirmText="查看VIP", comfirmBack = function()
				app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogVip"})
			end, callBack = function ()
			end})
	else
		app:alert({content="重置精英关卡需要花费"..dungeonConfig.token_cost.."符石\n是否继续？(今日已重置"..self.info.info.todayReset.."次)", title="系统提示", comfirmBack = function()
				app:getClient():buyDungeonTicket(self.info.dungeon_id)
			end, callBack = function ()
			end})
	end
end

return QUIDialogDungeon