local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogDailySignIn = class("QUIDialogDailySignIn", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetDailySignIn = import("..widgets.QUIWidgetDailySignIn")
local QUIWidgetDailySignInBox = import("..widgets.QUIWidgetDailySignInBox")
local QUIWidgetDialySignInStack = import("..widgets.QUIWidgetDialySignInStack")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIViewController = import("..QUIViewController")
local QRemote = import("...models.QRemote")
local QUIDialogDailySignInComplete = import("..dialogs.QUIDialogDailySignInComplete")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIDialogAddUpSignInComplete = import("..dialogs.QUIDialogAddUpSignInComplete")

function QUIDialogDailySignIn:ctor(options)
  local ccbFile = "ccb/Dialog_DailySignIn.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogDailySignIn._onTriggerClose)},
    {ccbCallbackName = "onTriggerRewardDec", callback = handler(self, QUIDialogDailySignIn._onTriggerRewardDec)}
  }
  QUIDialogDailySignIn.super.ctor(self, ccbFile, callBacks, options)

  self._ccbOwner.node_shadow_bottom:setVisible(true)
  self._ccbOwner.node_shadow_top:setVisible(false)
  
  --初始化累计签到
  self.stackSign = QUIWidgetDialySignInStack.new()
  self._ccbOwner.stack_node:addChild(self.stackSign)
  
  self:_initPageSwipe()
end

function QUIDialogDailySignIn:viewDidAppear()
  QUIDialogDailySignIn.super.viewDidAppear(self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetDailySignInBox.EVENT_CLICK, self._onTriggerClickItme, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogDailySignInComplete.SIGN_SUCCEED, self._onRefreshInfo, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogAddUpSignInComplete.RECEIVE_SUCCEED, self.signSuccess, self)
  if self._touchLayer ~= nil then
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
  end
end

function QUIDialogDailySignIn:viewWillDisappear()
  QUIDialogDailySignIn.super.viewWillDisappear(self)
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetDailySignInBox.EVENT_CLICK, self._onTriggerClickItme, self)
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogDailySignInComplete.SIGN_SUCCEED, self._onRefreshInfo, self)
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogAddUpSignInComplete.RECEIVE_SUCCEED, self.signSuccess, self)
  if self._touchLayer ~= nil then
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
  end
end

-- 初始化中间的物品框 swipe工能
function QUIDialogDailySignIn:_initPageSwipe()
  self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
  self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
  self._pageContent = CCNode:create()
  self._orginalPosition = ccp(self._pageContent:getPosition())

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
  self._touchLayer:attachToNode(self._ccbOwner.sheet,self._pageWidth, self._pageHeight, self._ccbOwner.sheet_layout:getPositionX(), self._ccbOwner.sheet_layout:getPositionY(), handler(self, self.onTouchEvent))

  self._isAnimRunning = false
  self:_initTime()
  self:_initItme()
end

function QUIDialogDailySignIn:_initTime()
  remote.daily:checkSignTime()
  local currTime = os.date("*t", q.serverTime())
  local month = 0
  if currTime["month"] < 10 then
    month = "0"..currTime["month"]
  else
    month = currTime["month"]
  end
  self.time = currTime["year"].."_"..month

  self.signNum, self.signTime = remote.daily:getDailySignIn() 
  self._ccbOwner.sign_num:setString(self.signNum)
  self._ccbOwner.tf_title:setString(currTime["month"].."月签到奖励")
end

function QUIDialogDailySignIn:_initItme()
  self._itmeBox = QUIWidgetDailySignIn.new({time = self.time, signNum = self.signNum, visibleHeight = self._pageHeight})
  self._offsetHeight = self._itmeBox:getBgSize().height
  self._totalHeight = self._offsetHeight
  self._offsetWidth= self._itmeBox:getBgSize().width
  self._pageContent:addChild(self._itmeBox)
  self:moveToIsReady()
end

function QUIDialogDailySignIn:moveToIsReady()
  local index, boxNum = self._itmeBox:getSignPosition()
  local boxSize = self._itmeBox.itmeBox[1]:getBoxSize()
  local positionY = nil
  if index ~= nil and boxNum ~= nil then
    local maxIndex = (boxNum > 30) and 5 or 4
    if index < 2 then
      return
    elseif index >= 2 and index < maxIndex then
      positionY = self._orginalPosition.y + (index - 1) * boxSize.width + index * 13
    elseif index >= maxIndex then
      positionY = self._totalHeight - self._pageHeight + self._orginalPosition.y
    end
    local moveTo = CCMoveTo:create(0.3, ccp(self._orginalPosition.x, positionY))
    local array = CCArray:create()
    array:addObject(moveTo)
    self._pageContent:runAction(CCSequence:create(array))
  end

end

-- 处理各种touch event
function QUIDialogDailySignIn:onTouchEvent(event)
  if event == nil or event.name == nil then
    return
  end
  if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
    self:moveTo(event.distance.y, true)
  elseif event.name == "began" then
    self._isMove = false
    self:_removeAction()
    self._startY = event.y
    self._pageY = self._pageContent:getPositionY()
  elseif event.name == "moved" then
    local offsetY = self._pageY + event.y - self._startY
    if offsetY < self._orginalPosition.y then
      self._ccbOwner.node_shadow_bottom:setVisible(true)
      self._ccbOwner.node_shadow_top:setVisible(false)
      offsetY = self._orginalPosition.y
    elseif offsetY > (self._totalHeight - self._pageHeight + self._orginalPosition.y) then
      offsetY = (self._totalHeight - self._pageHeight + self._orginalPosition.y)
      self._ccbOwner.node_shadow_bottom:setVisible(false)
      self._ccbOwner.node_shadow_top:setVisible(true)
    else
      self._ccbOwner.node_shadow_bottom:setVisible(true)
      self._ccbOwner.node_shadow_top:setVisible(true)
    end
    if math.abs(event.y - self._startY) > 10 then
      self._isMove = true
    end
    self:moveTo(offsetY, false)
    self._itmeBox:updateVisibleRange(self._pageContent:getPositionY())
    self._offsetHeight = self._itmeBox:getBgSize().height
    self._totalHeight = self._offsetHeight
  elseif event.name == "ended" then
    scheduler.performWithDelayGlobal(function ()
      self._isMove = false
    end,0)
  end
end

function QUIDialogDailySignIn:moveTo(posY, isAnimation)
  --   self._ccbOwner.sprite_scroll_cell:stopAllActions()
  --   self._ccbOwner.scroll_bar:stopAllActions()
  --   if   self._totalHeight <= self._pageHeight or (math.abs(posY) < 1 and self._scrollShow == false) then
  --    self._ccbOwner.sprite_scroll_cell:setOpacity(0)
  --    self._ccbOwner.scroll_bar:setOpacity(0)
  --   else
  --    self._ccbOwner.sprite_scroll_cell:setOpacity(255)
  --    self._ccbOwner.scroll_bar:setOpacity(255)
  --    self._scrollShow = true
  --   end
  if isAnimation == false then
    self._pageContent:setPositionY(posY)
    self:onFrame()
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

function QUIDialogDailySignIn:_contentRunAction(posX,posY)
  local actionArrayIn = CCArray:create()
  actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
  actionArrayIn:addObject(CCCallFunc:create(function ()
    self:_removeAction()
    self:onFrame()
    if   self._totalHeight > self._pageHeight and self._scrollShow == true then
    --                          self._ccbOwner.sprite_scroll_cell:runAction(CCFadeOut:create(0.3))
    --                          self._ccbOwner.scroll_bar:runAction(CCFadeOut:create(0.3))
    --                          self._scrollShow = false
    end
  end))
  local ccsequence = CCSequence:create(actionArrayIn)
  self._actionHandler = self._pageContent:runAction(ccsequence)
  self:startEnter()
end

function QUIDialogDailySignIn:_removeAction()
  self:stopEnter()
  if self._actionHandler ~= nil then
    self._pageContent:stopAction(self._actionHandler)
    self._actionHandler = nil
  end
end

function QUIDialogDailySignIn:startEnter()
  self:stopEnter()
  self._onFrameHandler = scheduler.scheduleGlobal(handler(self, self.onFrame), 0)
end

function QUIDialogDailySignIn:stopEnter()
  if self._onFrameHandler ~= nil then
    scheduler.unscheduleGlobal(self._onFrameHandler)
    self._onFrameHandler = nil
  end
end

function QUIDialogDailySignIn:onFrame()
--  local contentY = self._pageContent:getPositionY()
-- for index,value in pairs(self._virtualBox) do
--  if value.posY + contentY < -self._pageHeight + self._offsetY or value.posY + contentY > -self._offsetY then
--    self:setBox(value.icon)
--      value.icon = nil
--  end
-- end
-- for index,value in pairs(self._virtualBox) do
--  if value.posY + contentY >= -self._pageHeight + self._offsetY and value.posY + contentY <= -self._offsetY then
--    if value.icon == nil then
--        value.icon = self:getBox()
--        value.icon:setPosition(value.posX, value.posY)
--        value.icon:setVisible(true)
--        value.icon:resetAll()
--        value.icon:setGoodsInfo(value.info.type, ITEM_TYPE.ITEM, value.info.count)
--    end
--  end
-- end
--   if   self._totalHeight > self._pageHeight and contentY > 0 and contentY <= self._totalHeight - self._pageHeight then
--    local cellY = self._scrollH  * (1 - math.abs(contentY) / math.abs(self._totalHeight - self._pageHeight + 52)) - self._cellH/2
--    self._ccbOwner.sprite_scroll_cell:setPositionY(cellY)
--   end
end

--签到成功
function QUIDialogDailySignIn:_onRefreshInfo(data)
  if data.index ~= nil then
    self._itmeBox.itmeBox[data.index]:setSignIsDone()
    self:_initTime()
    local page = app:getNavigationController():getTopPage()
    page:_checkRedTip()
    self:signSuccess()
  end
end

--领取累积签到成功
function QUIDialogDailySignIn:signSuccess()
    self.stackSign:setSignNum()
    local page = app:getNavigationController():getTopPage()
    page:_checkRedTip()
end

function QUIDialogDailySignIn:_onTriggerClickItme(data)
  if self._isMove == false and data.itemType == nil then
    printInfo(data.state)
    app.sound:playSound("common_item")    
    if data.state == "IS_READY" then
      app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignInComplete" , options = {type = data.type, id = data.id, num = data.num, index = data.index}},
        {isPopCurrentDialog = false})
    else
      if data.type == ITEM_TYPE.MONEY or data.type == ITEM_TYPE.TOKEN_MONEY then
        app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignInCurrencyPrompt" , options = {type = data.type, index = data.index}},
          {isPopCurrentDialog = false})
      else
        local itemInfo = QStaticDatabase.sharedDatabase():getItemByID(data.id)
        if itemInfo.type == 3 then
          app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignInChipPrompt" , options = {itemInfo = itemInfo, id = data.id, index = data.index}},
            {isPopCurrentDialog = false})
        elseif itemInfo.type == 4 then
          app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignInItemPrompt" , options = {itemInfo = itemInfo, id = data.id, index = data.index}},
            {isPopCurrentDialog = false})
        end
      end
    end
  end
end

function QUIDialogDailySignIn:_onTriggerRewardDec()
  app.sound:playSound("common_others")
  app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignInRewardExplain"}, {isPopCurrentDialog = false})
end

function QUIDialogDailySignIn:_onTriggerClose()
  app.sound:playSound("common_close")
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogDailySignIn
