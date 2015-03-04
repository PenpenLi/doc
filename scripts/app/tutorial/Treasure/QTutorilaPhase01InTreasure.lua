--
-- Author: Your Name
-- Date: 2014-08-20 18:40:27
--
local QTutorialPhase = import("QTutorialPhase")
local QTutorilaPhase01InTreasure = class("QTutorilaPhase01InTreasure", QTutorialPhase)

local QUIViewController = import("..QUIViewController")
local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")
local QTutorialDirector = import("..QTutorialDirector")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")

QTutorilaPhase01InTreasure.TREASURE_SUCCESS = 2

function QTutorilaPhase01InTreasure:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  self._word = nil
  self._step = 0
  
  local page = app:getNavigationController():getTopPage()
  page:cleanBuildLayer()
  
--  local dialog = app:getNavigationTopLayerController():getTopDialog()
--  if dialog ~= nil then
--   app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
--  end
  
  self:stepManager()
end
--步骤管理
function QTutorilaPhase01InTreasure:stepManager()
  if self._step == 0 then
    self:_guideStart()
  elseif self._step == 1 then
    self:_waitCklic1()
  elseif self._step == 2 then
    self:_waitCklic3()
  elseif self._step == 3 then
    self:_guideClickTreasure()
  elseif self._step == 4 then
    self:_openCheast()
  elseif self._step == 5 then
    self:_guideGoldCheast()
  elseif self._step == 6 then
    self:_openGoldCheast()
  elseif self._step == 7 then
    self:_openReward()
  elseif self._step == 8 then 
    self:_waitClickOther()
  elseif self._step == 9 then
    self:_waitClick()
  elseif self._step == 10 then
    self:_closeReward()
  elseif self._step == 11 then
    self:_closeBuy()
  elseif self._step == 12 then
    self:_closeCheast()
  end
end
--引导开始
function QTutorilaPhase01InTreasure:_guideStart()

  --添加一次判断如果有这个英雄了 则直接跳过抽宝箱的新手引导
  --  local luckyAward = QStaticDatabase:sharedDatabase():getLuckyDraw("黄金宝箱免费第一次")
  if remote.herosUtil:getHeroByID(10001) ~= nil then
    local stage = app.tutorial:getStage()
    stage.forcedGuide = QTutorilaPhase01InTreasure.TREASURE_SUCCESS
    app.tutorial:setStage(stage)
    app.tutorial:setFlag(stage)
    self:finished()
    return
  end

--  if self._handTouch == nil then
--    self._handTouch = QUIWidgetTutorialHandTouch.new({word = "进入酒馆", direction = "up"})
--    self._handTouch:handLeftDown()
--    self._handTouch:tipsRightDown()
--    app.tutorialNode:addChild(self._handTouch)
--    self._handTouch:setVisible(false)
--  end
  
  self._perCP = ccp(display.width/2, display.height/2)
  
  self._word = "真是情深意浓的一对~让人又相信爱情了呢\\╮(╯▽╰)╭"
  self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, sayFun = function()
    self._CP = {x = 0, y = 0}
    self._size = {width = display.width*2, height = display.height*2}
  end})
  self._dialogueRight:setActorImage("ui/tyrande.png")
  app.tutorialNode:addChild(self._dialogueRight)
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 0 then
--      self._step = self._step + 1
--      self:_waitCklic1()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

--引导玩家点击宝箱
function QTutorilaPhase01InTreasure:_waitCklic1()
--  self:clearSchedule()
  if self._word ~= nil then
    self._word = nil
  end
  self._word = "嘛~但是就算是真爱，也不能阻止我们前进的步伐！"
  self._dialogueRight:addWord(self._word)
  self._CP = {x = 0, y = 0}
  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 1 then
--      self._step = self._step + 1
--      self:_waitCklic3()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

function QTutorilaPhase01InTreasure:_waitCklic3()
--  self:clearSchedule()
  if self._word ~= nil then
    self._word = nil
  end
  self._word = "英雄与美酒相伴~快去酒馆勾搭英雄重振你的战队吧~"
  self._dialogueRight:addWord(self._word)
  self._CP = {x = 0, y = 0}
  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 2 then
--      self._step = self._step + 1
--      self:_guideClickTreasure()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

function QTutorilaPhase01InTreasure:_guideClickTreasure()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  local page = app:getNavigationController():getTopPage()
  self._CP = page._ccbOwner.btn_chast:convertToWorldSpaceAR(ccp(0, 0))
  self._size = page._ccbOwner.btn_chast:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "进入酒馆", direction = "up"})
  self._handTouch:setPosition(self._CP.x + 20, self._CP.y + 70)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorilaPhase01InTreasure:_openCheast()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  if page._onCheast == nil then
    self:_jumpToEnd()
    return
  end
  page:_onCheast()
  self:_waitCklic2()
end

function QTutorilaPhase01InTreasure:_waitCklic2()
  self._dialogueRight:setVisible(true)
  if self._word ~= nil then
    self._word = nil
  end
  self._word = "酒香四溢~买一送一~这等好事还等什么呢？快抱一个回家吧~"
  self._dialogueRight:addWord(self._word)
  self._CP = {x = 0, y = 0}
  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 4 then
--      self._step = self._step + 1
--      self:_guideGoldCheast()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
--引导点击查看
function QTutorilaPhase01InTreasure:_guideGoldCheast()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationController():getTopDialog()
  self._CP = self._dialog._ccbOwner.button:convertToWorldSpaceAR(ccp(0, 0))
  self._size = self._dialog._ccbOwner.button:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击查看", direction = "up"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorilaPhase01InTreasure:_openGoldCheast()
  self._handTouch:removeFromParent()
  if self._dialog.goldViewHandler == nil then
    self:_jumpToEnd()
    return
  end
  self._dialog:goldViewHandler()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickBuyOne()
  end, 0.5)
end
--引导点击抽取一次
function QTutorilaPhase01InTreasure:_guideClickBuyOne()
  self:clearSchedule()
  self._dialog = app:getNavigationController():getTopDialog()
  self._CP = self._dialog._goldInfo._ccbOwner.button_one:convertToWorldSpaceAR(ccp(0, 0))
  self._size = self._dialog._goldInfo._ccbOwner.button_one:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "确认购买", direction = "down"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
--打开奖励页面
function QTutorilaPhase01InTreasure:_openReward()
  self._handTouch:removeFromParent()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialEvent.EVENT_GOLD_BUYONE, self.closeHeroCard, self)
  if self._dialog._goldInfo._onTriggerBuyOne == nil then
    self:_jumpToEnd()
    return
  end
  self._dialog._goldInfo:_onTriggerBuyOne()

end
--引导点击关闭英雄大图
function QTutorilaPhase01InTreasure:closeHeroCard()
  local stage = app.tutorial:getStage()
  stage.forcedGuide = QTutorilaPhase01InTreasure.TREASURE_SUCCESS
  app.tutorial:setStage(stage)
  app.tutorial:setFlag(stage)
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialEvent.EVENT_GOLD_BUYONE, self.closeHeroCard, self)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = {x = 0, y = 0}
  self._size = {width = display.width*2, height = display.height*2}
end

function QTutorilaPhase01InTreasure:_waitClickOther()
  if self._dialog._backClickHandler == nil then
    self:_jumpToEnd()
    return
  end
  self._dialog:_backClickHandler()
  self._dialogueRight:removeFromParent()
  self:openRewardHandler()
end

function QTutorilaPhase01InTreasure:openRewardHandler()
    if self._word ~= nil then
      self._word = nil
    end
    self._word = "这货虽然长的略抱歉了点~但一看就身经百战！相信我专业的眼光~"
    self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, sayFun = function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end})
    self._dialogueRight:setActorImage("ui/tyrande.png")
    app.tutorialNode:addChild(self._dialogueRight)
    
--    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 8 then
--        self._step = self._step + 1
--        self:_waitClick()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))  
end
--等待玩家点击后对话消失
function QTutorilaPhase01InTreasure:_waitClick()
--  self:clearSchedule()
  self._CP = nil
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideCloseReward()
  end, 0.5)
end
--引导点击确认，返回
function QTutorilaPhase01InTreasure:_guideCloseReward()
  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.btn_back:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击确认", direction = "up"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
--关闭奖励获得页面
function QTutorilaPhase01InTreasure:_closeReward()
  self._handTouch:removeFromParent()
  if self._dialog._onTriggerConfirm == nil then
    self:_jumpToEnd()
    return
  end
  self._dialog:_onTriggerConfirm()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideCloseBuyDialog()
  end, 0.5)
end
--引导
function QTutorilaPhase01InTreasure:_guideCloseBuyDialog()
  self:clearSchedule()
  self._dialog = app:getNavigationController():getTopPage()
  self._CP = self._dialog._ccbOwner.btn_home:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.btn_home:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "返回主界面", direction = "down"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
--关闭购买页面
function QTutorilaPhase01InTreasure:_closeBuy()
  self._handTouch:removeFromParent()
  if self._dialog._onTriggerBack == nil then
    self:_jumpToEnd()
    return
  end
  local page = app:getNavigationController():getTopPage()
  page:checkGuiad()
  self._dialog:_onTriggerBack()
  self._dialogueRight:removeFromParent()
  self:finished()
end

--如果出错则直接跳掉引导过程
function QTutorilaPhase01InTreasure:_jumpToEnd()
    app.tutorial._runingStage:jumpFinished()
    self:finished()
end
--引导点击关闭宝箱页面
--function QTutorilaPhase01InTreasure:_guidecloseCheast()
--  self._dialog = app:getNavigationController():getTopDialog()
--  self._CP = {x = 1140, y = 260}
--  self._size = {width = 100, height = 100}
--  self._handTouch:setPosition(self._perCP.x + 500, self._perCP.y)
--  self._handTouch._ccbOwner.tf_tips1:setPosition(-75,72)
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction((self._CP.x - 500) - self._perCP.x, self._CP.y - self._perCP.y)
--end
--关闭宝箱页面
--function QTutorilaPhase01InTreasure:_closeCheast()
--  self._dialog:_backClickHandler()
--  self._dialogueRight:removeFromParent()
--  self:finished()
--end
--移动到指定位置
function QTutorilaPhase01InTreasure:_nodeRunAction(posX,posY)
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

function QTutorilaPhase01InTreasure:_onTouch(event)
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
--        self._handTouch:setVisible(false)
        self:stepManager()
      end
    end
end
function QTutorilaPhase01InTreasure:clearSchedule()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
end

return QTutorilaPhase01InTreasure
