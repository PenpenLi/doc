--
-- Author: wkwang
-- Date: 2014-05-08 16:07:32
--

local QUIWidget = import(".QUIWidget")
local QUIWidgetInstanceHead = class("QUIWidgetInstanceHead", QUIWidget)
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")

QUIWidgetInstanceHead.EVENT_CITY_CLICK = "EVENT_CITY_CLICK"

function QUIWidgetInstanceHead:ctor(ccbFile,options)
	local callBacks = {
			{ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetInstanceHead._onTriggerClick)},
		}
	QUIWidgetInstanceHead.super.ctor(self,ccbFile,callBacks,options)

  	cc.GameObject.extend(self)
  	self:addComponent("components.behavior.EventProtocol"):exportMethods()
end

function QUIWidgetInstanceHead:setInfo(info)
	self._info = info

	self:unSelected()
	if self._info.dungeon_isboss == true then	
		self:setIcon(self._info.dungeon_icon)
	end

	if self._info.isLock == false then
		makeNodeFromNormalToGray(self._ccbOwner.node_root)
		self._ccbOwner.btn_head:setEnabled(false)
	else
		makeNodeFromGrayToNormal(self._ccbOwner.node_root)
		self._ccbOwner.btn_head:setEnabled(true)
	end
	self._ccbOwner.tf_number:setString(self._info.number)
	local starNum = 0
	if self._info.info ~=nil and self._info.info.star ~= nil then
		starNum = self._info.info.star
	end
	for i=1,3,1 do
		self._ccbOwner["star_bg"..i]:setVisible(false)
		if i > starNum then
			self._ccbOwner["star"..i]:setVisible(false)
		else
			self._ccbOwner["star"..i]:setVisible(true)
		end
	end
end

function QUIWidgetInstanceHead:hideStar()
	for i=1,3,1 do
		self._ccbOwner["star_bg"..i]:setVisible(false)
		self._ccbOwner["star"..i]:setVisible(false)
	end
end

function QUIWidgetInstanceHead:isGoldBoss(b)
	if self._info.dungeon_isboss == true and self._info.dungeon_type == DUNGEON_TYPE.ELITE then
		if b == false then
			self._ccbOwner.node_goldboss:setVisible(false)
			self._ccbOwner.node_sliverboss:setVisible(true)
		else
			self._ccbOwner.node_goldboss:setVisible(true)
			self._ccbOwner.node_sliverboss:setVisible(false)
		end
	end
end

function QUIWidgetInstanceHead:setIcon(path)
	local headImageTexture =CCTextureCache:sharedTextureCache():addImage(path)
	if self._imgSp == nil then
		self._imgSp = CCSprite:createWithTexture(headImageTexture)
	    local size = self._ccbOwner.head_cricle_di:getContentSize()
	    local ccclippingNode = QFullCircleUiMask.new()
	    ccclippingNode:setRadius(size.width/2)
	    ccclippingNode:addChild(self._imgSp)
	    self._ccbOwner.node_head_icon:addChild(ccclippingNode)
	else
		self._imgSp:setTexture(headImageTexture)
	end
end

function QUIWidgetInstanceHead:getBg()
	return self._ccbOwner.node_bg
end

function QUIWidgetInstanceHead:getDungeonId()
	return self._info.dungeon_id
end

function QUIWidgetInstanceHead:setTempData(data)
	self.tempData = data
end

function QUIWidgetInstanceHead:getTempData()
	return self.tempData
end

function QUIWidgetInstanceHead:selected()
	self._ccbOwner.node_select:setVisible(true)
	if self._ccbOwner.node_choose then
		self._ccbOwner.node_choose:setVisible(true)
	end
end

function QUIWidgetInstanceHead:unSelected()
	self._ccbOwner.node_select:setVisible(false)
	if self._ccbOwner.node_choose then
		self._ccbOwner.node_choose:setVisible(false)
	end
end

function QUIWidgetInstanceHead:_onTriggerClick()
	self:dispatchEvent({name = QUIWidgetInstanceHead.EVENT_CITY_CLICK, info = self._info})
end

return QUIWidgetInstanceHead