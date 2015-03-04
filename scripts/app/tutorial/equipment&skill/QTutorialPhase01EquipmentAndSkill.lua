local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01EquipmentAndSkill = class("QTutorialPhase01EquipmentAndSkill", QTutorialPhase)

local QUIViewController = import("..QUIViewController")
local QUIDialogHeroEquipmentDetail = import("...ui.dialogs.QUIDialogHeroEquipmentDetail")
local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")
local QTutorialDirector = import("..QTutorialDirector")
local QNavigationController = import("...controllers.QNavigationController")

QTutorialPhase01EquipmentAndSkill.EQUIPMENT_SUCCESS = 4

function QTutorialPhase01EquipmentAndSkill:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  self._step = 0
  
  local page = app:getNavigationController():getTopPage()
  page:cleanBuildLayer()
--  local dialog = app:getNavigationTopLayerController():getTopDialog()
--  if dialog ~= nil then
--    app:getNavigationTopLayerController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
--  end
  
--  if self._handTouch == nil then
--    self._handTouch = QUIWidgetTutorialHandTouch.new()
--    self._handTouch:handLeftDown()
--    self._handTouch:tipsLeftDown()
--    app.tutorialNode:addChild(self._handTouch)
--    self._handTouch:setVisible(false)
--  end
  local stage = app.tutorial:getStage()
  if stage.forcedGuide == 2 then
    stage.forcedGuide = 3
    app.tutorial:setFlag(stage)
  end
  self:stepManager()

end
--步骤管理
function QTutorialPhase01EquipmentAndSkill:stepManager()
  if self._step == 0 then
    self:_guideStart()
  elseif self._step == 1 then
    self:waitClick3()
  elseif self._step == 2 then
    self:_guideClickScaling()
  elseif self._step == 3 then
    self:_openScaling()
  elseif self._step == 4 then
    self:_openHero()
--  elseif self._step == 5 then
--    self:_guideClickHeroFrame()
  elseif self._step == 5 then
    self:_openHeroInfo()
--  elseif self._step == 6 then
--    self:_guideClickEquipment()
  elseif self._step == 6 then
    self:_openEquipment()
  elseif self._step == 7 then
    self:_guideClickEquBtn()
  elseif self._step == 8 then
    self:_clickEquBtn()
  elseif self._step == 9 then
    self:_waitClick1()
  elseif self._step == 10 then
    self:_waitClick2()
    --  elseif self._step == 6 then
    --    self:_openSkill()
    --  elseif self._step == 7 then
    --    self:_skillStrengthen()
    --  elseif self._step == 8 then
    --    self:_backHeroInfo()
  elseif self._step == 11 then
    self:_backHero()
  elseif self._step == 12 then
    self:_guideClickBack3()
  elseif self._step == 13 then
    self:_backMainMenu()
  elseif self._step == 14 then
    self:_openMap()
  elseif self._step == 15 then
    self:_openCopy()
  elseif self._step == 16 then
    self:_startBattle()
  end
end
--引导开始
function QTutorialPhase01EquipmentAndSkill:_guideStart()
  self._word = "哇，真幸运！获得了一件装备，赶快给那个绿家伙穿上~"
  self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, sayFun = function()
    self._CP = {x = 0, y = 0}
    self._size = {width = display.width*2, height = display.height*2}
  end})
  self._dialogueRight:setActorImage("ui/tyrande.png")
  app.tutorialNode:addChild(self._dialogueRight)
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 0 then
--        self._step = self._step + 1
--        self:waitClick3()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
function QTutorialPhase01EquipmentAndSkill:waitClick3()
--  self:clearSchedule()
    if self._word ~= nil then
       self._word = nil
    end
  self._word = "让我告诉你快捷穿装备的途径~"
  self._dialogueRight:addWord(self._word)
  self._CP = {x = 0, y = 0}
  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 1 then
--        self._step = self._step + 1
--        self:_guideClickScaling()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
--引导玩家点击扩展标签
function QTutorialPhase01EquipmentAndSkill:_guideClickScaling()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  local page = app:getNavigationController():getTopPage()
  self._CP = page._scaling._ccbOwner.button_scaling:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._scaling._ccbOwner.button_scaling:getContentSize()
  self._perCP = ccp(display.width/2, display.height/2)
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击进入菜单", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01EquipmentAndSkill:_openScaling()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  page._scaling:_onTriggerOffSideMenu()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickHero()
  end,0.5)
end
--引导玩家点击英雄总览按钮
function QTutorialPhase01EquipmentAndSkill:_guideClickHero()
  self:clearSchedule()
  local page = app:getNavigationController():getTopPage()
  self._CP = page._scaling._ccbOwner.btn_hero:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._scaling._ccbOwner.btn_hero:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击进入英雄界面", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01EquipmentAndSkill:_openHero()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  self._dialog = page._scaling:_onButtondownSideMenuHero()
  self:_guideClickHeroFrame()
end

--function QTutorialPhase01EquipmentAndSkill:waitClick4()
--  self._dialogueRight:setVisible(true)
--    if self._word ~= nil then
--       self._word = nil
--    end
--  self._word = "选中英雄"
--  self._dialogueRight:addWord(self._word)
--  self._CP = {x = 0, y = 0}
--  self._size = {width = display.width*2, height = display.height*2}
--  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 4 then
--        self._step = self._step + 1
--        self:_guideClickHeroFrame()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
--end

--引导玩家点击英雄头像
function QTutorialPhase01EquipmentAndSkill:_guideClickHeroFrame()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self.heros = self._dialog._page:getHeroFrames()
  self._CP = self.heros[#self.heros]._ccbOwner.bg:convertToWorldSpaceAR(ccp(0,0))
  self._size = self.heros[#self.heros]._ccbOwner.bg:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "选择英雄", direction = "down"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01EquipmentAndSkill:_openHeroInfo()
  self._handTouch:removeFromParent()
  self.heros[#self.heros]:_onTriggerHeroOverview()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickEquipment()
  end, 0.5)
end

--function QTutorialPhase01EquipmentAndSkill:waitClick5()
--  self._dialogueRight:setVisible(true)
--    if self._word ~= nil then
--       self._word = nil
--    end
--  self._word = "选择一个装备格"
--  self._dialogueRight:addWord(self._word)
--  self._CP = {x = 0, y = 0}
--  self._size = {width = display.width*2, height = display.height*2}
--  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 6 then
--        self._step = self._step + 1
--        self:_guideClickEquipment()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
--end

--引导玩家点击装备
function QTutorialPhase01EquipmentAndSkill:_guideClickEquipment()
  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._equipBox[2]._ccbOwner.btn_touch:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._equipBox[2]._ccbOwner.btn_touch:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击装备格", direction = "right"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
--打开装备信息页面
function QTutorialPhase01EquipmentAndSkill:_openEquipment()
  self._handTouch:removeFromParent()
  self._dialog._equipBox[2]:_onTriggerTouch()
--  if dialog._equipmentDetail._ccbOwner.status1_btn_Wear:isVisible() then
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:waitClick6()
  end, 0.1)
--  else
--    self:_guideClickBack3()
--  end
end

function QTutorialPhase01EquipmentAndSkill:waitClick6()
  self:clearSchedule()
  self._dialogueRight:setVisible(true)
    if self._word ~= nil then
       self._word = nil
    end
  self._word = "特别提示，所有的装备穿戴后都将与英雄绑定哦！"
  self._dialogueRight:addWord(self._word)
  self._CP = {x = 0, y = 0}
  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 8 then
--        self._step = self._step + 1
--        self:_guideClickEquBtn()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

--引导玩家点击装备按钮
function QTutorialPhase01EquipmentAndSkill:_guideClickEquBtn()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self.dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self.dialog._ccbOwner.wear_equ:convertToWorldSpaceAR(ccp(0, 10))
  self._size = self.dialog._ccbOwner.wear_equ:getContentSize()
--  self._perCP = ccp(display.width/2, display.height/2)
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "确认穿戴装备", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01EquipmentAndSkill:_clickEquBtn()
  self._handTouch:removeFromParent()
  local stage = app.tutorial:getStage()
  stage.forcedGuide = QTutorialPhase01EquipmentAndSkill.EQUIPMENT_SUCCESS
  app.tutorial:setStage(stage)
  app.tutorial:setFlag(stage)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogHeroEquipmentDetail.EVENT_WEAR_EQUIPMENT, self.wearEquipmentHandler, self)
  self.dialog:_onTriggerWear()
  --  function()
  --    scheduler.performWithDelayGlobal(function()
  --    self._layer:setVisible(true)
  --    self._dialogueRight:setVisible(true)
  --    self._dialogueRight:addWord("神清气爽，这个时候怎么可以不战一次呢", function()
  --      self._CP = {x = 0, y = 0}
  --      self._size = {width = display.width*2, height = display.height*2}
  --    end)
  --  end, 0.5)
  --  end)
end
function QTutorialPhase01EquipmentAndSkill:wearEquipmentHandler()
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogHeroEquipmentDetail.EVENT_WEAR_EQUIPMENT, self.wearEquipmentHandler, self)
    self._dialogueRight:setVisible(true)
    if self._word ~= nil then
       self._word = nil
    end
    self._word = "穿上了新装备顿时萌萌哒，有木有！"
    self._dialogueRight:addWord(self._word, function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end)
    
--    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 10 then
--        self._step = self._step + 1
--        self:_waitClick1()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
--等待玩家点击后对话消失
function QTutorialPhase01EquipmentAndSkill:_waitClick1()
--  self:clearSchedule()
    if self._word ~= nil then
       self._word = nil
    end
    self._word = "据说穿满六件装备后，英雄就能召唤绅士的力量呢~快去集齐六件装备吧！"
    self._dialogueRight:addWord(self._word, function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end)
    
--    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 11 then
--        self._step = self._step + 1
--        self:_waitClick2()
--      end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
function QTutorialPhase01EquipmentAndSkill:_waitClick2()
--  self:clearSchedule()
  self:_guideClickBack2()
end
--引导玩家点击技能
--function QTutorialPhase01EquipmentAndSkill:_guideClickSkill()
--    self._CP = self._dialog._ccbOwner.node_skillstrengthen:convertToWorldSpaceAR(ccp(0,0))
--    self._size = self._dialog._ccbOwner.node_skillstrengthen:getContentSize()
--    self._handTouch:handLeftUp()
--    self._handTouch:setVisible(true)
--    self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--function QTutorialPhase01EquipmentAndSkill:_openSkill()
--  self._dialog:_onSkillStrengthen()
--  self:_guideClickBack2()
--end
--引导玩家升级技能
--function QTutorialPhase01EquipmentAndSkill:_guideClickSkillStrengthen()
--  self._dialogueLeft:setVisible(false)
--  self._dialogueRight:setVisible(true)
--  self._dialogueRight:addWord("点击升级技能", function()
--    self._dialog = app:getNavigationController():getTopDialog()
--    self._CP = self._dialog._ccbOwner.btn_skill:convertToWorldSpaceAR(ccp(0,0))
--    self._size = self._dialog._ccbOwner.btn_skill:getContentSize()
--    self._handTouch:handLeftUp()
--    self._handTouch:setVisible(true)
--    self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--  end)
--end
--function QTutorialPhase01EquipmentAndSkill:_skillStrengthen()
--  self._dialog:_onTriggerUpgradeHandler()
--  scheduler.performWithDelayGlobal(function()
--    self._dialogueRight:addWord("神清气爽，这个时候怎么可以不战一次呢")
--  end, 1.0)
--  scheduler.performWithDelayGlobal(function()
--    self:_guideClickBack1()
--  end, 4.5)
--end
--引导玩家返回英雄信息页面
--function QTutorialPhase01EquipmentAndSkill:_guideClickBack1()
--  self._dialogueLeft:setVisible(true)
--  self._dialogueRight:setVisible(false)
--  self._dialogueLeft:addWord("点击返回英雄信息页面", function()
--    self._dialog = app:getNavigationController():getTopDialog()
--    self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
--    self._size = self._dialog._ccbOwner.btn_back:getContentSize()
--    self._handTouch:handRightDown()
--    self._handTouch:tipsRightDown()
--    self._handTouch:setVisible(true)
--    self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--  end)
--end
--function QTutorialPhase01EquipmentAndSkill:_backHeroInfo()
--  self._dialog:_onTriggerBack()
--  self:_guideClickBack2()
--end
--引导玩家返回英雄页面
function QTutorialPhase01EquipmentAndSkill:_guideClickBack2()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.btn_close:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.btn_close:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击关闭", direction = "down"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01EquipmentAndSkill:_backHero()
  self._handTouch:removeFromParent()
  self._dialog:_onTriggerClose()
  self:waitClick7()
end

function QTutorialPhase01EquipmentAndSkill:waitClick7()
  self._dialogueRight:setVisible(true)
  if self._word ~= nil then
     self._word = nil
  end
  self._word = "为了更多的新装备，继续我们的冒险吧，噢耶！"
  self._dialogueRight:addWord(self._word)
  self._CP = {x = 0, y = 0}
  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--      if self._step == 13 then
--        self._step = self._step + 1
--        self:_guideClickBack3()
--      end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

--引导玩家返回英雄总览页面
function QTutorialPhase01EquipmentAndSkill:_guideClickBack3()
--  self:clearSchedule()
  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationController():getTopPage()
  self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.btn_back:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击返回", direction = "right"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01EquipmentAndSkill:_backMainMenu()
  self._handTouch:removeFromParent()
  self._dialogueRight:removeFromParent()
  self._dialog:_onTriggerBack()
  self:finished()
end
--引导玩家点击副本
--function QTutorialPhase01EquipmentAndSkill:_guideClickMap()
--  local page = app:getNavigationController():getTopPage()
--  self._CP = page._ccbOwner.btn_instance:convertToWorldSpaceAR(ccp(0,0))
--  self._size = page._ccbOwner.btn_instance:getContentSize()
--  self._perCP = ccp(display.width/2, display.height/2)
--  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--  self._handTouch:handRightDown()
--  self._handTouch:tipsLeftUp()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--
--function QTutorialPhase01EquipmentAndSkill:_openMap()
--  local page = app:getNavigationController():getTopPage()
--  page:_onInstance()
--  self:_guideClickCopy()
--end
--引导玩家点击第二个副本
--function QTutorialPhase01EquipmentAndSkill:_guideClickCopy()
--  local page = app:getNavigationController():getTopDialog()
--  self._copy = page._currentPage._heads[2]
--  self._CP = self._copy._ccbOwner.btn_head:convertToWorldSpaceAR(ccp(0,0))
--  self._size = self._copy._ccbOwner.btn_head:getContentSize()
--  self._perCP = ccp(display.width/2, display.height/2)
--  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--  self._handTouch:tipsRightUp()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--打开关卡页面
--function QTutorialPhase01EquipmentAndSkill:_openCopy()
--  self._copy:_onTriggerClick()
--  self:_guideClickBattle()
--end
--引导玩家点击开战
--function QTutorialPhase01EquipmentAndSkill:_guideClickBattle()
--  local page = app:getNavigationController():getTopDialog()
--  self._CP = page._ccbOwner.btn_battle:convertToWorldSpaceAR(ccp(0,0))
--  self._size = page._ccbOwner.btn_battle:getContentSize()
--  self._handTouch:tipsLeftDown()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--function QTutorialPhase01EquipmentAndSkill:_startBattle()
--  local page = app:getNavigationController():getTopDialog()
--  page:_onTriggerFight()
--  self:finished()
--end
--移动到指定位置
function QTutorialPhase01EquipmentAndSkill:_nodeRunAction(posX,posY)
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

function QTutorialPhase01EquipmentAndSkill:_onTouch(event)
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

function QTutorialPhase01EquipmentAndSkill:clearSchedule()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
end
return QTutorialPhase01EquipmentAndSkill
