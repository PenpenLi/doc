--
-- Author: Qinyuanji
-- Date: 2015-01-15 
-- This class is the dialog for Arena against reocrd

local QUIDialog = import(".QUIDialog")
local QUIDialogArenaAgainstRecord = class("QUIDialogArenaAgainstRecord", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetArenaAgainstRecord = import("..widgets.QUIWidgetArenaAgainstRecord")

QUIDialogArenaAgainstRecord.MOVEMENT_MINIMUM_PIXEL = 10
QUIDialogArenaAgainstRecord.RECORD_GAP = 10

function QUIDialogArenaAgainstRecord:ctor(options)
	local ccbFile = "ccb/Dialog_AgainstRecord.ccbi";
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogArenaAgainstRecord._onTriggerClose)},
	}
	QUIDialogArenaAgainstRecord.super.ctor(self,ccbFile,callBacks,options)

	self.isAnimation = true

	self:_initHeroPageSwipe()
	self:_insertLatestAgainstRecord()
end

-- Init page size and touch layer area
function QUIDialogArenaAgainstRecord:_initHeroPageSwipe()

	self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
	self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
	self._pageContent = CCNode:create()
	self._pageContent:setPosition(self._pageWidth/2,0)
	self._originalPosX = self._pageContent:getPositionX()
	self._originalPosY = self._pageContent:getPositionY()

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150), self._pageWidth, self._pageHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
	layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
	ccclippingNode:setStencil(layerColor)
	ccclippingNode:addChild(self._pageContent)

	self._ccbOwner.sheet:addChild(ccclippingNode)

	self._touchLayer = QUIGestureRecognizer.new()
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:attachToNode(self._ccbOwner.sheet, self._pageWidth, self._pageHeight, 0, -self._pageHeight, handler(self, self.onTouchEvent))
end

-- request for arena against record of recent 20 rivalry
-- and fill the dialog with each record
function QUIDialogArenaAgainstRecord:_insertLatestAgainstRecord()
	self._totalHeight = QUIDialogArenaAgainstRecord.RECORD_GAP

	app:getClient():arenaAgainstRecordRequest(function (data)
		self._againstRecord = clone(data.arenaResponse.histories or nil)

		if self._againstRecord ~= nil then
			table.sort(self._againstRecord, function (x, y)
				return x.fighter1.lastFightAt > y.fighter1.lastFightAt
			end)

			index = 1
			for _, v in pairs(self._againstRecord) do
				local me = v.fighter1
				local rival = v.fighter2
				local result = v.success

				-- need to know which fighter is myself
				if me.userId ~= remote.user.userId then
					me, rival = rival, me
					result = not result
				end

			 	local widgetArenaAgainRecord = QUIWidgetArenaAgainstRecord.new(
			 		{parent = self, userId = rival.userId, nickName = rival.name, level = rival.level, result = result, 
			 		rankChanged = math.abs(me.rank - me.lastRank), avatar = rival.avatar, time = me.lastFightAt}) 

				local widgetHeight = widgetArenaAgainRecord:getContentHeight()
				widgetArenaAgainRecord:setPosition(0, -(index - 1) * (widgetHeight + QUIDialogArenaAgainstRecord.RECORD_GAP) - widgetHeight/2 - QUIDialogArenaAgainstRecord.RECORD_GAP)
				self._pageContent:addChild(widgetArenaAgainRecord)
				self._totalHeight = self._totalHeight + widgetHeight + QUIDialogArenaAgainstRecord.RECORD_GAP
				index = index + 1
			end
		end
	end)
end

function QUIDialogArenaAgainstRecord:viewDidAppear()
	QUIDialogArenaAgainstRecord.super.viewDidAppear(self)
    
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogArenaAgainstRecord:viewWillDisappear()
	self._touchLayer:removeEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE)
	QUIDialogArenaAgainstRecord.super.viewWillDisappear(self)
end 

function QUIDialogArenaAgainstRecord:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end


-- Respond to touch event
-- Moving more than 10 pixel is regarded as a movement, or it's regarded as a touch event
-- _isMoving variable is to distinguish when a touch event is a click or a movement.
function QUIDialogArenaAgainstRecord:onTouchEvent(event)
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
    	if math.abs(event.y - self._startY) > QUIDialogArenaAgainstRecord.MOVEMENT_MINIMUM_PIXEL then
			self._isMoving = true
        end
        -- Don't move the screen out of scope
        if newPosY < self._originalPosY or (newPosY - self._originalPosY) > (self._totalHeight - self._pageHeight) then
        	--return
        	self._isMoving = true
        end
		self._pageContent:setPositionY(newPosY)
    elseif event.name == "ended" then
    end
end

-- Check if current screen is in the scope of page
function QUIDialogArenaAgainstRecord:endMove()
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
function QUIDialogArenaAgainstRecord:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
end


function QUIDialogArenaAgainstRecord:_onTriggerCancel()
	self:_close()
end

function QUIDialogArenaAgainstRecord:_backClickHandler()
    self:_close()
end

function QUIDialogArenaAgainstRecord:_onTriggerClose()
	app.sound:playSound("common_cancel")
    self:_close()
end

function QUIDialogArenaAgainstRecord:_close()
    self:playEffectOut()
end

return QUIDialogArenaAgainstRecord
