--
-- Author: wkwang
-- Date: 2014-09-18 14:52:33
--
local QUIDialog = import(".QUIDialog")
local QUIDialogMailContent = class("QUIDialogMailContent", QUIDialog)

local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QUIWidgetMailAwards = import("..widgets.QUIWidgetMailAwards")
local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")

QUIDialogMailContent.MAIL_EVENT_RECV_AWARD = "MAIL_EVENT_RECV_AWARD"

function QUIDialogMailContent:ctor(options)
	local ccbFile = "ccb/Dialog_Email_Content.ccbi"
	local callbacks = {
		{ccbCallbackName = "onTriggerAutoAdd", callback = handler(self, QUIDialogMailContent._onTriggerAutoAdd)},
		{ccbCallbackName = "onTriggerReceive", callback = handler(self, QUIDialogMailContent._onTriggerReceive)},
	}
	QUIDialogMailContent.super.ctor(self, ccbFile, callbacks, options)

    self.isAnimation = true

	self.mail = options.mail

	self._ccbOwner.title:setString(self.mail.title)

    self._awardsHeight = 68
    self._awardsWidth = 186
	self._cellHeight = 100
	self._cellWidth = 100
	self._itemStartHeight = -50
    self._gap = 18
	self._totalHeight = 0

  	self._ccbOwner.tf_content:setString(self.mail.content)
	if self.mail.attachment == "" then
		self._ccbOwner.node_attachment:setVisible(false)
	end

    if self.mail.awards ~= nil and #self.mail.awards > 0 then
        local row = 0
        local line = 0
        for index,value in pairs(self.mail.awards) do
            local awardWidget = QUIWidgetMailAwards.new(value)
            awardWidget:setPosition(44 + row * self._awardsWidth, self._itemStartHeight - self._awardsHeight/2)
            self._ccbOwner.node_attachment:addChild(awardWidget)
            row = row + 1
            if row == 2 then
                row = 0
                line = line + 1
                self._itemStartHeight = self._itemStartHeight - line * self._awardsHeight
            end
        end
        self._itemStartHeight = self._itemStartHeight - self._awardsHeight
    end

	if self.mail.items ~= nil and #self.mail.items > 0 then
		local row = 0
		local line = 0
		for index,value in pairs(self.mail.items) do
			local mailIcon = QUIWidgetItemsBox.new()
            mailIcon:setScale(0.8)
    		mailIcon:setGoodsInfo(value.itemId, ITEM_TYPE.ITEM , (tonumber(value.count) or 0))
    		mailIcon:setPosition(56 + row*self._cellWidth, self._itemStartHeight - self._cellHeight/2)
    		self._ccbOwner.node_attachment:addChild(mailIcon:getView())
	    	row = row + 1
	    	if row == 4 then
	    		row = 0
	    		line = line + 1
                self._itemStartHeight = self._itemStartHeight - self._cellHeight
	    	end
		end
        self._itemStartHeight = self._itemStartHeight - self._cellHeight
    end
    if (self.mail.items ~= nil and #self.mail.items > 0) or (self.mail.awards ~= nil and #self.mail.awards > 0) then
		self._ccbOwner.btn_receive:setVisible(true)
		self._ccbOwner.btn_ok:setVisible(false)
	else
		self._ccbOwner.btn_receive:setVisible(false)
		self._ccbOwner.btn_ok:setVisible(true)
	end
	self._ccbOwner.node_bg:setPreferredSize(cc.size(412, math.abs(self._itemStartHeight)))
	self._totalHeight = self._ccbOwner.tf_content:getContentSize().height + self._ccbOwner.node_bg:getContentSize().height + self._gap * 2
	self:_initMaskContent()
end

-- 初始化邮箱
function QUIDialogMailContent:_initMaskContent()
    self._boxWidth = self._ccbOwner.sheet_layout:getContentSize().width
    self._boxHeight = self._ccbOwner.sheet_layout:getContentSize().height
    self._boxOriginX = self._ccbOwner.sheet_layout:getPositionX()
    self._boxOriginY = self._ccbOwner.sheet_layout:getPositionY()

    self._boxContent = CCNode:create()

    self._layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._boxWidth,self._boxHeight)
    local ccclippingNode = CCClippingNode:create()
    self._layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
    self._layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
    ccclippingNode:setStencil(self._layerColor)
    ccclippingNode:addChild(self._boxContent)

    self._ccbOwner.sheet:addChild(ccclippingNode)
    self._isAnimRunning = false

    self._touchLayer = QUIGestureRecognizer.new()
    self._touchLayer:attachToNode(self._ccbOwner.sheet, self._boxWidth, self._boxHeight, self._boxOriginX, self._boxOriginY, handler(self, self.onTouchEvent))

	self._ccbOwner.tf_content:retain()
    self._ccbOwner.tf_content:removeFromParent()
    self._boxContent:addChild(self._ccbOwner.tf_content)
    self._ccbOwner.tf_content:setPosition(16,-self._gap)
	self._ccbOwner.tf_content:release()
    self._ccbOwner.node_attachment:retain()
    self._ccbOwner.node_attachment:setPosition(0,-self._ccbOwner.tf_content:getContentSize().height - self._gap * 2 )
    self._ccbOwner.node_attachment:removeFromParent()
    self._boxContent:addChild(self._ccbOwner.node_attachment)
    self._ccbOwner.node_attachment:release()
end

function QUIDialogMailContent:viewDidAppear()
	QUIDialogMailContent.super.viewDidAppear(self)

    self._touchLayer:enable()
    self._touchLayer:setAttachSlide(true)
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogMailContent:viewWillDisappear()
	QUIDialogMailContent.super.viewWillDisappear(self)

    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
    
    self:_removeAction()
end

function QUIDialogMailContent:onTouchEvent(event)
    if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
        self:moveTo(event.distance.y, true)
    elseif event.name == "began" then
        self:_removeAction()
        self._startY = event.y
        self._pageY = self._boxContent:getPositionY()
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

function QUIDialogMailContent:_removeAction()
    if self._actionHandler ~= nil then
        self._boxContent:stopAction(self._actionHandler)       
        self._actionHandler = nil
    end
end

function QUIDialogMailContent:moveTo(posY, isAnimation)
    if isAnimation == false then
        self._boxContent:setPositionY(posY)
        return 
    end

    local contentY = self._boxContent:getPositionY()
    local targetY = 0
    if self._totalHeight <= self._boxHeight then
        targetY = 0
    elseif contentY + posY > self._totalHeight - self._boxHeight then
        targetY = self._totalHeight - self._boxHeight
    elseif contentY + posY < 0 then
        targetY = 0
    else
        targetY = contentY + posY
    end
    self:_contentRunAction(0, targetY)
end

function QUIDialogMailContent:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                                                self:_removeAction()
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._boxContent:runAction(ccsequence)
end

function QUIDialogMailContent:_onTriggerAutoAdd()
	self:_backClickHandler()
end

function QUIDialogMailContent:_onTriggerReceive()
    self._isReceive = true
	self:_backClickHandler()
end

function QUIDialogMailContent:_backClickHandler()
	self:playEffectOut()
end

function QUIDialogMailContent:viewAnimationOutHandler()
    if self._isReceive == true and self.mail.items ~= nil then
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIDialogMailContent.MAIL_EVENT_RECV_AWARD, mail = self.mail })
    end
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogMailContent