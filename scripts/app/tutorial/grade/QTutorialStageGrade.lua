--
-- Author: wkwang
-- Date: 2014-08-12 14:12:36
--
local QTutorialStage = import("..QTutorialStage")
local QTutorialStageGrade = class("QTutorialStageGrade", QTutorialStage)

local QTutorialPhase01InGrade = import(".QTutorialPhase01InGrade")

function QTutorialStageGrade:ctor()
	QTutorialStageGrade.super.ctor(self)
    self._enableTouch = false
end

function QTutorialStageGrade:_createTouchNode()
	local touchNode = CCNode:create()
    touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
    touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    touchNode:setTouchSwallowEnabled(true)
    app.tutorialNode:addChild(touchNode)
    self._touchNode = touchNode
end

function QTutorialStageGrade:enableTouch(func)
	self._enableTouch = true
	self._touchCallBack = func
end

function QTutorialStageGrade:disableTouch()
	self._enableTouch = false
	self._touchCallBack = nil
end

function QTutorialStageGrade:_createPhases()
	table.insert(self._phases, QTutorialPhase01InGrade.new(self))

	self._phaseCount = table.nums(self._phases)
end

function QTutorialStageGrade:start()
	self:_createTouchNode()
	self._touchNode:setTouchEnabled(true)
	self._touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QTutorialStageGrade._onTouch))
	QTutorialStageGrade.super.start(self)
end

function QTutorialStageGrade:ended()
	if self._touchNode ~= nil then
		self._touchNode:setTouchEnabled( false )
		self._touchNode:removeFromParent()
		self._touchNode = nil
	end
end

function QTutorialStageGrade:_onTouch(event)
	if self._enableTouch == true and self._touchCallBack ~= nil then
		return self._touchCallBack(event)
    elseif event.name == "began" then
        return true
    end
end

return QTutorialStageGrade