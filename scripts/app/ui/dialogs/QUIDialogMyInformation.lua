--
-- Author: Qinyuanji
-- Date: 2014-11-19 
--
local QUIDialog = import(".QUIDialog")
local QUIDialogMyInformation = class("QUIDialogMyInformation", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")
local QUIDialogChangeName = import(".QUIDialogChangeName")
local QUIDialogExchange = import(".QUIDialogExchange")
local QUIDialogChooseHead = import("..dialogs.QUIDialogChooseHead")
local QNotificationCenter = import("...controllers.QNotificationCenter")

function QUIDialogMyInformation:ctor(options)
	local ccbFile = "ccb/Dialog_MyInformation.ccbi";
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogMyInformation._onTriggerClose)},
		{ccbCallbackName = "onTriggerChangeNameHandler", callback = handler(self, QUIDialogMyInformation._onTriggerChangeNameHandler)},
		{ccbCallbackName = "onTriggerChooseHeadHandler", callback = handler(self, QUIDialogMyInformation._onTriggerChooseHeadHandler)},
		{ccbCallbackName = "onTriggerExchangeHandler", callback = handler(self, QUIDialogMyInformation._onTriggerExchangeHandler)},
		{ccbCallbackName = "onTriggerSystemSetting", callback = handler(self, QUIDialogMyInformation._onTriggerSystemSetting)},
	}
	QUIDialogMyInformation.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true --是否动画显示

	-- build objects for avatar
	self._avatar = CCNode:create()
	local ccclippingNode = QFullCircleUiMask.new()
	ccclippingNode:setRadius(50)
	ccclippingNode:addChild(self._avatar)
	self._ccbOwner.node_headPicture:addChild(ccclippingNode)

	-- update my information
	self:setMyInformation(options)
end

function QUIDialogMyInformation:viewDidAppear()
	QUIDialogMyInformation.super.viewDidAppear(self)
	QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogChooseHead.NEW_AVATAR_SELECTED, self.onAvatarChanged, self)
end 

function QUIDialogMyInformation:viewWillDisappear()
	QUIDialogMyInformation.super.viewWillDisappear(self)
	QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogChooseHead.NEW_AVATAR_SELECTED, self.onAvatarChanged, self)
end 

-- Listen to QUIDialogChooseHead.NEW_AVATAR_SELECTED, when avatar is changed, my information dialog needs update
function QUIDialogMyInformation:onAvatarChanged(event)
    self:setMyAvatar(event.newAvatar)
end

-- Update text and avatar
function QUIDialogMyInformation:setMyInformation(options)
	-- update text information 
	self._ccbOwner.tf_nickName:setString(options.nickName or "")
	self._ccbOwner.tf_exp:setString(string.format("%d/%d", options.exp or -1, options.expToNextLevel or -1))
	self._ccbOwner.tf_level:setString(options.level or "-1")
	self._ccbOwner.tf_maxLevel:setString(options.heroMaxLevel or "-1")

	-- update avatar
    self:setMyAvatar(options.avatar)
end

function QUIDialogMyInformation:setMyAvatar(avatar)
    local resPath = avatar
    if resPath == "" or resPath == nil then
      resPath = "icon/head/orc_warlord.png"
    end
    local texture = CCTextureCache:sharedTextureCache():addImage(resPath)
    if texture ~= nil then
      local sprite = CCSprite:createWithTexture(texture)
      local size = self._ccbOwner.node_headPicture_bg:getContentSize()
      sprite:setScale(size.width/sprite:getContentSize().width)
      self._avatar:removeAllChildren()
      self._avatar:addChild(sprite)
    end
end

function QUIDialogMyInformation:_onTriggerChangeNameHandler()
	app.sound:playSound("common_small")
	app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogChangeName", 
		options = {nickName = self._ccbOwner.tf_nickName:getString(), nameChangedCallBack = function(newName)
			self._ccbOwner.tf_nickName:setString(newName)
		end}}, {isPopCurrentDialog = false})
end

function QUIDialogMyInformation:_onTriggerChooseHeadHandler()
	app.sound:playSound("common_small")
	self._chooseHeadDialog = app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogChooseHead"}, {isPopCurrentDialog = false})
end

function QUIDialogMyInformation:_onTriggerExchangeHandler()
	app.sound:playSound("common_small")
	app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogExchange"}, {isPopCurrentDialog = false})
end

function QUIDialogMyInformation:_onTriggerSystemSetting()
	app.sound:playSound("common_small")
	app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogSystemSetting"}, {isPopCurrentDialog = false})
end

function QUIDialogMyInformation:_onTriggerClose()
	-- app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
	app.sound:playSound("common_cancel")
	self:_onTriggerCancel()
end

function QUIDialogMyInformation:_onTriggerCancel()
	self:playEffectOut()
end

function QUIDialogMyInformation:_backClickHandler()
    self:_onTriggerCancel()
end

function QUIDialogMyInformation:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogMyInformation