local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogRewardRules = class("QUIDialogRewardRules", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetRewardRulesClient = import("..widgets.QUIWidgetRewardRulesClient")

function QUIDialogRewardRules:ctor(options)
  local ccbFile = "ccb/Dialog_RewardRules.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogRewardRules._onTriggerClose)}
  }
  QUIDialogRewardRules.super.ctor(self, ccbFile, callBacks, options)
  self.isAnimation = true
  self.info = options.info
  self:_initHeroPageSwipe()
end

function QUIDialogRewardRules:viewDidAppear()
  QUIDialogRewardRules.super.viewDidAppear(self)
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogRewardRules:viewWillDisappear()
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
end

-- 初始化中间的英雄选择框 swipe工能
function QUIDialogRewardRules:_initHeroPageSwipe()
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

function QUIDialogRewardRules:initPage()
  self._totalHeight = 0
  self.clent = QUIWidgetRewardRulesClient.new({info = self.info})
  self._offsetHeight = 1020
  self._totalHeight = self._offsetHeight
  self._offsetWidth= 700
  self._pageContent:addChild(self.clent)
end

function QUIDialogRewardRules:onTouchEvent(event)
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

function QUIDialogRewardRules:moveTo(posY, isAnimation)
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

function QUIDialogRewardRules:_contentRunAction(posX, posY)
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

function QUIDialogRewardRules:_removeAction()
  -- self:stopEnter()
  if self._actionHandler ~= nil then
    self._pageContent:stopAction(self._actionHandler)   
    self._actionHandler = nil
  end
end

function QUIDialogRewardRules:viewAnimationOutHandler()
  app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogRewardRules:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogRewardRules:_onTriggerClose()
  app.sound:playSound("common_close")
  self:playEffectOut()
end

return QUIDialogRewardRules