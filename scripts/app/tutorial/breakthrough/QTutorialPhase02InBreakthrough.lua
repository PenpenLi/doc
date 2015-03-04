--
-- Author: wkwang
-- Date: 2014-08-13 16:08:30
--
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase02InBreakthrough = class("QTutorialPhase02InBreakthrough", QTutorialPhase)

local QUIDialogBreakthrough = import("...ui.dialogs.QUIDialogBreakthrough")
local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")

--步骤开始
function QTutorialPhase02InBreakthrough:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  
  self._step = 0
  scheduler.performWithDelayGlobal(function()
    self:stepManager()
  end, 0.5)
end

--步骤管理
function QTutorialPhase02InBreakthrough:stepManager()
  if self._step == 0 then
    self:_guideStart()
  elseif self._step == 1 then
    self:_guideClickHeroBreakthrough()
  elseif self._step == 2 then
    self:_openHeroBreakthrough()
  elseif self._step == 3 then
    self:_confrimHeroBreakthrough()
  elseif self._step == 4 then
    self:_confrimHero()
  elseif self._step == 5 then
    self:_closeHeroBreakthrough()
  end
end

--引导开始
function QTutorialPhase02InBreakthrough:_guideStart()

  if remote.herosUtil:checkHerosEquipmentByID("orc_warlord") == false then
    self:finished()
    return
  end

--  if self._handTouch == nil then
--    self._handTouch = QUIWidgetTutorialHandTouch.new()
--    self._handTouch:handLeftDown()
--    self._handTouch:tipsLeftDown()
--    app.tutorialNode:addChild(self._handTouch)
--    self._handTouch:setVisible(false)
--  end
  
  self._perCP = ccp(display.width/2, display.height/2)
  self._word = "勇敢的少年，你终于集齐六件装备，可以华丽丽的突破了~"
  self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word,
    isSay = true, sayFun = function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end})
  self._dialogueRight:setActorImage("ui/tyrande.png")
  app.tutorialNode:addChild(self._dialogueRight)
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 0 then
--      self._step = self._step + 1
--      self:_guideClickHeroBreakthrough()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

--引导玩家点击突破按钮
function QTutorialPhase02InBreakthrough:_guideClickHeroBreakthrough()
--  self:clearSchedule()
  self._dialogueRight:removeFromParent()
--  if self._handTouch ~= nil then
--    self._handTouch = QUIWidgetTutorialHandTouch.new()
--    self._handTouch:handRightDown()
--    self._handTouch:tipsLeftDown()
--    app.tutorialNode:addChild(self._handTouch)
--    self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--    self._handTouch:setVisible(false)
--  end
  
  self._perCP = ccp(display.width/2, display.height/2)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.node_breakthrough:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.node_breakthrough:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击突破按钮", direction = "up"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase02InBreakthrough:_openHeroBreakthrough()
  self._handTouch:removeFromParent()
  self._dialog = self._dialog:_onBreakthrough()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickBreakthrough()
  end, 0.5)
end
--引导玩家点击确定突破英雄
function QTutorialPhase02InBreakthrough:_guideClickBreakthrough()
  self:clearSchedule()
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.bt_confirm:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.bt_confirm:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "确认突破", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase02InBreakthrough:_confrimHeroBreakthrough()
  self._handTouch:removeFromParent()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialEvent.EVENT_HERO_BREAKTHROUGH, self._wordGuide, self)
  self._dialog:_onTriggerConfirm()
end
function QTutorialPhase02InBreakthrough:_wordGuide()
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialEvent.EVENT_HERO_BREAKTHROUGH, self._wordGuide, self)
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    if self._word ~= nil then
       self._word = nil
    end
    self._word = "哇，这就是传说中绅士的力量！为了英雄更加威武雄壮而努力奋战吧~"
    self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = false, text = self._word,
      isSay = true, sayFun = function()
        self._CP = {x = 0, y = 0}
        self._size = {width = display.width*2, height = display.height*2}
      end})
    self._dialogueRight:setActorImage("ui/tyrande.png")
    app.tutorialNode:addChild(self._dialogueRight)
  end, 2)
-- self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 3 then
--      self._step = self._step + 1
--      self._CP = nil
--      self:_confrimHero()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

function QTutorialPhase02InBreakthrough:_confrimHero()
  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self:_confrimHeroBreakSuccess()
end

--引导玩家点击关闭按钮
function QTutorialPhase02InBreakthrough:_confrimHeroBreakSuccess()
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.btn_close:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.btn_close:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击关闭", direction = "down"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
  --  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)

end

function QTutorialPhase02InBreakthrough:_closeHeroBreakthrough()
  self._handTouch:removeFromParent()
  self._dialog:_onTriggerClose()
  self._dialogueRight:removeFromParent()
  self:finished()
end
-- 移动到指定位置
function QTutorialPhase02InBreakthrough:_nodeRunAction(posX,posY)
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

function QTutorialPhase02InBreakthrough:_onTouch(event)
  if event.name == "began" then
    return true
  elseif event.name == "ended" then
    if self._dialogueRight ~= nil and self._dialogueRight._isSaying == true and self._dialogueRight:isVisible() then 
        self._dialogueRight:printAllWord(self._word)
--        self._dialogueRight._ccbOwner.label_text:setString(q.autoWrap(self._word,29,16,504))
    elseif self._CP ~= nil and event.x >=  self._CP.x - self._size.width/2 and event.x <= self._CP.x + self._size.width/2 and
      event.y >=  self._CP.y - self._size.height/2 and event.y <= self._CP.y + self._size.height/2  then
      self._step = self._step + 1
      self._perCP = self._CP
      self._CP = nil
--      self._handTouch:setVisible(false)
      self:stepManager()
    end
  end
end

function QTutorialPhase02InBreakthrough:clearSchedule()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
end

return QTutorialPhase02InBreakthrough
