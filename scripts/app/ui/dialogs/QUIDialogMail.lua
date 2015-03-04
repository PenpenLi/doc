
local QUIDialog = import(".QUIDialog")
local QUIDialogMail = class(".QUIDialogMail", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QRemote = import("...models.QRemote")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetMailSheet = import("..widgets.QUIWidgetMailSheet")
local QUIDialogMailContent = import("..dialogs.QUIDialogMailContent")
local QUIViewController = import("..QUIViewController")

-- 邮件对话框
function QUIDialogMail:ctor(options)
	local ccbFile = "ccb/Dialog_Email.ccbi"
    self._mailSheets = {}

	local callBacks = {
		{ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogMail._onTriggerClose)}
    }
    QUIDialogMail.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = true --是否动画显示

    self:_initMailScrollBox()
end

function QUIDialogMail:viewDidAppear()
	QUIDialogMail.super.viewDidAppear(self)

    self._remoteProxy = cc.EventProxy.new(remote.mails)
    self._remoteProxy:addEventListener(remote.mails.MAILS_UPDATE_EVENT, handler(self, self._onEvent))

    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetMailSheet.MAIL_EVENT_CLICK, self._onEvent,self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogMailContent.MAIL_EVENT_RECV_AWARD, self._onEvent,self)
    -- self:_hideMailContent()

    -- app:getClient():mailList()
    self:_updateMailBox()

    self._touchLayer:enable()
    self._touchLayer:setAttachSlide(true)
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogMail:viewWillDisappear()
	QUIDialogMail.super.viewWillDisappear(self)
	self._remoteProxy:removeAllEventListeners()

    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()

    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetMailSheet.MAIL_EVENT_CLICK, self._onEvent,self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogMailContent.MAIL_EVENT_RECV_AWARD, self._onEvent,self)
    
    self:_removeAction()
end

-- 初始化邮箱
function QUIDialogMail:_initMailScrollBox()
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

end

function QUIDialogMail:_updateMailBox()
    if remote.mails == nil then
        return
    end

    local index = 0
    self._totalHeight = 0
    self._mailSheets = {}
    self._boxContent:removeAllChildren()
    for _, mail in pairs(remote.mails:getMails()) do
        local mailSheet = self:_createMailSheet(index, mail):getView()
        self._boxContent:addChild(mailSheet)
        self._totalHeight = self._totalHeight + self._boxSheetHeight
        index = index + 1
        self._mailSheets[#self._mailSheets + 1] = mailSheet
    end
    self._totalMailCount = index
end

function QUIDialogMail:_createMailSheet(index, mail)
    local widget = QUIWidgetMailSheet.new({mail = mail})
    self._boxSheetHeight = widget._ccbOwner.layout:getContentSize().height
    widget:getView():setPositionX(self._ccbOwner.sheet_layout:getPositionX() + widget._ccbOwner.layout:getContentSize().width / 2)
    widget:getView():setPositionY(self._ccbOwner.sheet_layout:getPositionY() + self._boxHeight - widget._ccbOwner.layout:getContentSize().height / 2 - index * widget._ccbOwner.layout:getContentSize().height)
    return widget
end

function QUIDialogMail:_recvMailAward(mail)
    app:getClient():mailRecvAward(mail.mailId, function ()
        remote.mails:removeMailsForId(mail.mailId)
    end)
end

function QUIDialogMail:_showMailContent(mail)
    if mail.readed == false then
        app:getClient():mailRead(mail.mailId, function ()
            app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogMailContent", options = {mail = mail}}, {isPopCurrentDialog = false})
        end)
        mail.readed = true
    else
        app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogMailContent", options = {mail = mail}}, {isPopCurrentDialog = false})
    end
end

-- 移动MailBox
function QUIDialogMail:_mailBoxMove()
    if self._totalMailCount == 0 then
        return
    end

    self._boxContent:setPositionY(self._boxContent:getPositionY() + self._deltaY)
end

-- 向上的一个简单地移动动画
function QUIDialogMail:_mailBoxUp()
    if self._isAnimRunning == true or self._totalMailCount == 0 then
        return
    end
    local offsetY = 0
    if self._boxSheetHeight + self._boxContent:getPositionY() < self._boxOriginY + self._boxHeight then
        if self._boxSheetHeight > self._boxHeight then
            offsetY = self._boxOriginY + self._boxHeight - (self._boxSheetHeight + self._boxContent:getPositionY())
        else
            offsetY = offsetY - self._boxContent:getPositionY()
        end
    end
    self:_contentRunAction(0,offsetY)
end

-- 向下的一个简单地移动动画
function QUIDialogMail:_mailBoxDown()
    if self._isAnimRunning == true or self._totalMailCount == 0 then
        return
    end
    local offsetY = 0
    if self._boxContent:getPositionY() < self._boxOriginY then
        offsetY = offsetY - self._boxContent:getPositionY()
    end
    self:_contentRunAction(0,offsetY)

end

-- 移动到指定位置
function QUIDialogMail:_contentRunAction(posX,posY)
    self._isAnimRunning = true
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveBy:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                                                self._isAnimRunning = false
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._boxContent:runAction(ccsequence)
end

-- 处理邮箱事件
function QUIDialogMail:_onEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == remote.mails.MAILS_UPDATE_EVENT then
        self:_updateMailBox()
    elseif event.name == QUIWidgetMailSheet.MAIL_EVENT_CLICK then
        self:_showMailContent(event.mail)
    elseif event.name == QUIDialogMailContent.MAIL_EVENT_RECV_AWARD then
        self:_recvMailAward(event.mail)
    end
end

function QUIDialogMail:onTouchEvent(event)
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
            for _, mailSheet in pairs(self._mailSheets) do
                mailSheet:setBtnDisable()
            end
        end
        self:moveTo(offsetY, false)
    elseif event.name == "ended" then
        scheduler.performWithDelayGlobal(function ()
            self._isMove = false
            end,0)
    end
end

function QUIDialogMail:_removeAction()
    -- self:stopEnter()
    if self._actionHandler ~= nil then
        self._boxContent:stopAction(self._actionHandler)       
        self._actionHandler = nil
    end
end

function QUIDialogMail:moveTo(posY, isAnimation)
    -- self._ccbOwner.sprite_scroll_cell:stopAllActions()
    -- self._ccbOwner.sprite_scroll_bar:stopAllActions()
    -- if  self._totalHeight <= self._pageHeight or (math.abs(posY) < 1 and self._scrollShow == false) then
    --     self._ccbOwner.sprite_scroll_cell:setOpacity(0)
    --     self._ccbOwner.sprite_scroll_bar:setOpacity(0)
    -- else
    --     self._ccbOwner.sprite_scroll_cell:setOpacity(255)
    --     self._ccbOwner.sprite_scroll_bar:setOpacity(255)
    --     self._scrollShow = true
    -- end
    if isAnimation == false then
        self._boxContent:setPositionY(posY)
        -- self:onFrame()
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

function QUIDialogMail:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                                                self:_removeAction()
                                                -- self:onFrame()
                                                -- if  self._totalHeight > self._pageHeight and self._scrollShow == true then
                                                --     self._ccbOwner.sprite_scroll_cell:runAction(CCFadeOut:create(0.3))
                                                --     self._ccbOwner.sprite_scroll_bar:runAction(CCFadeOut:create(0.3))
                                                --     self._scrollShow = false
                                                -- end
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._boxContent:runAction(ccsequence)
    -- self:startEnter()
end

function QUIDialogMail:_backClickHandler()
    self:_onTriggerClose()
end

-- 关闭对话框
function QUIDialogMail:_onTriggerClose()
    app.sound:playSound("common_close")
    self:playEffectOut()
end

function QUIDialogMail:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogMail
