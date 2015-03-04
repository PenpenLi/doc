--
-- Author: Your Name
-- Date: 2014-05-22 14:09:45
--
local QUIDialog = import(".QUIDialog")
local QUIDialogTeamArrangement = class("QUIDialogTeamArrangement", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetHeroOverview = import("..widgets.QUIWidgetHeroOverview")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroSmallFrame = import("..widgets.QUIWidgetHeroSmallFrame")
local QUIWidgetTeamField = import("..widgets.QUIWidgetTeamField")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIViewController = import("..QUIViewController")
local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QRemote = import("...models.QRemote")
local QTeam = import("...utils.QTeam")

QUIDialogTeamArrangement.TOTAL_HERO_FRAME = 10
QUIDialogTeamArrangement.TAB_ALL = "TAB_ALL"
QUIDialogTeamArrangement.TAB_TANK = "TAB_TANK"
QUIDialogTeamArrangement.TAB_TREAMENT = "TAB_TREAMENT"
QUIDialogTeamArrangement.TAB_CONTENTATTACH = "TAB_CONTENTATTACH"
QUIDialogTeamArrangement.TAB_MAGICATTACH = "TAB_MAGICATTACH"

function QUIDialogTeamArrangement:ctor(options)
	local ccbFile = "ccb/Dialog_TeamArrangement.ccbi"
	local callBacks = {
		-- {ccbCallbackName = "onTriggerBack", 				callback = handler(self, QUIDialogTeamArrangement._onTriggerBack)},
  --   	{ccbCallbackName = "onTriggerHome",         callback = handler(self, QUIDialogTeamArrangement._onTriggerHome)},
		{ccbCallbackName = "onTriggerLeft", 				callback = handler(self, QUIDialogTeamArrangement._onTriggerLeft)},
		{ccbCallbackName = "onTriggerRight", 				callback = handler(self, QUIDialogTeamArrangement._onTriggerRight)},
		{ccbCallbackName = "onTriggerTabAll", 				callback = handler(self, QUIDialogTeamArrangement._onTriggerTabAll)},
		{ccbCallbackName = "onTriggerTabTank", 				callback = handler(self, QUIDialogTeamArrangement._onTriggerTabTank)},
		{ccbCallbackName = "onTriggerTabTreatment", 		callback = handler(self, QUIDialogTeamArrangement._onTriggerTabTreatment)},
		{ccbCallbackName = "onTriggerTabContentAttack", 	callback = handler(self, QUIDialogTeamArrangement._onTriggerTabContentAttack)},
		{ccbCallbackName = "onTriggerTabMagicAttack",		callback = handler(self, QUIDialogTeamArrangement._onTriggerMagicAttack)},
		{ccbCallbackName = "onTriggerToHeroOverview",		callback = handler(self, QUIDialogTeamArrangement._onTriggerToHeroOverview)},
		{ccbCallbackName = "onTriggerFright",  callback = handler(self, QUIDialogTeamArrangement._onTriggerFright)},
		{ccbCallbackName = "onTriggerConfrim",  callback = handler(self, QUIDialogTeamArrangement._onTriggerConfrim)},
	}
	QUIDialogTeamArrangement.super.ctor(self,ccbFile,callBacks,options)
	app:getNavigationController():getTopPage():setManyUIVisible()
 
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
 	
    self._teamKey = options.teamKey
    self._teamCls = options.teamCls
    if self._teamKey == nil then
    	self._teamKey = QTeam.INSTANCE_TEAM
    end
    if self._teamKey == QTeam.SUNWELL_ATTACK_TEAM or self._teamKey == QTeam.POWER_TEAM or self._teamKey == QTeam.INTELLECT_TEAM then
    	self._ccbOwner.tips:setVisible(true)
    	self._ccbOwner.sheet_hreo:setPositionY(self._ccbOwner.sheet_hreo:getPositionY() - 30)
    	local size = self._ccbOwner.sheet_layout:getContentSize()
    	self._ccbOwner.sheet_layout:setContentSize(CCSize(size.width, size.height - 30))
    	self._ccbOwner.sheet_layout:setPositionY(self._ccbOwner.sheet_layout:getPositionY() + 30)
    	if self._teamKey == QTeam.SUNWELL_ATTACK_TEAM then
    		self._ccbOwner.tips:setString("英雄头像的灰度表示主动技能的冷却时间（20级以上的英雄才能参加决战太阳之井）")
    	elseif self._teamKey == QTeam.POWER_TEAM then
    		self._ccbOwner.tips:setString("建议选择物理伤害的英雄")
    	elseif self._teamKey == QTeam.INTELLECT_TEAM then
    		self._ccbOwner.tips:setString("建议选择魔法伤害的英雄")
    	end
    end

    if self._teamCls == nil then
    	self._teamCls = "QUIWidgetHeroSmallFrame"
    end

	-- 初始化中间英雄页面滑动框
	self:_initHeroPageSwipe()

	--初始化事件监听器
	self._eventProxy = QNotificationCenter.new()

	--初始化战队容器
	self._teamField = QUIWidgetTeamField.new()
	self._teamField:addEventProxy(self._eventProxy)
	self._ccbOwner.node_teamField:addChild(self._teamField:getView())

    if options.battleButtonVisible ~= nil and options.battleButtonVisible == false then
    	self._ccbOwner.btn_battle:setVisible(false)
		self._ccbOwner.btn_confrim:setVisible(true)
	else
    	self._ccbOwner.btn_battle:setVisible(true)
		self._ccbOwner.btn_confrim:setVisible(false)
    end

	self._herosNativeID = remote.herosUtil:getHaveHeroKey(self._teamKey)
	self._herosID = self._herosNativeID

	-- 初始化右边的tabs
	if options ~= nil and options.tab ~= nil then
		self:_selectTab(options.tab)
	else 
		self:_selectTab(QUIDialogTeamArrangement.TAB_ALL)
	end

	--获取战队信息
	self._isFrist = true
	self:_showTeams()
	self._isFrist = false
	  
	self._scrollPosYMin = 151.0
	self._scrollPosYMax = -121.0
	self._ccbOwner.scroll_bar:setOpacity(0)
	self._ccbOwner.sprite_scroll_cell:setOpacity(0)
	
	self.info = options.info
end

function QUIDialogTeamArrangement:viewDidAppear()
	QUIDialogTeamArrangement.super.viewDidAppear(self)
    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(QRemote.HERO_UPDATE_EVENT, handler(self, self.onEvent))
    self._remoteProxy:addEventListener(QRemote.TEAMS_UPDATE_EVENT, handler(self, self.onEvent))
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroSmallFrame.EVENT_HERO_FRAMES_CLICK, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroOverview.EVENT_HERO_SHEET_MOVE, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroOverview.EVENT_DISABLE_SCROLL_BAR, self.onEvent,self)
    self._eventProxy:addEventListener(QUIWidgetTeamField.EVENT_REMOVE_HROE, handler(self, self.onEvent))

    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
	self:addBackEvent()
end

function QUIDialogTeamArrangement:viewWillDisappear()
	QUIDialogTeamArrangement.super.viewWillDisappear(self)
	remote.teams:revertTeam(self._teamKey)
    self._remoteProxy:removeAllEventListeners()

    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()

    self._eventProxy:removeAllEventListeners()
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroSmallFrame.EVENT_HERO_FRAMES_CLICK, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroOverview.EVENT_HERO_SHEET_MOVE, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroOverview.EVENT_DISABLE_SCROLL_BAR, self.onEvent,self)
	self:removeBackEvent()
end

-- filter 英雄根据英雄的天赋
--{{actorId,createdAt,exp,heroId,id,level,typeCode,updateAt,userId}}
-- filter 英雄根据英雄的天赋
function QUIDialogTeamArrangement:_filterHerosByTalent()
	if self.tab == QUIDialogTeamArrangement.TAB_ALL then
		-- 显示全部英雄不做任何filter
		self._herosID = self._herosNativeID
		return 
	end

	if self._herosID ~= nil then
		local result = {}

		for i, actorId in pairs(self._herosNativeID) do
			local characher = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
			local talent = QStaticDatabase:sharedDatabase():getTalentByID(characher.talent)

			if self.tab == QUIDialogTeamArrangement.TAB_TANK then
				if talent.func == 't' then
					result[#result + 1] = actorId
				end
			elseif self.tab == QUIDialogTeamArrangement.TAB_TREAMENT then
				if talent.func == 'health' then
					result[#result + 1] = actorId
				end
			elseif self.tab == QUIDialogTeamArrangement.TAB_CONTENTATTACH then
				if talent.func == 'dps' and talent.attack_type == 1 then
					result[#result + 1] = actorId
				end
			elseif self.tab == QUIDialogTeamArrangement.TAB_MAGICATTACH then
				if talent.func == 'dps' and talent.attack_type == 2 then
					result[#result + 1] = actorId
				end
			end
		end
		self._herosID = result
		return 
	end
	return 
end

-- 初始化中间的英雄选择框 swipe工能
function QUIDialogTeamArrangement:_initHeroPageSwipe()
	
	self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
	self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
	self._pageContent = CCNode:create()
--	self._ccbOwner.sheet_layout:setVisible(false)

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._pageWidth,self._pageHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
	layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
	ccclippingNode:setStencil(layerColor)
	ccclippingNode:addChild(self._pageContent)
    self._ccbOwner.sheet_hreo:addChild(ccclippingNode)

	self._touchLayer = QUIGestureRecognizer.new()
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:attachToNode(self._ccbOwner.sheet_hreo,self._pageWidth, self._pageHeight, 0, -self._pageHeight, handler(self, self.onTouchEvent))

	self._isAnimRunning = false
end

-- 选择tab
function QUIDialogTeamArrangement:_selectTab(tab)
	self._ccbOwner.node_hero_tab_all:setHighlighted(false)
	self._ccbOwner.node_hero_tab_tank:setHighlighted(false)
	self._ccbOwner.node_hero_tab_treatment:setHighlighted(false)
	self._ccbOwner.node_hero_tab_contentattack:setHighlighted(false)
	self._ccbOwner.node_hero_tab_magicattack:setHighlighted(false)

	self.tab = tab
	if tab == QUIDialogTeamArrangement.TAB_ALL then
		self._ccbOwner.node_hero_tab_all:setHighlighted(true)
	elseif tab == QUIDialogTeamArrangement.TAB_TANK then
		self._ccbOwner.node_hero_tab_tank:setHighlighted(true)
	elseif tab == QUIDialogTeamArrangement.TAB_TREAMENT then
		self._ccbOwner.node_hero_tab_treatment:setHighlighted(true)
	elseif tab == QUIDialogTeamArrangement.TAB_CONTENTATTACH  then
		self._ccbOwner.node_hero_tab_contentattack:setHighlighted(true)
	elseif tab == QUIDialogTeamArrangement.TAB_MAGICATTACH  then
		self._ccbOwner.node_hero_tab_magicattack:setHighlighted(true)
	end

	self._isFrist = true
	self:_updateCurrentPage()
	self._isFrist = false
end

--根据当前页数刷新当前页英雄显示
function QUIDialogTeamArrangement:_updateCurrentPage()
	self:_filterHerosByTalent()
	if self._page == nil then
		self._page = QUIWidgetHeroOverview.new({rows = 5, lines = 2, hgap = 0, vgap = 0, offsetX = 0, offsetY = 0, cls = self._teamCls})
		self._pageContent:addChild(self._page:getView())
	end

	self._page:displayHeros(self._herosID, remote.teams:getTeams(self._teamKey))
	self._page:onMove()
end

---------------------------------战队相关处理----------------------

--从缓存里面取出战队数据 显示出来
function QUIDialogTeamArrangement:_showTeams()
	local teamHero = {}
	remote.teams:checkHeroTeam(self._teamKey)
	local team = remote.teams:getTeams(self._teamKey) or {}
	for _,teamInfo in pairs(team) do
		for _,heroInfo in pairs(remote.herosUtil.heros) do
			if teamInfo == heroInfo.actorId then
				table.insert(teamHero, heroInfo)
			end
		end
	end
	self._teamField:setTeamInfo(teamHero)
	self:refreshFrame()
	self:dispatchEvent({name = EVENT_COMPLETED})
end

--从缓存里面取出战队数据 显示出来
function QUIDialogTeamArrangement:refreshFrame()
	local frames = self._page:getHeroFrames()
	for _,frame in pairs(frames) do
		if frame:isVisible() == true then
			frame:refreshInfo()
		end
	end
end

--添加英雄到战队
function QUIDialogTeamArrangement:_addHeroToTeam(herosID, position)
	if self._teamField:getRuning() == true then
		return
	end
	if self:_checkHeroInTeam(herosID) == true then 
		self:_removeHeroToTeam(herosID)
		return 
	end
	if remote.teams:addHero(herosID, self._teamKey) == false then
		app:alert({content="战队已满，请先选择英雄取消出战状态"})
		return 
	end
	-- self:_showTeams()

	local teamHero = {}
	remote.teams:checkHeroTeam(self._teamKey)
	local team = remote.teams:getTeams(self._teamKey) or {}
	for _,teamInfo in pairs(team) do
		for _,heroInfo in pairs(remote.herosUtil.heros) do
			if teamInfo == heroInfo.actorId then
				table.insert(teamHero, heroInfo)
			end
		end
	end
	self:refreshFrame()

	if position == nil and self._page ~= nil then
		local frames = self._page:getHeroFrames()
		for _,frame in pairs(frames) do
			if herosID == frame:getHero() then
				position = frame:convertToWorldSpaceAR(ccp(0,0))
				break
			end
		end
	end

	if position == nil then
		position = ccp(display.cx, display.cy)
	end

	--播放上阵音效
    local heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(herosID)
	audio.playSound(heroDisplay.preparation,false)

	self._teamField:freshTeamFieldForAnimation(teamHero, position)
end

--移除英雄从战队
function QUIDialogTeamArrangement:_removeHeroToTeam(herosID)
	if self._teamField:getRuning() == true then
		return
	end
	if self:_checkHeroInTeam(herosID) == false then return end

	app.sound:playSound("cancel_to_battle")
	remote.teams:delHero(herosID, self._teamKey)	
	local teamHero = {}
	remote.teams:checkHeroTeam(self._teamKey)
	local team = remote.teams:getTeams(self._teamKey) or {}
	for _,teamInfo in pairs(team) do
		for _,heroInfo in pairs(remote.herosUtil.heros) do
			if teamInfo == heroInfo.actorId then
				table.insert(teamHero, heroInfo)
			end
		end
	end
	self:refreshFrame()
	
	self._teamField:freshTeamFieldForAnimation(teamHero)
end

--检查英雄是否在战队
function QUIDialogTeamArrangement:_checkHeroInTeam(herosID)
	if remote.teams == nil then 
		return false
	end
	return remote.teams:contains(herosID, self._teamKey)
end

--进入战斗
function QUIDialogTeamArrangement:_starBattle()
	self.config = QStaticDatabase:sharedDatabase():getDungeonConfigByID(self.info.dungeon_id)
	local config = clone(self.config)
	local teamHero = remote.teams:getTeams(self._teamKey) or {}
    app:getClient():dungeonFightStart(self.info.dungeon_id, teamHero,
      	function(data) 
			remote.teams:saveTeam(self._teamKey)
	        local options = self:getOptions()
	        config.awards = data.awards
	        config.awards2 = data.awards2 -- awards2 is full of garbage
	        config.teamName = self._teamKey

		  	--解锁战队格子
		  	remote.teams:unlockTeamForDungeon(self.info.dungeon_id)

       		app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
       		app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
       		app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_PAGE, uiClass = "QUIPageEmpty"}, {transitionClass = "QUITransitionImmediately"})

       		app:enterIntoBattleScene(config, {fromController = options.fromController})
  		end)
  	-- end
end

--开始竞技场战斗
function QUIDialogTeamArrangement:startArenaBatttle()
	app:getClient():arenaFightStartRequest(self.info.rivalInfo.userId, function ()
			remote.teams:saveTeam(self._teamKey)
			--更新今日竞技场打斗次数
			remote.user:addPropNumForKey("todayArenaFightCount")
			remote.user:addPropNumForKey("addupArenaFightCount")

			local config = {}
			config.id = "arena"
			config.name = "竞技场关卡"
			config.description = "这是一个竞技场关卡"
			config.monster_id = "arena_"
			config.isPVPMode = true
			config.isArena = true
			config.duration = 90
			config.team_exp = 0
			config.energy = 0
			config.hero_exp = 0
			config.money = 0
			config.sweep_id = -1
			config.sweep_num = -1
			config.mode = 3 -- BATTLE_MODE
			config.scene = "ccb/Battle_Scene.ccbi"
			config.bg = "map/arena.jpg"
			config.bg_2 = "map/arena.jpg"
			config.bg_3 = "map/arena.jpg"
			config.bgm = app.sound:getSoundURLById("arena_background")
			config.team1Name = remote.user.nickname
			config.team1Icon = remote.user.avatar
			if config.team1Icon == nil or string.len(config.team1Icon) == 0 then
				config.team1Icon = "icon/head/orc_warlord.png"
			end
			config.team2Name = self.info.rivalInfo.name
			config.team2Icon = self.info.rivalInfo.avatar
			if config.team2Icon == nil or string.len(config.team2Icon) == 0 then
				config.team2Icon = "icon/head/orc_warlord.png"
			end
			local enemyInfo = {}
			for _, member in ipairs(self.info.rivalInfo.heros) do
				local info = {}
				info.actorId = member.actorId
				info.level = member.level
				info.breakthrough = member.breakthrough
				info.grade = member.grade
				info.rankCode = "R0"
				info.items = member.items
				info.skills = member.skills
				table.insert(enemyInfo, info)
			end
			config.pvp_rivals = enemyInfo
			config.myInfo = self.info.myInfo
			config.myInfo.arenaMoney = remote.user.arenaMoney or 0
			config.rivalsInfo = self.info.rivalInfo
			config.rivalsPos = self.info.rivalsPos

			if config.rivalsInfo.force >= (self.info.myInfo.force or 0) then
				config.skipBattleWithWin = false
			else
				config.skipBattleWithWin = true
			end
	        config.teamName = self._teamKey

	   		app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	   		app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_PAGE, uiClass = "QUIPageEmpty"}, {transitionClass = "QUITransitionImmediately"})
			self.info.options.arenaResponse = nil
			remote.arena:clearFighter()
			app:enterIntoBattleScene(config)
		end, function ()
			self.info.options.arenaResponse = nil
			remote.arena:removeFighter(self.info.rivalInfo.userId)
		end)
end

function QUIDialogTeamArrangement:startSunWellBatttle()
	local dungeonInfo = self.info
	local actorIds = remote.teams:getTeams(self._teamKey)
	app:getClient():sunwellFightStartRequest(dungeonInfo.dungeonIndex, dungeonInfo.hardIndex, actorIds,
		function (data)
			remote.teams:saveTeam(self._teamKey)
			local config = {}
			config.id = "sunwell"
			config.name = "太阳井关卡"
			config.description = "这是一个太阳井关卡"
			config.monster_id = "sunwell_"
			config.isPVPMode = true
			config.isSunwell = true
			config.duration = 90
			config.team_exp = 0
			config.energy = 0
			config.hero_exp = 0
			config.money = 0
			config.sweep_id = -1
			config.sweep_num = -1
			config.mode = 3 -- BATTLE_MODE
			config.scene = "ccb/Battle_Scene.ccbi"
			config.bg = "map/arena.jpg"
			config.bg_2 = "map/arena.jpg"
			config.bg_3 = "map/arena.jpg"
			config.bgm = app.sound:getSoundURLById("sunwell_background")
			config.team1Name = remote.user.nickname
			config.team1Icon = remote.user.avatar
			config.sunwellMoney = dungeonInfo.sunwellMoney
			if config.team1Icon == nil or string.len(config.team1Icon) == 0 then
				config.team1Icon = "icon/head/orc_warlord.png"
			end
			config.team2Name = dungeonInfo.info.name
			printInfo(config.team2Name)
			config.team2Icon = dungeonInfo.info.avatar
			if config.team2Icon == nil or string.len(config.team2Icon) == 0 then
				config.team2Icon = "icon/head/orc_warlord.png"
			end
			local enemyInfo = {}
			for _, member in ipairs(dungeonInfo.info.heros) do
				local info = {}
				info.actorId = member.actorId
				info.level = member.level
				info.breakthrough = member.breakthrough
				info.grade = member.grade
				info.items = member.items
				info.skills = member.skills
				info.hp = member.hp
				info.skillCD = member.skillCD
				if member.hp == nil or member.hp > 0 then
					table.insert(enemyInfo, info)
				end
			end
			config.pvp_rivals = enemyInfo
			config.dungeonInfo = dungeonInfo
			config.myTeam = actorIds
	        config.teamName = self._teamKey

	   		app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	   		app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	   		app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_PAGE, uiClass = "QUIPageEmpty"}, {transitionClass = "QUITransitionImmediately"})
			app:enterIntoBattleScene(config)
		end,function ()
			
		end
		)
end

function QUIDialogTeamArrangement:_teamIsNil()
  app:alert({content="还未设置战队，无法参加战斗！现在就设置战队？",title="系统提示",callBack=nil,comfirmBack= nil})
end

function QUIDialogTeamArrangement:_handleAvailableNumberNotEnough()
  app:alert({content="本关卡战斗次数已达本日上限！",title="系统提示",callBack=nil,comfirmBack = nil})
end

--------------------------------------------------event start-----------------------

-- 处理各种touch event
function QUIDialogTeamArrangement:onTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
    	self._page:endMove(event.distance.y)
  	elseif event.name == "began" then
	    if self._page:getIsMove() == true then
	    	return 
	    end
  		self._startY = event.y
  		self._pageY = self._page:getView():getPositionY()
  		self._page:starMove()
    elseif event.name == "moved" then
    	local offsetY = self._pageY + event.y - self._startY
        if math.abs(event.y - self._startY) > 10 then
            self._isMove = true
        end
		self._page:getView():setPositionY(offsetY)
    elseif event.name == "ended" then
    	scheduler.performWithDelayGlobal(function ()
    		self._isMove = false
    		end,0)
    end
end

-- 处理各种touch event
function QUIDialogTeamArrangement:onEvent(event)
	if event == nil or event.name == nil then
        return
    end

	if event.name == QRemote.HERO_UPDATE_EVENT then
		self:_updateCurrentPage()
	elseif event.name == QRemote.TEAMS_UPDATE_EVENT then
		self:_showTeams()
	elseif event.name == QUIWidgetHeroSmallFrame.EVENT_HERO_FRAMES_CLICK then
		if self._isMove then return end
		self:_addHeroToTeam(event.hero.actorId, event.position)	
	elseif event.name == QUIWidgetTeamField.EVENT_REMOVE_HROE then
		self:_removeHeroToTeam(event.actorId)	
	elseif event.name == QUIWidgetHeroOverview.EVENT_HERO_SHEET_MOVE then
    if self._ccbOwner.scroll_bar:getOpacity() < 255 then
      self._ccbOwner.sprite_scroll_cell:stopAllActions()
      self._ccbOwner.scroll_bar:stopAllActions()
      self._ccbOwner.sprite_scroll_cell:setOpacity(255)
      self._ccbOwner.scroll_bar:setOpacity(255)
    end

    local percent = event.percent
    if percent < 0 then
      percent = 0
    end
    if percent > 1 then
      percent = 1
    end
    local positionY = (self._scrollPosYMax - self._scrollPosYMin) * percent + self._scrollPosYMin
    self._ccbOwner.sprite_scroll_cell:setPositionY(positionY)
  elseif event.name == QUIWidgetHeroOverview.EVENT_DISABLE_SCROLL_BAR then
    self._ccbOwner.sprite_scroll_cell:runAction(CCFadeOut:create(0.3))
    self._ccbOwner.scroll_bar:runAction(CCFadeOut:create(0.3))
    end
end

function QUIDialogTeamArrangement:_onTriggerTabAll(tag, menuItem)
	app.sound:playSound("common_switch")
	self:_selectTab(QUIDialogTeamArrangement.TAB_ALL)
end

function QUIDialogTeamArrangement:_onTriggerTabTank(tag, menuItem)
	app.sound:playSound("common_switch")
	self:_selectTab(QUIDialogTeamArrangement.TAB_TANK)
end

function QUIDialogTeamArrangement:_onTriggerTabTreatment(tag, menuItem)
	app.sound:playSound("common_switch")
	self:_selectTab(QUIDialogTeamArrangement.TAB_TREAMENT)
end

function QUIDialogTeamArrangement:_onTriggerTabContentAttack(tag, menuItem)
	app.sound:playSound("common_switch")
	self:_selectTab(QUIDialogTeamArrangement.TAB_CONTENTATTACH)
end

function QUIDialogTeamArrangement:_onTriggerMagicAttack(tag, menuItem)
	app.sound:playSound("common_switch")
	self:_selectTab(QUIDialogTeamArrangement.TAB_MAGICATTACH)
end

function QUIDialogTeamArrangement:onTriggerBackHandler(tag)
	self:_onTriggerBack()
end

function QUIDialogTeamArrangement:onTriggerHomeHandler(tag)
	self:_onTriggerHome()
end

function QUIDialogTeamArrangement:_onTriggerBack(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogTeamArrangement:_onTriggerHome(tag)
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
    local options = self:getOptions()
    if options.fromController ~= nil then
    	options.fromController:popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
    end
end

function QUIDialogTeamArrangement:_checkTeam()
	if remote.teams:getHerosCount(self._teamKey) == 0 then
		self:_teamIsNil()
	    return false
	end
	local teamHero = remote.teams:getTeams(self._teamKey) or {}
	--检查是否包含非治疗职业
	local isAllHeath = true
		for _,actorId in pairs(teamHero) do
		local characher = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
		local talent = QStaticDatabase:sharedDatabase():getTalentByID(characher.talent).func
		if talent ~= 'health' then
			isAllHeath = false
			break
		end
	end
	if isAllHeath == true then
		app.tip:floatTip("出战英雄不能全部为治疗英雄")
	  	return false
	end
	return true
end

function QUIDialogTeamArrangement:_onTriggerFright()
	if self:_checkTeam() ~= true then
		return 
	end
  	app.sound:playSound("battle_fight")
  	if self._teamKey == remote.teams.INSTANCE_TEAM or self._teamKey == remote.teams.TIME_MACHINE_TEAM or self._teamKey == remote.teams.POWER_TEAM or self._teamKey == remote.teams.INTELLECT_TEAM then
  		self:_starBattle()
  	elseif self._teamKey == remote.teams.ARENA_ATTACK_TEAM then
  		self:startArenaBatttle()
  	elseif self._teamKey == remote.teams.SUNWELL_ATTACK_TEAM then
  		self:startSunWellBatttle()
  	end
end

function QUIDialogTeamArrangement:_onTriggerConfrim()
	if self:_checkTeam() ~= true then
		return 
	end
	remote.teams:saveTeam(self._teamKey)
	app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogTeamArrangement