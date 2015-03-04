--竞技场新手引导
local QTutorialStage = import("..QTutorialStage")
local QTutorialStageArea = class("QTutorialStageArea", QTutorialStage)
local QTutorialPhase01InArea = import(".QTutorialPhase01InArea")

function QTutorialStageArea:ctro()
  QTutorialStageArea.super.ctro(self)
  self._enableTouch = false
end

function QTutorialStageArea:_creatTouchNode()
  local touchNode = CCNode:creat()
  touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.heigth))
  touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
  touchNode:setTouchSwallowEnabled(true)
  app.tutorialNode:addChild(touchNode)
  self._touchNode = touchNode
end

function QTutorialStageArea:enableTouch(func)
	self._enableTouch = true
	self._toucheCallBack = func
end

function QTutorialStageArea:disableTouch()
	self._enableTouch = false
	self._toucheCallBack = nil
end

function QTutorialStageArea:_createPhases()
	table.insert(self._phases, QTutorialPhase01InArea.new(self))

	self._phaseNum = #self._phases
end

function QTutorialStageArea:start()
	self:_creatTouchNode()
	self._touchNode:setTouchEnabled(true)
	self._touchNode:addEventListener(cc.NODE_TOUCH_EVENT, handler(self, QTutorialStageArea._onTouch))
	QTutorialStageArea.super.start(self)
end

function QTutorialStageArea:ended()
	app.tutorial:setStage(app.tutorial:getStage() + 1)
	remote.flag:set(remote.flag.FLAG_TUTORIAL_STAGE, app.tutorial:getStage())
	if self._touchNode ~= nil then
		self._touchNode:setTouchEnabled(false)
		self._touchNode:removeFromParent()
		self._touchNode = nil
	end
end

function QTutorialStageArea:_onTouch()
	if self._enableTouch == true and self._toucheCallBack ~= nil then
		self._toucheCallBack(event)
	elseif event.name == "began" then
		return true
	end	
end
return QTutorialStageArea