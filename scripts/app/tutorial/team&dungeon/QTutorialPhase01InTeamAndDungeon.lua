--
-- Author: wkwang
-- Date: 2014-08-11 11:22:48
--
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01InTeamAndDungeon = class("QTutorialPhase01InTeamAndDungeon", QTutorialPhase)

local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QTutorialDirector = import("..QTutorialDirector")
local QTeam = import("...utils.QTeam")
local QNavigationController = import("...controllers.QNavigationController")

QTutorialPhase01InTeamAndDungeon.ADD_HERO_TEAM = 0.5

function QTutorialPhase01InTeamAndDungeon:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  self._word = nil 
  
  local page = app:getNavigationController():getTopPage()
  page:cleanBuildLayer()
  
  printInfo("Tutorial began")
  local dialog = app:getNavigationMidLayerController():getTopDialog()
  if dialog ~= nil then
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
  end
  
--  if self._handTouch == nil then
--    self._handTouch = QUIWidgetTutorialHandTouch.new()
--    self._handTouch:handLeftDown()
--    self._handTouch:tipsLeftDown()
--    app.tutorialNode:addChild(self._handTouch)
--    self._handTouch:setVisible(false)
--  end
  
  local page = app:getNavigationController():getTopDialog()
  if page.class.__cname == ".QUIDialogInstance" then
     self._step = 3
     self:_guideClickCopy()
  else
     self._step = 1
     self:stepManager()
  end
--  if app.tutorial:getStage() >= QTutorialDirector.Stage_3_TeamAndDungeon - QTutorialPhase01InTeamAndDungeon.ADD_HERO_TEAM then
--     local dialogName = app:getNavigationController():getTopDialog().class.__cname
--    if dialogName == ".QUIDialogInstance" then
--      self._step = 8
--      self:_guideClickCopy()
--    else
--      self._step = 7
--    self:_guideClickMap()
--    end
--  else
--  end
end

function QTutorialPhase01InTeamAndDungeon:stepManager()
  if self._step == 1 then
    self:_guideStart()
--  elseif self._step == 2 then
--    self:_guideClickScaling()
--  elseif self._step == 3 then
--    self:_openScaling()
--  elseif self._step == 4 then
--    self:_openTeam()
--  elseif self._step == 5 then
--    self:_addHeroToTeam()
--  elseif self._step == 6 then
--    self:_waitClick()
--  elseif self._step == 7 then
--    self:_backViewFromTeamView()
  elseif self._step == 2 then
    self:_guideClickMap()
  elseif self._step == 3 then
    self:_openMap()
--  elseif self._step == 4 then
--    self:waitClick2()
  elseif self._step == 4 then
    self:_openCopy()
  elseif self._step == 5 then
    self:_next()
  elseif self._step == 6 then
    self:guideClickHero()
  elseif self._step == 7 then
    self:_addHeroToTeam()
  elseif self._step == 8 then
    self:_waitClick()
  elseif self._step == 9 then
    self:startBattle()
  end
end
--引导开始
function QTutorialPhase01InTeamAndDungeon:_guideStart()
  self._word = "勇敢的少年，开启新世界的征程吧！ "
  self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word,
    isSay = true, sayFun = function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end})
  self._dialogueRight:setActorImage("ui/tyrande.png")
  app.tutorialNode:addChild(self._dialogueRight)
  printInfo("This is Tutorial")

--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 1 then
--        self._step = self._step + 1
--        self:_guideClickMap()
--      end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
--引导玩家点击伸缩按钮
--function QTutorialPhase01InTeamAndDungeon:_guideClickScaling()
--  self._layer:setVisible(false)
--  self._dialogueRight:setVisible(false)
--  local page = app:getNavigationController():getTopPage()
--  self._CP = page._scaling._ccbOwner.button_scaling:convertToWorldSpaceAR(ccp(0,0))
--  self._size = page._scaling._ccbOwner.button_scaling:getContentSize()
--  self._perCP = ccp(display.width/2, display.height/2)
--  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--function QTutorialPhase01InTeamAndDungeon:_openScaling()
--  local page = app:getNavigationController():getTopPage()
--  page._scaling:_onTriggerOffSideMenu()
--  scheduler.performWithDelayGlobal(function()
--    self:_guideClickTeam()
--  end,0.5)
--end
--
--引导玩家点击阵容按钮
--function QTutorialPhase01InTeamAndDungeon:_guideClickTeam()
--  local page = app:getNavigationController():getTopPage()
--  self._CP = page._scaling._ccbOwner.btn_team:convertToWorldSpaceAR(ccp(0,0))
--  self._size = page._scaling._ccbOwner.btn_team:getContentSize()
--  self._handTouch:setVisible(true)
--  self._handTouch:handLeftDown()
--  self._handTouch:tipsLeftUp()
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--
--function QTutorialPhase01InTeamAndDungeon:_openTeam()
--  local page = app:getNavigationController():getTopPage()
--  self._dialog = page._scaling:_onButtondownSideMenuTeam()
--  -- self._dialog:addEventListener(EVENT_COMPLETED, handler(self, self._guideClickHero))
--  self:_guideClickHero()
--end
--
--引导玩家点击英雄
--function QTutorialPhase01InTeamAndDungeon:_guideClickHero()
--  --  self._dialog:removeEventListener(EVENT_COMPLETED, handler(self, self._guideClickHero))
--  local heros = self._dialog._page:getHeroFrames()
--  if #heros > 0 then
--    self._widget = heros[#heros]
--    self._CP = self._widget._ccbOwner.btn_hero_head:convertToWorldSpaceAR(ccp(0,0))
--    self._size = self._widget._ccbOwner.btn_hero_head:getContentSize()
--    self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--    self._handTouch:setVisible(true)
--    self._handTouch:handRightDown()
--    self._handTouch:tipsLeftDown()
--    self:_nodeRunAction((self._CP.x) - self._perCP.x, (self._CP.y) - self._perCP.y)
--  end
--end
--
--function QTutorialPhase01InTeamAndDungeon:_addHeroToTeam()
--  self._dialog:_addHeroToTeam(self._dialog._herosID[1])
--  scheduler.performWithDelayGlobal(function()
--    self._layer:setVisible(true)
--    self._dialogueRight:setVisible(true)
--    self._dialogueRight:addWord("一切准备就绪，GOGOGO", function()
--    self._CP = {x = 0, y = 0}
--    self._size = {width = display.width*2, height = display.height*2}
--    app.tutorial:setStage(app.tutorial:getStage() + QTutorialPhase01InTeamAndDungeon.ADD_HERO_TEAM)
--    remote.flag:set(remote.flag.FLAG_TUTORIAL_STAGE, app.tutorial:getStage())
--    end)
--  end, 0.5)
--end
--等待玩家点击后对话消失
--function QTutorialPhase01InTeamAndDungeon:_waitClick()
--  self:_guideBackMain()
--end
--
--引导玩家点击返回
--function QTutorialPhase01InTeamAndDungeon:_guideBackMain()
--  self._layer:setVisible(false)
--  self._dialogueRight:removeFromParent()
--  self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
--  self._size = self._dialog._ccbOwner.btn_back:getContentSize()
--  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--  self._handTouch:handRightDown()
--  self._handTouch:tipsRightDown()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--
--function QTutorialPhase01InTeamAndDungeon:_backViewFromTeamView()
--  self._dialog:_onTriggerBack()
--  self._dialog = nil
--  self:_guideClickMap()
--end

--引导玩家点击地图按钮
function QTutorialPhase01InTeamAndDungeon:_guideClickMap()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  local page = app:getNavigationController():getTopPage()
  self._CP = page._ccbOwner.btn_instance:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._ccbOwner.btn_instance:getContentSize()
  self._perCP = ccp(display.width/2, display.height/2)
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "进入副本", direction = "right"})
  self._handTouch:setPosition(self._CP.x, self._CP.y + 30)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InTeamAndDungeon:_openMap()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  page:_onInstance()
  self._dialogueRight:removeFromParent()
  self:waitClick2()
end

--function QTutorialPhase01InTeamAndDungeon:waitClick1()
--    if self._word ~= nil then
--       self._word = nil
--    end
--    self._word = "选择一个关卡挑战吧 "
--    self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word,
--    isSay = true, sayFun = nil})
--    self._dialogueRight:setActorImage("ui/tyrande.png")
--    app.tutorialNode:addChild(self._dialogueRight)
--    
--    self._CP = {x = 0, y = 0}
--    self._size = {width = display.width*2, height = display.height*2}
--    
--    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 3 then
--        self._step = self._step + 1
--        self:waitClick2()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
--end

function QTutorialPhase01InTeamAndDungeon:waitClick2()
--  self:clearSchedule()
    self:_guideClickCopy()
end

--引导玩家点击第一个副本
function QTutorialPhase01InTeamAndDungeon:_guideClickCopy()
  self:clearSchedule()
  local page = app:getNavigationController():getTopDialog()
  self._copy = page._currentPage._heads[1]
  self._CP = self._copy._ccbOwner.btn_head:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._copy._ccbOwner.btn_head:getContentSize()
  self._perCP = ccp(display.width/2, display.height/2)
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "进入关卡", direction = "right"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
--打开关卡页面
function QTutorialPhase01InTeamAndDungeon:_openCopy()
  self._handTouch:removeFromParent()
  self._copy:_onTriggerClick()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickBattle()
  end, 0.5)
end
--引导玩家点击下一步
function QTutorialPhase01InTeamAndDungeon:_guideClickBattle()
  self:clearSchedule()
  local page = app:getNavigationController():getTopDialog()
  self._CP = page._ccbOwner.btn_battle:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._ccbOwner.btn_battle:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击下一步", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01InTeamAndDungeon:_next()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopDialog()
    page:_onTriggerTeam()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_chooseHero()
  end, 0.5)
end
function QTutorialPhase01InTeamAndDungeon:_chooseHero()
  if remote.teams:getHerosCount(QTeam.INSTANCE_TEAM) ~= 0 then
    self._step = 8
    self:_clickBattle()
  else  
    if self._word ~= nil then
       self._word = nil
    end
    self._word = "让这个绿皮肤的大块头展示身手的时候到了，快派他上阵！"
    self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word,
    isSay = true, sayFun = nil})
    self._dialogueRight:setActorImage("ui/tyrande.png")
    app.tutorialNode:addChild(self._dialogueRight)
    
    self._CP = {x = 0, y = 0}
    self._size = {width = display.width*2, height = display.height*2}
    
--    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 6 then
--        self._step = self._step + 1
--        self:guideClickHero()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
  end
end

function QTutorialPhase01InTeamAndDungeon:guideClickHero()
--    self:clearSchedule()
    self._dialogueRight:setVisible(false)
    self._dialog = app:getNavigationController():getTopDialog()
   local heros = self._dialog._page:getHeroFrames()
    if #heros > 0 then
      self._widget = heros[#heros]
      self._CP = self._widget._ccbOwner.btn_hero_head:convertToWorldSpaceAR(ccp(0,0))
      self._size = self._widget._ccbOwner.btn_hero_head:getContentSize() 
      self._handTouch = QUIWidgetTutorialHandTouch.new({word = "选择英雄上阵", direction = "down"})
      self._handTouch:setPosition(self._CP.x, self._CP.y)
      app.tutorialNode:addChild(self._handTouch)
--      self:_nodeRunAction((self._CP.x) - self._perCP.x, (self._CP.y) - self._perCP.y)
    else
      self:_jumpToEnd()
    end
end

function QTutorialPhase01InTeamAndDungeon:_addHeroToTeam()
    self._handTouch:removeFromParent()
    if self._widget._onTriggerHeroOverview == nil then
      self:_jumpToEnd()
      return
    end
    self._widget:_onTriggerHeroOverview()
    self._dialogueRight:setVisible(true)
    if self._word ~= nil then
       self._word = nil
    end
    self._word = "一切准备就绪，GOGOGO"
    self._dialogueRight:addWord(self._word, function()
    self._CP = {x = 0, y = 0}
    self._size = {width = display.width*2, height = display.height*2}
    end)
    
--    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 8 then
--        self._step = self._step + 1
--        self:_waitClick()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
--等待玩家点击后对话消失
function QTutorialPhase01InTeamAndDungeon:_waitClick()
--  self:clearSchedule()
  self._dialogueRight:removeFromParent()
  self:_clickBattle()
end

function QTutorialPhase01InTeamAndDungeon:_clickBattle()
  local page = app:getNavigationController():getTopDialog()
  self._CP = page._ccbOwner.btn_battle:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._ccbOwner.btn_battle:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击开始战斗", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InTeamAndDungeon:startBattle()
  self._handTouch:removeFromParent()
  local dialog = app:getNavigationController():getTopDialog()
  dialog._ccbOwner.btn_battle:setEnabled(false)
  self._CP = nil
  scheduler.performWithDelayGlobal(function()
    dialog:_starBattle()
    end, 0)
  self:finished()
end

--如果出错则直接跳掉引导过程
function QTutorialPhase01InTeamAndDungeon:_jumpToEnd()
    app.tutorial._runingStage:jumpFinished()
    self:finished()
end

-- 移动到指定位置
function QTutorialPhase01InTeamAndDungeon:_nodeRunAction(posX,posY)
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

function QTutorialPhase01InTeamAndDungeon:_onTouch(event)
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

function QTutorialPhase01InTeamAndDungeon:clearSchedule()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
end

return QTutorialPhase01InTeamAndDungeon
