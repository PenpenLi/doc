--
-- Author: Qinyuanji
-- Date: 2015-01-13
-- 
-- 


local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01ArenaAddName = class("QTutorialPhase01ArenaAddName", QTutorialPhase)

local QUIWidgetTutorialDialogue = import("...ui.widgets.QUIWidgetTutorialDialogue")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")
local QTutorialDirector = import("..QTutorialDirector")

local QUIViewController = import("..QUIViewController")

--步骤开始
function QTutorialPhase01ArenaAddName:start()
  self._stage:enableTouch(handler(self, self._onTouch))
  
  local page = app:getNavigationController():getTopPage()
  page:cleanBuildLayer()

  self._step = 0
  self:stepManager()
end

--步骤管理
function QTutorialPhase01ArenaAddName:stepManager()
  if self._step == 0 then
    self:_guideStart()
  elseif self._step == 1 then
    self:waitClick1()
  elseif self._step == 2 then
    self:nameSetOver()
  end
end

--引导开始
function QTutorialPhase01ArenaAddName:_guideStart()
    self._arenaPrompt = "酷炫的战队怎么能没有名字呢？快给战队起一个碉堡的名字吧！"
    self._arenaGuide = QUIWidgetTutorialDialogue.new({isLeftSide = true, text = self._arenaPrompt,
        isSay = true, sayFun = function(...) end})
    self._arenaGuide:setActorImage("ui/tyrande.png")
    app.tutorialNode:addChild(self._arenaGuide)  
end

--显示取名对话框
function QTutorialPhase01ArenaAddName:waitClick1()
  if self._arenaPrompt ~= nil then
     self._arenaPrompt = nil
  end
  
  self._arenaGuide:setVisible(false)
  self._stage._touchNode:setTouchSwallowEnabled(false)

  app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogChangeName", 
    options = {arena = true, nameChangedCallBack = function(newName)
      self._arenaGuide:setVisible(true)
      self._arenaPrompt = "又一个拥有酷炫名字的战队诞生啦！恭喜恭喜~"
      self._arenaGuide:addWord(self._arenaPrompt)
      -- TODO, we need to navigate to Arena page
    end, cancelCallBack = function ( ... )
      self._arenaGuide:setVisible(true)
      self._arenaPrompt = "任性无效~取消无效~快取名吧~yeah~"
      self._arenaGuide:addWord(self._arenaPrompt)
      self._step = self._step - 1
      self._stage._touchNode:setTouchSwallowEnabled(true)
    end}}, {isPopCurrentDialog = false})
end

function QTutorialPhase01ArenaAddName:_onTouch(event)
  if event.name == "began" then
    return true
  elseif event.name == "ended" then
    if self._arenaGuide ~= nil and self._arenaGuide:isVisible() then 
      if self._arenaGuide._isSaying == true then 
        self._arenaGuide:printAllWord(self._arenaPrompt)
      else    
        self._step = self._step + 1
        self:stepManager()
      end
    end
  end
end

function QTutorialPhase01ArenaAddName:nameSetOver( ... )
    self._arenaGuide:removeFromParent()
    self:finished()
end

return QTutorialPhase01ArenaAddName
