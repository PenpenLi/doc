local QTutorialPhase = import("..QTutorialPhase")
local QTutoiralPhase01InArea = class("QTutoiralPhase01InArea", QTutoiralPhase01InArea)

function QTutoiralPhase01InArea:start()
	self._stage:enableTouch(handler(self, self._onTouch()))
	self.step = 0
	self.stepManager()
end
--步骤管理
function QTutoiralPhase01InArea:stepManager()
	if self.step == 0 then
		self:_guideStart()
	elseif self.step == 1 then
		self:_openArea()
	end
end
--引导开始
function QTutoiralPhase01InArea:_guideStart()
	self._dialogRight = QUIWidgetTutorialDialogue.new({isLeft = true, text = "新手引导，竞技场",isSay = true, sayFun = function()
			self.step = 1
			scheduler.performWithDelay(function()
					self:stepManager()
				end, 1.0)
		end})
	self._dialogRight:setActorImage("ui/orc_warlord.png")
end
--进入竞技场
function QTutoiralPhase01InArea:_openArea()
	
end