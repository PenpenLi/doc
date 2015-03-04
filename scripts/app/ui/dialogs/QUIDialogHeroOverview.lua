
local QUIDialog = import(".QUIDialog")
local QUIDialogHeroOverview = class(".QUIDialogHeroOverview", QUIDialog)

local QNotificationCenter = import("...controllers.QNotificationCenter")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QRemote = import("...models.QRemote")
local QTeam = import("...utils.QTeam")
local QUIWidgetHeroOverview = import("..widgets.QUIWidgetHeroOverview")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIViewController = import("..QUIViewController")
local QUIWidgetHeroFrame = import("..widgets.QUIWidgetHeroFrame")
local QTutorialDirector = import("...tutorial.QTutorialDirector")

QUIDialogHeroOverview.TOTAL_HERO_FRAME = 6
QUIDialogHeroOverview.TAB_ALL = "TAB_ALL"
QUIDialogHeroOverview.TAB_TANK = "TAB_TANK"
QUIDialogHeroOverview.TAB_TREAMENT = "TAB_TREAMENT"
QUIDialogHeroOverview.TAB_CONTENTATTACH = "TAB_CONTENTATTACH"
QUIDialogHeroOverview.TAB_MAGICATTACH = "TAB_MAGICATTACH"
QUIDialogHeroOverview.TUTORIAL_HERO_UP_GRADE = "TUTORIAL_HERO_UP_GRADE"

-- 英雄总览界面
function QUIDialogHeroOverview:ctor(options)
	local ccbFile = "ccb/Dialog_HeroOverview.ccbi"
	local callBacks = {
		-- {ccbCallbackName = "onTriggerBack", 				callback = handler(self, QUIDialogHeroOverview._onTriggerBack)},
		{ccbCallbackName = "onTriggerTabAll", 				callback = handler(self, QUIDialogHeroOverview._onTriggerTabAll)},
		{ccbCallbackName = "onTriggerTabTank", 				callback = handler(self, QUIDialogHeroOverview._onTriggerTabTank)},
		{ccbCallbackName = "onTriggerTabTreatment", 		callback = handler(self, QUIDialogHeroOverview._onTriggerTabTreatment)},
		{ccbCallbackName = "onTriggerTabContentAttack", 	callback = handler(self, QUIDialogHeroOverview._onTriggerTabContentAttack)},
		{ccbCallbackName = "onTriggerMagicAttack",			callback = handler(self, QUIDialogHeroOverview._onTriggerMagicAttack)},
		{ccbCallbackName = "onTriggerOpenTeamArrangement",	callback = handler(self, QUIDialogHeroOverview._onTriggerOpenTeamArrangement)}

	}
	QUIDialogHeroOverview.super.ctor(self,ccbFile,callBacks,options)
	app:getNavigationController():getTopPage():setManyUIVisible()
	self:setLock(true)

	-- 初始化中间英雄页面滑动框
	self:_initHeroPageSwipe()

	--初始化事件监听器
	self._eventProxy = QNotificationCenter.new()

	self._nativeActorIds = remote.herosUtil:getHerosKey()
	self._actorIds = self._nativeActorIds
	self._haveHerosID = remote.herosUtil:getHaveHeroKey()

	-- 初始化右边的tabs
	if options ~= nil and options.tab ~= nil then
		self:_selectTab(options.tab)
	else 
		self:_selectTab(QUIDialogHeroOverview.TAB_ALL)
	end
	self._isFrist = false
	self._isMove = false

	self._scrollPosYMin = 171.0
	self._scrollPosYMax = -226.0
	self._ccbOwner.sprite_scroll_bar:setOpacity(0)
	self._ccbOwner.sprite_scroll_cell:setOpacity(0)
end

function QUIDialogHeroOverview:viewDidAppear()
	QUIDialogHeroOverview.super.viewDidAppear(self)
    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(QRemote.HERO_UPDATE_EVENT, handler(self, self.onEvent))
    self._remoteProxy:addEventListener(QRemote.TEAMS_UPDATE_EVENT, handler(self, self.onEvent))
    self._remoteProxy:addEventListener(QRemote.ITEMS_UPDATE_EVENT, handler(self, self.onEvent))

    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroFrame.EVENT_HERO_FRAMES_CLICK, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroOverview.EVENT_HERO_SHEET_MOVE, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroOverview.EVENT_DISABLE_SCROLL_BAR, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogHeroOverview.TUTORIAL_HERO_UP_GRADE, self._checkTutorial,self)
	self:addBackEvent()
end

function QUIDialogHeroOverview:viewWillDisappear()
	QUIDialogHeroOverview.super.viewWillDisappear(self)
    self._remoteProxy:removeAllEventListeners()

    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroFrame.EVENT_HERO_FRAMES_CLICK, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroOverview.EVENT_HERO_SHEET_MOVE, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroOverview.EVENT_DISABLE_SCROLL_BAR, self.onEvent,self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogHeroOverview.TUTORIAL_HERO_UP_GRADE, self._checkTutorial,self)
	self:removeBackEvent()
end

-- 更新英雄数据
function QUIDialogHeroOverview:_onHeroDataUpdate()
	self._nativeActorIds = remote.herosUtil:getHerosKey()
	self._actorIds = self._nativeActorIds
	self:_filterHerosByTalent()
	self._haveHerosID = {}
	for _,actorId in pairs(self._actorIds) do
		local heroInfo = remote.herosUtil:getHeroByID(actorId)
		if heroInfo ~= nil then
			table.insert(self._haveHerosID, actorId)
		end
	end
end

function QUIDialogHeroOverview:_checkTutorial(hero)
  self.upGradeHeroInfo = hero.upGradeHeroInfo
   
  if app.tutorial:isTutorialFinished() == false then
    if app.tutorial:getStage().intencifyGuide == QTutorialDirector.Guide_Start then
        app.tutorial:startTutorial(QTutorialDirector.Stage_6_Intensify)
    end
  end
end

function QUIDialogHeroOverview:runTo(actorId)
	if self._page ~= nil then
		return self._page:runTo(actorId)
	end
	return false
end

-- 处理各种touch event
function QUIDialogHeroOverview:onTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
    	self._page:endMove(event.distance.y)
  	elseif event.name == "began" then
		self._isMove = false
	    if self._page:getIsMove() == true then
            self._isMove = true
	    	self._page:stopMove()
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
    end
end

-- 处理各种touch event
function QUIDialogHeroOverview:onEvent(event)
	if event == nil or event.name == nil then
        return
    end

    if event.name == QRemote.HERO_UPDATE_EVENT or event.name == QRemote.ITEMS_UPDATE_EVENT or event.name == QRemote.TEAMS_UPDATE_EVENT then
		self:_updateCurrentPage()
	elseif event.name == QUIWidgetHeroFrame.EVENT_HERO_FRAMES_CLICK then
  		app.sound:playSound("common_others")
		if self._isMove == false then
			local pos = 0
			for i, actorId in ipairs(self._haveHerosID) do
				if actorId == event.actorId then
					pos = i
					break
				end
			end
			app:getNavigationController():setDialogOptions({pageIndex = self.displayFramePageIndex})
			if pos > 0 and remote.herosUtil:getHeroByID(event.actorId) ~= nil then
				local hero_info_dialog = app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogHeroInformation",
				 options = {hero = self._haveHerosID, pos = pos}})
				return hero_info_dialog
			else
				local characher = QStaticDatabase:sharedDatabase():getCharacterByID(event.actorId)
				local grade_info = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(event.actorId, characher.grade or 0)
				local soulGemId = grade_info.soul_gem
				local currentGemCount = remote.items:getItemsNumByID(soulGemId)
				local needGemCount = grade_info.soul_gem_count or 0

				-- can summon the hero
				if currentGemCount >= needGemCount then
					local displayInfo = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(event.actorId)
					app:alert({content = "要召唤\"" .. displayInfo.name .. "\"需要花费" .. tostring(characher.summon_money or 0) .. "金币，是否确认召唤?",title = "召唤英雄", comfirmBack = function()
						app:getClient():summonHero(event.actorId,function()
								local callfunc = function ()
									app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogShowHeroAvatar", 
										options= {actorId = event.actorId}}, {isPopCurrentDialog = false})
								end
							    app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAchieveCard", 
							        options={actorId = event.actorId, callBack = callfunc}}, {isPopCurrentDialog = false})
							end)
					end, callBack = function ()
			end},false)
				else
					local itemId = tostring(soulGemId)
					local item_dialog = app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogItemDropInfo", options = {itemId=itemId}})
					return item_dialog
				end
			end
		end
	elseif event.name == QUIWidgetHeroOverview.EVENT_HERO_SHEET_MOVE then
		if self._ccbOwner.sprite_scroll_bar:getOpacity() < 255 then
			self._ccbOwner.sprite_scroll_cell:stopAllActions()
			self._ccbOwner.sprite_scroll_bar:stopAllActions()
			self._ccbOwner.sprite_scroll_cell:setOpacity(255)
			self._ccbOwner.sprite_scroll_bar:setOpacity(255)
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
		self._ccbOwner.sprite_scroll_bar:runAction(CCFadeOut:create(0.3))
    end
end

--切换table后调用
function QUIDialogHeroOverview:_updateCurrentPage()
	self:_onHeroDataUpdate()

	if self._page == nil then
		self._page = QUIWidgetHeroOverview.new({rows = 2, lines = 3, hgap = 0, vgap = 0, offsetX = 0, offsetY = 0})
		self._pageContent:addChild(self._page:getView())
	end
	self._page:displayHeros(self._actorIds)
	self._page:onMove()
end

-- 初始化中间的英雄选择框 swipe工能
function QUIDialogHeroOverview:_initHeroPageSwipe()
	self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
	self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
	self._pageContent = CCNode:create()

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._pageWidth,self._pageHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
	layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
	ccclippingNode:setStencil(layerColor)
	ccclippingNode:addChild(self._pageContent)

	self._ccbOwner.sheet:addChild(ccclippingNode)
	
	self._touchLayer = QUIGestureRecognizer.new()
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:attachToNode(self._ccbOwner.sheet,self._pageWidth, self._pageHeight, 0, -self._pageHeight, handler(self, self.onTouchEvent))

	self._isAnimRunning = false
end

-- filter 英雄根据英雄的天赋
function QUIDialogHeroOverview:_filterHerosByTalent()
	if self.tab == QUIDialogHeroOverview.TAB_ALL then
		-- 显示全部英雄不做任何filter
		return 
	end

	if self._actorIds ~= nil then
		local result = {}

		for i, actorId in pairs(self._actorIds) do
			local characher = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
			local talent = QStaticDatabase:sharedDatabase():getTalentByID(characher.talent)

			if self.tab == QUIDialogHeroOverview.TAB_TANK then
				if talent.func == 't' then
					result[#result + 1] = actorId
				end
			elseif self.tab == QUIDialogHeroOverview.TAB_TREAMENT then
				if talent.func == 'health' then
					result[#result + 1] = actorId
				end
			elseif self.tab == QUIDialogHeroOverview.TAB_CONTENTATTACH then
				if talent.func == 'dps' and talent.attack_type == 1 then
					result[#result + 1] = actorId
				end
			elseif self.tab == QUIDialogHeroOverview.TAB_MAGICATTACH then
				if talent.func == 'dps' and talent.attack_type == 2 then
					result[#result + 1] = actorId
				end
			end
		end
		self._actorIds = result
		return 
	end
	return 
end
 
-- 选择tab
function QUIDialogHeroOverview:_selectTab(tab, isSound)
	if isSound == true then
		app.sound:playSound("common_switch")
	end
	self._ccbOwner.node_hero_tab_all:setHighlighted(false)
	self._ccbOwner.node_hero_tab_tank:setHighlighted(false)
	self._ccbOwner.node_hero_tab_treatment:setHighlighted(false)
	self._ccbOwner.node_hero_tab_contentattack:setHighlighted(false)
	self._ccbOwner.node_hero_tab_magicattack:setHighlighted(false)

	self._ccbOwner.node_hero_tab_all:setEnabled(true)
	self._ccbOwner.node_hero_tab_tank:setEnabled(true)
	self._ccbOwner.node_hero_tab_treatment:setEnabled(true)
	self._ccbOwner.node_hero_tab_contentattack:setEnabled(true)
	self._ccbOwner.node_hero_tab_magicattack:setEnabled(true)

	self.tab = tab
	if tab == QUIDialogHeroOverview.TAB_ALL then
		self._ccbOwner.node_hero_tab_all:setHighlighted(true)
		self._ccbOwner.node_hero_tab_all:setEnabled(false)
	elseif tab == QUIDialogHeroOverview.TAB_TANK then
		self._ccbOwner.node_hero_tab_tank:setHighlighted(true)
		self._ccbOwner.node_hero_tab_tank:setEnabled(false)
	elseif tab == QUIDialogHeroOverview.TAB_TREAMENT then
		self._ccbOwner.node_hero_tab_treatment:setHighlighted(true)
		self._ccbOwner.node_hero_tab_treatment:setEnabled(false)
	elseif tab == QUIDialogHeroOverview.TAB_CONTENTATTACH  then
		self._ccbOwner.node_hero_tab_contentattack:setHighlighted(true)
		self._ccbOwner.node_hero_tab_contentattack:setEnabled(false)
	elseif tab == QUIDialogHeroOverview.TAB_MAGICATTACH  then
		self._ccbOwner.node_hero_tab_magicattack:setHighlighted(true)
		self._ccbOwner.node_hero_tab_magicattack:setEnabled(false)
	end

	self._isFrist = true
	self:_updateCurrentPage()
	self._isFrist = false
end

-- Tab 全部
function QUIDialogHeroOverview:_onTriggerTabAll(tag, menuItem)
	if self.tab ~= QUIDialogHeroOverview.TAB_ALL then
		self:_selectTab(QUIDialogHeroOverview.TAB_ALL, true)
	end
end

-- 选择tab 坦克
function QUIDialogHeroOverview:_onTriggerTabTank(tag, menuItem)
	if self.tab ~= QUIDialogHeroOverview.TAB_TANK then
		self:_selectTab(QUIDialogHeroOverview.TAB_TANK, true)
	end
end

-- 选择tab治疗
function QUIDialogHeroOverview:_onTriggerTabTreatment(tag, menuItem)
	if self.tab ~= QUIDialogHeroOverview.TAB_TREAMENT then
		self:_selectTab(QUIDialogHeroOverview.TAB_TREAMENT, true)
	end
end

-- 选择tab物攻
function QUIDialogHeroOverview:_onTriggerTabContentAttack(tag, menuItem)
	if self.tab ~= QUIDialogHeroOverview.TAB_CONTENTATTACH then
		self:_selectTab(QUIDialogHeroOverview.TAB_CONTENTATTACH, true)
	end
end

-- 选择tab魔攻
function QUIDialogHeroOverview:_onTriggerMagicAttack(tag, menuItem)
	if self.tab ~= QUIDialogHeroOverview.TAB_MAGICATTACH then
		self:_selectTab(QUIDialogHeroOverview.TAB_MAGICATTACH, true)
	end
end

function QUIDialogHeroOverview:onTriggerBackHandler(tag)
	self:_onTriggerBack()
end

function QUIDialogHeroOverview:onTriggerHomeHandler(tag)
	self:_onTriggerHome()
end

-- 对话框退出
function QUIDialogHeroOverview:_onTriggerBack(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- 对话框退出
function QUIDialogHeroOverview:_onTriggerHome(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

function QUIDialogHeroOverview:_resetPageIndex()
	self._pageJump:pageAt(self.displayTotalDisplayFramePageCount, self.displayFramePageIndex)
end

return QUIDialogHeroOverview
