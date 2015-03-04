--
-- Author: Qinyuanji
-- Date: 2014-11-19 
-- This class is the dialog for changing avatar, it includes QUIWidgetChooseHead.

local QUIDialog = import(".QUIDialog")
local QUIDialogChooseHead = class("QUIDialogChooseHead", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetChooseHead = import("..widgets.QUIWidgetChooseHead")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUIDialogChooseHead.NEW_AVATAR_SELECTED = "NEW_AVATAR_SELECTED"
QUIDialogChooseHead.MOVEMENT_MINIMUM_PIXEL = 10

function QUIDialogChooseHead:ctor(options)
	local ccbFile = "ccb/Dialog_ChooseHead.ccbi";
	local callBacks = {
	}
	QUIDialogChooseHead.super.ctor(self,ccbFile,callBacks,options)
	self.isAnimation = true

	self:_initHeroPageSwipe()
end

-- Init page size and touch layer area
function QUIDialogChooseHead:_initHeroPageSwipe()
	self._widgetChooseHead = QUIWidgetChooseHead.new() 

	self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
	self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
	self._pageContent = CCNode:create()
	self._pageContent:setPosition(self._pageWidth/2, -self._pageHeight/2)
	self._originalPosX = self._pageContent:getPositionX()
	self._originalPosY = self._pageContent:getPositionY()

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150), self._pageWidth, self._pageHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
	layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
	ccclippingNode:setStencil(layerColor)
	ccclippingNode:addChild(self._pageContent)
	self._pageContent:addChild(self._widgetChooseHead)

	self._ccbOwner.sheet:addChild(ccclippingNode)

	self._touchLayer = QUIGestureRecognizer.new()
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:attachToNode(self._ccbOwner.sheet, self._pageWidth, self._pageHeight, 0, -self._pageHeight, handler(self, self.onTouchEvent))

	self._isAnimRunning = false
end

function QUIDialogChooseHead:viewDidAppear()
	QUIDialogChooseHead.super.viewDidAppear(self)
    
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))

	QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogChooseHead.NEW_AVATAR_SELECTED, self.onAvatarChanged, self)
end

function QUIDialogChooseHead:viewWillDisappear()
	self._touchLayer:removeEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE)
	
	QUIDialogChooseHead.super.viewWillDisappear(self)
	QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogChooseHead.NEW_AVATAR_SELECTED, self.onAvatarChanged, self)
end 

function QUIDialogChooseHead:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- If an avatar is selected, close the dialog
function QUIDialogChooseHead:onAvatarChanged(event)
    self:_onTriggerClose()
end

-- Respond to touch event
-- Moving more than 10 pixel is regarded as a movement, or it's regarded as a touch event
-- _isMoving variable is to distinguish when a touch event is a click or a movement.
function QUIDialogChooseHead:onTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end

    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
    	if self._isMoving then
    		self._widgetChooseHead:endMove() 		
    		self:endMove()
    	end
  	elseif event.name == "began" then
  		self._isMoving = false
   		self._startY = event.y
   		self._pageY = self._pageContent:getPositionY()
    elseif event.name == "moved" then
    	local newPosY = self._pageY + event.y - self._startY
    	if math.abs(event.y - self._startY) > QUIDialogChooseHead.MOVEMENT_MINIMUM_PIXEL then
			self._isMoving = true
  			self._widgetChooseHead:onMove()
        end
		self._pageContent:setPositionY(newPosY)
    elseif event.name == "ended" then
    end
end

-- Check if current screen is in the scope of page
function QUIDialogChooseHead:endMove()
	local currentPosY = self._pageContent:getPositionY()
	local newPosY = currentPosY
	if currentPosY < self._originalPosY then
		newPosY = self._originalPosY
	elseif (currentPosY - self._originalPosY) > (self._widgetChooseHead:getContentHeight() - self._pageHeight) then
		newPosY = self._widgetChooseHead:getContentHeight() - self._pageHeight + self._originalPosY
	end

	if newPosY ~= currentPosY then
		self:_contentRunAction(self._originalPosX, newPosY)
	end
end

-- Move to position smoothly
function QUIDialogChooseHead:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
end


function QUIDialogChooseHead:_onTriggerCancel()
	self:_onTriggerClose()
end

function QUIDialogChooseHead:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogChooseHead:_onTriggerClose()
    self:playEffectOut()
end

return QUIDialogChooseHead
