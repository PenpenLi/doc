--
-- Author: wkwang
-- Date: 2014-08-28 14:57:27
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetLoadTF = class("QUIWidgetLoadTF", QUIWidget)

function QUIWidgetLoadTF:ctor(options)
	local ccbFile = "ccb/Widget_ToLodin.ccbi"
	local callBacks = {}
	QUIWidgetLoadTF.super.ctor(self, ccbFile, callBacks, options)

end

function QUIWidgetLoadTF:update(percent)
	self._ccbOwner.tf_percent:setString(string.format("%d",percent*100).."%")
end

return QUIWidgetLoadTF