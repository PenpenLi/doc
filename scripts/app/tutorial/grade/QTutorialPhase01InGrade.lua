--
-- Author: wkwang
-- Date: 2014-08-12 14:20:47
--
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01InGrade = class("QTutorialPhase01InGrade", QTutorialPhase)

local QUIDialogGrade = import("...ui.dialogs.QUIDialogGrade")
local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")
local QTutorialDirector = import("..QTutorialDirector")

QTutorialPhase01InGrade.GRADE_SUCCESS = 0.5

--步骤开始
function QTutorialPhase01InGrade:start()
  self._stage:enableTouch(handler(self, self._onTouch))

  if self._handTouch == nil then
    self._handTouch = QUIWidgetTutorialHandTouch.new()
    self._handTouch:handLeftDown()
    self._handTouch:tipsLeftDown()
    app.tutorialNode:addChild(self._handTouch)
    self._perCP = ccp(display.width/2, display.height/2)
    self._handTouch:setVisible(false)
  end

  self._step = 0
  if app.tutorial:getStage() >= QTutorialDirector.Stage_5_Grade - QTutorialPhase01InGrade.GRADE_SUCCESS then
    local dialogName = app:getNavigationController():getTopDialog().class.__cname
    if dialogName == ".QUIDialogInstance" then
      self._step = 12
      self:_guideClickCopy()
    else
      self._step = 11
      self:_guideClickMap()
    end
  else
    self:stepManager()
  end
end

--步骤管理
function QTutorialPhase01InGrade:stepManager()
  if self._step == 0 then
    self:_guideStart()
  elseif self._step == 1 then
    self:_guideClickScaling()
  elseif self._step == 2 then
    self:_openScaling()
  elseif self._step == 3 then
    self:_openHero()
  elseif self._step == 4 then
    self:_openHeroInfo()
  elseif self._step == 5 then
    self:_openHeroGrade()
  elseif self._step == 6 then
    self:_confrimHeroGrade()
  elseif self._step == 7 then
    self:_waitClick()
  elseif self._step == 8 then
    self:_confrimGrade()
  elseif self._step == 9 then
    self:_confrimSkillUnlock()
  elseif self._step == 10 then
    self:_closeHeroInfo()
  elseif self._step == 11 then
    self:_closeHeroOverView()
  elseif self._step == 12 then
    self:_openMap()
  elseif self._step == 13 then
    self:_openCopy()
  elseif self._step == 14 then
    self:_startBattle()
  end
end

--引导开始
function QTutorialPhase01InGrade:_guideStart()
  --增加遮罩
  self._layer = CCLayerColor:create(ccc4(0, 0, 0, 0.7 * 255), display.width, display.height)
  self._layer:setPosition(ccp(0,0))
  self._layer:setVisible(true)
  app.tutorialNode:addChild(self._layer)
  self._dialogueRight = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = "英雄不断升星才能迎娶白富美走向人生巅峰~",
    isSay = true, sayFun = function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end})
  self._dialogueRight:setActorImage("ui/tyrande.png")
  app.tutorialNode:addChild(self._dialogueRight)
end

--引导玩家点击伸缩按钮
function QTutorialPhase01InGrade:_guideClickScaling()
  self._layer:setVisible(false)
  self._dialogueRight:setVisible(false)
  local page = app:getNavigationController():getTopPage()
  self._CP = page._scaling._ccbOwner.button_scaling:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._scaling._ccbOwner.button_scaling:getContentSize()
  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InGrade:_openScaling()
  local page = app:getNavigationController():getTopPage()
  page._scaling:_onTriggerOffSideMenu()
  scheduler.performWithDelayGlobal(function()
    self:_guideClickHero()
  end,0.5)
end

--引导玩家点击英雄总览按钮
function QTutorialPhase01InGrade:_guideClickHero()
  local page = app:getNavigationController():getTopPage()
  self._CP = page._scaling._ccbOwner.btn_hero:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._scaling._ccbOwner.btn_hero:getContentSize()
  self._handTouch:setVisible(true)
  self._handTouch:tipsLeftUp()
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InGrade:_openHero()
  local page = app:getNavigationController():getTopPage()
  self._dialog = page._scaling:_onButtondownSideMenuHero()
  self:_guideClickHeroFrame()
end
--引导玩家点击英雄头像
function QTutorialPhase01InGrade:_guideClickHeroFrame()
  self.heros = self._dialog._page:getHeroFrames()
  self._CP = self.heros[#self.heros]._ccbOwner.bg:convertToWorldSpaceAR(ccp(0,0))
  self._size = self.heros[#self.heros]._ccbOwner.bg:getContentSize()
  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
  self._handTouch:setVisible(true)
  self._handTouch:handRightDown()
  self._handTouch:tipsRightUp()
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InGrade:_openHeroInfo()
  self.heros[#self.heros]:_onTriggerHeroOverview()
  self:_guideClickHeroGrade()
end

--引导玩家点击进阶按钮
function QTutorialPhase01InGrade:_guideClickHeroGrade()
  self._dialog = app:getNavigationController():getTopDialog()
  self._CP = self._dialog._ccbOwner.node_advance:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.node_advance:getContentSize()
  self._handTouch:handRightDown()
  self._handTouch:tipsRightUp()
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InGrade:_openHeroGrade()
  self._dialog = self._dialog:_onAdvance()
  self:_guideClickGradeBtn()
end

--引导玩家点击确定进阶按钮
function QTutorialPhase01InGrade:_guideClickGradeBtn()
  self._CP = self._dialog._ccbOwner.btn_bg:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.btn_bg:getContentSize()
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InGrade:_confrimHeroGrade()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialEvent.EVENT_GRADE_SUCCESS,self.confrimHeroGradeHandler, self)
  self._dialog:_onTriggerConfirm()
end
function QTutorialPhase01InGrade:confrimHeroGradeHandler()
  scheduler.performWithDelayGlobal(function()
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialEvent.EVENT_GRADE_SUCCESS, self.confrimHeroGradeHandler, self)
    self._layer:setVisible(true)
    self._dialogueRight:removeFromParent()
    self._dialogueRight1 = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = "每天早上都被自己帅醒", isSay = true, sayFun = function()
      self._CP = {x = 0, y = 0}
      self._size = {width = display.width*2, height = display.height*2}
    end})
    self._dialogueRight1:setActorImage("ui/orc_warlord.png")
    app.tutorialNode:addChild(self._dialogueRight1)
    app.tutorial:setStage(app.tutorial:getStage() + QTutorialPhase01InGrade.GRADE_SUCCESS)
    remote.flag:set(remote.flag.FLAG_TUTORIAL_STAGE, app.tutorial:getStage())
  end, 0.5)
end
function QTutorialPhase01InGrade:_waitClick()
  self:_guideClickGradeSuccessBtn()
end
--引导玩家点击进阶成功确定
function QTutorialPhase01InGrade:_guideClickGradeSuccessBtn()
  self._layer:setVisible(false)
  self._dialogueRight1:removeFromParent()
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.bg_ok_bg:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.bg_ok_bg:getContentSize()
  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InGrade:_confrimGrade()
  self._dialog:_onTriggerConfirm()
  self:_guideClickSkillUnlock()
end
--引导玩家点击解锁确定
function QTutorialPhase01InGrade:_guideClickSkillUnlock()
  self._dialog = app:getNavigationMidLayerController():getTopDialog()
  self._CP = self._dialog._ccbOwner.bg_ok_bg:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.bg_ok_bg:getContentSize()
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01InGrade:_confrimSkillUnlock()
  self._dialog:_onTriggerConfirm()
  self:_guideClickCloseBtn()
end
--引导玩家点击英雄信息界面返回按钮
function QTutorialPhase01InGrade:_guideClickCloseBtn()
  self._dialog = app:getNavigationController():getTopDialog()
  self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.btn_back:getContentSize()
  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
  self._handTouch:tipsRightDown()
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01InGrade:_closeHeroInfo()
  self._dialog:_onTriggerBack()
  self:_guideClickHeroOverViewBackBtn()
end
--引导玩家点击英雄总览界面返回按钮
function QTutorialPhase01InGrade:_guideClickHeroOverViewBackBtn()
  self._dialog = app:getNavigationController():getTopDialog()
  self._CP = self._dialog._ccbOwner.btn_back:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._dialog._ccbOwner.btn_back:getContentSize()
  self._handTouch:tipsRightDown()
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InGrade:_closeHeroOverView()
  self._dialog:_onTriggerBack()
  local dialogName = app:getNavigationController():getTopDialog().class.__cname
  if dialogName == ".QUIDialogInstance" then
    self._step = self._step + 1
    self:_guideClickCopy()
  else
    self:_guideClickMap()
  end
end
--引导玩家点击副本
function QTutorialPhase01InGrade:_guideClickMap()
  local page = app:getNavigationController():getTopPage()
  self._CP = page._ccbOwner.btn_instance:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._ccbOwner.btn_instance:getContentSize()
  self._perCP = ccp(display.width/2, display.height/2)
  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
  self._handTouch:handRightDown()
  self._handTouch:tipsLeftUp()
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end

function QTutorialPhase01InGrade:_openMap()
  local page = app:getNavigationController():getTopPage()
  page:_onInstance()
  self:_guideClickCopy()
end
--引导玩家选择关卡
function QTutorialPhase01InGrade:_guideClickCopy()
  local page = app:getNavigationController():getTopDialog()
  self._copy = page._currentPage._heads[3]
  self._CP = self._copy._ccbOwner.btn_head:convertToWorldSpaceAR(ccp(0,0))
  self._size = self._copy._ccbOwner.btn_head:getContentSize()
  self._perCP = ccp(display.width/2, display.height/2)
  self._handTouch:setPosition(self._perCP.x, self._perCP.y)
  self._handTouch:handRightDown()
  self._handTouch:tipsRightUp()
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
--打开关卡页面
function QTutorialPhase01InGrade:_openCopy()
  self._copy:_onTriggerClick()
  self:_guideClickBattle()
end
--引导玩家点击开战
function QTutorialPhase01InGrade:_guideClickBattle()
  local page = app:getNavigationController():getTopDialog()
  self._CP = page._ccbOwner.btn_battle:convertToWorldSpaceAR(ccp(0,0))
  self._size = page._ccbOwner.btn_battle:getContentSize()
  self._handTouch:tipsLeftDown()
  self._handTouch:setVisible(true)
  self:_nodeRunAction(self._CP.x - self._perCP.x, self._CP.y - self._perCP.y)
end
function QTutorialPhase01InGrade:_startBattle()
  local page = app:getNavigationController():getTopDialog()
  page:_onTriggerFight()
  self:finished()
end
-- 移动到指定位置
function QTutorialPhase01InGrade:_nodeRunAction(posX,posY)
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

function QTutorialPhase01InGrade:_onTouch(event)
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

return QTutorialPhase01InGrade
