local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01Intensify = class("QTutorialPhase01Intensify", QTutorialPhase)

local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")
local QTutorialDirector = import("..QTutorialDirector")
local QUIWidgetHeroUpgradeCell = import("...ui.widgets.QUIWidgetHeroUpgradeCell")

QTutorialPhase01Intensify.INTENSIFY_SUCCESS = 1

function QTutorialPhase01Intensify:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  self._step = 0
  self._perCP = ccp(display.width/2, display.height/2)

--  local page = app:getNavigationController():getTopPage()
--  page:cleanBuildLayer()
--  if self._handTouch == nil then
--    self._handTouch = QUIWidgetTutorialHandTouch.new()
--    self._handTouch:handLeftDown()
--    self._handTouch:tipsLeftDown()
--    app.tutorialNode:addChild(self._handTouch)
--    self._handTouch:setVisible(false)
--  end
    self:stepManager()
end
--步骤管理
function QTutorialPhase01Intensify:stepManager()
  if self._step == 0 then
    self:_guideStart()
  elseif self._step == 1 then
    self:_guideClickHeroFrame()
  elseif self._step == 2 then
    self:_openHeroInfo()
--  elseif self._step == 3 then
--    self:_guideClickIntensify()
  elseif self._step == 3 then
    self:_openHeroIntensify()
--  elseif self._step == 5 then
--    self:_guideClickBread()
  elseif self._step == 4 then
    self:_autoAdd()
  elseif self._step == 5 then
    self:_finishing()
--  elseif self._step == 7 then
--    self:_backHeroInfo()
--  elseif self._step == 8 then
--    self:_backHero()
--  elseif self._step == 9 then
--    self:_backCopy()
--  elseif self._step == 10 then
--    self:_openMap()
--  elseif self._step == 11 then
--    self:_openCopy()
--  elseif self._step == 12 then
--    self:_startBattle()
  end
end
function QTutorialPhase01Intensify:_guideStart()

  local stage = app.tutorial:getStage()
  stage.intencifyGuide = QTutorialPhase01Intensify.INTENSIFY_SUCCESS
  app.tutorial:setStage(stage)
  app.tutorial:setFlag(stage)
  self._word = "又有新的小伙伴加入啦，队长威武~快给他迅速升级吧！"
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
--      self:_guideClickHeroFrame()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
--引导玩家点击扩展标签
--function QTutorialPhase01Intensify:_guideClickScaling()
--  self._dialogueRight:setVisible(false)
--  self._layer:setVisible(false)
--  local page = app:getNavigationController():getTopPage()
--  self._CP = page._scaling._ccbOwner.button_scaling:convertToWorldSpaceAR(ccp(0,0))
--  self._size = page._scaling._ccbOwner.button_scaling:getContentSize()
--  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--function QTutorialPhase01Intensify:_openScaling()
--  local page = app:getNavigationController():getTopPage()
--  page._scaling:_onTriggerOffSideMenu()
--  scheduler.performWithDelayGlobal(function()
--    self:_guideClickHero()
--  end,0.5)
--end
--引导玩家点击英雄
--function QTutorialPhase01Intensify:_guideClickHero()
--  local page = app:getNavigationController():getTopPage()
--  self._CP = page._scaling._ccbOwner.btn_hero:convertToWorldSpaceAR(ccp(0,0))
--  self._size = page._scaling._ccbOwner.btn_hero:getContentSize()
--  self._handTouch:tipsLeftUp()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--function QTutorialPhase01Intensify:_openHero()
--  local page = app:getNavigationController():getTopPage()
--  page._scaling:_onButtondownSideMenuHero()
--  self:_guideClickHeroFrame()
--end
--引导玩家点击英雄头像
function QTutorialPhase01Intensify:_guideClickHeroFrame()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationController():getTopDialog()
  self.heros = self._dialog._page:getVirtualFrames()
  for k, value in pairs(self.heros) do
    if self._dialog.upGradeHeroInfo == self.heros[k].actorId then
      self._dialog:runTo(self._dialog.upGradeHeroInfo)
    end
  end
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self.hero = self._dialog._page:getHeroFrames()
    for k, value in pairs(self.hero) do
      if self._dialog.upGradeHeroInfo == self.hero[k]:getHero() then
        self.upGradeHeroNum = k
      end
    end
    
    self._CP = self.hero[self.upGradeHeroNum]._ccbOwner.bg:convertToWorldSpaceAR(ccp(0,0))
    self._size = self.hero[self.upGradeHeroNum]._ccbOwner.bg:getContentSize()
    self._handTouch = QUIWidgetTutorialHandTouch.new({word = "选择英雄", direction = "down"})
    self._handTouch:setPosition(self._CP.x, self._CP.y)
    app.tutorialNode:addChild(self._handTouch)
--    self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
  end, 0.5)
end
function QTutorialPhase01Intensify:_openHeroInfo()
  self._handTouch:removeFromParent()
  self:clearSchedule()
  self.hero[self.upGradeHeroNum]:_onTriggerHeroOverview()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickIntensify()
  end, 0.5)
end

--function QTutorialPhase01Intensify:waitClick()
--  self._dialogueRight:setVisible(true)
--  if self._word ~= nil then
--     self._word = nil
--  end
--  self._word = "点击打开英雄升级界面"
--  self._dialogueRight:addWord(self._word)
--  self._CP = {x = 0, y = 0}
--  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 2 then
--        self._step = self._step + 1
--        self:_guideClickIntensify()
--      end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
--end

--引导玩家打开英雄升级页面
function QTutorialPhase01Intensify:_guideClickIntensify()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.node_upgrade:convertToWorldSpaceAR(ccp(0, 0))
  self._size = self._dialog._ccbOwner.node_upgrade:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "打开升级界面", direction = "up"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01Intensify:_openHeroIntensify()
  self._handTouch:removeFromParent()
  self._dialog:_onUpgrade()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickBread()
  end, 0.5)
end

--function QTutorialPhase01Intensify:waitClick2()
--  self:clearSchedule()
--  self._dialogueRight:setVisible(true)
--  if self._word ~= nil then
--     self._word = nil
--  end
--  self._word = "点击使用经验道具"
--  self._dialogueRight:addWord(self._word)
--  self._CP = {x = 0, y = 0}
--  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 4 then
--        self._step = self._step + 1
--        self:_guideClickBread()
--      end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
--end

--引导玩家点击面包
function QTutorialPhase01Intensify:_guideClickBread()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._upgrade._itmes[1]._ccbOwner.layout:convertToWorldSpaceAR(ccp(0, 0))
  self._size = self._dialog._upgrade._itmes[1]._ccbOwner.layout:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击使用道具", direction = "right"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01Intensify:_autoAdd()
  self._handTouch:removeFromParent()
  self._dialog._upgrade._itmes[1]:_onUpHandler()
  self:_guideClickStrengthen()
end
--结束语
function QTutorialPhase01Intensify:_guideClickStrengthen()
  self._dialogueRight:setVisible(true)
  if self._word ~= nil then
     self._word = nil
  end
  self._word = "为了新英雄能更快的上阵杀敌，不要让他的等级掉队哦~"
  self._dialogueRight:addWord(self._word, function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
  end)
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 6 then
--        self._step = self._step + 1
--        self:_finishing()
--      end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
--引导结束
function QTutorialPhase01Intensify:_finishing()
--  self:clearSchedule()
  self._dialogueRight:removeFromParent()
  self:finished()
end
--function QTutorialPhase01Intensify:_heroStrengthen()
--  
--  self._dialog:_onTriggerStrengthen()
--end
--
--function QTutorialPhase01Intensify:heroStrengthenHandler()
--  scheduler.performWithDelayGlobal(function()
--    
--    self._layer:setVisible(true)
--    self._dialogueRight:setVisible(true)
--    self._dialogueRight:addWord("吃饱了是不是感觉自己猛猛的╭(●｀∀’●)╯", function()
--      self._CP = {x = 0, y = 0}
--      self._size = {width = display.width*2, height = display.height*2}
--    end)
--    app.tutorial:setStage(app.tutorial:getStage() + QTutorialPhase01Intensify.INTENSIFY_SUCCESS)
--    remote.flag:set(remote.flag.FLAG_TUTORIAL_STAGE, app.tutorial:getStage())
--  end, 0.5)
--end
--等待玩家点击后对话消失
--function QTutorialPhase01Intensify:_waitClick()
--  self:_guideClickBackHeroInfo()
--end

--function QTutorialPhase01Intensify:_startBattle()
--  local page = app:getNavigationController():getTopDialog()
--  self:finished()
--  page:_onTriggerFight()
--end
--移动到指定位置
function QTutorialPhase01Intensify:_nodeRunAction(posX,posY)
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

function QTutorialPhase01Intensify:_onTouch(event)
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

function QTutorialPhase01Intensify:clearSchedule()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
end

return QTutorialPhase01Intensify
