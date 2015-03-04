--
-- Author: Your Name
-- Date: 2014-06-12 12:07:38
--

local QUITransition = import(".QUITransition")
local QUITransitionDialogHeroIntensify = class("QUITransitionDialogHeroIntensify", QUITransition)

function QUITransitionDialogHeroIntensify:_doTransition()
	local old = self:getOldController()
	local new = self:getNewController()
	new:setHeros(old._herosID,old._pos)
end

return QUITransitionDialogHeroIntensify

