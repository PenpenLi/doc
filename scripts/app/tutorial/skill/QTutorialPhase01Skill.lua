local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01InSkill = class("QTutorialPhase01InSkill", QTutorialPhase)

local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")
local QTutorialDirector = import("..QTutorialDirector")
local QNavigationController = import("...controllers.QNavigationController")

QTutorialPhase01InSkill.SKILL_SUCCESS = 1

--步骤开始
function QTutorialPhase01InSkill:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  
  local page = app:getNavigationController():getTopPage()
  page:cleanBuildLayer()
--  if self._handTouch == nil then
--    self._handTouch = QUIWidgetTutorialHandTouch.new()
--    self._handTouch:handLeftDown()
--    self._handTouch:tipsLeftDown()
--    app.tutorialNode:addChild(self._handTouch)
--    self._handTouch:setVisible(false)
--  end
    --标志引导完成
   local stage = app.tutorial:getStage()
    stage.skillGuide = QTutorialPhase01InSkill.SKILL_SUCCESS
    app.tutorial:setStage(stage)
    app.tutorial:setFlag(stage)
    
  self.firstDialog = app:getNavigationMidLayerController():getTopDialog()
  if self.firstDialog ~= nil and self.firstDialog.class.__cname == "QUIDialogHeroEquipmentDetail" then
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    self._step = 5
    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
      self:_guideClickHeroGrade()
    end, UNLOCK_DELAY_TIME + 0.5)
  else
    self._perCP = ccp(display.width/2, display.height/2)
    self._step = 0
    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
      self:stepManager()
    end, UNLOCK_DELAY_TIME + 0.5)
  end
end

--步骤管理
function QTutorialPhase01InSkill:stepManager()
  if self._step == 0 then
    self:_guideStart()
  elseif self._step == 1 then
    self:waitClick1()
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
--  elseif self._step == 7 then
--    self:_guideClickHeroGrade()
  elseif self._step == 6 then
    self:_openHeroGrade()
--  elseif self._step == 9 then
--    self:_guideClickGradeBtn()
  elseif self._step == 7 then
    self:_confrimHeroGrade()
  elseif self._step == 8 then
    self:_waitClick5()
--  elseif self._step == 8 then
--    self:_confrimGrade()
--  elseif self._step == 9 then
--    self:_confrimSkillUnlock()
--  elseif self._step == 10 then
--    self:_closeHeroInfo()
--  elseif self._step == 11 then
--    self:_closeHeroOverView()
--  elseif self._step == 12 then
--    self:_openMap()
--  elseif self._step == 13 then
--    self:_openCopy()
  elseif self._step == 9 then
    self:_startBattle()
  end
end

--引导开始
function QTutorialPhase01InSkill:_guideStart()
    self:clearSchedule()
   
  self._word = "好厉害！已经可以给英雄技能升级了呢~"
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
--      self:waitClick1()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

function QTutorialPhase01InSkill:waitClick1()
--  self:clearSchedule()
  if self._word ~= nil then
     self._word = nil
  end
  self._word = "你懂的~从这里可以进入英雄各个界面~"
  self._dialogueRight:addWord(self._word)
  self._CP = {x = 0, y = 0}
  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 1 then
--      self._step = self._step + 1
--      self:_guideClickScaling()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end

--引导玩家点击伸缩按钮
function QTutorialPhase01InSkill:_guideClickScaling()
--  self:clearSchedule()    
  self._dialogueRight:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  self._CP = page._scaling._ccbOwner.button_scaling:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._scaling._ccbOwner.button_scaling:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击进入菜单", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InSkill:_openScaling()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  page._scaling:_onTriggerOffSideMenu()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickHero()
  end,0.5)
end

--引导玩家点击英雄总览按钮
function QTutorialPhase01InSkill:_guideClickHero()
  self:clearSchedule()
  local page = app:getNavigationController():getTopPage()
  self._CP = page._scaling._ccbOwner.btn_hero:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._scaling._ccbOwner.btn_hero:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击进入英雄界面", direction = "left"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InSkill:_openHero()
  self._handTouch:removeFromParent()
  local page = app:getNavigationController():getTopPage()
  self._dialog = page._scaling:_onButtondownSideMenuHero()
  self:_guideClickHeroFrame()
end

--function QTutorialPhase01InSkill:waitClick2()
--  self._dialogueRight:setVisible(true)
--  if self._word ~= nil then
--     self._word = nil
--  end
--  self._word = "选择一个英雄"
--  self._dialogueRight:addWord(self._word)
--  self._CP = {x = 0, y = 0}
--  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 4 then
--      self._step = self._step + 1
--      self:_guideClickHeroFrame()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
--end

--引导玩家点击英雄头像
function QTutorialPhase01InSkill:_guideClickHeroFrame()
--  self:clearSchedule()
--  self._dialogueRight:setVisible(false)
  self.heros = self._dialog._page:getHeroFrames()
  for k, value in pairs(self.heros) do 
    if remote.herosUtil:getHeroByID(value:getHero()) ~= nil then
      self.heroId = k
    end
  end
  self._CP = self.heros[self.heroId]._ccbOwner.bg:convertToWorldSpaceAR(ccp(0,0))
  self._size = self.heros[self.heroId]._ccbOwner.bg:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "选择英雄", direction = "down"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InSkill:_openHeroInfo()
  self._handTouch:removeFromParent()
  self.heros[self.heroId]:_onTriggerHeroOverview()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickHeroGrade()
  end, 0.5)
end

--function QTutorialPhase01InSkill:waitClick3()
--  self._dialogueRight:setVisible(true)
--  if self._word ~= nil then
--     self._word = nil
--  end
--  self._word = "点击打开英雄技能面板"
--  self._dialogueRight:addWord(self._word)
--  self._CP = {x = 0, y = 0}
--  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 6 then
--      self._step = self._step + 1
--      self:_guideClickHeroGrade()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
--end

--引导玩家点击技能按钮
function QTutorialPhase01InSkill:_guideClickHeroGrade()
--  self:clearSchedule()
--  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.node_skill:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.node_skill:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "打开技能界面", direction = "up"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InSkill:_openHeroGrade()
  self._handTouch:removeFromParent()
  self._dialog:_onSkill()
  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    self:_guideClickGradeBtn()
  end,1)
end

--function QTutorialPhase01InSkill:waitClick4()
--  self._dialogueRight:setVisible(true)
--  if self._word ~= nil then
--     self._word = nil
--  end
--  self._word = "点击升级技能"
--  self._dialogueRight:addWord(self._word)
--  self._CP = {x = 0, y = 0}
--  self._size = {width = display.width*2, height = display.height*2}
  
--  self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 8 then
--      self._step = self._step + 1
--      self:_guideClickGradeBtn()
--    end
--  end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
--end

--引导玩家点击加技能点按钮
function QTutorialPhase01InSkill:_guideClickGradeBtn()
--  self:clearSchedule()
--  self._dialogueRight:setVisible(false)
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self.skillCell = self._dialog._skill.skillCell
  self._CP = self.skillCell[1]._ccbOwner.btn_plus:convertToWorldSpaceAR(ccp(0,0))
  self._size = self.skillCell[1]._ccbOwner.btn_plus:getContentSize()
  self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击升级技能", direction = "right"})
  self._handTouch:setPosition(self._CP.x, self._CP.y)
  app.tutorialNode:addChild(self._handTouch)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InSkill:_confrimHeroGrade()
  self._handTouch:removeFromParent()
--  QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialEvent.EVENT_SKILL_SUCCESS,self.confrimHeroGradeHandler, self)
  self.skillCell[1]:_onPlus()
  self:confrimHeroGradeHandler()
end
function QTutorialPhase01InSkill:confrimHeroGradeHandler()
--    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialEvent.EVENT_SKILL_SUCCESS, self.confrimHeroGradeHandler, self)
    if self._word ~= nil then
       self._word = nil
    end
    self._word = "技能点每5分钟会恢复1点，好好使用哦~"
    self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, sayFun = function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end})
    self._dialogueRight:setActorImage("ui/tyrande.png")
    app.tutorialNode:addChild(self._dialogueRight)
    
--    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
--    if self._step == 10 then
--      self._step = self._step + 1
--      self:_waitClick5()
--    end
--    end, TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME))
end
function QTutorialPhase01InSkill:_waitClick5()
  self:clearSchedule()
  self:_startBattle()
end
--引导玩家点击进阶成功确定
--function QTutorialPhase01InSkill:_guideClickGradeSuccessBtn()
--  self._layer:setVisible(false)
--  self._dialogueRight1:removeFromParent()
--  self._dialog = app:getNavigationMidLayerController():getTopDialog()
--  self._CP = self._dialog._ccbOwner.bg_ok_bg:convertToWorldSpaceAR(ccp(0,0))
--  self._size = self._dialog._ccbOwner.bg_ok_bg:getContentSize()
--  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--
--function QTutorialPhase01InSkill:_confrimGrade()
--  self._dialog:_onTriggerConfirm()
--  self:_guideClickSkillUnlock()
--end
--引导玩家点击解锁确定
--function QTutorialPhase01InSkill:_guideClickSkillUnlock()
--  self._dialog = app:getNavigationMidLayerController():getTopDialog()
--  self._CP = self._dialog._ccbOwner.bg_ok_bg:convertToWorldSpaceAR(ccp(0,0))
--  self._size = self._dialog._ccbOwner.bg_ok_bg:getContentSize()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--function QTutorialPhase01InSkill:_confrimSkillUnlock()
--  self._dialog:_onTriggerConfirm()
--  self:_guideClickCloseBtn()
--end
--引导玩家点击英雄信息界面返回按钮
--function QTutorialPhase01InSkill:_guideClickCloseBtn()
--  self._dialog = app:getNavigationController():getTopDialog()
--  self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
--  self._size = self._dialog._ccbOwner.btn_back:getContentSize()
--  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--  self._handTouch:tipsRightDown()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--function QTutorialPhase01InSkill:_closeHeroInfo()
--  self._dialog:_onTriggerBack()
--  self:_guideClickHeroOverViewBackBtn()
--end
--引导玩家点击英雄总览界面返回按钮
--function QTutorialPhase01InSkill:_guideClickHeroOverViewBackBtn()
--  self._dialog = app:getNavigationController():getTopDialog()
--  self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
--  self._size = self._dialog._ccbOwner.btn_back:getContentSize()
--  self._handTouch:tipsRightDown()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--
--function QTutorialPhase01InSkill:_closeHeroOverView()
--  self._dialog:_onTriggerBack()
--  local dialogName = app:getNavigationController():getTopDialog().class.__cname
--  if dialogName == ".QUIDialogInstance" then
--    self._step = self._step + 1
--    self:_guideClickCopy()
--  else
--    self:_guideClickMap()
--  end
--end
--引导玩家点击副本
--function QTutorialPhase01InSkill:_guideClickMap()
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
--function QTutorialPhase01InSkill:_openMap()
--  local page = app:getNavigationController():getTopPage()
--  page:_onInstance()
--  self:_guideClickCopy()
--end
--引导玩家选择关卡
--function QTutorialPhase01InSkill:_guideClickCopy()
--  local page = app:getNavigationController():getTopDialog()
--  self._copy = page._currentPage._heads[3]
--  self._CP = self._copy._ccbOwner.btn_head:convertToWorldSpaceAR(ccp(0,0))
--  self._size = self._copy._ccbOwner.btn_head:getContentSize()
--  self._perCP = ccp(display.width/2, display.height/2)
--  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
--  self._handTouch:handRightDown()
--  self._handTouch:tipsRightUp()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
--打开关卡页面
--function QTutorialPhase01InSkill:_openCopy()
--  self._copy:_onTriggerClick()
--  self:_guideClickBattle()
--end
--引导玩家点击开战
--function QTutorialPhase01InSkill:_guideClickBattle()
--  local page = app:getNavigationController():getTopDialog()
--  self._CP = page._ccbOwner.btn_battle:convertToWorldSpaceAR(ccp(0,0))
--  self._size = page._ccbOwner.btn_battle:getContentSize()
--  self._handTouch:tipsLeftDown()
--  self._handTouch:setVisible(true)
--  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
--end
function QTutorialPhase01InSkill:_startBattle()
  self._dialogueRight:removeFromParent()
  self:finished()
end
-- 移动到指定位置
function QTutorialPhase01InSkill:_nodeRunAction(posX,posY)
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

function QTutorialPhase01InSkill:_onTouch(event)
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

function QTutorialPhase01InSkill:clearSchedule()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
end

return QTutorialPhase01InSkill
