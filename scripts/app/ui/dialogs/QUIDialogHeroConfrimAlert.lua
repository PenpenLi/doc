--
-- Author: wkwang
-- Date: 2014-07-17 14:08:11
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogHeroConfrimAlert = class("QUIDialogHeroConfrimAlert", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogHeroConfrimAlert:ctor(options)
	assert(options ~= nil, "alert dialog options is nil !")
 	local ccbFile = "ccb/Dialog_HeroConfrimAlert.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogHeroConfrimAlert._onTriggerConfirm)},
    }
    QUIDialogHeroConfrimAlert.super.ctor(self, ccbFile, callBacks, options)

    self._closeCallBack = options.callBack
    if options.comfirmBack then
    	self._comfirmBack = options.comfirmBack
    else
    	self._comfirmBack = options.callBack
    end

    if options.title then
    	self._title = options.title
    	self._ccbOwner.tf_title:setString(self._title)
    end

    if options.content then
    	self._content = options.content
    	self._ccbOwner.tf_content:setString(self._content)
    end

    if options.name then
    	self._name = options.name
    	self._ccbOwner.tf_name:setPositionX(self._ccbOwner.tf_content:getPositionX() + self._ccbOwner.tf_content:getContentSize().width)
    	self._ccbOwner.tf_name:setString(self._name)
    end

    if options.color then
    	self._color = options.color
    	self._ccbOwner.tf_name:setColor(self._color)
    end
end

function QUIDialogHeroConfrimAlert:_onTriggerConfirm()
	self:_close()
	if self._comfirmBack ~= nil then
		self._comfirmBack()
	end
end

function QUIDialogHeroConfrimAlert:_backClickHandler()
    self:_close()
end

function QUIDialogHeroConfrimAlert:_close()
    if self._closeCallBack ~= nil then
        self._closeCallBack()
    end
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogHeroConfrimAlert