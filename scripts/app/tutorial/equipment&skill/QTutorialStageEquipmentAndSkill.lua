--阵容和副本新手引导

local QTutorialStage = import("..QTutorialStage")
local QTutorialStageEquipmentAndSkill = class("QTutorialStageEquipmentAndSkill", QTutorialStage)

local QTutorialPhase01EquipmentAndSkill = import(".QTutorialPhase01EquipmentAndSkill")

function QTutorialStageEquipmentAndSkill:ctro()
  QTutorialStageEquipmentAndSkill.super.ctro(self)
  self._enableTouch = false
end

function QTutorialStageEquipmentAndSkill:_createTouchNode()
  local touchNode = CCNode:create()
  touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
  touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
  touchNode:setTouchSwallowEnabled(true)
  app.tutorialNode:addChild(touchNode)
  self._touchNode = touchNode
end

function QTutorialStageEquipmentAndSkill:enableTouch(func)
  self._enableTouch = true
  self._touchCallBack = func
end

function QTutorialStageEquipmentAndSkill:displayTouch()
  self._enableTouch = true
  self._touchCallBack = nil
end

function QTutorialStageEquipmentAndSkill:_createPhases()
  table.insert(self._phases, QTutorialPhase01EquipmentAndSkill.new(self))
  
  self._phaseCount = table.nums(self._phases)
end

function QTutorialStageEquipmentAndSkill:start()
  self:_createTouchNode()
  self._touchNode:setTouchEnabled(true)
  self._touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self._onTouch))
  QTutorialStageEquipmentAndSkill.super.start(self)
end

function QTutorialStageEquipmentAndSkill:ended()
  scheduler.performWithDelayGlobal(function()
    local page = app:getNavigationController():getTopPage()
    page:checkGuiad()
  end,0)
  if self._touchNode ~= nil then
    self._touchNode:setTouchEnabled(false)
    self._touchNode:removeFromParent()
    self._touchNode = nil
  end
end

function QTutorialStageEquipmentAndSkill:_onTouch(event)
  if self._enableTouch == true and self._touchCallBack ~= nil then
    return self._touchCallBack(event)
  elseif event.name == "began" then
    return true
  end
end

return QTutorialStageEquipmentAndSkill