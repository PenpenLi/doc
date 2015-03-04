--
-- Author: Qinyuanji
-- Date: 2014-11-20
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetArenaAgainstRecord = class("QUIWidgetArenaAgainstRecord", QUIWidget)
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")

QUIWidgetArenaAgainstRecord.PAGE_MARGIN = 40
QUIWidgetArenaAgainstRecord.EVENT_RESPOND_IGNORE = 0.3


function QUIWidgetArenaAgainstRecord:ctor(options)
	local ccbFile = "ccb/Widget_AgainstRecord.ccbi"
	local callBacks = {
		{ccbCallbackName = "onHead", callback = handler(self, QUIWidgetArenaAgainstRecord._onHead)}
	}
	QUIWidgetArenaAgainstRecord.super.ctor(self, ccbFile, callBacks, options)

	self._contentHeight = self._ccbOwner.background:getContentSize().height

	-- build objects for avatar
	self._avatar = CCNode:create()
	local ccclippingNode = QFullCircleUiMask.new()
	ccclippingNode:setRadius(50)
	ccclippingNode:addChild(self._avatar)
	self._ccbOwner.node_headPicture:addChild(ccclippingNode)

    -- lastMoveTime is used to know whether an event is a click or gesture movement
	self._parent = options.parent
	self._userId = options.userId
	self._nickName = options.nickName or ""
	self._level = options.level or ""
	self._avatarFile = options.avatar or "icon/head/orc_warlord.png"
	self._result = options.result == true and 1 or 0 -- 0 means lost
	self._rankChanged = options.rankChanged or 0
	self._time = options.time or -1
end

function QUIWidgetArenaAgainstRecord:onEnter()
	self._ccbOwner.nickName:setString(self._nickName)
	self._ccbOwner.level:setString("LV." .. self._level)
	self._ccbOwner.time:setString(self:getTimeDescription(self._time))
	self:setAvatar(self._avatarFile)

	if self._result == 1 then
		self._ccbOwner.win_flag:setVisible(true)
		self._ccbOwner.lose_flag:setVisible(false)
		if self._rankChanged ~= 0 then
			self._ccbOwner.green_flag:setVisible(true)
			self._ccbOwner.red_flag:setVisible(false)
			self._ccbOwner.green_rankChanged:setString(tostring(self._rankChanged))
		end
	else
		self._ccbOwner.win_flag:setVisible(false)
		self._ccbOwner.lose_flag:setVisible(true)
		if self._rankChanged ~= 0 then
			self._ccbOwner.green_flag:setVisible(false)
			self._ccbOwner.red_flag:setVisible(true)
			self._ccbOwner.red_rankChanged:setString(tostring(self._rankChanged))
		end
	end

	if self._rankChanged == 0 then
		self._ccbOwner.green_flag:setVisible(false)
		self._ccbOwner.red_flag:setVisible(false)
		self._ccbOwner.red_rankChanged:setVisible(false)
	end
end

function QUIWidgetArenaAgainstRecord:getTimeDescription(time)
	local gap = math.floor((q.serverTime()*1000 - time)/1000 )
	if gap > 0 then
		if gap < 60 * 60 then
			return math.floor(gap/60) .. "分钟前"
		elseif gap < 24 * 60 * 60 then
			return math.floor(gap/(60 * 60)) .. "小时前"
		elseif gap < 7 * 24 * 60 * 60 then
			return math.floor(gap/(24 * 60 * 60)) .. "天前"
		else
			return "7天前"
		end
	end

	return "7天前"
end

function QUIWidgetArenaAgainstRecord:onExit()
end

function QUIWidgetArenaAgainstRecord:setAvatar(avatar)
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

function QUIWidgetArenaAgainstRecord:_onHead()
	if self._parent._isMoving then
		return
	end

	app:getClient():arenaQueryFighterRequest(self._userId, function(data)
		local fighter = data.arenaResponse.fighter
		fighter.force = 0
		if fighter.heros ~= nil then
			for _,hero in pairs(fighter.heros) do
				fighter.force = fighter.force + hero.force
			end
		end

  		app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogArenaFigterInfo",
    		options = {info = {name = self._nickName, level = self._level, avatar = self._avatarFile, victory = fighter.victory, force = fighter.force, 
    		heros = fighter.heros or {}}}}, {isPopCurrentDialog = false})
	end)
end

function QUIWidgetArenaAgainstRecord:getContentHeight()
	return self._contentHeight
end

return QUIWidgetArenaAgainstRecord