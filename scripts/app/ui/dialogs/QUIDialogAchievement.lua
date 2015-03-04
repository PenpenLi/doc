--
-- Author: wkwang
-- Date: 2014-11-24 11:35:03
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogAchievement = class("QUIDialogAchievement", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetAchievementItem = import("..widgets.QUIWidgetAchievementItem")
local QUIViewController = import("..QUIViewController")

function QUIDialogAchievement:ctor(options)
	local ccbFile = "ccb/Dialog_Achievement.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerTabDefault", 				callback = handler(self, QUIDialogAchievement._onTriggerTabDefault)},
		{ccbCallbackName = "onTriggerTabHero", 					callback = handler(self, QUIDialogAchievement._onTriggerTabHero)},
		{ccbCallbackName = "onTriggerTabInstance", 				callback = handler(self, QUIDialogAchievement._onTriggerTabInstance)},
		{ccbCallbackName = "onTriggerTabArena", 				callback = handler(self, QUIDialogAchievement._onTriggerTabArena)},
		{ccbCallbackName = "onTriggerTabOther", 				callback = handler(self, QUIDialogAchievement._onTriggerTabOther)},
	}
	QUIDialogAchievement.super.ctor(self,ccbFile,callBacks,options)
	app:getNavigationController():getTopPage():setManyUIVisible()
	self:setLock(true)

	-- 初始化页面滑动框和遮罩层
	self:_initPageSwipe()
end

function QUIDialogAchievement:viewDidAppear()
	QUIDialogAchievement.super.viewDidAppear(self)
    self._menuTouchLayer:enable()
    self._menuTouchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onMenuTouchEvent))

    self._itemTouchLayer:enable()
    self._itemTouchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onItemTouchEvent))

    self._achieveProxy = cc.EventProxy.new(remote.achieve)
    self._achieveProxy:addEventListener(remote.achieve.EVENT_UPDATE, handler(self, self._achievementsInfoUpdate))

	self:addBackEvent()
end

function QUIDialogAchievement:viewWillDisappear()
  	QUIDialogAchievement.super.viewWillDisappear(self)
    self._menuTouchLayer:removeAllEventListeners()
    self._menuTouchLayer:disable()
    self._menuTouchLayer:detach()
    self._itemTouchLayer:removeAllEventListeners()
    self._itemTouchLayer:disable()
    self._itemTouchLayer:detach()
    self._achieveProxy:removeAllEventListeners()
	self:removeBackEvent()
	self:_removeAction(self._itemContent)
	self:_removeAction(self._menuContent)
end

function QUIDialogAchievement:_initPageSwipe()
	self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
	self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
	self._itemWidth = self._ccbOwner.sheet_content:getContentSize().width
	self._itemHeight = self._ccbOwner.sheet_content:getContentSize().height
	self._menuWidth = self._ccbOwner.sheet_menu:getContentSize().width
	self._menuHeight = self._ccbOwner.sheet_menu:getContentSize().height

	self._itemContent = CCNode:create() --成就条目容器
	self._itemContent:setPosition(self._ccbOwner.sheet_content:getPositionX(), 0)
	self._menuContent = self._ccbOwner.node_btn --成就菜单容器

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._pageWidth,self._pageHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
	layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
	ccclippingNode:setStencil(layerColor)
	ccclippingNode:addChild(self._itemContent)
	self._menuContent:retain()
	self._menuContent:removeFromParent()
	ccclippingNode:addChild(self._menuContent)
	self._menuContent:release()

	self._ccbOwner.sheet:addChild(ccclippingNode)

	self._menuTouchLayer = QUIGestureRecognizer.new()
	self._menuTouchLayer:setSlideRate(0.3)
	self._menuTouchLayer:setAttachSlide(true)
	self._menuTouchLayer:attachToNode(self._ccbOwner.sheet, self._menuWidth, self._menuHeight, self._ccbOwner.sheet_menu:getPositionX(),
		self._ccbOwner.sheet_menu:getPositionY(), handler(self, self.onMenuTouchEvent))

	self._itemTouchLayer = QUIGestureRecognizer.new()
	self._itemTouchLayer:setSlideRate(0.3)
	self._itemTouchLayer:setAttachSlide(true)
	self._itemTouchLayer:attachToNode(self._ccbOwner.sheet, self._itemWidth, self._itemHeight, self._ccbOwner.sheet_content:getPositionX(),
		self._ccbOwner.sheet_content:getPositionY(), handler(self, self.onItemTouchEvent))

	self._menuTotalHeight = 86*4
	self._itemTotalHeight = 0
	self._offsetX = 205.0 + 425
	self._offsetY = -74
	self._cellH = self._ccbOwner.sprite_scroll_cell:getContentSize().height
	self._scrollH = self._ccbOwner.sprite_scroll_bar:getContentSize().height - self._cellH
	self._ccbOwner.tf_number:setString("成就点数: "..remote.achieve.achievePoint)

	if remote.achieve:checkAchieveDoneForType(remote.achieve.DEFAULT) == true then
		self:_selectTab(remote.achieve.DEFAULT)
	elseif remote.achieve:checkAchieveDoneForType(remote.achieve.TYPE_HERO) == true then
		self:_selectTab(remote.achieve.TYPE_HERO)
	elseif remote.achieve:checkAchieveDoneForType(remote.achieve.TYPE_INSTANCE) == true then
		self:_selectTab(remote.achieve.TYPE_INSTANCE)
	elseif remote.achieve:checkAchieveDoneForType(remote.achieve.TYPE_USER) == true then
		self:_selectTab(remote.achieve.TYPE_USER)
	else
		self:_selectTab(remote.achieve.DEFAULT)
	end
end

function QUIDialogAchievement:_selectTab(tab, isForceFresh)
	if self._isMenuMove == true then return end
	if tab ~= self.tab or isForceFresh == true then
		self._ccbOwner.btn_default:setHighlighted(false)
		self._ccbOwner.btn_hero:setHighlighted(false)
		self._ccbOwner.btn_instance:setHighlighted(false)
		self._ccbOwner.btn_arena:setHighlighted(false)
		self._ccbOwner.btn_other:setHighlighted(false)

		self._ccbOwner.btn_default:setEnabled(true)
		self._ccbOwner.btn_hero:setEnabled(true)
		self._ccbOwner.btn_instance:setEnabled(true)
		self._ccbOwner.btn_arena:setEnabled(true)
		self._ccbOwner.btn_other:setEnabled(true)

		self._ccbOwner.node_tips_hero:setVisible(remote.achieve:checkAchieveDoneForType(remote.achieve.TYPE_HERO))
		self._ccbOwner.node_tips_instance:setVisible(remote.achieve:checkAchieveDoneForType(remote.achieve.TYPE_INSTANCE))
		self._ccbOwner.node_tips_arena:setVisible(remote.achieve:checkAchieveDoneForType(remote.achieve.TYPE_ARENA))
		self._ccbOwner.node_tips_other:setVisible(remote.achieve:checkAchieveDoneForType(remote.achieve.TYPE_USER))

		self.tab = tab
		if tab == remote.achieve.DEFAULT then
			self._ccbOwner.btn_default:setHighlighted(true)
			self._ccbOwner.btn_default:setEnabled(false)
		elseif tab == remote.achieve.TYPE_HERO then
			self._ccbOwner.btn_hero:setHighlighted(true)
			self._ccbOwner.btn_hero:setEnabled(false)
		elseif tab == remote.achieve.TYPE_INSTANCE then
			self._ccbOwner.btn_instance:setHighlighted(true)
			self._ccbOwner.btn_instance:setEnabled(false)
		elseif tab == remote.achieve.TYPE_ARENA then
			self._ccbOwner.btn_arena:setHighlighted(true)
			self._ccbOwner.btn_arena:setEnabled(false)
		elseif tab == remote.achieve.TYPE_USER then
			self._ccbOwner.btn_other:setHighlighted(true)
			self._ccbOwner.btn_other:setEnabled(false)
		end
		self._items = remote.achieve:getAchieveListByType(self.tab)
		self:_initPage()
	end
end

function QUIDialogAchievement:_initPage()
	--释放现有的BOX
	if self._virtualItem ~= nil then
		for index,value in pairs(self._virtualItem) do
			if value.icon ~= nil then
				self:releaseItem(value.icon)
		    	value.icon = nil
			end
		end
	end
	self._virtualItem = {}
	self._ccbOwner.sprite_scroll_cell:setOpacity(0)
	self._ccbOwner.sprite_scroll_bar:setOpacity(0)
	local posX = self._offsetX
	local posY = self._offsetY
	local cellHeight = 144--139
	local count = 0
	self._itemTotalHeight = 0
	for _,value in pairs(self._items) do
		table.insert(self._virtualItem, {info = value, posX = posX, posY = posY})
		posX = self._offsetX
		posY = posY - cellHeight
		count = count + 1
	end
	self._itemTotalHeight = count * cellHeight
	self._itemContent:setPosition(0, 0)
	self:onFrame()
end

function QUIDialogAchievement:onFrame()
	local contentY = self._itemContent:getPositionY()
	for index,value in pairs(self._virtualItem) do
		if value.posY + contentY < -self._pageHeight + self._offsetY or value.posY + contentY > -self._offsetY then
			self:releaseItem(value.icon)
	    	value.icon = nil
		end
	end
	for index,value in pairs(self._virtualItem) do
		if value.posY + contentY >= -self._pageHeight + self._offsetY and value.posY + contentY <= -self._offsetY then
			if value.icon == nil then
			    value.icon = self:getItem()
			    value.icon:setPosition(value.posX, value.posY)
			    value.icon:setVisible(true)
			    value.icon:setInfo(value.info)
			end
		end
	end
	if 	self._itemTotalHeight > self._pageHeight and contentY > 0 and contentY <= self._itemTotalHeight - self._pageHeight then
		local cellY = self._scrollH  * (1 - math.abs(contentY) / math.abs(self._itemTotalHeight - self._pageHeight)) + self._cellH/2
		self._ccbOwner.sprite_scroll_cell:setPositionY(cellY)
	end
end

--[[移除BOX从滑动容器中]]
function QUIDialogAchievement:releaseItem(item)
	if item ~= nil then
		if self._itemCache == nil then
			self._itemCache = {}
		end
		table.insert(self._itemCache, item)
		item:setVisible(false)
	end
end

--[[获取BOX从滑动容器中]]
function QUIDialogAchievement:getItem()
	local item = nil
	if self._itemCache ~= nil and #self._itemCache > 0 then
		item = self._itemCache[1]
		table.remove(self._itemCache,1)
	else
		item = QUIWidgetAchievementItem.new()--app.widgetCache:getWidgetForName("QUIWidgetItemsBox", self._pageContent)
		item:addEventListener(QUIWidgetAchievementItem.EVENT_CLICK, handler(self, self.itemClickHandler))
		self._itemContent:addChild(item)
		item:setVisible(false)
	end
	return item
end

-- 成就条目触摸
function QUIDialogAchievement:onItemTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
		self._itemActionHandler = self:moveTo(self._itemContent, self._itemTotalHeight, event.distance.y, true)
  	elseif event.name == "began" then
  		self:_removeAction(self._itemContent)
  		self._startY = event.y
  		self._menuY = self._itemContent:getPositionY()
    elseif event.name == "moved" then
    	local offsetY = self._menuY + event.y - self._startY
        if math.abs(event.y - self._startY) > 10 then
            self._isItemMove = true
        end
		self:moveTo(self._itemContent, self._itemTotalHeight, offsetY, false)
	elseif event.name == "ended" then
    	scheduler.performWithDelayGlobal(function ()
    		self._isItemMove = false
    		end,0)
    end
end

-- 成就菜单触摸
function QUIDialogAchievement:onMenuTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
		self._menuActionHandler = self:moveTo(self._menuContent, self._menuTotalHeight, event.distance.y, true)
  	elseif event.name == "began" then
  		self:_removeAction(self._menuContent)
  		self._startY = event.y
  		self._menuY = self._menuContent:getPositionY()
    elseif event.name == "moved" then
    	local offsetY = self._menuY + event.y - self._startY
        if math.abs(event.y - self._startY) > 10 then
            self._isMenuMove = true
        end
		self:moveTo(self._menuContent, self._menuTotalHeight, offsetY, false)
	elseif event.name == "ended" then
    	scheduler.performWithDelayGlobal(function ()
    		self._isMenuMove = false
    		end,0)
    end
end

function QUIDialogAchievement:moveTo(node, totalHeight, posY, isAnimation)
	self._ccbOwner.sprite_scroll_cell:stopAllActions()
	self._ccbOwner.sprite_scroll_bar:stopAllActions()
	if 	totalHeight <= self._pageHeight or (math.abs(posY) < 1 and self._scrollShow == false) then
		self._ccbOwner.sprite_scroll_cell:setOpacity(0)
		self._ccbOwner.sprite_scroll_bar:setOpacity(0)
	else
		self._ccbOwner.sprite_scroll_cell:setOpacity(255)
		self._ccbOwner.sprite_scroll_bar:setOpacity(255)
		self._scrollShow = true
	end
	if isAnimation == false then
		node:setPositionY(posY)
		self:onFrame()
		return 
	end

	local contentY = node:getPositionY()
	local targetY = 0
	if totalHeight <= self._pageHeight then
		targetY = 0
	elseif contentY + posY > totalHeight - self._pageHeight then
		targetY = totalHeight - self._pageHeight
	elseif contentY + posY < 0 then
		targetY = 0
	else
		targetY = contentY + posY
	end
	self._runNode = node
	return self:_contentRunAction(node, targetY, totalHeight)
end

function QUIDialogAchievement:_contentRunAction(node, posY ,totalHeight)
	posX = self._runNode:getPositionX()
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    											self:_removeAction(node)
    											self:onFrame()
												if 	totalHeight > self._pageHeight and self._scrollShow == true then
													self._ccbOwner.sprite_scroll_cell:runAction(CCFadeOut:create(0.3))
													self._ccbOwner.sprite_scroll_bar:runAction(CCFadeOut:create(0.3))
													self._scrollShow = false
												end
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    local actionHandler = self._runNode:runAction(ccsequence)
    self:startEnter()
    return actionHandler
end

function QUIDialogAchievement:_removeAction(node)
	-- if node ~= self._runNode then return end
	self:stopEnter()
	local actionHandler = nil
	if node == self._menuContent then
		actionHandler = self._menuActionHandler
		self._menuActionHandler = nil
	elseif node == self._itemContent then
		actionHandler = self._itemActionHandler
		self._itemActionHandler = nil
	end
	if actionHandler ~= nil and node ~= nil then
		node:stopAction(actionHandler)		
	end
end

function QUIDialogAchievement:startEnter()
	self:stopEnter()
    self._onFrameHandler = scheduler.scheduleGlobal(handler(self, self.onFrame), 0)
end

function QUIDialogAchievement:stopEnter()
    if self._onFrameHandler ~= nil then
    	scheduler.unscheduleGlobal(self._onFrameHandler)
    	self._onFrameHandler = nil
    end
end

function QUIDialogAchievement:_achievementsInfoUpdate()
	self:_selectTab(self.tab , true)
	self._ccbOwner.tf_number:setString("成就点数: "..remote.achieve.achievePoint)
end

function QUIDialogAchievement:_onTriggerTabDefault()
	app.sound:playSound("common_switch")
	self:_selectTab(remote.achieve.DEFAULT)
end

function QUIDialogAchievement:_onTriggerTabHero()
	app.sound:playSound("common_switch")
	self:_selectTab(remote.achieve.TYPE_HERO)
end

function QUIDialogAchievement:_onTriggerTabInstance()
	app.sound:playSound("common_switch")
	self:_selectTab(remote.achieve.TYPE_INSTANCE)
end

function QUIDialogAchievement:_onTriggerTabArena()
	app.sound:playSound("common_switch")
	self:_selectTab(remote.achieve.TYPE_ARENA)
end

function QUIDialogAchievement:_onTriggerTabOther()
	app.sound:playSound("common_switch")
	self:_selectTab(remote.achieve.TYPE_USER)
end

function QUIDialogAchievement:onTriggerBackHandler()
	app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogAchievement:onTriggerHomeHandler()
	app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

function QUIDialogAchievement:itemClickHandler(event)
	if self._isItemMove == true then return end
	local achieveInfo = remote.achieve:getAchieveById(event.index)
	if achieveInfo.state == remote.achieve.MISSION_COMPLETE then
		return 
	end
	app.sound:playSound("common_small")
	if achieveInfo.state ~= remote.achieve.MISSION_DONE then
		app.tip:floatTip("成就尚未完成")
		return
	end
    app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAlertDialyTask", 
    	options = {index = event.index}}, {isPopCurrentDialog = false})
end

return QUIDialogAchievement