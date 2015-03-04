local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogSunWellRule = class("QUIDialogSunWellRule", QUIDialog)

local QUIWidgetSunWellRuleClient = import("..widgets.QUIWidgetSunWellRuleClient")
local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")

function QUIDialogSunWellRule:ctor(options)
   local ccbFile = "ccb/Dialog_SunWell_Rule.ccbi"
   local callBack = {
    {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogSunWellRule._onTriggerClose)}
   }
   QUIDialogSunWellRule.super.ctor(self, ccbFile, callBack, options)
   self.isAnimation = true
   self:_initHeroPageSwipe()
end

function QUIDialogSunWellRule:viewDidAppear()
  QUIDialogSunWellRule.super.viewDidAppear(self)
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogSunWellRule:viewWillDisappear()
  if self._touchLayer ~= nil then
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
  end
end

-- 初始化中间的英雄选择框 swipe工能
function QUIDialogSunWellRule:_initHeroPageSwipe()
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

  self:initPage()
end


function QUIDialogSunWellRule:initPage()
  self._totalHeight = 0
  self._client = QUIWidgetSunWellRuleClient.new()
  self._offsetHeight = 360
  self._totalHeight = self._offsetHeight
  self._offsetWidth= 790
  self._pageContent:addChild(self._client)
end


function QUIDialogSunWellRule:onTouchEvent(event)
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

function QUIDialogSunWellRule:moveTo(posY, isAnimation)
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

function QUIDialogSunWellRule:_contentRunAction(posX, posY)
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

function QUIDialogSunWellRule:_removeAction()
  -- self:stopEnter()
  if self._actionHandler ~= nil then
    self._pageContent:stopAction(self._actionHandler)   
    self._actionHandler = nil
  end
end

function QUIDialogSunWellRule:viewAnimationOutHandler()
  app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogSunWellRule:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogSunWellRule:_onTriggerClose()
  app.sound:playSound("common_close")
  self:playEffectOut()
end

return QUIDialogSunWellRule