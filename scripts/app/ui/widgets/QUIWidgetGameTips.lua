--
-- Author: qinyuanji
-- Date: 2014-11-15 
-- Game tips widget - shown when loading page is on.
-- Center the text when it's changed


local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetGameTips = class("QUIWidgetGameTips", QUIWidget)

function QUIWidgetGameTips:ctor(options)
	local ccbFile = "ccb/Widget_ToLodin2.ccbi"
	local callBacks = {}
	QUIWidgetGameTips.super.ctor(self, ccbFile, callBacks, options)
	self._spaceWidth = 5
	self._tipsOriginalWidth = self:_getWholeTipsWidth()
end

-- set tips text and return the new width
function QUIWidgetGameTips:setString(tipsText)
	if tipsText ~= nil then
		self._ccbOwner.tf_tipsText:setString(tipsText)
	end
	-- return new width of whole tips
	return self:_getWholeTipsWidth()
end

function QUIWidgetGameTips:_getWholeTipsWidth()
	return self._ccbOwner.tf_tipsHead:getContentSize().width + self._spaceWidth + 
	 						self._ccbOwner.tf_tipsText:getContentSize().width 
end

function QUIWidgetGameTips:getTipsOriginalWidth()
	return self._tipsOriginalWidth
end

return QUIWidgetGameTips