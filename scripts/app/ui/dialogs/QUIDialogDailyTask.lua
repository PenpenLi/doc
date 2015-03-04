--
-- Author: wkwang
-- Date: 2014-11-15 11:21:55
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogDailyTask = class("QUIDialogDailyTask", QUIDialog)

local QUIWidgetDailyTaskCell = import("..widgets.QUIWidgetDailyTaskCell")
local QNavigationController = import("...controllers.QNavigationController")
local QUIViewController = import("..QUIViewController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")

function QUIDialogDailyTask:ctor(options)
	local ccbFile = "ccb/Dialog_DailyMission.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", 				callback = handler(self, QUIDialogDailyTask._onTriggerClose)},
	}
	QUIDialogDailyTask.super.ctor(self,ccbFile,callBacks,options)

    self.isAnimation = true

	-- 初始化中间页面滑动框
	self:_initHeroPageSwipe()
end

-- 初始化中间的英雄选择框 swipe工能
function QUIDialogDailyTask:_initHeroPageSwipe()
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

	self._cellHeight = 144
	self._offsetHeight = -70
	self._offsetWidth= self._pageWidth/2
	self:initPage()
end

function QUIDialogDailyTask:viewDidAppear()
	QUIDialogDailyTask.super.viewDidAppear(self)
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))

    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(remote.TASK_UPDATE_EVENT, handler(self, self._taskInfoUpdate))

    self._taskProxy = cc.EventProxy.new(remote.task)
    self._taskProxy:addEventListener(remote.task.EVENT_DONE, handler(self, self._taskInfoUpdate))
    self._taskProxy:addEventListener(remote.task.EVENT_TIME_DONE, handler(self, self._taskInfoUpdate))

end

function QUIDialogDailyTask:viewWillDisappear()
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
    self._remoteProxy:removeAllEventListeners()
    self._taskProxy:removeAllEventListeners()
    self:removeTbl()
end

function QUIDialogDailyTask:removeTbl()
	if self._cellTbls == nil then return end
	for _,cell in pairs(self._cellTbls) do
		if cell ~= nil then
			cell:removeAllEventListeners()
			cell:removeFromParent()
		end
	end
	self._cellTbls = nil
end

function QUIDialogDailyTask:initPage()
	self._totalHeight = 0
	self._pageContent:setPositionY(0)
	self._ccbOwner.node_complete:setVisible(false)
    self:removeTbl()
	self._cellTbls = {}
	local taskConfigs = remote.task:getDailyTask()
	local taskList = {}
	for _,value in pairs(taskConfigs) do
		table.insert(taskList, value)
	end
	table.sort(taskList,function (a,b)
			if a.state ~= b.state then
	        	if a.state == remote.task.TASK_DONE or b.state == remote.task.TASK_COMPLETE then
	        		return true
        		elseif b.state == remote.task.TASK_DONE or a.state == remote.task.TASK_COMPLETE then
        			return false
	        	end
	        end
	        return a.config.index < b.config.index
        end)
	for _,config in pairs(taskList) do
		if (config.display_level == nil or config.display_level <= remote.user.level) and config.isShow == true then
			local cell = QUIWidgetDailyTaskCell.new()
			table.insert(self._cellTbls, cell)
			cell:addEventListener(QUIWidgetDailyTaskCell.EVENT_QUICK_LINK, handler(self,self.quickLinkHandler))
			cell:addEventListener(QUIWidgetDailyTaskCell.EVENT_CLICK, handler(self, self.cellClickHandler))
			cell:setInfo(config)
			cell:setPosition(self._offsetWidth, -self._totalHeight + self._offsetHeight) 
			self._totalHeight = self._totalHeight + self._cellHeight
			self._pageContent:addChild(cell)
		end
	end
	if #self._cellTbls == 0 then
		self._ccbOwner.node_complete:setVisible(true)
	end
end

function QUIDialogDailyTask:onTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
		self:moveTo(event.distance.y, true)
  	elseif event.name == "began" then
  		self:_removeAction()
  		self._startY = event.y
  		self._pageY = self._pageContent:getPositionY()
    elseif event.name == "moved" then
    	local offsetY = self._pageY + event.y - self._startY
        if math.abs(event.y - self._startY) > 10 then
            self._isMove = true
        end
		self:moveTo(offsetY, false)
	elseif event.name == "ended" then
    	scheduler.performWithDelayGlobal(function ()
    		self._isMove = false
    		end,0)
    end
end

function QUIDialogDailyTask:moveTo(posY, isAnimation)
	if isAnimation == false then
		self._pageContent:setPositionY(posY)
		-- self:onFrame()
		return 
	end

	local contentY = self._pageContent:getPositionY()
	local targetY = 0
	if self._totalHeight <= self._pageHeight then
		targetY = 0
	elseif contentY + posY > self._totalHeight - self._pageHeight then
		targetY = self._totalHeight - self._pageHeight
	elseif contentY + posY < 0 then
		targetY = 0
	else
		targetY = contentY + posY
	end
	self:_contentRunAction(0, targetY)
end

function QUIDialogDailyTask:_contentRunAction(posX, posY)
	if posY == self._pageContent:getPositionY() then
		return
	end
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    											self:_removeAction()
    											-- self:onFrame()
												-- if 	self._totalHeight > self._pageHeight and self._scrollShow == true then
												-- 	self._ccbOwner.sprite_scroll_cell:runAction(CCFadeOut:create(0.3))
												-- 	self._ccbOwner.sprite_scroll_bar:runAction(CCFadeOut:create(0.3))
												-- 	self._scrollShow = false
												-- end
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
    -- self:startEnter()
end

function QUIDialogDailyTask:_removeAction()
	-- self:stopEnter()
	if self._actionHandler ~= nil then
		self._pageContent:stopAction(self._actionHandler)		
		self._actionHandler = nil
	end
end

-- function QUIDialogDailyTask:startEnter()
-- 	self:stopEnter()
--     self._onFrameHandler = scheduler.scheduleGlobal(handler(self, self.onFrame), 0)
-- end

-- function QUIDialogDailyTask:stopEnter()
--     if self._onFrameHandler ~= nil then
--     	scheduler.unscheduleGlobal(self._onFrameHandler)
--     	self._onFrameHandler = nil
--     end
-- end

-- function QUIDialogDailyTask:onFrame()
	-- local contentY = self._pageContent:getPositionY()
	-- for index,value in pairs(self._virtualBox) do
	-- 	if value.posY + contentY < -self._pageHeight + self._offsetY or value.posY + contentY > -self._offsetY then
	-- 		self:setBox(value.icon)
	--     	value.icon = nil
	-- 	end
	-- end
	-- for index,value in pairs(self._virtualBox) do
	-- 	if value.posY + contentY >= -self._pageHeight + self._offsetY and value.posY + contentY <= -self._offsetY then
	-- 		if value.icon == nil then
	-- 		    value.icon = self:getBox()
	-- 		    value.icon:setPosition(value.posX, value.posY)
	-- 		    value.icon:setVisible(true)
	-- 		    value.icon:resetAll()
	-- 		    value.icon:setGoodsInfo(value.info.type, ITEM_TYPE.ITEM, value.info.count)
	-- 		end
	-- 	end
	-- end
	-- if 	self._totalHeight > self._pageHeight and contentY > 0 and contentY <= self._totalHeight - self._pageHeight then
	-- 	local cellY = self._scrollH  * (1 - math.abs(contentY) / math.abs(self._totalHeight - self._pageHeight)) + self._cellH/2
	-- 	self._ccbOwner.sprite_scroll_cell:setPositionY(cellY)
	-- end
-- end

function QUIDialogDailyTask:_taskInfoUpdate()
	self:initPage()
end

function QUIDialogDailyTask:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogDailyTask:_onTriggerClose()
	app.sound:playSound("common_close")
	self:playEffectOut()
end

function QUIDialogDailyTask:viewAnimationOutHandler()
	app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	if self._quickLinkIndex ~= nil then
		remote.task:quickLink(self._quickLinkIndex)
	end
end

function QUIDialogDailyTask:quickLinkHandler(event)
	self._quickLinkIndex = event.index
	self:_onTriggerClose()
end

function QUIDialogDailyTask:cellClickHandler(event)
	if self._isMove == true then return end
	app.sound:playSound("common_small")
    app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAlertDialyTask", 
    	options = {index = event.index}}, {isPopCurrentDialog = false})
end

return QUIDialogDailyTask