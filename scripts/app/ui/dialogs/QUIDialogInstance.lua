--
-- Author: wkwang
-- Date: 2014-05-05 14:22:52
--
local QUIDialog = import(".QUIDialog")
local QUIDialogInstance = class(".QUIDialogInstance", QUIDialog)
local QUIWidgetAchievement = import("..widgets.QUIWidgetAchievement")
local QUIWidgetInstance = import("..widgets.QUIWidgetInstance")
local QUIViewController = import("..QUIViewController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetInstanceHead = import("..widgets.QUIWidgetInstanceHead")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QTutorialDirector = import("...tutorial.QTutorialDirector")

function QUIDialogInstance:ctor(options)
	local ccbFile = "ccb/Dialog_BigEliteChoose.ccbi"
	local callBacks = {
						-- {ccbCallbackName = "onTriggerBack", callback = handler(self, QUIDialogInstance._onTriggerBack)},
						-- {ccbCallbackName = "onTriggerHome", callback = handler(self, QUIDialogInstance._onTriggerHome)},
						{ccbCallbackName = "onTriggerLeft", callback = handler(self, QUIDialogInstance._onTriggerLeft)},
						{ccbCallbackName = "onTriggerRight", callback = handler(self, QUIDialogInstance._onTriggerRight)},
						{ccbCallbackName = "onTriggerNormal", callback = handler(self, QUIDialogInstance._onTriggerNormal)},
						{ccbCallbackName = "onTriggerElite", callback = handler(self, QUIDialogInstance._onTriggerElite)},
					}
	QUIDialogInstance.super.ctor(self,ccbFile,callBacks,options)

	app:getNavigationController():getTopPage():setManyUIVisible()
	if options == nil then
		options = {}
		self:setOptions(options)
	end
	if options.instanceType == nil then
		options.instanceType = DUNGEON_TYPE.NORMAL
	end

	self._chest = QUIWidgetAchievement.new()
	self._ccbOwner.node_chest:addChild(self._chest)

	self:madeTouchLayer()

	self:selectType(options.instanceType)

	self:_checkEliteIsOpen()
end

function QUIDialogInstance:viewDidAppear()
    QUIDialogInstance.super.viewDidAppear(self)

    self._touchLayer:enable()
    self._touchLayer:setAttachSlide(true)
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SWIPE_GESTURE, handler(self, self._onEvent))
  	self:addBackEvent()
end

function QUIDialogInstance:viewWillDisappear()
	self:_removeAllAction()
    QUIDialogInstance.super.viewWillDisappear(self)
    self:_removePage(self._currentPage)
    self:_removePage(self._nextPage)
	self:removeBackEvent()

    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
end

function QUIDialogInstance:madeTouchLayer()
	self._size = self._ccbOwner.node_mask:getContentSize()
	self._mapContent = CCNode:create()
	local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._size.width,self._size.height)
	local ccclippingNode = CCClippingNode:create()
	ccclippingNode:setStencil(layerColor)
	ccclippingNode:addChild(self._mapContent)
	self._mapContent:setPositionX(self._size.width/2)
	self._mapContent:setPositionY(self._size.height/2)
	self._ccbOwner.map_content:addChild(ccclippingNode)

	self._touchLayer = QUIGestureRecognizer.new()
    self._touchLayer:attachToNode(self._ccbOwner.map_touchLayer,self._size.width,self._size.height,-self._size.width/2,-self._size.height/2)
end

--根据副本类型显示副本内容
function QUIDialogInstance:selectType(instanceType)
	self:hideArrow()
	self:_removeAllMapInfo()
	self:_removeAllAction()
	self._instanceType = instanceType
	local options = self:getOptions()
	options.instanceType = instanceType
	self._actionHandler = {}
  	self:_removePage(self._currentPage)
	self._currentPage = nil
	self._nextPage = nil
	if self._instanceType == DUNGEON_TYPE.NORMAL then
		self._ccbOwner.btn_normal:setTouchEnabled(false)
		self._ccbOwner.btn_normal:setHighlighted(true)
		self._ccbOwner.btn_elite:setTouchEnabled(true)
		self._ccbOwner.btn_elite:setHighlighted(false)
	else
		self._ccbOwner.btn_normal:setTouchEnabled(true)
		self._ccbOwner.btn_normal:setHighlighted(false)
		self._ccbOwner.btn_elite:setHighlighted(true)
		self._ccbOwner.btn_elite:setTouchEnabled(false)
	end

	self._needPassID = remote.instance:countNeedPassForType(self._instanceType)
	self._instanceData = remote.instance:getInstancesWithUnlockAndType(self._instanceType)
	self._totalIndex = #self._instanceData

	if options.currentIndex == nil or remote.instance:getIsNew() == true then
		remote.instance:setIsNew(false)
		local lastIndex 
		local index = 1
		for _,instance in pairs(self._instanceData) do
			for _,dungeon in pairs(instance.data) do
				if dungeon.dungeon_id == self._needPassID then
					lastIndex = index
					break
				end
			end
			if lastIndex ~= nil then
				break
			end
			index = index + 1
		end
		if lastIndex ~= nil then
			options.currentIndex = lastIndex
		elseif options.currentIndex == nil then
			options.currentIndex = self._totalIndex
		end
	end

	self._currentIndex = options.currentIndex
	self._nextIndex = options.currentIndex
	self:showInstanceForData()
end

function QUIDialogInstance:showInstanceForData()
	if self._totalIndex < self._nextIndex or self._nextIndex == 0 then
		return 
	end
	self:removePageAction()
	self:hideArrow()
	self._nextPage = self:madePageForIndex(self._nextIndex)
	if self._currentIndex == self._nextIndex then
		self._currentPage = self._nextPage
		self._nextPage = nil
        self._currentPage:addEventListener(QUIWidgetInstanceHead.EVENT_CITY_CLICK, handler(self,self._headClickHandler))
		self._ccbOwner.map_content:addChild(self._currentPage)
		self:hideMapInfo()
        self:checkButtonShow()
	else
		if self._currentIndex < self._nextIndex then
			self._nextPage:setPositionX(self._size.width/2)
		else
			self._nextPage:setPositionX(-self._size.width/2)
		end
		self._ccbOwner.map_content:addChild(self._nextPage)
		self:_movePage()
	end
end

--显示箭头
function QUIDialogInstance:showArrow(node)
	if node ~= nil then
		self._ccbOwner.node_arrow:setVisible(true)
		local size = node:getBg():getContentSize()

		local p = node:convertToWorldSpaceAR(ccp(0,0))
		p = self._ccbOwner.node_arrow:getParent():convertToNodeSpaceAR(p)
		p.y = p.y + size.height/2
		self._ccbOwner.node_arrow:setPosition(p)
	end
end
--隐藏箭头
function QUIDialogInstance:hideArrow()
	self._ccbOwner.node_arrow:setVisible(false)
end

--根据index生成当前的page
function QUIDialogInstance:madePageForIndex()
	return QUIWidgetInstance.new(self._instanceData[self._nextIndex])
end

--显示当前副本的信息
function QUIDialogInstance:showMapInfo()
	local info = self._instanceData[self._nextIndex]
	if info == nil then return end
	self._ccbOwner.tf_title:setString(info.data[1].instance_name)
	local totalStar,currentStar = 0, 0
	for _,value in pairs(info.data) do
		totalStar = totalStar + 3
		currentStar = currentStar + (value.info and (value.info.star or 0) or 0)
	end
	self._ccbOwner.tf_star:setString(currentStar.."/"..totalStar)
	self._chest:setVisible(true)
	self._chest:starDrop(info.data[1].instance_id,currentStar,totalStar)
end

function QUIDialogInstance:_movePage()
	self:hideMapInfo()
	local offsetX = -self._nextPage:getPositionX()
	self._nextActionHandler = self:_nodeRunAction(self._nextPage,offsetX,0)
	self._currActionHandler = self:_nodeRunAction(self._currentPage,offsetX,0,function ()
		if self._nextActionHandler ~= nil then
			self._nextActionHandler = nil
		end
		if self._currActionHandler ~= nil then
			self._currActionHandler = nil
		end
        self:_removePage(self._currentPage)
        self._currentPage = self._nextPage
        self._nextPage = nil
        self._currentPage:addEventListener(QUIWidgetInstanceHead.EVENT_CITY_CLICK, handler(self,self._headClickHandler))
        self._currentIndex = self._nextIndex
        local options = self:getOptions()
        options.currentIndex = self._currentIndex
        self:checkButtonShow()
	end)
end

function QUIDialogInstance:removePageAction()
	if self._currActionHandler ~= nil then
		self._currentPage:stopAction(self._currActionHandler)
		self._currActionHandler = nil
		self._currentPage:removeFromParent()
	end
	if self._nextActionHandler ~= nil then
		self._nextPage:stopAction(self._nextActionHandler)
		self._nextActionHandler = nil
		self._currentPage = self._nextPage
	end
end

function QUIDialogInstance:checkButtonShow()
	self._ccbOwner.btn_right:setVisible(true)
	self._ccbOwner.btn_left:setVisible(true)
	if self._currentIndex == 1 then
		self._ccbOwner.btn_left:setVisible(false)
	end
	if self._currentIndex == self._totalIndex then
		self._ccbOwner.btn_right:setVisible(false)
	end
	if self._needPassID ~= nil then
		self:showArrow(self._currentPage:setLastDungeon(self._needPassID))
	end
end

--隐藏界面信息
function QUIDialogInstance:hideMapInfo()
	self:_nodeRunHideAction(self._ccbOwner.tf_title,"title")
	self:_nodeRunHideAction(self._ccbOwner.tf_star,"star")
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCDelayTime:create(0.3))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    											self._actionHandler["info"] = nil
    											self:showMapInfo()
                                            end))
    self._actionHandler["info"] = self:getView():runAction(CCSequence:create(actionArrayIn))
end

function QUIDialogInstance:_checkEliteIsOpen()
	-- if #remote.instance.eliteInfo == 0 or remote.instance.eliteInfo[1].isLock == false then
	if #remote.instance.eliteInfo == 0 or remote.instance.eliteInfo[1].unlock_team_level > remote.user.level then
		-- makeNodeFromNormalToGray(self._ccbOwner.btn_elite)
		-- self._ccbOwner.btn_elite:setTouchEnabled(false)
		self._ccbOwner.btn_elite:setVisible(false)
	end
end

function QUIDialogInstance:_nodeRunHideAction(node,name)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCFadeOut:create(0.3))
    actionArrayIn:addObject(CCFadeIn:create(0.5))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    		self._actionHandler[name] = nil
    	end))
    self._actionHandler[name] = node:runAction(CCSequence:create(actionArrayIn))
end

function QUIDialogInstance:_removeAllAction()
	if self._actionHandler == nil or #self._actionHandler == 0 then 
		return 
	end
    for name,value in pairs(self._actionHandler) do
    	if name == "title" then
    		self._ccbOwner.tf_title:stopAction(value)
		elseif name == "star" then
    		self._ccbOwner.tf_star:stopAction(value)
		elseif name == "info" then
    		self:getView():stopAction(value)
    	end
    end
end

function QUIDialogInstance:_removeAllMapInfo()
	self._ccbOwner.tf_title:setString("")
	self._ccbOwner.tf_star:setString("")
	self._chest:setVisible(false)
end

-- 移动到指定位置
function QUIDialogInstance:_nodeRunAction(node,posX,posY,callFunc)
    self._isMove = true
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveBy:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                                                self._isMove = false
                                                if callFunc ~= nil then
                                                	callFunc()
                                                end
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    return node:runAction(ccsequence)
end

function QUIDialogInstance:_removePage(page)
	if page ~= nil then
    	page:removeEventListenersByEvent(QUIWidgetInstanceHead.EVENT_CITY_CLICK)
    	page:removeFromParent()
	end
end

function QUIDialogInstance:_onEvent(event)
	local direction = event.direction
	if event.name == QUIGestureRecognizer.EVENT_SWIPE_GESTURE then
		if direction == QUIGestureRecognizer.SWIPE_RIGHT or direction == QUIGestureRecognizer.SWIPE_RIGHT_UP or direction == QUIGestureRecognizer.SWIPE_RIGHT_UP then
			self:_onTriggerLeft()
		elseif direction == QUIGestureRecognizer.SWIPE_LEFT or direction == QUIGestureRecognizer.SWIPE_LEFT_UP or direction == QUIGestureRecognizer.SWIPE_LEFT_DOWN then
			self:_onTriggerRight()
		end
	end
end

function QUIDialogInstance:_headClickHandler(event)
	app.sound:playSound("battle_level")
	local needTeamLevel = event.info.unlock_team_level or 0
	if needTeamLevel <= remote.user.level then
		app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogDungeon", options = {info = event.info}})
	else
		app.tip:floatTip(string.format("该副本需要战队等级%d解锁",needTeamLevel))
	end
end

function QUIDialogInstance:onTriggerBackHandler(tag)
	self:_onTriggerBack()
end

function QUIDialogInstance:onTriggerHomeHandler(tag)
	self:_onTriggerHome()
end

function QUIDialogInstance:_onTriggerBack()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogInstance:_onTriggerHome()
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

function QUIDialogInstance:_onTriggerLeft()
    app.sound:playSound("common_change")
  if self._isMove == true then return end
  if self._totalIndex > 1 then
    self._nextIndex = self._currentIndex - 1
    self:showInstanceForData()
  end
end

function QUIDialogInstance:_onTriggerRight()
	app.sound:playSound("common_change")
  if self._isMove == true then return end
  if self._currentIndex < self._totalIndex then
    self._nextIndex = self._currentIndex + 1
    self:showInstanceForData()
  end
end

function QUIDialogInstance:_onTriggerNormal() 
    app.sound:playSound("battle_change")
	if self._isMove == true then return end
	local options = self:getOptions()
	options.currentIndex = nil
	self:selectType(DUNGEON_TYPE.NORMAL)
end

function QUIDialogInstance:_onTriggerElite()
    app.sound:playSound("battle_change")
	if self._isMove == true then return end
	local options = self:getOptions()
	options.currentIndex = nil
	self:selectType(DUNGEON_TYPE.ELITE)
end
return QUIDialogInstance
