--
-- Author: Qinyuanji
-- Date: 2015-01-15 
-- This class is the dialog for Rank system

local QUIDialog = import(".QUIDialog")
local QUIDialogRank = class("QUIDialogRank", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetMyRank = import("..widgets.QUIWidgetMyRank")
local QUIWidgetTopRank = import("..widgets.QUIWidgetTopRank")

local QArenaRank = import("...rank.QArenaRank")
local QAllFightCapacityRank = import("...rank.QAllFightCapacityRank")
local QTeamFightCapacityRank = import("...rank.QTeamFightCapacityRank")
local QHeroStarRank = import("...rank.QHeroStarRank")
local QAllStarRank = import("...rank.QAllStarRank")
local QNormalStarRank = import("...rank.QNormalStarRank")
local QEliteStarRank = import("...rank.QEliteStarRank")
local QAchievementPointRank = import("...rank.QAchievementPointRank")

QUIDialogRank.MOVEMENT_MINIMUM_PIXEL = 10
QUIDialogRank.RECORD_GAP = 10
QUIDialogRank.REFRESH_HOUR = 9
QUIDialogRank.BUTTON_GAP = 3
QUIDialogRank.BUTTON_HEIGHT = 48
QUIDialogRank.RECORD_HEIGHT = 90
QUIDialogRank.ACTION_DURATION = 0.2

lastRefreshHour = tonumber(os.date("%H"))

--[[
options:
	initRank: 1: 排行榜 2：战斗力 3：副本 4：成就
	callbacks: callback for each rank when loading rank is finished, callback will be invoked
		callbacks.common: common callback that every rank loaded will be invoked
		callbacks.dailyArenaRankCallBack
		callbacks.allFightCapacityCallBack
		callbacks.teamFightCapacityCallBack
		callbacks.heroStarCallBack
		callbacks.allStarCallBack
		callbacks.normalStarCallBack
		callbacks.eliteStarCallBack
		callbacks.achievementPointCallBack
--]]

function QUIDialogRank:ctor(options)
	local ccbFile = "ccb/Dialog_ArenaRank.ccbi";
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogRank._onTriggerClose)},
		{ccbCallbackName = "onTriggerArena", callback = handler(self, QUIDialogRank.onTriggerArena)},
		{ccbCallbackName = "onTriggerFightCapacityRank", callback = handler(self, QUIDialogRank.onTriggerFightCapacityRank)},
		{ccbCallbackName = "onTriggerDungeonRank", callback = handler(self, QUIDialogRank.onTriggerDungeonRank)},
		{ccbCallbackName = "onTriggerAchievementRank", callback = handler(self, QUIDialogRank.onTriggerAchievementRank)},

		{ccbCallbackName = "onDailyArenaRank", callback = handler(self, QUIDialogRank.onDailyArenaRank)},
		{ccbCallbackName = "onAllFightCapacity", callback = handler(self, QUIDialogRank.onAllFightCapacity)},
		{ccbCallbackName = "onTeamFightCapacity", callback = handler(self, QUIDialogRank.onTeamFightCapacity)},
		{ccbCallbackName = "onHeroStar", callback = handler(self, QUIDialogRank.onHeroStar)},
		{ccbCallbackName = "onAllStar", callback = handler(self, QUIDialogRank.onAllStar)},
		{ccbCallbackName = "onNormalStar", callback = handler(self, QUIDialogRank.onNormalStar)},
		{ccbCallbackName = "onEliteStar", callback = handler(self, QUIDialogRank.onEliteStar)},
		{ccbCallbackName = "onAchievementPoint", callback = handler(self, QUIDialogRank.onAchievementPoint)},		
	}
	QUIDialogRank.super.ctor(self,ccbFile,callBacks,options)
	self.isAnimation = true

	self._myRankBar = QUIWidgetMyRank.new()
	self._ccbOwner.myRankBar:addChild(self._myRankBar)
	self._ccbOwner.myRankBar:setVisible(false)
	self._ccbOwner.TBC:setVisible(false)

	self:_initMatrix()
	self._currentRank = self.rankMatrix.DailyArena
	self.initRank = 1 -- by default, showing the first rank
	-- callbacks
	if options then
		if options.callbacks then
			self.commonCallback = options.callbacks.common
			self.rankMatrix.DailyArena.callback = options.callbacks.dailyArenaRankCallBack 
			self.rankMatrix.AllFightCapacity.callback = options.callbacks.allFightCapacityCallBack 
			self.rankMatrix.TeamFightCapacity.callback = options.callbacks.teamFightCapacityCallBack 
			self.rankMatrix.HeroStar.callback = options.callbacks.heroStarCallBack 
			self.rankMatrix.AllStar.callback = options.callbacks.allStarCallBack 
			self.rankMatrix.NormalStar.callback = options.callbacks.normalStarCallBack 
			self.rankMatrix.EliteStar.callback = options.callbacks.eliteStarCallBack  
			self.rankMatrix.AchievePoint.callback = options.callbacks.achievementPointCallBack 
		end
		self.initRank = options.initRank or 1 
	end

	self:_initNavigationSlide()
	self:_initNavigationBar()
end

-- Initialize the tree structure of rank navigation bar
function QUIDialogRank:_initNavigationBar()
	self._treeNode = {}
	self:insertChildNode(nil, self._ccbOwner.arenaRank, self.onDailyArenaRank, self.initRank == 1)
	self:insertChildNode(self._ccbOwner.arenaRank, self._ccbOwner.dailyArenaRank)

	self:insertChildNode(nil, self._ccbOwner.fightCapacityRank, self.onAllFightCapacity, self.initRank == 2)
	self:insertChildNode(self._ccbOwner.fightCapacityRank, self._ccbOwner.allFightCapacity)
	self:insertChildNode(self._ccbOwner.fightCapacityRank, self._ccbOwner.teamFightCapacity)
	self:insertChildNode(self._ccbOwner.fightCapacityRank, self._ccbOwner.heroStar)

	self:insertChildNode(nil, self._ccbOwner.dungeonRank, self.onAllStar, self.initRank == 3)
	self:insertChildNode(self._ccbOwner.dungeonRank, self._ccbOwner.allStar)
	self:insertChildNode(self._ccbOwner.dungeonRank, self._ccbOwner.normalStar)
	self:insertChildNode(self._ccbOwner.dungeonRank, self._ccbOwner.eliteStar)

	self:insertChildNode(nil, self._ccbOwner.achievementRank, self.onAchievementPoint, self.initRank == 4)
	self:insertChildNode(self._ccbOwner.achievementRank, self._ccbOwner.achievementPoint)

	self:UpdateTreeNode(true)
end

-- The matrix for different rank 
function QUIDialogRank:_initMatrix()
	self.rankMatrix = {
		DailyArena = {ccb = "dailyArenaRank", showMyInfo = false, disableDetail = false, description = "", switch = 1, 
							numberName = "", horiLine = false, root = "arenaRank"},
		AllFightCapacity = {ccb = "allFightCapacity", showMyInfo = true, disableDetail = true, description = "所有英雄总战力:", switch = 2, 
							numberName = "force", horiLine = true, root = "fightCapacityRank"},
		TeamFightCapacity = {ccb = "teamFightCapacity", showMyInfo = true, disableDetail = true, description = "最高五人总战力:", switch = 2, 
							numberName = "teamForce", horiLine = true, root = "fightCapacityRank"},
		HeroStar = {ccb = "heroStar", showMyInfo = true, disableDetail = true, description = "英雄总星级:", switch = 2, showStar = true, 
							numberName = "heroStar", horiLine = true, root = "fightCapacityRank"},
		AllStar = {ccb = "allStar", showMyInfo = true, disableDetail = true, description = "副本总星级:", switch = 2, showStar = true, 
							numberName = "totalStar", horiLine = true, root = "dungeonRank"},
		NormalStar = {ccb = "normalStar", showMyInfo = true, disableDetail = true, description = "普通副本总星级:", switch = 2, showStar = true, 
							numberName = "normalStar", horiLine = true, root = "dungeonRank"},
		EliteStar = {ccb = "eliteStar", showMyInfo = true, disableDetail = true, description = "精英副本总星级:", switch = 2, showStar = true, 
							numberName = "eliteStar", horiLine = true, root = "dungeonRank"},
		AchievePoint = {ccb = "achievementPoint", showMyInfo = true, disableDetail = true, description = "成就点数:", switch = 2, 
							numberName = "achievePoint", horiLine = true, root = "achievementRank"},
	}
end

-- Build a tree structure
-- If parent is nil, node is root or it's a child node
function QUIDialogRank:insertChildNode(parent, child, defaultNode, expand)
	if parent == nil then
		table.insert(self._treeNode, {expand = expand or false, node = child, defaultNode = defaultNode})
		child._childNode = {}
	else
		for _, v in ipairs(self._treeNode) do 
			if v.node == parent then
				table.insert(v.node._childNode, child)
			end
		end
	end
end

-- Init page size and touch layer area when size is changed
-- Different rank list has different touch area
function QUIDialogRank:_initRankPageSlide(small)
	self._ccbOwner.myRankBar:setVisible(false)
	self._ccbOwner.horiLine:setVisible(false)

	-- Do not re-initialize when size is not changed
	if (small and self._content == self._ccbOwner.sheet_content_small) or (small == nil and self._content == self._ccbOwner.sheet_content) then
		return
	end

	if self._touchLayer ~= nil then
		self._touchLayer:removeEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE)
		self._touchLayer:detach()
		self._touchLayer = nil 
	end
	if self._pageContent ~= nil then
		self._pageContent:removeAllChildren()
		self._pageContent = nil 
	end
	if self._touchSheet ~= nil then
		self._touchSheet:removeChild(self._ccclippingNode)
	end

	self._content = small and self._ccbOwner.sheet_content_small or self._ccbOwner.sheet_content
	self._touchSheet = small and self._ccbOwner.mainSheet_small or self._ccbOwner.mainSheet

	self._pageWidth = self._content:getContentSize().width or self._content:getContentSize().width
	self._pageHeight = self._content:getContentSize().height or self._content:getContentSize().height
	self._pageContent = CCNode:create()
	self._pageContent:setPosition(self._pageWidth/2,0)
	self._originalPosX = self._pageContent:getPositionX()
	self._originalPosY = self._pageContent:getPositionY()

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150), self._pageWidth, self._pageHeight)
	self._ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._content:getPositionX())
	layerColor:setPositionY(self._content:getPositionY())
	self._ccclippingNode:setStencil(layerColor)
	self._ccclippingNode:addChild(self._pageContent)

	self._touchSheet:addChild(self._ccclippingNode)

	self._touchLayer = QUIGestureRecognizer.new()
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:attachToNode(self._touchSheet, self._pageWidth, self._pageHeight, 0, -self._pageHeight, handler(self, self.onTouchEvent))
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogRank:_initNavigationSlide()
	self._navPageWidth = self._ccbOwner.nav_menu:getContentSize().width
	self._navPageHeight = self._ccbOwner.nav_menu:getContentSize().height
	self._navOriginalPosX = self._ccbOwner.navRoot:getPositionX()
	self._navOriginalPosY = self._ccbOwner.navRoot:getPositionY()

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150), self._navPageWidth, self._navPageHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.nav_menu:getPositionX())
	layerColor:setPositionY(self._ccbOwner.nav_menu:getPositionY())
	ccclippingNode:setStencil(layerColor)
	self._ccbOwner.navRoot:removeFromParent()
	ccclippingNode:addChild(self._ccbOwner.navRoot)

	self._ccbOwner.navSheet:addChild(ccclippingNode)

	self._navTouchLayer = QUIGestureRecognizer.new()
	self._navTouchLayer:setAttachSlide(true)
	self._navTouchLayer:setSlideRate(0.3)
	self._navTouchLayer:attachToNode(self._ccbOwner.navSheet, self._navPageWidth, self._navPageHeight, 0, -self._navPageHeight, handler(self, self.onNavTouchEvent))
end

function QUIDialogRank:viewDidAppear()
	QUIDialogRank.super.viewDidAppear(self)
    
    self._navTouchLayer:enable()
    self._navTouchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onNavTouchEvent))
end

function QUIDialogRank:viewWillDisappear()
	self._touchLayer:removeEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE)
	self._navTouchLayer:removeEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE)
	QUIDialogRank.super.viewWillDisappear(self)
end 

function QUIDialogRank:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- Update rank list on demand --------------------------------------------------------------------------------------------------------
-- check if rank needs update and fill the dialog with each record
-- finishedCallBack is the callback when loading is finished
function QUIDialogRank:updateRankList(finishedCallBack)

	local function preUpdateRankRange(finishedCallBack)
		self._totalHeight = #self._currentRank.rank:getList()*(QUIDialogRank.RECORD_HEIGHT + QUIDialogRank.RECORD_GAP)
		self:updateRankRange()
		if finishedCallBack ~= nil then
			finishedCallBack()
		end
		if self.commonCallback ~= nil then
			self.commonCallback()
		end
	end

	self._index = 1
	self._totalHeight = QUIDialogRank.RECORD_GAP			
	self._pageContent:removeAllChildren()
	self._pageContent:setPosition(self._pageWidth/2,0)

	if self._currentRank.rank:needsUpdate() then
		self._currentRank.rank:update(function ()
			preUpdateRankRange(finishedCallBack)
		end, function ()
			self._ccbOwner.TBC:setVisible(true)
		end)
	else
		preUpdateRankRange(finishedCallBack)
	end
end

-- Because the rank record is too many to be loaded at a time
-- So I decide to switch to load on demand (lazy load)
-- When scroll down to that part, the record in that area will be displayed
-- The record out of bound will be removed to save the memory
function QUIDialogRank:updateRankRange()
	if self._currentRank.rank:getList() == nil then
		return
	end

	self._ccbOwner.TBC:setVisible(false)
	local upperBound = -(self._pageContent:getPositionY() - QUIDialogRank.RECORD_HEIGHT*2) -- From where record begins
	local bottomBound = -(self._pageContent:getPositionY() + self._pageHeight + QUIDialogRank.RECORD_HEIGHT*2) -- To where record ends
	local displayUpperBound = 0 -- From where existing record begins
	local displayBottomBound = 0 -- To where existing record ends

	-- Remove invisible record which is out of bound
    local children = self._pageContent:getChildren()
    local count = children and children:count() or 0
    local needRemove = {}
    if count > 0 then
    	displayUpperBound = tolua.cast(children:objectAtIndex(0), "CCNode"):getPositionY()
    	displayBottomBound = tolua.cast(children:objectAtIndex(count - 1), "CCNode"):getPositionY()
		for j = 0, count - 1 do
			local node = tolua.cast(children:objectAtIndex(j), "CCNode")
			if node:getPositionY() < bottomBound or 
				node:getPositionY() > upperBound then
				table.insert(needRemove, node)
			end
			-- Add child to node will not sort by posY, so we need to find out the minimum and maximum posY
			if node:getPositionY() > displayUpperBound then
				displayUpperBound = node:getPositionY()
			elseif node:getPositionY() < displayBottomBound then
				displayBottomBound = node:getPositionY()
			end
		end

		for _, v in ipairs(needRemove) do
			self._pageContent:removeChild(v)
		end
	end

	-- Create new record if it has not been created and within the bound
	for i = 1, #self._currentRank.rank:getList() do
		local currentWidgetPosY = -(i - 1) * (QUIDialogRank.RECORD_HEIGHT + QUIDialogRank.RECORD_GAP) - QUIDialogRank.RECORD_HEIGHT/2 - QUIDialogRank.RECORD_GAP
		
		if currentWidgetPosY < upperBound and currentWidgetPosY > bottomBound then
			if currentWidgetPosY > displayUpperBound or currentWidgetPosY < displayBottomBound then
			 	local widgetRank = QUIWidgetTopRank.new({parent = self, switch = self._currentRank.switch, disableDetail = self._currentRank.disableDetail,
			 		info = {response = self._currentRank.rank:getList()[i], description = self._currentRank.description, showStar = self._currentRank.showStar,
			 				number = self._currentRank.rank:getList()[i][self._currentRank.numberName]}}) 

				widgetRank:setPosition(0, currentWidgetPosY)
				self._pageContent:addChild(widgetRank)
			end
		end
	end
end

-- Update the navigation bar by the state of each node ------------------------------------------------------------------------------
-- noEffect: if node movement needs action
function QUIDialogRank:UpdateTreeNode(noEffect)
	local posY = 0
	local offset = 0
	for _, v in ipairs(self._treeNode) do
		if v.expand then
			offset = self:ExpandNode(v.node, posY, noEffect)
			v.defaultNode(self)
		else
			offset = self:FoldNode(v.node, posY, noEffect)
		end

		posY = posY - offset
	end
	self._navTotalHeight = self._ccbOwner.navSheet:getPositionY() - posY + QUIDialogRank.BUTTON_HEIGHT/2
end

-- Expand particular node
function QUIDialogRank:ExpandNode(node, posY, noEffect)
	if noEffect then
		node:setPositionY(posY)
	else
	    local moveTo = CCMoveTo:create(QUIDialogRank.ACTION_DURATION, ccp(node:getPositionX(), posY))
	    local array = CCArray:create()
	    array:addObject(moveTo)
	    node:runAction(CCSequence:create(array))
	end	
	node:setHighlighted(true)

	-- Show child node
    local offset = 0
    if node._childNode ~= nil then
		for i = 1, #node._childNode do
			local cPosY = posY - node:getContentSize().height/2 - QUIDialogRank.BUTTON_HEIGHT/2
			    	 - (i - 1) * (QUIDialogRank.BUTTON_HEIGHT + QUIDialogRank.BUTTON_GAP)
			if noEffect then
				node._childNode[i]:setPositionY(cPosY)
			else
			    local moveTo = CCMoveTo:create(QUIDialogRank.ACTION_DURATION, 
			    	ccp(node:getPositionX(), cPosY))
			    local array = CCArray:create()
			    array:addObject(CCCallFunc:create(
		            function()
		                node._childNode[i]:setVisible(true)
		            end))
			    array:addObject(moveTo)
			    node._childNode[i]:runAction(CCSequence:create(array))
			end
			node._childNode[i]:setHighlighted(false)
			node._childNode[i]:setEnabled(true)
	    end
		node._childNode[1]:setHighlighted(true)
		node._childNode[1]:setEnabled(false)
		offset = #node._childNode * (QUIDialogRank.BUTTON_HEIGHT + QUIDialogRank.BUTTON_GAP)
	end

    return offset + node:getContentSize().height
end

-- Fold particular node
function QUIDialogRank:FoldNode(node, posY, noEffect)
	if noEffect then
		node:setPositionY(posY)
	else
	    local moveTo = CCMoveTo:create(QUIDialogRank.ACTION_DURATION, ccp(node:getPositionX(), posY))
	    local array = CCArray:create()
	    array:addObject(moveTo)
	    node:runAction(CCSequence:create(array))
	end
	node:setHighlighted(false)

	-- Fold child node
    local offset = 0
    if node._childNode ~= nil then
		for i = 1, #node._childNode do
			if noEffect then
				node._childNode[i]:setPositionY(posY)
			else
			    local moveTo = CCMoveTo:create(QUIDialogRank.ACTION_DURATION, ccp(node:getPositionX(), posY))
			    local array = CCArray:create()
			    array:addObject(moveTo)
			    array:addObject(CCCallFunc:create(
		            function()
		                node._childNode[i]:setVisible(false)
		            end))
			    node._childNode[i]:runAction(CCSequence:create(array))
			end
			node._childNode[i]:setHighlighted(false)
	    end
	end

    return offset + node:getContentSize().height
end

-- Rank category button functions ---------------------------------------------------------------------------------
function QUIDialogRank:onTriggerArena(eventType)
	if self._isNavMoving == true or tonumber(eventType) ~= CCControlEventTouchUpInside then 		
		if self:isExpand(self._ccbOwner.arenaRank) then
			self._ccbOwner.arenaRank:setHighlighted(true)
		end
	else	
		self:updateExpandState(self._ccbOwner.arenaRank)
 	end
end

function QUIDialogRank:onTriggerFightCapacityRank(eventType)
	if self._isNavMoving == true or tonumber(eventType) ~= CCControlEventTouchUpInside then 		
		if self:isExpand(self._ccbOwner.fightCapacityRank) then
			self._ccbOwner.fightCapacityRank:setHighlighted(true)
		end
	else	
		self:updateExpandState(self._ccbOwner.fightCapacityRank)
	end
end

function QUIDialogRank:onTriggerDungeonRank(eventType)
	if self._isNavMoving == true or tonumber(eventType) ~= CCControlEventTouchUpInside then 		
		if self:isExpand(self._ccbOwner.dungeonRank) then
			self._ccbOwner.dungeonRank:setHighlighted(true)
		end
	else	
		self:updateExpandState(self._ccbOwner.dungeonRank)
	end
end

function QUIDialogRank:onTriggerAchievementRank(eventType)
	if self._isNavMoving == true or tonumber(eventType) ~= CCControlEventTouchUpInside then 		
		if self:isExpand(self._ccbOwner.achievementRank) then
			self._ccbOwner.achievementRank:setHighlighted(true)
		end
	else	
		self:updateExpandState(self._ccbOwner.achievementRank)
	end
end

function QUIDialogRank:updateExpandState( button )
	for i = 1, #self._treeNode do
		if self._treeNode[i].node == button then
			self._treeNode[i].expand = not self._treeNode[i].expand
		else
			self._treeNode[i].expand = false
		end
	end
	self:UpdateTreeNode()
end

function QUIDialogRank:isExpand( button )
	for i = 1, #self._treeNode do
		if self._treeNode[i].node == button then
			return self._treeNode[i].expand
		end
	end
end

-- Rank button functions ------------------------------------------------------------------------------------------
function QUIDialogRank:onDailyArenaRank( ... )
	if self._isNavMoving == true then return end 
	self:updateRankState("arenaRank", QArenaRank, self.rankMatrix.DailyArena)
end

function QUIDialogRank:onAllFightCapacity( ... )
	if self._isNavMoving == true then return end 
	self:updateRankState("allFightCapacityRank", QAllFightCapacityRank, self.rankMatrix.AllFightCapacity)
end

function QUIDialogRank:onTeamFightCapacity( ... )
	if self._isNavMoving == true then return end 
	self:updateRankState("teamFightCapacityRank", QTeamFightCapacityRank, self.rankMatrix.TeamFightCapacity)
end

function QUIDialogRank:onHeroStar( ... )
	if self._isNavMoving == true then return end 
	self:updateRankState("heroStarRank", QHeroStarRank, self.rankMatrix.HeroStar)
end

function QUIDialogRank:onAllStar( ... )
	if self._isNavMoving == true then return end 
	self:updateRankState("allStarRank", QAllStarRank, self.rankMatrix.AllStar)
end

function QUIDialogRank:onNormalStar( ... )
	if self._isNavMoving == true then return end 
	self:updateRankState("normalStarRank", QNormalStarRank, self.rankMatrix.NormalStar)
end

function QUIDialogRank:onEliteStar( ... )
	if self._isNavMoving == true then return end 
	self:updateRankState("eliteStarRank", QEliteStarRank, self.rankMatrix.EliteStar)
end

function QUIDialogRank:onAchievementPoint( ... )
	if self._isNavMoving == true then return end 
	self:updateRankState("achievementPointRank", QAchievementPointRank, self.rankMatrix.AchievePoint)
end

function QUIDialogRank:updateRankState(remoteRank, remoteRankClass, newRank)
	if remote[remoteRank] == nil then
		remote[remoteRank] = remoteRankClass.new()
	end
	if self._currentRank.rank == remote[remoteRank] then
		self._ccbOwner[self._currentRank.ccb]:setHighlighted(true)
		return
	end

	self._currentRank = newRank
	self:_initRankPageSlide(self._currentRank.showMyInfo)
	self._currentRank.rank = remote[remoteRank]
	self:updateRankList(function ()
		if self._currentRank.callback then self._currentRank.callback() end
		self._ccbOwner.horiLine:setVisible(self._currentRank.horiLine)
		self._ccbOwner.myRankBar:setVisible(self._currentRank.showMyInfo)
		self:updateMyRankInfo()
	end)
	self:updateChildNodeState(self._ccbOwner[self._currentRank.root], self._ccbOwner[self._currentRank.ccb])
end

function QUIDialogRank:updateChildNodeState(parent, child)
	for i = 1, #self._treeNode do
		if self._treeNode[i].node == parent then
			for j = 1, #parent._childNode do
				if parent._childNode[j] == child then
					child:setHighlighted(true)
					child:setEnabled(false)
				else
					parent._childNode[j]:setHighlighted(false)
					parent._childNode[j]:setEnabled(true)
				end
			end
			break
		end
	end
end

function QUIDialogRank:updateMyRankInfo()
	local myself = self._currentRank.rank:getMyInfo()
	if myself ~= nil then
		local myInfo = {avatar = myself.avatar, level = myself.level, name = myself.name, rank = myself.rank, lastRank = myself.lastRank, 
						description = self._currentRank.description, number = myself[self._currentRank.numberName], showStar = self._currentRank.showStar}
		self._myRankBar:setFlag(self._currentRank.switch)
		self._myRankBar:setInfo({myInfo = myInfo})
	end
end

-- Gesture reaction -------------------------------------------------------------------------------------------------
-- Respond to touch event
-- Moving more than 10 pixel is regarded as a movement, or it's regarded as a touch event
-- _isMoving variable is to distinguish when a touch event is a click or a movement.
function QUIDialogRank:onTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end

    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
    	if self._isMoving then
    		self:endMove()
    	end
  	elseif event.name == "began" then
  		self._isMoving = false
   		self._startY = event.y
   		self._pageY = self._pageContent:getPositionY()
    elseif event.name == "moved" then
    	local newPosY = self._pageY + event.y - self._startY
    	if math.abs(event.y - self._startY) > QUIDialogRank.MOVEMENT_MINIMUM_PIXEL then
			self._isMoving = true
        end
        -- Don't move the screen out of scope
        if newPosY < self._originalPosY or (newPosY - self._originalPosY) > (self._totalHeight - self._pageHeight) then
        	--return
        	self._isMoving = true
        end
		self._pageContent:setPositionY(newPosY)
		if newPosY <= (self._totalHeight - self._pageHeight) and newPosY >= 0 then
			self:updateRankRange()
		end
    elseif event.name == "ended" then
    end
end

-- Check if current screen is in the scope of page
function QUIDialogRank:endMove()
	local currentPosY = self._pageContent:getPositionY()
	local newPosY = currentPosY
	if currentPosY < self._originalPosY then
		newPosY = self._originalPosY
	elseif (currentPosY - self._originalPosY) > (self._totalHeight - self._pageHeight) then
		if self._totalHeight > self._pageHeight then
			newPosY = self._totalHeight - self._pageHeight + self._originalPosY
		else
			newPosY = self._originalPosY
		end
	end

	if newPosY ~= currentPosY then
		self:_contentRunAction(self._originalPosX, newPosY)
	end
end

-- Move to position smoothly
function QUIDialogRank:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
end

function QUIDialogRank:onNavTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end

    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
    	if self._isNavMoving then
    		--self:endMove()
    	end
  	elseif event.name == "began" then
  		self._isNavMoving = false
   		self._navStartY = event.y
   		self._navPageY = self._ccbOwner.navRoot:getPositionY()
    elseif event.name == "moved" then
    	local newPosY = self._navPageY + event.y - self._navStartY
    	if math.abs(event.y - self._navStartY) > QUIDialogRank.MOVEMENT_MINIMUM_PIXEL then
			self._isNavMoving = true
        end
        -- Don't move the screen out of scope
        if newPosY < self._navOriginalPosY or (newPosY - self._navOriginalPosY) > (self._navTotalHeight - self._navPageHeight) then
        	return
        	--self._isNavMoving = true
        end
		self._ccbOwner.navRoot:setPositionY(newPosY)
    elseif event.name == "ended" then
    end
end

-- Dialog quit functions -------------------------------------------------------------------------------------------
function QUIDialogRank:_onTriggerCancel()
	self:_close()
end

function QUIDialogRank:_backClickHandler()
    self:_close()
end

function QUIDialogRank:_onTriggerClose()
	app.sound:playSound("common_cancel")
    self:_close()
end

function QUIDialogRank:_close()
    self:playEffectOut()
end

return QUIDialogRank
