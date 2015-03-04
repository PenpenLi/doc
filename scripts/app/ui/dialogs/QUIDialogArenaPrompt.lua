--
-- Author: Qinyuanji
-- Date: 2015-01-16
--
local QUIDialog = import(".QUIDialog")
local QUIDialogArenaPrompt = class("QUIDialogArenaPrompt", QUIDialog)
local QNavigationController = import("...controllers.QNavigationController")
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")

function QUIDialogArenaPrompt:ctor(options)
	local ccbFile = "ccb/Dialog_ArenaPrompt.ccbi"
	local callBacks = {}
	QUIDialogArenaPrompt.super.ctor(self, ccbFile, callBacks, options)

	self.isAnimation = true

	-- build objects for avatar
	self._avatar = CCNode:create()
	local ccclippingNode = QFullCircleUiMask.new()
	ccclippingNode:setRadius(50)
	ccclippingNode:addChild(self._avatar)
	self._ccbOwner.node_headPicture:addChild(ccclippingNode)

	self._level = options.level or ""
	self._nickName = options.nickName or ""
	self._avatarFile = options.avatar or "icon/head/orc_warlord.png"
end

function QUIDialogArenaPrompt:viewDidAppear()
	QUIDialogArenaPrompt.super.viewDidAppear(self)
    
    self:setAvatar(self._avatarFile)
    self._ccbOwner.level:setString(self._level)
    self._ccbOwner.nickName:setString(self._nickName)
end

function QUIDialogArenaPrompt:viewWillDisappear()	
	QUIDialogArenaPrompt.super.viewWillDisappear(self)
end 

function QUIDialogArenaPrompt:setAvatar(avatar)
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

function QUIDialogArenaPrompt:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogArenaPrompt:_backClickHandler()
    self:_close()
end

function QUIDialogArenaPrompt:_close()
    self:playEffectOut()
end

return QUIDialogArenaPrompt