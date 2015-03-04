--
-- Author: wkwang
-- Date: 2014-10-29 15:20:04
--
local QUIDialog = import("..QUIDialog")
local QUIDialogBackpackDetail = class("QUIDialogBackpackDetail", QUIDialog)

local QUIWidgetItemsBox =  import("..widgets.QUIWidgetItemsBox")
local QUIWidgetBackpackDetail =  import("..widgets.QUIWidgetBackpackDetail")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QNotificationCenter = import("...controllers.QNotificationCenter")

function QUIDialogBackpackDetail:ctor(options)
	local ccbFile = "ccb/Dialog_PacksackItemInfo.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", 				callback = handler(self, QUIDialogBackpackDetail._onTriggerClose)},
	}
	QUIDialogBackpackDetail.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true

	self._itemId = options.itemId
	self._itemNum = remote.items:getItemsNumByID(self._itemId)
	self._itemConfig = QStaticDatabase:sharedDatabase():getItemByID(self._itemId)

	self:_initPageSwipe()

	self._detail = QUIWidgetBackpackDetail.new({itemId = self._itemId})
	self._totalHeight = math.abs(self._detail:getTotalHeight())
	self._pageContent:addChild(self._detail)
	self._ccbOwner.tf_name:setString(self._itemConfig.name)
	self._ccbOwner.tf_num:setString(self._itemNum)

	if self._itemIcon == nil then
		self._itemIcon = QUIWidgetItemsBox.new()
		self._ccbOwner.node_icon:removeAllChildren()
		self._ccbOwner.node_icon:addChild(self._itemIcon)
	end
	self._itemIcon:resetAll()
	self._itemIcon:setGoodsInfo(self._itemId, ITEM_TYPE.ITEM, 0)
end

function QUIDialogBackpackDetail:viewDidAppear()
	QUIDialogBackpackDetail.super.viewDidAppear(self)
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogBackpackDetail:viewWillDisappear()
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetItemsBox.EVENT_CLICK, self._itemClickHandler,self)
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
	self:_removeAction()
end

function QUIDialogBackpackDetail:_initPageSwipe()
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
	self._touchLayer:attachToNode(self._ccbOwner.sheet,self._pageWidth, self._pageHeight, -self._pageWidth/2, -self._pageHeight, handler(self, self.onTouchEvent))
end

function QUIDialogBackpackDetail:onTouchEvent(event)
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
		self:moveTo(offsetY, false)
    end
end

function QUIDialogBackpackDetail:_removeAction()
	-- self:stopEnter()
	if self._actionHandler ~= nil then
		self._pageContent:stopAction(self._actionHandler)		
		self._actionHandler = nil
	end
end

function QUIDialogBackpackDetail:moveTo(posY, isAnimation)
	if isAnimation == false then
		self._pageContent:setPositionY(posY)
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

function QUIDialogBackpackDetail:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    											self:_removeAction()
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
end

function QUIDialogBackpackDetail:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogBackpackDetail:_onTriggerClose()
	app.sound:playSound("common_close")
    self:playEffectOut()
end

function QUIDialogBackpackDetail:viewAnimationOutHandler()
    self:removeSelfFromParent()
end

function QUIDialogBackpackDetail:removeSelfFromParent()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogBackpackDetail