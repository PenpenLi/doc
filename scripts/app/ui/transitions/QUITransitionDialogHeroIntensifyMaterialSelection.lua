--
-- Author: Your Name
-- Date: 2014-06-16 15:57:38
--
local QUITransition = import(".QUITransition")
local QUITransitionDialogHeroIntensifyMaterialSelection = class("QUITransitionDialogHeroIntensifyMaterialSelection", QUITransition)

function QUITransitionDialogHeroIntensifyMaterialSelection:_doTransition()
	local old = self:getOldController()
	local new = self:getNewController()
	new:setInitInfo(old._herosID[old._pos],old._selectHeros)
end

return QUITransitionDialogHeroIntensifyMaterialSelection