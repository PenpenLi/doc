--
-- Author: wkwang
-- Date: 2015-01-15 15:42:22
-- 此widget没有使用CCB文件
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetUserHead = class("QUIWidgetUserHead", QUIWidget)

local QFullCircleUiMask = import("..battle.QFullCircleUiMask")

function QUIWidgetUserHead:ctor(options)
	QUIWidgetUserHead.super.ctor(self,ccbFile,callBacks,options)

	--init head frame and bg sprite 
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ui/Elite_normol.plist")
	self._bgSp = CCSprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("head_cricle_di.png"))
	self:addChild(self._bgSp)
	self._icon = CCSprite:create()
	self:addChild(self._icon)
	self._frameSp = CCSprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("head_cricle.png"))
	self:addChild(self._frameSp)
	--添加头像的圆形遮罩
	self._headContent = CCNode:create()
	local ccclippingNode = QFullCircleUiMask.new()
	ccclippingNode:setRadius(50)
	ccclippingNode:addChild(self._headContent)
	self._icon:addChild(ccclippingNode)

	--init node for user level sprite
	self._levelSp = CCSprite:create()
	self._levelSp:setPosition(-51, 30)
	self:addChild(self._levelSp)
	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ui/Pagehome2.plist");
	self._levelSp:addChild(CCSprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("level_cricle.png")))
	self._tfLevel = ui.newBMFontLabel({
	    text = "0",
	    font = "font/FontHeroHeadLevel.fnt",
	})
	self._tfLevel:setGap(-2)
	self._levelSp:addChild(self._tfLevel)
	self:setUserAvatar()
end

function QUIWidgetUserHead:setUserAvatar(url)
	if url == nil or url == "" then url = "icon/head/orc_warlord.png" end
	local texture = CCTextureCache:sharedTextureCache():addImage(url)
    if texture ~= nil then
      local sprite = CCSprite:createWithTexture(texture)
      local size = self._bgSp:getContentSize()
      sprite:setScale(size.width/sprite:getContentSize().width)
      self._headContent:removeAllChildren()
      self._headContent:addChild(sprite)
    end
end

function QUIWidgetUserHead:setUserLevel(level)
	self._tfLevel:setString(level)
end

function QUIWidgetUserHead:setUserLevelVisible(b)
	self._levelSp:setVisible(b)
end

return QUIWidgetUserHead