--
-- Author: wkwang
-- Date: 2014-08-18 20:51:58
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetMonsterHead = class("QUIWidgetMonsterHead", QUIWidget)
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUIWidgetMonsterHead.EVENT_BEGAIN = "MONSTER_EVENT_BEGAIN"
QUIWidgetMonsterHead.EVENT_END = "MONSTER_EVENT_END"

function QUIWidgetMonsterHead:ctor(options, index)
	local ccbFile
	if options.is_boss ~= nil and options.is_boss == true then
		ccbFile = "ccb/Widget_EliteInfo_head.ccbi"
	else
		ccbFile = "ccb/Widget_EliteInfo_MonsterHead.ccbi"
	end
	local callBacks = {
    }
	QUIWidgetMonsterHead.super.ctor(self, ccbFile, callBacks, options)

	local size = self._ccbOwner.head_cricle_di:getContentSize()
	local scale = self._ccbOwner.head_cricle_di:getScale()
    self._headContent = CCNode:create()
    local ccclippingNode = QFullCircleUiMask.new()
    ccclippingNode:setRadius(scale * size.width/2)
    ccclippingNode:addChild(self._headContent)
    self._ccbOwner.content:addChild(ccclippingNode)

    self.config = options
    local displayConfig = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self.config.npc_id)
    local headImageTexture = CCTextureCache:sharedTextureCache():addImage(displayConfig.icon)
  	self._imgSp = CCSprite:createWithTexture(headImageTexture)
  	local imgSize = self._imgSp:getContentSize()
  	self._imgSp:setScale(scale * size.width/imgSize.width)
  	self._headContent:addChild(self._imgSp)
  	self.info = clone(displayConfig)
  	self._size = size
  	self._scale = scale
  	self._index = index
end

function QUIWidgetMonsterHead:getSize()
	return self._ccbOwner.head_size:getContentSize()
end

function QUIWidgetMonsterHead:onEnter()
  self._ccbOwner.head_cricle_di:setTouchEnabled(true)
  self._ccbOwner.head_cricle_di:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
  self._ccbOwner.head_cricle_di:setTouchSwallowEnabled(false)
  self._ccbOwner.head_cricle_di:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIWidgetMonsterHead._onTouch))
end

function QUIWidgetMonsterHead:onExit()
  self._ccbOwner.head_cricle_di:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
end

function QUIWidgetMonsterHead:_onTouch(event)
  if event.name == "began" then
     QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetMonsterHead.EVENT_BEGAIN , eventTarget = self, info = self.info, config = self.config})
--    local position = self._ccbOwner.cityNode:convertToWorldSpaceAR(ccp(0, 0))
--    self.prompt = QUIWidgetMonsterPrompt.new({info = self.info, size = self._size, scale = self._scale, config = self.config})
--    local positionX = position.x + self.prompt.size.width/5 - (self._index-1) * 100
--    local positionY = position.y - self:getSize().height/2 + (self.prompt.skillChange+self.prompt.contentChange)
--    self.prompt:setPosition(positionX, positionY)
--    self._ccbOwner.head_cricle_di:addChild(self.prompt)
    return true
  elseif event.name == "ended" or event.name == "cancel" then
    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetMonsterHead.EVENT_END , eventTarget = self})
--    self.prompt:removeFromParent()
  end
end
return QUIWidgetMonsterHead