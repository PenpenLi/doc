local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogVip = class("QUIDialogVip", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetVipClient = import("..widgets.QUIWidgetVipClient")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")

function QUIDialogVip:ctor(options)
  local ccbFile = "ccb/Dialog_Vip.ccbi"
  local callbacks = { 
    {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogVip._onTriggerClose)},
    {ccbCallbackName = "onTriggerLeft", callback = handler(self, QUIDialogVip._onTriggerLeft)},
    {ccbCallbackName = "onTriggerRight", callback = handler(self, QUIDialogVip._onTriggerRight)},
    {ccbCallbackName = "onTriggerRecharge", callback = handler(self, QUIDialogVip._onTriggerRecharge)}
  }
  QUIDialogVip.super.ctor(self, ccbFile, callbacks, options)

  self.vip = 1
  self.moveIsFinished = true
  
  self:resetAll()
  self:_initHeroPageSwipe()
end

function QUIDialogVip:viewDidAppear()
  QUIDialogVip.super.viewDidAppear(self)
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogVip:viewWillDisappear()
  if self._touchLayer ~= nil then
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
  end
end

-- 初始化中间的英雄选择框 swipe工能
function QUIDialogVip:_initHeroPageSwipe()
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

  self:setVipInfo()
  self:setVipContentInfo()
end

function QUIDialogVip:resetAll()
  self._ccbOwner.cur_vip_level:setString(0)
  self._ccbOwner.will_vip_level:setString(0)
  self._ccbOwner.need_token:setString(0)
  self._ccbOwner.vip_left:setString(0)
  self._ccbOwner.vip_right:setString(0)
  
  --暂时关闭充值按钮
  makeNodeFromNormalToGray(self._ccbOwner.recharge)
end

function QUIDialogVip:setVipInfo()
  local chargeToken = 2
  local needToken = 10
  local myVipLevel = 0
  local nextVipLevel = myVipLevel + 1
  self._ccbOwner.cur_vip_level:setString(myVipLevel)
  self._ccbOwner.will_vip_level:setString(nextVipLevel)
  self._ccbOwner.need_token:setString(needToken - chargeToken)
  
  if chargeToken == 0 then
    self._ccbOwner.vip_bar:setScaleX(0)
  else
    self._ccbOwner.vip_bar:setScaleX(chargeToken/needToken)
  end
end

function QUIDialogVip:setVipContentInfo()
  self.vipContent = QUIWidgetVipClient.new({vip = "VIP"..self.vip})
  self._totalHeight = self.vipContent:getContentSize()
  self._pageContent:addChild(self.vipContent)
  self._ccbOwner.left_btn:setVisible(true)
  self._ccbOwner.right_btn:setVisible(true)
  
  if self.vip == 1 then
    self._ccbOwner.left_btn:setVisible(false)
  elseif self.vip == 15 then
    self._ccbOwner.right_btn:setVisible(false)
  end
  self._ccbOwner.vip_level:setString(self.vip)
  self._ccbOwner.vip_left:setString(self.vip - 1)
  self._ccbOwner.vip_right:setString(self.vip + 1)
end

function QUIDialogVip:onTouchEvent(event)
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

function QUIDialogVip:moveTo(posY, isAnimation)
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

function QUIDialogVip:_contentRunAction(posX, posY)
  if posY == self._pageContent:getPositionY() then
    return
  end
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                          self:_removeAction()
                          -- self:onFrame()
                        -- if   self._totalHeight > self._pageHeight and self._scrollShow == true then
                        --  self._ccbOwner.sprite_scroll_cell:runAction(CCFadeOut:create(0.3))
                        --  self._ccbOwner.sprite_scroll_bar:runAction(CCFadeOut:create(0.3))
                        --  self._scrollShow = false
                        -- end
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
    -- self:startEnter()
end

function QUIDialogVip:_removeAction()
  -- self:stopEnter()
  if self._actionHandler ~= nil then
    self._pageContent:stopAction(self._actionHandler)   
    self._actionHandler = nil
  end
end

function QUIDialogVip:_onTriggerLeft()
  if self.vip == 1 then return end
  if self.moveIsFinished == true then
    self:vipContentMoveAnimation("left")
  end
end

function QUIDialogVip:_onTriggerRight()
  if self.vip == 15 or self.moveIsFinished == false then return end
  if self.moveIsFinished == true then
    self:vipContentMoveAnimation("right")
  end
end

--vip特权移动动画
function QUIDialogVip:vipContentMoveAnimation(direction)
  self.moveIsFinished = false
  local oldPostion = ccp(self._pageContent:getPosition())
  local purposePoint = nil
  local originPoint = nil
  if direction == "left" then
    purposePoint = ccp(oldPostion.x - 1000, oldPostion.y)
    originPoint = ccp(oldPostion.x + 2000, oldPostion.y)
    self.vip = self.vip - 1
  elseif direction == "right" then
    self.vip = self.vip + 1
    purposePoint = ccp(oldPostion.x + 1000, oldPostion.y)
    originPoint = ccp(oldPostion.x - 2000, oldPostion.y)
  end
  
  local moveTo = CCMoveTo:create(0.2, purposePoint)
  local func = CCCallFunc:create(function()
      self.vipContent:removeFromParent()
      self:setVipContentInfo()
      self._pageContent:setPosition(originPoint)
      local move = CCMoveTo:create(0.2, ccp(oldPostion.x, oldPostion.y))
      local callFunc = CCCallFunc:create(function()
        self.moveIsFinished = true
      end)
      local actionArray = CCArray:create()
      actionArray:addObject(move)
      actionArray:addObject(callFunc)
      self._pageContent:runAction(CCSequence:create(actionArray))
  end)
  local actionArrayIn = CCArray:create()
  actionArrayIn:addObject(moveTo)
  actionArrayIn:addObject(func)
  local ccsequence = CCSequence:create(actionArrayIn)
  self._pageContent:runAction(ccsequence)
end

function QUIDialogVip:_onTriggerRecharge()
end

function QUIDialogVip:_onTriggerClose()
  app.sound:playSound("common_close")
  app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogVip