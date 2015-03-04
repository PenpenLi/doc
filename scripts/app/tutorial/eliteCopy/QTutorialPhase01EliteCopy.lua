local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01EliteCopy = class("QTutorialPhase01EliteCopy", QTutorialPhase)

local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

function QTutorialPhase01EliteCopy:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  self._step = 0
  
  local stage = app.tutorial:getStage()
  stage.temaBoxGuide = 1
  app.tutorial:setStage(stage)
  app.tutorial:setFlag(stage)

  if self._handTouch == nil then
    self._handTouch = QUIWidgetTutorialHandTouch.new()
    self._handTouch:handLeftDown()
    self._handTouch:tipsLeftDown()
    app.tutorialNode:addChild(self._handTouch)
    self._perCP = ccp(display.width/2, display.height/2)
    self._handTouch:setVisible(false)
  end
  
  self:stepManager()
  
end
--步骤管理
function QTutorialPhase01EliteCopy:stepManager()
  if self._step == 0 then
    self:_guideStart()
  elseif self._step == 1 then
    self:_guideBackIntance()
  elseif self._step == 2 then
    self:waitClick()
  elseif self._step == 3 then
    self:_openEliteCopy()
  end
end
function QTutorialPhase01EliteCopy:_guideStart()
  self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = "好厉害~二十级就可以去精英副本了，有更多宝物等着你哦~",
    isSay = true, sayFun = function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end})
  self._dialogueRight:setActorImage("ui/tyrande.png")
  app.tutorialNode:addChild(self._dialogueRight)
  
  scheduler.performWithDelayGlobal(function()
    if self._step == 0 then
      self._step = self._step + 1
      self:_guideBackIntance()
    end
  end, 2)
end

function QTutorialPhase01EliteCopy:_guideBackIntance()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationController():getTopDialog()
  
  if self._dialog.class.__cname == ".QUIDialogInstance" then
      self._step = self._step + 1
     self:_guideClickEliteBtn()
  else
    self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
    self._size = self._dialog._ccbOwner.btn_back:getContentSize()
    self._handTouch:setPosition(self._perCP.x, self._perCP.y)
    self._handTouch:setVisible(true)
    self._handTouch:handRightDown()
    self._handTouch:tipsRightDown()
    self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
  end
end

function QTutorialPhase01EliteCopy:waitClick()
  self._dialog:_onTriggerBack()
  scheduler.performWithDelayGlobal(function()
    self:_guideClickEliteBtn()
  end, 0.5)
end

function QTutorialPhase01EliteCopy:_guideClickEliteBtn()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationController():getTopDialog()
    self._CP = self._dialog._ccbOwner.btn_elite:convertToWorldSpaceAR(ccp(0,0))
    self._size = self._dialog._ccbOwner.btn_elite:getContentSize()
    self._handTouch:setPosition(self._perCP.x, self._perCP.y)
    self._handTouch:setVisible(true)
    self._handTouch:handRightDown()
    self._handTouch:tipsRightUp()
    self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01EliteCopy:_openEliteCopy()
  self._dialog:_onTriggerElite()
  self:_finishing()
end
--引导结束
function QTutorialPhase01EliteCopy:_finishing()
  self._dialogueRight:removeFromParent()
  self:finished()
end

--移动到指定位置
function QTutorialPhase01EliteCopy:_nodeRunAction(posX,posY)
  self._isMove = true
  local actionArrayIn = CCArray:create()
  actionArrayIn:addObject(CCMoveBy:create(0.2, ccp(posX,posY)))
  actionArrayIn:addObject(CCCallFunc:create(function ()
    self._isMove = false
    self._actionHandler = nil
  end))
  local ccsequence = CCSequence:create(actionArrayIn)
  self._actionHandler = self._handTouch:runAction(ccsequence)
end

function QTutorialPhase01EliteCopy:_onTouch(event)
  if event.name == "began" then
    return true
  elseif event.name == "ended" then
    if self._CP ~= nil and event.x >=  self._CP.x - self._size.width/2 and event.x <= self._CP.x + self._size.width/2 and
      event.y >=  self._CP.y - self._size.height/2 and event.y <= self._CP.y + self._size.height/2  then
      self._step = self._step + 1
      self._perCP = self._CP
      self._CP = nil
      self._handTouch:setVisible(false)
      self:stepManager()
    end
  end
end

return QTutorialPhase01EliteCopy
