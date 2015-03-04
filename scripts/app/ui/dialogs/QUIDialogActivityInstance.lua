--
-- Author: Your Name
-- Date: 2014-11-28 15:12:46
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogActivityInstance = class("QUIDialogActivityInstance", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetActivityInstance = import("..widgets.QUIWidgetActivityInstance")
local QStaticDatabase = import("...controllers.QStaticDatabase")


function QUIDialogActivityInstance:ctor(options)
	local ccbFile = "ccb/Dialog_TimeMachine_choose.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", 				callback = handler(self, QUIDialogActivityInstance._onTriggerClose)},

	}
	QUIDialogActivityInstance.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true

    self.instanceId = options.instanceId
	-- 初始化中间滑动框
	self:_initPageSwipe()
	self._offsetX = 122
	self._offsetY = -71
    if self.instanceId ~= nil then
    	self:initPage()
    end
end

function QUIDialogActivityInstance:viewDidAppear()
	QUIDialogActivityInstance.super.viewDidAppear(self)
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))

	self._userEventProxy = cc.EventProxy.new(remote.user)
    self._userEventProxy:addEventListener(remote.user.EVENT_USER_PROP_CHANGE, handler(self, self._userUpdateHandler))
end

function QUIDialogActivityInstance:viewWillDisappear()
  	QUIDialogActivityInstance.super.viewWillDisappear(self)
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
    self._userEventProxy:removeAllEventListeners()
end

-- 初始化中间的英雄选择框 swipe工能
function QUIDialogActivityInstance:_initPageSwipe()
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
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:attachToNode(self._ccbOwner.sheet,self._pageWidth, self._pageHeight, 0, -self._pageHeight, handler(self, self.onTouchEvent))

	self._isAnimRunning = false
	self._totalHeight = 0
end

function QUIDialogActivityInstance:initPage()
	local line = 3
	local posX = self._offsetX
	local posY = self._offsetY
	local cellWidth = 200
	local cellHeight = -153
	local index = 1
	self._totalHeight = 0
	self:removeAllCell()
	self._config = remote.activityInstance:getInstanceListById(self.instanceId)
	if #self._config > 0 then
		local dungeonConfig = QStaticDatabase:sharedDatabase():getDungeonConfigByID(self._config[1].dungeon_id)
		self._ccbOwner.tf_energy:setString(dungeonConfig.energy)
	end
	self:_userUpdateHandler()
	for _,value in pairs(self._config) do
		local instanceCell = QUIWidgetActivityInstance.new()
		instanceCell:setInfo(value)
		instanceCell:setPosition(posX,posY)
		instanceCell:addEventListener(QUIWidgetActivityInstance.EVENT_END, handler(self, self.cellClickHandler))
		table.insert(self._cells, instanceCell)
		self._pageContent:addChild(instanceCell)
		if index%line == 0 then
			posX = self._offsetX
			posY = posY + cellHeight
		else
			posX = posX + cellWidth
		end
		index = index + 1
	end
end

function QUIDialogActivityInstance:_userUpdateHandler()
	self._config = remote.activityInstance:getInstanceListById(self.instanceId)
	if #self._config > 0 then
		self._ccbOwner.tf_count:setString((self._config[1].attack_num - remote.activityInstance:getAttackCountByType(self._config[1].instance_id)).."次")
	end
end

function QUIDialogActivityInstance:removeAllCell()
	if self._cells ~= nil then
		for _,cell in pairs(self._cells) do
			cell:removeFromParent()
			cell:removeAllEventListeners()
		end
	end
	self._cells = {}
end

function QUIDialogActivityInstance:onTouchEvent(event)
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

function QUIDialogActivityInstance:moveTo(posY, isAnimation)
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

function QUIDialogActivityInstance:_contentRunAction(posX, posY)
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

function QUIDialogActivityInstance:_removeAction()
	-- self:stopEnter()
	if self._actionHandler ~= nil then
		self._pageContent:stopAction(self._actionHandler)		
		self._actionHandler = nil
	end
end

function QUIDialogActivityInstance:cellClickHandler(event)
	if self._isMove == true then return end
	app.sound:playSound("battle_level")
	self._config = remote.activityInstance:getInstanceListById(self.instanceId)
	if #self._config > 0 then
		local needEnergy = QStaticDatabase:sharedDatabase():getDungeonConfigByID(self._config[1].dungeon_id).energy
		if remote.user:checkPropEnough("energy", needEnergy) == false then
			return 
		end
		if (self._config[1].attack_num - remote.activityInstance:getAttackCountByType(self._config[1].instance_id)) > 0 then
			self:_onTriggerClose()
			app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogActivityDungeon", options = {info = event.info}})
		else
        	app.tip:floatTip("今日次数已用完")
		end
	end
end

function QUIDialogActivityInstance:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogActivityInstance:_onTriggerClose()
	app.sound:playSound("common_close")
	self:playEffectOut()
end

function QUIDialogActivityInstance:viewAnimationOutHandler()
	app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogActivityInstance