local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01InBreakthrough = class("QTutorialPhase01InBreakthrough", QTutorialPhase)

local QUIDialogBreakthrough = import("...ui.dialogs.QUIDialogBreakthrough")
local QUIDialogHeroEquipmentDetail = import("...ui.dialogs.QUIDialogHeroEquipmentDetail")
local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")

function QTutorialPhase01InBreakthrough:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  
  local page = app:getNavigationController():getTopPage()
  page:cleanBuildLayer()
  
  --先标志已经完成
  local stage = app.tutorial:getStage()
  stage.breakthroughGuide = 1
  app.tutorial:setStage(stage)
  app.tutorial:setFlag(stage)
  
  self._step = 0
  self._perCP = ccp(display.width/2, display.height/2)
  
--  if self._handTouch == nil then
--    self._handTouch = QUIWidgetTutorialHandTouch.new()
--    self._handTouch:handLeftDown()
--    self._handTouch:tipsLeftDown()
--    app.tutorialNode:addChild(self._handTouch)
--    self._handTouch:setVisible(false)
--  end
  
  self.firstDialog = app:getNavigationMidLayerController():getTopDialog()
--  if self.firstDialog ~= nil and self.firstDialog.class.__cname == "QUIDialogheroInformation" then
--    self._step = 6
--    self:_guideClickEquBtn()
  if self.firstDialog ~= nil and self.firstDialog.class.__cname == "QUIDialogHeroEquipmentDetail" then
    self._step = 6
    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
      QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogHeroEquipmentDetail.EVENT_WEAR_EQUIPMENT, self.guideClick, self)
      self:_guideClickEquBtn()
    end, 1)
  else
    self:stepManager()
  end
  
end

function QTutorialPhase01InBreakthrough:stepManager()
  if self._step == 0 then
    self:startGuide()
  elseif self._step == 1 then
    self:_guideClickScaling()
  elseif self._step == 2 then
    self:_openScaling()
  elseif self._step == 3 then
    self:_openHero()
  elseif self._step == 4 then
    self:next() 
  elseif self._step == 5 then
    self:clearDialgue()
  elseif self._step == 6 then
    self:_openEquipment()
  elseif self._step == 7 then
    self:_clickEquBtn()
  end
end

function QTutorialPhase01InBreakthrough:startGuide()
  if remote.herosUtil:checkHerosEquipmentByID("orc_warlord") == false then
    self:finished()
    return
  end
  
  self._word = "真是不错的战利品~还记得怎么穿装备吗?"
  self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word,
    isSay = true, sayFun = function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end})
  self._dialogueRight:setActorImage("ui/tyrande.png")
  app.tutorialNode:addChild(self._dialogueRight)
  self._step = self._step + 1
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 1 then
--      self:_guideClickScaling()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
--引导玩家点击扩展标签
function QTutorialPhase01InBreakthrough:_guideClickScaling()
--  self:clearSchedule()
  self._dialogueRight:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  self._CP = page._scaling._ccbOwner.button_scaling:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._scaling._ccbOwner.button_scaling:getContentSize()
  self._perCP = ccp(display.width/2, display.height/2)
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击进入菜单", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
  self._step = self._step + 1
end
function QTutorialPhase01InBreakthrough:_openScaling()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  page._scaling:_onTriggerOffSideMenu()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickHero()
  end,0.5)
end
--引导玩家点击英雄总览按钮
function QTutorialPhase01InBreakthrough:_guideClickHero()
  self:clearSchedule()
--  self._dialogueRight:setVisible(false)
  local page = app:getNavigationController():getTopPage()
  self._CP = page._scaling._ccbOwner.btn_hero:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._scaling._ccbOwner.btn_hero:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击进入英雄界面", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
  self._step = self._step + 1
end

function QTutorialPhase01InBreakthrough:_openHero()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  self._dialog = page._scaling:_onButtondownSideMenuHero()
  self:_guideClickHeroFrame()
end
--引导玩家点击英雄头像
function QTutorialPhase01InBreakthrough:_guideClickHeroFrame()
  self.heros = self._dialog._page:getHeroFrames()
  local breakthroughHero = remote.herosUtil:checkAllHerosBreakthroughNeedEqu()
  for k, value in pairs(self.heros) do
    if self.heros[k]:getHero() == breakthroughHero then
      self.upGradeHeroNum = k
    end
  end
  self._CP = self.heros[self.upGradeHeroNum]._ccbOwner.bg:convertToWorldSpaceAR(ccp(0,0))
  self._size = self.heros[self.upGradeHeroNum]._ccbOwner.bg:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "选择英雄", direction = "down"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
  self._step = self._step + 1
end

function QTutorialPhase01InBreakthrough:next()
  self._handTouch:removeFromParent()
    self.heros[self.upGradeHeroNum]:_onTriggerHeroOverview()
    self:_openHeroInfo()
end

function QTutorialPhase01InBreakthrough:_openHeroInfo()
    self._word = "咳咳咳，快把衣服穿上，怪不好意思的"
    self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word,
    isSay = true, sayFun = function()end})
    self._dialogueRight:setActorImage("ui/tyrande.png")
    app.tutorialNode:addChild(self._dialogueRight)
    self._CP = {x = 0, y = 0}
    self._size = {width = display.width*2, height = display.height*2}
    if self.firstDialog ~= nil and self.firstDialog.class.__cname == "QUIDialogHeroEquipmentDetail" then
      self._step = self._step + 2
--      self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--          if self._step == 5 then
--              self:_guideClickEquBtn()
--          end
--      end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
    else
      self._step = self._step + 1
--      self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--          if self._step == 5 then
--              self:clearDialgue()
--          end
--      end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
    end
end

function QTutorialPhase01InBreakthrough:clearDialgue()
--    self:clearSchedule()
    self._dialogueRight:removeFromParent()
    self._dialogueRight = nil 
    self:_wearEqu()
end

function QTutorialPhase01InBreakthrough:_wearEqu()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogHeroEquipmentDetail.EVENT_WEAR_EQUIPMENT, self.guideClick, self)
  self:_guideClickEquipment()
end
function QTutorialPhase01InBreakthrough:guideClick()
   self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickEquipment()
  end, 1)
end
--引导玩家点击装备
function QTutorialPhase01InBreakthrough:_guideClickEquipment()
  self:clearSchedule()
--  self._dialogueRight:addWord("点击装备格")
  if self._heroDialog == nil then
    self._heroDialog = app:getNavigationMidLayerController():getTopDialog()
  end
    if self._heroDialog == nil or self._heroDialog._equipBox == nil then --如果获取界面失败 则直接跳转到完成
      app.tutorial._runingStage:jumpFinished()
      self:finished()
      return 
    end
    
    for k, value in pairs(self._heroDialog._equipBox) do
      if value._ccbOwner.tf_wear_green:isVisible() == true then
          self.equNum = k
          self:waitClick()
          return
      end
    end
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogHeroEquipmentDetail.EVENT_WEAR_EQUIPMENT, self.guideClick, self)
    self:finished()
end
function QTutorialPhase01InBreakthrough:waitClick()
--  self._heroDialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._heroDialog._equipBox[self.equNum]._ccbOwner.btn_touch:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._heroDialog._equipBox[self.equNum]._ccbOwner.btn_touch:getContentSize()
  self._perCP = ccp(display.width/2, display.height/2)
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击装备格", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
  self._step = self._step + 1
end
--打开装备信息页面
function QTutorialPhase01InBreakthrough:_openEquipment()
  self._handTouch:removeFromParent()
  if self._heroDialog ~= nil then 
    self._heroDialog._equipBox[self.equNum]:_onTriggerTouch()
  end
  if self._dialogueRight ~= nil then
    self._dialogueRight:removeFromParent()
    self._dialogueRight = nil
  end
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickEquBtn()
  end, 0.1)
end

--引导玩家点击装备按钮
function QTutorialPhase01InBreakthrough:_guideClickEquBtn()
--  self._dialogueRight:addWord("点击确认装备（装备后会与英雄绑定）")
  self.dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self.dialog._ccbOwner.wear_equ:convertToWorldSpaceAR(ccp(0, 10))
  self._size = self.dialog._ccbOwner.wear_equ:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "确认穿戴装备", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
  self._step = self._step + 1
end
function QTutorialPhase01InBreakthrough:_clickEquBtn()
  self._handTouch:removeFromParent()
  self._step = self._step - 2
   self.dialog:_onTriggerWear()
end

function QTutorialPhase01InBreakthrough:_nodeRunAction(posX,posY)
  self._isMove = true
  local actionArrayIn = CCArray:create()
  actionArrayIn:addObject(CCMoveBy:create(0.1, ccp(posX,posY)))
  actionArrayIn:addObject(CCCallFunc:create(function ()
    self._isMove = false
    self._actionHandler = nil
  end))
  local ccsequence = CCSequence:create(actionArrayIn)
  self._actionHandler = self._handTouch:runAction(ccsequence)
end

function QTutorialPhase01InBreakthrough:_onTouch(event)
  if event.name == "began" then
    return true
  elseif event.name == "ended" then
    if self._dialogueRight ~= nil and self._dialogueRight._isSaying == true and self._dialogueRight:isVisible() then 
        self._dialogueRight:printAllWord(self._word)
--        self._dialogueRight._ccbOwner.label_text:setString(q.autoWrap(self._word,29,16,504))
    elseif self._CP ~= nil and event.x >=  self._CP.x - self._size.width/2 and event.x <= self._CP.x + self._size.width/2 and
      event.y >=  self._CP.y - self._size.height/2 and event.y <= self._CP.y + self._size.height/2  then
--      self._step = self._step + 1
      self._perCP = self._CP
      self._CP = nil
--      self._handTouch:setVisible(false)
      self:stepManager()
    end
  end
end

function QTutorialPhase01InBreakthrough:clearSchedule()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
end
return QTutorialPhase01InBreakthrough