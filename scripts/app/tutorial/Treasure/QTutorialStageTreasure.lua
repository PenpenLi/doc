--
-- Author: xurui
-- 宝箱新手引导
-- Date: 2014-08-20 18:34:17
--
local QTutorialStage = import("..QTutorialStage")
local QTutorialStageTreasure = class("QTutorialStageTreasure", QTutorialStage)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("...ui.QUIViewController")
local QTutorilaPhase01InTreasure = import(".QTutorilaPhase01InTreasure")

function QTutorialStageTreasure:ctor()
	QTutorialStageTreasure.super.ctor(self)
	self._enableTouch = false
end

function QTutorialStageTreasure:_createTouchNode()
	local touchNode = CCNode:create()
	touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
	touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
	touchNode:setTouchSwallowEnabled(true)
	app.tutorialNode:addChild(touchNode)
	self._touchNode = touchNode
end

function QTutorialStageTreasure:enableTouch(func)
	self._enableTouch = true
	self._touchCallBack = func
end

function QTutorialStageTreasure:disableTouch()
	self._enableTouch = false
	self._touchCallBack = nil
end

function QTutorialStageTreasure:_createPhases()
	table.insert(self._phases, QTutorilaPhase01InTreasure.new(self))

	self._phaseCount = table.nums(self._phases)
end

function QTutorialStageTreasure:start()
	self:_createTouchNode()
	self._touchNode:setTouchEnabled(true)
	self._touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QTutorialStageTreasure._onTouch))
	QTutorialStageTreasure.super.start(self)
end

function QTutorialStageTreasure:ended()
  scheduler.performWithDelayGlobal(function()
    local page = app:getNavigationController():getTopPage()
    page:buildLayer()
    page:checkGuiad()
  end,0)
	if self._touchNode ~= nil then
		self._touchNode:setTouchEnabled(false)
		self._touchNode:removeFromParent()
		self._touchNode = nil
	end
end

function QTutorialStageTreasure:_onTouch(event)
	if self._enableTouch == true and self._touchCallBack ~= nil then
		return self._touchCallBack(event)
	  elseif event.name == "began" then
		    return true
	  end
end

return QTutorialStageTreasure