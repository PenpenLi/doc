--
-- Author: wkwang
-- Date: 2014-08-22 17:30:59
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetLoadBar = class("QUIWidgetLoadBar", QUIWidget)

function QUIWidgetLoadBar:ctor(options)
	local ccbFile = "ccb/Widget_LoginPressBar.ccbi"
	local callBacks = {}
	QUIWidgetLoadBar.super.ctor(self, ccbFile, callBacks, options)

	self._size = self._ccbOwner.node_bar:getContentSize()
	self._masklayer = CCLayerColor:create(ccc4(0,0,0,150),self._size.width,self._size.height)
	self._masklayer:setAnchorPoint(ccp(0,0.5))
	local ccclippingNode = CCClippingNode:create()
	ccclippingNode:setStencil(self._masklayer)
	self._ccbOwner.node_bar:removeFromParent()
	self._ccbOwner.node_bar:setPosition(0, 0)
	ccclippingNode:addChild(self._ccbOwner.node_bar)
	ccclippingNode:setPosition(-self._size.width/2, -self._size.height/2)
	self._ccbOwner.node_mask:addChild(ccclippingNode)

	self:resetAll()
end

function QUIWidgetLoadBar:resetAll()
	self._masklayer:setScaleX(0)
	self._ccbOwner.node_light:setVisible(false)
	self._ccbOwner.tf_percent:setString("0%")
end

function QUIWidgetLoadBar:setPercent(percent)
	self._masklayer:setScaleX(percent)
	self._ccbOwner.node_light:setVisible(false)
	self._ccbOwner.tf_percent:setString(string.format("%d",percent*100).."%")
end

function QUIWidgetLoadBar:setTip(tip)
   tolua.cast(self._ccbOwner.tf_percent:getParent():getChildren():objectAtIndex(4), "CCLabelBMFont"):setString(tip)
end

return QUIWidgetLoadBar