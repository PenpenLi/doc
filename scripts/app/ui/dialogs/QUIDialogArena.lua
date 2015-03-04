--
-- Author: wkwang
-- Date: 2015-01-14 20:06:17
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogArena = class("QUIDialogArena", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QUIDialogStore = import("..dialogs.QUIDialogStore")
local QUIViewController = import("..QUIViewController")
local QUIWidgetArena = import("..widgets.QUIWidgetArena")
local QShop = import("...utils.QShop")
local QArenaDialogWin = import("..battle.QArenaDialogWin")
local QArenaDialogLose = import("..battle.QArenaDialogLose")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QTutorialDirector = import("...tutorial.QTutorialDirector")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QVIPUtil = import("...utils.QVIPUtil")

function QUIDialogArena:ctor(options)
 	local ccbFile = "ccb/Dialog_Arena.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerIntroduce", callback = handler(self, QUIDialogArena._onTriggerIntroduce)},
        {ccbCallbackName = "onTriggerRecord", callback = handler(self, QUIDialogArena._onTriggerRecord)},
        {ccbCallbackName = "onTriggerRank", callback = handler(self, QUIDialogArena._onTriggerRank)},
        {ccbCallbackName = "onTriggerConvert", callback = handler(self, QUIDialogArena._onTriggerConvert)},
        {ccbCallbackName = "onTriggerTeam", callback = handler(self, QUIDialogArena._onTriggerTeam)},
        {ccbCallbackName = "onTriggerBuyCount", callback = handler(self, QUIDialogArena._onTriggerBuyCount)},
        {ccbCallbackName = "onTriggerRefresh", callback = handler(self, QUIDialogArena._onTriggerRefresh)},
    }
    QUIDialogArena.super.ctor(self, ccbFile, callBacks, options)
	app:getNavigationController():getTopPage():setManyUIVisible()

	self:resetAll()
end

function QUIDialogArena:viewDidAppear()
    QUIDialogArena.super.viewDidAppear(self)
  	self:addBackEvent()
  	if false and remote.user.nickname == nil or remote.user.nickname == "" then
      	app.tutorial:startTutorial(QTutorialDirector.Stage_10_ArenaAddName)
    end   
	self:refreshArena()
	self.arenaEventProxy = cc.EventProxy.new(remote.arena)
    self.arenaEventProxy:addEventListener(remote.arena.EVENT_UPDATE, handler(self, self.arenaResponseHandler))
    self.arenaEventProxy:addEventListener(remote.arena.EVENT_UPDATE_SELF, handler(self, self.responseSelfHandler))
    self.arenaEventProxy:addEventListener(remote.arena.EVENT_UPDATE_TEAM, handler(self, self.responseTeamHandler))
end

function QUIDialogArena:viewWillDisappear()
    QUIDialogArena.super.viewWillDisappear(self)
    self.arenaEventProxy:removeAllEventListeners()
    self.arenaEventProxy = nil
	self:removeBackEvent()
	if self._teamHeros ~= nil then
		for _,value in pairs(self._teamHeros) do
			value:removeFromParent()
		end
		self._teamHeros = nil
	end
	if self._users ~= nil then
		for _,value in pairs(self._users) do
			value:removeAllEventListeners()
			value:removeFromParent()
		end
		self._users = nil
	end
	self:removeTimeCount()
end

function QUIDialogArena:resetAll()
	self._ccbOwner.tf_rank:setString(0)
	self._ccbOwner.tf_arena_point:setString(0)
	self._ccbOwner.tf_battleforce:setString(0)

	self._ccbOwner.tf_count:setString("0/0")
	self._ccbOwner.node_have:setVisible(false)
	self._ccbOwner.node_buy:setVisible(false)

	local maxCount = remote.teams:getHerosMaxCount()
	for i=1,maxCount,1 do
		self._ccbOwner["node_lock"..i]:setVisible(false)
	end

	self._ccbOwner.node_time:setVisible(false)

	for i=1,4,1 do
		self._ccbOwner["node_team"..i]:removeAllChildren()
	end
end

--战队刷新
function QUIDialogArena:refreshArena(isForce)
	local options = self:getOptions()
	if options == nil then
		options = {}
		self:setOptions(options)
	end
	if options.arenaResponse ~= nil and isForce ~= true then
		self.myInfo = remote.arena:madeReciveData("self").arenaResponse.self
		self.rivals = clone(options.arenaResponse.rivals or {})
		self:myTeamHandler()
		self:competitorHandler()
	else
		remote.arena:requestArenaInfo()
	end
end

function QUIDialogArena:arenaResponseHandler(event)
	local data = event.data
	self.myInfo = clone(data.arenaResponse.self)
	self.rivals = clone(data.arenaResponse.rivals or {})
	local options = self:getOptions()
	options.arenaResponse = data.arenaResponse
	self:myTeamHandler()
	self:competitorHandler()
end

function QUIDialogArena:responseSelfHandler(event)
	local data = event.data
	self.myInfo = clone(data.arenaResponse.self)
	self:myTeamHandler()
end

function QUIDialogArena:responseTeamHandler(event)
	local data = event.data
	self.myInfo = clone(data.arenaResponse.self)
	self:myTeamHandler()
end

--战队信息处理
function QUIDialogArena:myTeamHandler()
	if self.myInfo.topRank ~= remote.user.arenaTopRank then
		remote.user:update({arenaTopRank = self.myInfo.topRank})
	end
	--设置战队成员
	-- set local instance team to server, server will save at frist time
	-- if server response team not compare local , then save local to server
	local team = remote.teams:getTeams(remote.teams.ARENA_DEFEND_TEAM)
	if (team == nil or #team == 0) and self.myInfo.heros ~= nil and #self.myInfo.heros > 0 then
		for _,value in pairs(self.myInfo.heros) do
			remote.teams:addHero(value.actorId, remote.teams.ARENA_DEFEND_TEAM)
		end
		remote.teams:saveTeam(remote.teams.ARENA_DEFEND_TEAM)
	else
		if team == nil or #team == 0 then
			team = remote.teams:getTeams(remote.teams.INSTANCE_TEAM)
			if team == nil or #team == 0 then
				team = {}
				local haveHeros = remote.herosUtil:getHaveHeroKey()
				local maxCount = #haveHeros > remote.teams:getHerosMaxCount() and remote.teams:getHerosMaxCount() or #haveHeros
				for i=1,maxCount,1 do
					table.insert(team, haveHeros[i])
				end
			end
		end

		if team ~= nil and #team >= 0 then
			if self.myInfo.heros == nil or #team ~= #self.myInfo.heros then
				self:saveTeam(team)
				return
			else
				for _,actorId in pairs(team) do
					local isFind = false
					for _,value2 in pairs(self.myInfo.heros) do
						if actorId == value2.actorId then
							isFind = true
						end
					end
					if isFind == false then
						self:saveTeam(team)
						return
					end
				end
			end
		end
	end
	if self.myInfo.heros == nil then
		self.myInfo.heros = {}
	end
	if self._teamHeros == nil then
		self._teamHeros = {}
	end
	local index = 1
	for _,value in pairs(self.myInfo.heros) do
		if self._ccbOwner["node_hero"..index] ~= nil then
			if #self._teamHeros < index then
				local heroHead = QUIWidgetHeroHead.new()
				heroHead:setHero(value.actorId)
				heroHead:setLevel(value.level)
				heroHead:setBreakthrough(value.breakthrough)
				heroHead:setStar(value.grade)
				self._ccbOwner["node_hero"..index]:removeAllChildren()
				self._ccbOwner["node_hero"..index]:addChild(heroHead)
				table.insert(self._teamHeros, heroHead)
			else
		        self._teamHeros[index]:setHero(value.actorId)
		        self._teamHeros[index]:setLevel(value.level)
		        self._teamHeros[index]:setBreakthrough(value.breakthrough)
		        self._teamHeros[index]:setStar(value.grade)
			end
			index = index + 1
		end
	end

	-- set self info
	self._ccbOwner.tf_rank:setString(self.myInfo.rank)
	self._ccbOwner.tf_arena_point:setString(remote.user.arenaMoney)
	self._ccbOwner.tf_battleforce:setString(remote.teams:getBattleForceForKey(remote.teams.ARENA_DEFEND_TEAM))
  
	local config = QStaticDatabase:sharedDatabase():getConfiguration()

	self._totalCount = 5
	self._cdTime = config.ARENA_CD.value
	if self.myInfo.fightCount < self._totalCount then
		self._ccbOwner.node_have:setVisible(true)
		self._ccbOwner.node_buy:setVisible(false)
		self._ccbOwner.tf_count:setString(string.format("%d/%d", self._totalCount-self.myInfo.fightCount, self._totalCount))

		local passTime = (self.myInfo.lastFightAt or 0)/1000 + self._cdTime
		if passTime > q.serverTime() and self.myInfo.fightCount > 0 then
			self._ccbOwner.node_time:setVisible(true)
			self:timeCount()
		else
			self._ccbOwner.node_time:setVisible(false)
		end
	else
		self._ccbOwner.node_have:setVisible(false)
		self._ccbOwner.node_buy:setVisible(true)
		self._ccbOwner.node_time:setVisible(false)
	end
end

--对手信息处理
function QUIDialogArena:competitorHandler()
	if self._users == nil then
		self._users = {}
	else
		for _,cell in pairs(self._users) do
			cell:setVisible(false)
		end
	end
	local index = 1
	for _,value in pairs(self.rivals) do
		if #self._users < index then
			local userCell = QUIWidgetArena.new()
			userCell:addEventListener(userCell.EVENT_USER_HEAD_CLICK, handler(self, self.clickCellHandler))
			userCell:addEventListener(userCell.EVENT_BATTLE, handler(self, self.startBattleHandler))
			userCell:setInfo(value)
			self._ccbOwner["node_team"..index]:addChild(userCell)
			table.insert(self._users, userCell)
		else
			self._users[index]:setInfo(value)
			self._users[index]:setVisible(true)
		end
		index = index + 1
	end
end

-- save self team to server
function QUIDialogArena:saveTeam(team)
	remote.arena:requestSetDefenseHero(team)
end

function QUIDialogArena:timeCount()
	self:removeTimeCount()
	local timeFun = function()
			local passTime = q.serverTime() - (self.myInfo.lastFightAt or 0)/1000
			if passTime <= self._cdTime then
				local needTime = self._cdTime - passTime 
				self._ccbOwner.tf_time:setString(string.format("%02d:%02d后", math.floor(needTime/60),math.floor(needTime%60)))
			else
				self._ccbOwner.node_time:setVisible(false)
				self:removeTimeCount()
			end
		end
	self._timeHandler = scheduler.scheduleGlobal(timeFun, 1)
	timeFun()
end

function QUIDialogArena:removeTimeCount()
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
	end
end

function QUIDialogArena:startBattle(userId)
	local rivalInfo = nil
	local rivalsPos = 0
	for _,value in pairs(self.rivals) do
      	rivalsPos = rivalsPos + 1
		if value.userId == userId then
			rivalInfo = value
			break
		end
	end
	if rivalInfo == nil then
		return
	end

	local teams = remote.teams:getTeams(remote.teams.ARENA_ATTACK_TEAM)
	if teams == nil or #teams == 0 then
		teams = clone(remote.teams:getTeams(remote.teams.INSTANCE_TEAM))
		remote.teams:setTeams(remote.teams.ARENA_ATTACK_TEAM, teams)
	end
	remote.teams:sortTeam(rivalInfo.heros)
	app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogTeamArrangement",
		options = {info = {myInfo = self.myInfo, rivalInfo = rivalInfo, rivalsPos = rivalsPos, options = self:getOptions()}, battleButtonVisible = true, teamKey = remote.teams.ARENA_ATTACK_TEAM}})

end

function QUIDialogArena:_teamIsNil()
  app:alert({content="还未设置战队，无法参加战斗！现在就设置战队？",title="系统提示",callBack=nil,comfirmBack= function()
  		self:_onTriggerTeam()
  	end, callBack = function ()
	end})
end

function QUIDialogArena:_onTriggerIntroduce(event)
  app.sound:playSound("common_others")
  app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogRewardRules",
    options = {info = self.myInfo}})
end

function QUIDialogArena:clickCellHandler(event)
  app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogArenaFigterInfo",
    options = {info = event.info}})
end

function QUIDialogArena:startBattleHandler(event)
	if (self._totalCount-self.myInfo.fightCount) <= 0 then
    	app.tip:floatTip("今日挑战次数已达上限")
		return
	end
  	if remote.teams:getHerosCount(remote.teams.ARENA_DEFEND_TEAM) == 0 then
    	self:_teamIsNil()
    	return 
  	end

	local passTime = q.serverTime() - (self.myInfo.lastFightAt or 0)/1000
	local config = QStaticDatabase:sharedDatabase():getConfiguration()
	if passTime <= self._cdTime and self.myInfo.fightCount > 0 then
  		if not QVIPUtil:canResetArenaCD() then
			app:alert({content="竞技场战斗CD中无法挑战，升级至vip"..QVIPUtil:getcanResetArenaCDUnlockLevel().."可解锁“立即重置竞技场CD”功能，是否充值？", title="系统提示", confirmText="查看VIP", comfirmBack = function()
					app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogVip"})
				end, callBack = function ()
				end})
			return
  		else
  				app:alert({content=string.format("挑战时间在冷却中，消除冷却时间需花费%d符石\n是否消除CD直接挑战对方？", config.ARENA_CD_REMOVE.value),title="系统提示",comfirmBack=function()
					self:startBattle(event.info.userId)
				end, callBack = function ()
				end})
			return
		end
	end
	self:startBattle(event.info.userId)
end

function QUIDialogArena:_onTriggerRecord(event)
	app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogArenaAgainstRecord"}, 
		{isPopCurrentDialog = false})
end

function QUIDialogArena:_onTriggerRank(event)
	app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogRank"}, 
		{isPopCurrentDialog = false})
end

function QUIDialogArena:_onTriggerConvert(event)
  app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogStore", 
  	options = {type = QShop.ARENA_SHOP, info = {arenaMoney = remote.user.arenaMoney or 0}}})
end

function QUIDialogArena:_onTriggerTeam(event)
	app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogTeamArrangement",
		options = {info = self.info, battleButtonVisible = false, teamKey = remote.teams.ARENA_DEFEND_TEAM}})
end

function QUIDialogArena:_onTriggerBuyCount(event)
	local config = QStaticDatabase:sharedDatabase():getTokenConsumeByType("arena_times")
	if self.myInfo.fightBuyCount >= #config then
    	app.tip:floatTip("今日购买次数已达上限")
	else
		local costToken = config[self.myInfo.fightBuyCount+1].token_cost
		app:alert({content=string.format("购买%d次挑战次数需花费%d符石\n是否继续？（今日已购买%d次）", self._totalCount, costToken, self.myInfo.fightBuyCount), title="系统提示", comfirmBack=function()
				if costToken > remote.user.token then
    				app.tip:floatTip("符石不足")
    				return 
				end
				remote.arena:requestBuyFighterCount()
			end, callBack = function ()
			end})
	end
end

function QUIDialogArena:_onTriggerRefresh(event)
	self:refreshArena(true)
end

function QUIDialogArena:onTriggerBackHandler(tag)
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogArena:onTriggerHomeHandler(tag)
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

return QUIDialogArena