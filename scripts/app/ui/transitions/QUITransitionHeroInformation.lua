
local QUITransition = import(".QUITransition")
local QUITransitionDialogHeroInformation = class("QUITransitionDialogHeroInformation", QUITransition)

function QUITransitionDialogHeroInformation:_doTransition()
	local old = self:getOldController()
end

return QUITransitionDialogHeroInformation

