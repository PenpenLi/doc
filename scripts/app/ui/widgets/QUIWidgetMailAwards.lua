--
-- Author: wkwang
-- Date: 2015-01-26 10:37:04
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetMailAwards = class("QUIWidgetMailAwards", QUIWidget)

function QUIWidgetMailAwards:ctor(options)
	local ccbFile = "ccb/Widget_MailAwards.ccbi"
  	local callBacks = {}
	QUIWidgetMailAwards.super.ctor(self,ccbFile,callBacks,options)

	self.type = options.type
	self.count = options.count
	local respath = remote.items:getURLForItem(self.type)
	if respath ~= nil then
	    local texture = CCTextureCache:sharedTextureCache():addImage(respath)
		self._ccbOwner.node_icon:setTexture(texture)
	    local size = texture:getContentSize()
	    local rect = CCRectMake(0, 0, size.width, size.height)
	    self._ccbOwner.node_icon:setTextureRect(rect)
	end
    self._ccbOwner.tf_value:setString(self.count)
end

return QUIWidgetMailAwards