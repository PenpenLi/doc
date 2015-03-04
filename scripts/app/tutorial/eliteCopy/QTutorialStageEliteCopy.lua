local QTutorialStage = import("..QTutorialStage")
local QTutorialStageEliteCopy = class("QTutorialStageEliteCopy", QTutorialStage)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("...ui.QUIViewController")
local QTutorialPhase01EliteCopy = import(".QTutorialPhase01EliteCopy")

function QTutorialStageEliteCopy:ctor()
  QTutorialStageEliteCopy.super.ctor(self)
    self._enableTouch = false
end

function QTutorialStageEliteCopy:_createTouchNode()
  local touchNode = CCNode:create()
    touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
    touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    touchNode:setTouchSwallowEnabled(true)
    app.tutorialNode:addChild(touchNode)
    self._touchNode = touchNode
end

function QTutorialStageEliteCopy:enableTouch(func)
  self._enableTouch = true
  self._touchCallBack = func
end

function QTutorialStageEliteCopy:disableTouch()
  self._enableTouch = false
  self._touchCallBack = nil
end

function QTutorialStageEliteCopy:_createPhases()
  table.insert(self._phases, QTutorialPhase01EliteCopy.new(self))

  self._phaseCount = table.nums(self._phases)
end

function QTutorialStageEliteCopy:start()
  self:_createTouchNode()
  self._touchNode:setTouchEnabled(true)
  self._touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QTutorialStageEliteCopy._onTouch))
  QTutorialStageEliteCopy.super.start(self)
end

function QTutorialStageEliteCopy:ended()
  if self._touchNode ~= nil then
    self._touchNode:setTouchEnabled(false)
    self._touchNode:removeFromParent()
    self._touchNode = nil
  end
end

function QTutorialStageEliteCopy:_onTouch(event)
  if self._enableTouch == true and self._touchCallBack ~= nil then
    return self._touchCallBack(event)
    elseif event.name == "began" then
        return true
    end
end

return QTutorialStageEliteCopy