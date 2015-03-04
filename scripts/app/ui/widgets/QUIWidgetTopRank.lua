--
-- Author: Qinyuanji
-- Date: 2015-1-20
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetTopRank = class("QUIWidgetTopRank", QUIWidget)
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")

QUIWidgetTopRank.GAP = 10

function QUIWidgetTopRank:ctor(options)
	local ccbFile = "ccb/Widget_ArenaRank_client2.ccbi"
	local callBacks = {
		{ccbCallbackName = "onHead", callback = handler(self, QUIWidgetTopRank._onHead)}
	}
	QUIWidgetTopRank.super.ctor(self, ccbFile, not options.disableDetail and callBacks or {}, options)

	self._contentHeight = self._ccbOwner.background:getContentSize().height
	self._parent = options.parent
	self._switch = options.switch -- 1 means one bar, 2 means two bars
	self._userId = options.info.response.userId
	self._nickName = options.info.response.name == "" and "尚未取名" or options.info.response.name
	self._avatarFile = options.info.response.avatar or ""
	self._level = options.info.response.level or 0
	self._rank = options.info.response.rank or -1
	self._description = options.info.description or ""
	self._number = options.info.number or 0

	self:setAvatar(self._avatarFile)
	if self._switch == 1 then
		self._ccbOwner.level1:setString("LV." .. self._level)
		self._ccbOwner.nickName1:setString(self._nickName)
		self._ccbOwner.oneBar:setVisible(true)
		self._ccbOwner.twoBar:setVisible(false)
	else
		self._ccbOwner.star:setVisible(options.info.showStar)
		self._ccbOwner.level2:setString("LV." .. self._level)
		self._ccbOwner.nickName2:setString(self._nickName)
		self._ccbOwner.description2:setString(self._description)
		self._ccbOwner.num2:setString(self._number)
		self._ccbOwner.oneBar:setVisible(false)
		self._ccbOwner.twoBar:setVisible(true)
		local offset = self._ccbOwner.description2:getPositionX() + self._ccbOwner.description2:getContentSize().width
		if options.info.showStar then
			self._ccbOwner.star:setPositionX(offset + QUIWidgetTopRank.GAP*2)
			offset = offset + self._ccbOwner.star:getContentSize().width
		end
		self._ccbOwner.num2:setPositionX(offset + QUIWidgetTopRank.GAP)
	end

	if self._rank == 1 then
		self._ccbOwner.first:setVisible(true)
		self._ccbOwner.second:setVisible(false)
		self._ccbOwner.third:setVisible(false)
		self._ccbOwner.other:setVisible(false)
	elseif self._rank == 2 then
		self._ccbOwner.first:setVisible(false)
		self._ccbOwner.second:setVisible(true)
		self._ccbOwner.third:setVisible(false)
		self._ccbOwner.other:setVisible(false)
	elseif self._rank == 3 then
		self._ccbOwner.first:setVisible(false)
		self._ccbOwner.second:setVisible(false)
		self._ccbOwner.third:setVisible(true)
		self._ccbOwner.other:setVisible(false)
	else
		self._ccbOwner.first:setVisible(false)
		self._ccbOwner.second:setVisible(false)
		self._ccbOwner.third:setVisible(false)
		self._ccbOwner.other:setString(self._rank)
	end
end

function QUIWidgetTopRank:setAvatar(avatar)
	-- build objects for avatar
	self._avatar = CCNode:create()
	local ccclippingNode = QFullCircleUiMask.new()
	ccclippingNode:setRadius(50)
	ccclippingNode:addChild(self._avatar)
	self._ccbOwner.node_headPicture:addChild(ccclippingNode)

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

function QUIWidgetTopRank:_onHead()
	if self._parent._isMoving then
		return
	end

	app:getClient():arenaQueryFighterRequest(self._userId, function(data)
		local fighter = data.arenaResponse.fighter
		local force = 0
		if fighter.heros ~= nil then
			for _,hero in pairs(fighter.heros) do
				force = force + hero.force
			end
		end

  		app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogArenaFigterInfo",
    		options = {info = {name = self._nickName, level = self._level, avatar = self._avatarFile, victory = fighter.victory, force = force, 
    		heros = fighter.heros or {}}}}, {isPopCurrentDialog = false})
	end)
end

function QUIWidgetTopRank:getContentHeight()
	return self._contentHeight
end

return QUIWidgetTopRank