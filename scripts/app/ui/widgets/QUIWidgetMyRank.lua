--
-- Author: Qinyuanji
-- Date: 2014-11-20
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetMyRank = class("QUIWidgetMyRank", QUIWidget)
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")

QUIWidgetMyRank.GAP = 20

function QUIWidgetMyRank:ctor(options)
	local ccbFile = "ccb/Widget_ArenaRank_client1.ccbi"
	local callBacks = {
	}
	QUIWidgetMyRank.super.ctor(self, ccbFile, callBacks, options)

	if options ~= nil then
		self:setInfo(options)
	end
end

-- 2 means two bar, 1 means one bar
function QUIWidgetMyRank:setFlag(flag)
	self._switch = flag
	self._ccbOwner.twoBar:setVisible(flag == 2)
	self._ccbOwner.oneBar:setVisible(flag == 1)
end

function QUIWidgetMyRank:setInfo(options)
	self:hideAllElements()

	self:setAvatar(remote.user.avatar)
	if options.myInfo.rank then
		self._ccbOwner.myRank:setString(options.myInfo.rank)
		self._ccbOwner.myRank:setVisible(true) 
	else
		self._ccbOwner.NA:setVisible(true)
	end

	if self._switch == 1 then
		self._ccbOwner.level1:setString("LV." .. (remote.user.level))
		self._ccbOwner.nickName1:setString((remote.user.nickname == nil or remote.user.nickname == "") and "尚未取名" or remote.user.nickname)
	else
		self._ccbOwner.star:setVisible(options.myInfo.showStar)
		self._ccbOwner.level2:setString("LV." .. (remote.user.level))
		self._ccbOwner.nickName2:setString((remote.user.nickname == nil or remote.user.nickname == "") and "尚未取名" or remote.user.nickname)
		self._ccbOwner.description2:setString(options.myInfo.description or "")
		self._ccbOwner.num2:setString(options.myInfo.number or 0)
		local offset = self._ccbOwner.description2:getPositionX() + self._ccbOwner.description2:getContentSize().width
		if options.myInfo.showStar then
			self._ccbOwner.star:setPositionX(offset + QUIWidgetMyRank.GAP)
			offset = offset + self._ccbOwner.star:getContentSize().width
		end
		self._ccbOwner.num2:setPositionX(offset + QUIWidgetMyRank.GAP)
	end

	if options.myInfo.rank ~= nil and options.myInfo.lastRank ~= nil and options.myInfo.rank ~= options.myInfo.lastRank then
		local rankChanged = options.myInfo.lastRank - options.myInfo.rank
		self._ccbOwner.yesterday:setVisible(true)
		if rankChanged > 0 then
			self._ccbOwner.green_flag:setVisible(true)
			self._ccbOwner.green_rankChanged:setVisible(true)
			self._ccbOwner.green_rankChanged:setString(tostring(math.abs(rankChanged)))
		elseif rankChanged < 0 then
			self._ccbOwner.red_flag:setVisible(true)
			self._ccbOwner.red_rankChanged:setVisible(true)
			self._ccbOwner.red_rankChanged:setString(tostring(math.abs(rankChanged)))
		end
	end
end

function QUIWidgetMyRank:hideAllElements()
	self._ccbOwner.green_flag:setVisible(false)
	self._ccbOwner.red_flag:setVisible(false)
	self._ccbOwner.green_rankChanged:setVisible(false)
	self._ccbOwner.red_rankChanged:setVisible(false)
	self._ccbOwner.yesterday:setVisible(false)
	self._ccbOwner.myRank:setVisible(false)
	self._ccbOwner.NA:setVisible(false)
end

function QUIWidgetMyRank:setAvatar(avatar)
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


function QUIWidgetMyRank:getContentHeight()
	return self._contentHeight
end

return QUIWidgetMyRank