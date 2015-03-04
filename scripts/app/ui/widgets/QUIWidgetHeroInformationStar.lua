
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroInformationStar = class("QUIWidgetHeroInformationStar", QUIWidget)

function QUIWidgetHeroInformationStar:ctor(options)
	local ccbFile = "ccb/Widget_HeroInformation_star.ccbi"
	local callBacks = {}
	QUIWidgetHeroInformationStar.super.ctor(self, ccbFile, callBacks, options)
	

end

function QUIWidgetHeroInformationStar:_hideAllStar(isShowBack)
	for i = 1, 5, 1 do
		local s = self._ccbOwner["sprite_star"..tostring(i)]
		s:setVisible(false)
		if isShowBack == false then
			local sb = self._ccbOwner["sprite_starback"..tostring(i)]
			sb:setVisible(false)
		end
	end
end

function QUIWidgetHeroInformationStar:hideBg()
	self._ccbOwner.node_bg:setVisible(false)
end

function QUIWidgetHeroInformationStar:showStar(number, isShowBack)
	if isShowBack == nil then 
		isShowBack = false
	end
	self:_hideAllStar(isShowBack)
	number = number + 1
	for i = 1, number, 1 do
		local s = self._ccbOwner["sprite_star"..tostring(i)]
		local sb = self._ccbOwner["sprite_starback"..tostring(i)]
		if s and sb then 
			s:setVisible(true)
			sb:setVisible(true)
		end
	end
end

return QUIWidgetHeroInformationStar