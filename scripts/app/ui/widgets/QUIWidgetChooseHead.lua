--
-- Author: Qinyuanji
-- Date: 2014-11-20
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetChooseHead = class("QUIWidgetChooseHead", QUIWidget)
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIDialogChooseHead = import("..dialogs.QUIDialogChooseHead")
local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIWidgetChooseHead.AVATAR_GAP = 30
QUIWidgetChooseHead.PAGE_MARGIN = 40
QUIWidgetChooseHead.BREAKTHROUGH_AVATAR_LEVEL = 6
QUIWidgetChooseHead.BREAKTHROUGH_AVATAR_IGNORE = "orc_warlord"
QUIWidgetChooseHead.DEFAULT_COLUMN_NUMBER = 4
QUIWidgetChooseHead.EVENT_RESPOND_IGNORE = 0.3

function QUIWidgetChooseHead:ctor(columnNumber)
	local ccbFile = "ccb/Widget_ChooseHead.ccbi"
	local callBacks = {}
	QUIWidgetChooseHead.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    -- lastMoveTime is used to know whether an event is a click or gesture movement
	self._lastMoveTime = q.time()
	-- calculate a proper width for showing avatar depends on the column numbers
	self._columnNumber = columnNumber and columnNumber or QUIWidgetChooseHead.DEFAULT_COLUMN_NUMBER
	self._pageWidth = self._ccbOwner.layer_content:getContentSize().width
	self._pageHeight = self._ccbOwner.layer_content:getContentSize().height
	self._avatarWidth = (self._pageWidth - 2 * QUIWidgetChooseHead.PAGE_MARGIN + QUIWidgetChooseHead.AVATAR_GAP - self._columnNumber * QUIWidgetChooseHead.AVATAR_GAP) / self._columnNumber

	--
	self._avatarList = {} 
	local defaultAvatars = QStaticDatabase:sharedDatabase():getDefaultAvatars()
	for k, avatar in pairs(defaultAvatars) do
		table.insert(self._avatarList, {index = k, resPath = avatar.icon})
	end
	table.sort( self._avatarList, function (a, b)
		return a.index < b.index
	end)

	--
	self._breakthroughtAvatarList = {}
	for _, heroInfo in pairs(remote.herosUtil.heros) do
		if heroInfo.breakthrough >= QUIWidgetChooseHead.BREAKTHROUGH_AVATAR_LEVEL and heroInfo.actorId ~= QUIWidgetChooseHead.BREAKTHROUGH_AVATAR_IGNORE then
			local resPath = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(heroInfo.actorId).icon
			table.insert(self._breakthroughtAvatarList, {resPath = resPath})
		end
	end

	self:show(self._avatarList, self._breakthroughtAvatarList)
end

-- Remove all the avatar sprite listener
function QUIWidgetChooseHead:onExit()
	if self._avatarSpriteList == nil or #self._avatarSpriteList == 0 then
		return
	end
	for k, v in pairs(self._avatarSpriteList) do
		v.removeEventListener(QUIWidgetHeroHead.EVENT_HERO_HEAD_CLICK, handler(self, self.onAvatarChanged))
	end

	if self._breakthroughAvatarSpriteList == nil or #self._breakthroughAvatarSpriteList == 0 then
		return
	end
	for k, v in pairs(self._breakthroughAvatarSpriteList) do
		v.removeEventListener(QUIWidgetHeroHead.EVENT_HERO_HEAD_CLICK, handler(self, self.onAvatarChanged))
	end
end

-- Show avatar in list style
-- Each avatar has touch event associated
-- When avatar is selected, update with server and send event to outer class
function QUIWidgetChooseHead:show(avatarList, breakthroughAvatarList)
	if avatarList == nil or #avatarList <= 0 then
		return
	end

	-- Show normal avatar
	self._avatarSpriteList = {}
	local index = 0
	local startPosX = QUIWidgetChooseHead.PAGE_MARGIN
	local startPosY = self._ccbOwner.basicAvatar:getPositionY() - QUIWidgetChooseHead.AVATAR_GAP
	local currentPosX = startPosX
	local currentPosY = startPosY
	for k, v in pairs(avatarList) do
	    local sprite = QUIWidgetHeroHead.new()	
	    sprite:setHeroByFile(v.resPath)
	    self._ccbOwner.layer_content:addChild(sprite)
		sprite:addEventListener(QUIWidgetHeroHead.EVENT_HERO_HEAD_CLICK, handler(self, self.onAvatarChanged))

      	sprite:setScale(self._avatarWidth/sprite:getHeroHeadSize().width)
      	sprite:setPosition(currentPosX + self._avatarWidth/2, currentPosY - self._avatarWidth/2)

      	sprite:setBreakthrough(1)

      	table.insert(self._avatarSpriteList, sprite)
      	index = index + 1

      	-- calculate new position X, Y
      	currentPosX = startPosX + (index % self._columnNumber) * (self._avatarWidth + QUIWidgetChooseHead.AVATAR_GAP)
       	currentPosY = startPosY - math.modf(index / self._columnNumber) * (self._avatarWidth + QUIWidgetChooseHead.AVATAR_GAP)	
    end

    -- set break through text position
    if index % self._columnNumber ~= 0 then
    	currentPosY = currentPosY - self._avatarWidth - 2 * QUIWidgetChooseHead.AVATAR_GAP
    else 
     	currentPosY = currentPosY - QUIWidgetChooseHead.AVATAR_GAP
    end
    self._ccbOwner.breakthroughAvatar:setPositionY(currentPosY)

    -- Show breakthrough avatar
 	self._breakthroughAvatarSpriteList = {}
 	index = 0
	startPosX = QUIWidgetChooseHead.PAGE_MARGIN
	startPosY = currentPosY - QUIWidgetChooseHead.AVATAR_GAP
	currentPosX = startPosX
	currentPosY = startPosY
	for k, v in pairs(breakthroughAvatarList) do
	    local sprite = QUIWidgetHeroHead.new()	
	    sprite:setHeroByFile(v.resPath)
	    self._ccbOwner.layer_content:addChild(sprite)
		sprite:addEventListener(QUIWidgetHeroHead.EVENT_HERO_HEAD_CLICK, handler(self, self.onAvatarChanged))

      	sprite:setScale(self._avatarWidth/sprite:getHeroHeadSize().width)
      	sprite:setPosition(currentPosX + self._avatarWidth/2, currentPosY - self._avatarWidth/2)

      	sprite:setBreakthrough(QUIWidgetChooseHead.BREAKTHROUGH_AVATAR_LEVEL)

      	table.insert(self._breakthroughAvatarSpriteList, sprite)
      	index = index + 1

       	-- calculate new position X, Y
      	currentPosX = startPosX + (index % self._columnNumber) * (self._avatarWidth + QUIWidgetChooseHead.AVATAR_GAP)
       	currentPosY = startPosY - math.modf(index / self._columnNumber) * (self._avatarWidth + QUIWidgetChooseHead.AVATAR_GAP)	
    end
   
   	-- set content height
    if index % self._columnNumber ~= 0 then
    	currentPosY = currentPosY - self._avatarWidth - QUIWidgetChooseHead.AVATAR_GAP
    else 
     	currentPosY = currentPosY - QUIWidgetChooseHead.AVATAR_GAP
    end
    self._contentHeight = self._pageHeight - currentPosY
end

-- React on click event, but ignore when moving
-- Quick-x also responds on gesture movement, so we set the lastMoveTime when it's moving, and ignore the event if it issues after the release of gesture too soon 
function QUIWidgetChooseHead:onAvatarChanged(event)
	if q.time() - self._lastMoveTime < QUIWidgetChooseHead.EVENT_RESPOND_IGNORE then
		return
	end
	app.sound:playSound("common_item")

	-- we need to save the new avatar file to local variable because 
	-- success callback is async process, if we click too quickly, the event.target._avatarFile will be nil when success is invoked
	local newAvatarFile = event.target._avatarFile
    app:getClient():changeAvatar(newAvatarFile, function (data)
					QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIDialogChooseHead.NEW_AVATAR_SELECTED, newAvatar = newAvatarFile})
					end)
end

-- React on movement gesture
function QUIWidgetChooseHead:onMove()
	self._lastMoveTime = q.time()
end

function QUIWidgetChooseHead:endMove()
	self._lastMoveTime = q.time()
end

function QUIWidgetChooseHead:getContentHeight()
	return self._contentHeight
end

return QUIWidgetChooseHead