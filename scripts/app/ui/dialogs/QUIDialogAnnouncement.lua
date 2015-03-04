--
-- Author: Qinyuanji
-- Date: 2015-02-09 
-- This class is for Announcement which is displayed after user logs in successfully

local QUIDialog = import(".QUIDialog")
local QUIDialogAnnouncement = class("QUIDialogAnnouncement", QUIDialog)
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")

QUIDialogAnnouncement.MOVEMENT_MINIMUM_PIXEL = 10
QUIDialogAnnouncement.MARGIN = 30
QUIDialogAnnouncement.GAP = 10

function QUIDialogAnnouncement:ctor(options)
	local ccbFile = "ccb/Dialog_Announcement.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogAnnouncement._onTriggerClose)}
	}
	QUIDialogAnnouncement.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = true --是否动画显示

	local index = nil
	local announcementList = QStaticDatabase:sharedDatabase():getAnnouncement(index)
	if index then
		self._announcement = announcementList
	else
		local announcementList_ = {}
		for _, v in pairs(announcementList) do 
			table.insert(announcementList_, v)
		end
		table.sort(announcementList_, function (x, y)
			return tonumber(x.id) <= tonumber(y.id)
		end)
		for _, v in ipairs(announcementList_) do 
			self._announcement = v
		end
	end

	self._contentWidth = self._ccbOwner.content:getContentSize().width
	self.fullWidth = 25
	self.width = 18
	self._content = q.autoWrap(self._announcement.content, self.fullWidth, self.width, self._contentWidth, false)

	self:setWelcome(self._announcement.start)
	self:setContent(self._content)
	self._totalHeight = QUIDialogAnnouncement.MARGIN + 
						self._ccbOwner.title:getContentSize().height + QUIDialogAnnouncement.GAP + 
						self._ccbOwner.welcome:getContentSize().height + QUIDialogAnnouncement.GAP + 
						self._ccbOwner.content:getContentSize().height + QUIDialogAnnouncement.MARGIN
	self:_initNavigationSlide()
	self:setTitle(self._announcement.title)
end

function QUIDialogAnnouncement:_initNavigationSlide()
	self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
	self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
	self._originalPosX = self._ccbOwner.touch_sheet:getPositionX()
	self._originalPosY = self._ccbOwner.touch_sheet:getPositionY()

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150), self._pageWidth, self._pageHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
	layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
	ccclippingNode:setStencil(layerColor)
	self._ccbOwner.touch_sheet:removeFromParent()
	ccclippingNode:addChild(self._ccbOwner.touch_sheet)

	self._ccbOwner.sheet:addChild(ccclippingNode)

	self._touchLayer = QUIGestureRecognizer.new()
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:attachToNode(self._ccbOwner.sheet, self._pageWidth, self._pageHeight, 0, -self._pageHeight, handler(self, self.onTouchEvent))
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))

    if self._totalHeight > self._pageHeight then
    	self._ccbOwner.shade:setVisible(true)
    else
     	self._ccbOwner.shade:setVisible(false)
	end
end

function QUIDialogAnnouncement:setTitle(title)
	self._ccbOwner.title:setString(title)
	local length = self._ccbOwner.title:getContentSize().width
	self._ccbOwner.title:setPositionX(self._pageWidth/2 - length/2)
end

function QUIDialogAnnouncement:setContent(content)
	self._ccbOwner.content:setString(content)
end

function QUIDialogAnnouncement:setWelcome(welcome)
	self._ccbOwner.welcome:setString(welcome)
end

-- Gesture reaction -------------------------------------------------------------------------------------------------
-- Respond to touch event
-- Moving more than 10 pixel is regarded as a movement, or it's regarded as a touch event
-- _isMoving variable is to distinguish when a touch event is a click or a movement.
function QUIDialogAnnouncement:onTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end

    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
    	-- if self._isMoving then
    	-- 	self:endMove()
    	-- end
  	elseif event.name == "began" then
  		self._isMoving = false
   		self._startY = event.y
   		self._pageY = self._ccbOwner.touch_sheet:getPositionY()
    elseif event.name == "moved" then
    	local newPosY = self._pageY + event.y - self._startY
    	if math.abs(event.y - self._startY) > QUIDialogAnnouncement.MOVEMENT_MINIMUM_PIXEL then
			self._isMoving = true
        end
        -- Don't move the screen out of scope
        if newPosY < self._originalPosY or (newPosY - self._originalPosY) > (self._totalHeight - self._pageHeight) then
        	return
        end
		self._ccbOwner.touch_sheet:setPositionY(newPosY)
    elseif event.name == "ended" then
    end
end

function QUIDialogAnnouncement:_onTriggerClose()
  	app.sound:playSound("common_close")
	self:playEffectOut()
end

function QUIDialogAnnouncement:viewAnimationOutHandler()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- function QUIDialogAnnouncement:_backClickHandler()
--     self:_onTriggerClose()
-- end

return QUIDialogAnnouncement