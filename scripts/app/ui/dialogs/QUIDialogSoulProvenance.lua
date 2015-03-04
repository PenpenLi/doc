--
-- Author: Your Name
-- Date: 2014-06-19 15:29:07
--
local QUIDialog = import(".QUIDialog")
local QUIDialogSoulProvenance = class("QUIDialogSoulProvenance", QUIDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogSoulProvenance:ctor(options)
	local ccbFile = "ccb/Dialog_HeroInformation_client.ccbi";
	local callBacks = {
		-- {ccbCallbackName = "onTriggerClose", 	callback = handler(self, QUIDialogSoulProvenance._onTriggerClose)},
	}
	QUIDialogSoulProvenance.super.ctor(self,ccbFile,callBacks,options)

	self._itemID = options.itemID
	self._needNum = options.needNum or 0

	if self._itemID == nil then
		return 
	end
	local item = QStaticDatabase:sharedDatabase():getItemByID(tonumber(self._itemID))
	if item ~= nil and item.icon ~= nil then
	    local texture = CCTextureCache:sharedTextureCache():addImage(item.icon)
		self._ccbOwner.node_item:setTexture(texture)
	    local size = texture:getContentSize()
	    local rect = CCRectMake(0, 0, size.width, size.height)
	    self._ccbOwner.node_item:setTextureRect(rect)
	end
	self._ccbOwner.tf_hero_name:setString("")
	self._ccbOwner.tf_num:setString("")
	if item ~= nil then
		self._ccbOwner.tf_hero_name:setString(item.name)
		local haveNum = remote.items.getItemsNumByID(item.id)
		self._ccbOwner.tf_num:setString("("..haveNum.."/"..self._needNum..")")
	end
end

function QUIDialogSoulProvenance:_onTriggerClose()
	self:getView():removeFromParent()
    -- app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogSoulProvenance:_backClickHandler()
    self:_onTriggerClose()
end

return QUIDialogSoulProvenance