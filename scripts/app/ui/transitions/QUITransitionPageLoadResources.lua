--
-- Author: Your Name
-- Date: 2014-06-19 17:48:41
--
local QUITransition = import(".QUITransition")
local QUITransitionPageLoadResources = class("QUITransitionPageLoadResources", QUITransition)

function QUITransitionPageLoadResources:_doTransition()
	local new = self:getNewController()
	new:loadBattleResources()

end

return QUITransitionPageLoadResources