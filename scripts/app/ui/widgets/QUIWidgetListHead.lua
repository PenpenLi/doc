--
-- Author: Your Name
-- Date: 2014-05-08 16:07:32
--

local QUIWidget = import(".QUIWidget")
local QUIWidgetListHead = class("QUIWidgetListHead", QUIWidget)

local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIDialogSystemPrompt = import("..dialogs.QUIDialogSystemPrompt")
local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIWidgetListHead.HEAD_ON_PRESS = "HEAD_ON_PRESS"

function QUIWidgetListHead:ctor(options)
	local ccbFile = "ccb/Widget_List_2.ccbi"
	local callBacks = {
	{ccbCallbackName = "onPress", callback = handler(self, QUIWidgetListHead._onPress)}
	}
	QUIWidgetListHead.super.ctor(self,ccbFile,callBacks,options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    local size = self._ccbOwner.node_head_cricle:getContentSize()
    self._headContent = CCNode:create()
    local ccclippingNode = QFullCircleUiMask.new()
    -- ccclippingNode:setPosition(ccp(-size.width/2,-size.height/2))
    ccclippingNode:setRadius(size.width/2)
    ccclippingNode:addChild(self._headContent)
    self._ccbOwner.node_head:addChild(ccclippingNode)
end

function QUIWidgetListHead:setInfo(user,isGlobalRank)
	if isGlobalRank == true then
    	self._ccbOwner.label_no:setString(user.position)
    else
    	self._ccbOwner.label_no:setString(user.rank)
    end
    if user.rankCode ~= "R0" then
    	self._ccbOwner.label_titlelevel:setString(user.rankCode)
    else
    	self._ccbOwner.label_titlelevel:setString("")
    end
    self._ccbOwner.label_level:setString(user.level)
    self._ccbOwner.label_name:setString(user.name)
    self._ccbOwner.label_horour:setString(user.honor)
    self:showRankIcon(user.position)

	local headImageTexture =CCTextureCache:sharedTextureCache():addImage(user.icon)
	if self._imgSp == nil then
		self._imgSp = CCSprite:createWithTexture(headImageTexture)
		self._headContent:addChild(self._imgSp)
	else
		self._imgSp:setTexture(headImageTexture)
		self._imgSp:setScale(1)
	end

    self._user = user
end

function QUIWidgetListHead:getUser()
	return self._user
end

function QUIWidgetListHead:getWidth()
	return self._ccbOwner.node_size:getContentSize().width
end

function QUIWidgetListHead:showRankIcon(rank)
	self._ccbOwner.node_r1:setVisible(false)
	self._ccbOwner.node_r2:setVisible(false)
	self._ccbOwner.node_r3:setVisible(false)
	self._ccbOwner.node_r10:setVisible(false)
	self._ccbOwner.node_r11:setVisible(false)

	if rank == 1 then
		self._ccbOwner.node_r1:setVisible(true)
	elseif rank == 2 then
		self._ccbOwner.node_r2:setVisible(true)
	elseif rank == 3 then
		self._ccbOwner.node_r3:setVisible(true)
	elseif rank <= 10 then
		self._ccbOwner.node_r10:setVisible(true)
	else
		self._ccbOwner.node_r11:setVisible(true)
	end
end

function QUIWidgetListHead:_onPress()
	self:dispatchEvent({name = QUIWidgetListHead.HEAD_ON_PRESS, target = self})
end

return QUIWidgetListHead