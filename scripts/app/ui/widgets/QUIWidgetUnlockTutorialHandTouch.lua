local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetUnlockTutorialHandTouch = class("QUIWidgetUnlockTutorialHandTouch", QUIWidget)

local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTips = import(".utils.QTips")

QUIWidgetUnlockTutorialHandTouch.UNLOCK_TUTORIAL_EVENT_CLICK = "UNLOCK_TUTORIAL_EVENT_CLICK"

function QUIWidgetUnlockTutorialHandTouch:ctor(options)
  local ccbFile = nil
  if options.direction == nil or options.direction == "up" or options.direction == "down" then
     ccbFile = "ccb/Widget_NewBuilding_open.ccbi"
  elseif options.direction == "left" or options.direction == "right" then
     ccbFile = "ccb/Widget_NewBuilding_open2.ccbi"
  end
  local callbacks = {
    {ccbCallbackName = "onTirggerClick", callback = handler(self, QUIWidgetUnlockTutorialHandTouch._onTirggerClick)}
  }
  QUIWidgetUnlockTutorialHandTouch.super.ctor(self, ccbFile, callbacks, options)
  
  if options.word ~= nil then
   self._word = options.word
  end
  self._ccbOwner.word:setString(self._word or "")
  
  if options.direction == "left" then
    self:getView():setScaleX(-1)
    self._ccbOwner.word:setScaleX(-1)
  end
  if options.direction == "down" then
    self:getView():setScaleY(-1)
    self._ccbOwner.word:setScaleY(-1)
  end
  self.isClick = true
  if options.type ~= nil then
    self.type = options.type
  end
  
end

function QUIWidgetUnlockTutorialHandTouch:setHandTouch(word, direction)
  self._ccbOwner.word:setString(word or "")
  if direction == "right" or direction == "up" then
    self:getView():setScaleX(1)
  elseif direction == "left" or direction == "down" then
    self:getView():setScaleX(-1)
  end
end

function QUIWidgetUnlockTutorialHandTouch:_onTirggerClick()
  local page = app:getNavigationController():getTopPage()
  if page._isMoveing == true then return end
  local unlockTutorial = app.tip:getUnlockTutorial()
  if self.type == "shop" then
     unlockTutorial.shopTutorial = QTips.UNLOCK_TUTORIAL_END
  elseif self.type == "goblinshop" then
     unlockTutorial.goblinTutorial = QTips.UNLOCK_TUTORIAL_END
  elseif self.type == "blackshop" then
     unlockTutorial.blackTutorial = QTips.UNLOCK_TUTORIAL_END
  elseif self.type == "space" then
     unlockTutorial.spaceTutorial = QTips.UNLOCK_TUTORIAL_END
  elseif self.type == "gold" then
     unlockTutorial.goldTutorial = QTips.UNLOCK_TUTORIAL_END
  elseif self.type == "arena" then
     unlockTutorial.arenaTutorial = QTips.UNLOCK_TUTORIAL_END
  elseif self.type == "sunwell" then
     unlockTutorial.sunwellTutorial = QTips.UNLOCK_TUTORIAL_END
  end
  app.tip:setUnlockTutorial(unlockTutorial)
  QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetUnlockTutorialHandTouch.UNLOCK_TUTORIAL_EVENT_CLICK, type = self.type})
end

return QUIWidgetUnlockTutorialHandTouch