--
-- Author: wkwang
-- Date: 2014-10-25 10:29:58
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogTreasureChestDraw = class("QUIDialogTreasureChestDraw", QUIDialog)

local QUIWidgetChestGold = import("..widgets.QUIWidgetChestGold")
local QUIWidgetChestSilver = import("..widgets.QUIWidgetChestSilver")
local QUIWidgetChestGoldInfo = import("..widgets.QUIWidgetChestGoldInfo")
local QUIWidgetChestSilverInfo = import("..widgets.QUIWidgetChestSilverInfo")
local QNavigationController = import("...controllers.QNavigationController")
local QFlag = import("...utils.QFlag")

function QUIDialogTreasureChestDraw:ctor(options)
	local ccbFile = "ccb/Dialog_TreasureChestDraw.ccbi"
    local callBacks = {
        -- {ccbCallbackName = "onTriggerHome", callback = handler(self, QUIDialogTreasureChestDraw._onTriggerHome)},
        -- {ccbCallbackName = "onTriggerBack", callback = handler(self, QUIDialogTreasureChestDraw._onTriggerBack)},
    }
    QUIDialogTreasureChestDraw.super.ctor(self, ccbFile, callBacks, options)
	--app:getNavigationController():getTopPage():setManyUIVisible()

	self._pageWidth = self._ccbOwner.node_mask:getContentSize().width
    self._pageHeight = self._ccbOwner.node_mask:getContentSize().height
    self._pageContent = self._ccbOwner.node_contain
    self._orginalPosition = ccp(self._pageContent:getPosition())

    local layerColor = CCLayerColor:create(ccc4(255,0,0,150),self._pageWidth,self._pageHeight)
    local ccclippingNode = CCClippingNode:create()
    layerColor:setPositionX(self._ccbOwner.node_mask:getPositionX())
    layerColor:setPositionY(self._ccbOwner.node_mask:getPositionY())
    ccclippingNode:setStencil(layerColor)
    self._pageContent:removeFromParent()
    ccclippingNode:addChild(self._pageContent)

    self._ccbOwner.node_mask:getParent():addChild(ccclippingNode)

    self._sliverPanel = QUIWidgetChestSilver.new()
    self._goldPanel = QUIWidgetChestGold.new()
    self._sliverInfo = QUIWidgetChestSilverInfo.new()
    self._sliverInfo:setPositionY(-500)
    self._goldInfo = QUIWidgetChestGoldInfo.new()
    self._goldInfo:setPositionY(-500)
    self._ccbOwner.sliver_contain:addChild(self._sliverPanel)
    self._ccbOwner.sliver_contain:addChild(self._sliverInfo)
    self._ccbOwner.gold_contain:addChild(self._goldPanel)
    self._ccbOwner.gold_contain:addChild(self._goldInfo)

	self._silverP = ccp(self._ccbOwner.sliver_contain:getPosition())
	self._goldP = ccp(self._ccbOwner.gold_contain:getPosition())	
	self:getIsFristBuy()
end

function QUIDialogTreasureChestDraw:getIsFristBuy()
	remote.flag:get({QFlag.FLAG_FRIST_GOLD_CHEST,QFlag.FLAG_FRIST_SILVER_CHEST},function(data)
			if data[QFlag.FLAG_FRIST_GOLD_CHEST] ~= "" then
				self._goldPanel:setIsFrist(false)
				self._goldInfo:setIsFrist(false)
			else
				self._goldPanel:setIsFrist(true)
				self._goldInfo:setIsFrist(true)
			end
			if data[QFlag.FLAG_FRIST_SILVER_CHEST] ~= "" then
				self._sliverPanel:setIsFrist(false)
				self._sliverInfo:setIsFrist(false)
			else
				self._sliverPanel:setIsFrist(true)
				self._sliverInfo:setIsFrist(true)
			end
		end)
end

function QUIDialogTreasureChestDraw:viewDidAppear()
	QUIDialogTreasureChestDraw.super.viewDidAppear(self)
	self._sliverPanel:addEventListener(QUIWidgetChestSilver.EVENT_VIEW, handler(self, self.silverViewHandler))
	self._goldPanel:addEventListener(QUIWidgetChestGold.EVENT_VIEW, handler(self, self.goldViewHandler))
	self._sliverInfo:addEventListener(QUIWidgetChestSilverInfo.EVENT_BACK, handler(self, self.silverBackHandler))
	self._goldInfo:addEventListener(QUIWidgetChestGoldInfo.EVENT_BACK, handler(self, self.goldBackHandler))

	remote.flag:addEventListener(remote.flag.EVENT_UPDATE, handler(self, self.updateFristBuy))
	self:addBackEvent()
end

function QUIDialogTreasureChestDraw:viewWillDisappear()
  	QUIDialogTreasureChestDraw.super.viewWillDisappear(self)
	self._sliverPanel:removeAllEventListeners()
	self._goldPanel:removeAllEventListeners()
	self._sliverInfo:removeAllEventListeners()
	self._goldInfo:removeAllEventListeners()
	remote.flag:removeAllEventListeners()
	self:removeBackEvent()
end

function QUIDialogTreasureChestDraw:updateFristBuy()
	self:getIsFristBuy()
end

function QUIDialogTreasureChestDraw:silverViewHandler()
	self._ccbOwner.sliver_contain:runAction(CCMoveTo:create(0.3, ccp(self._silverP.x, self._silverP.y+500)))
end

function QUIDialogTreasureChestDraw:goldViewHandler()
	self._ccbOwner.gold_contain:runAction(CCMoveTo:create(0.3, ccp(self._goldP.x, self._goldP.y+500)))
end

function QUIDialogTreasureChestDraw:silverBackHandler()
	self._ccbOwner.sliver_contain:runAction(CCMoveTo:create(0.3, self._silverP))
end

function QUIDialogTreasureChestDraw:goldBackHandler()
	self._ccbOwner.gold_contain:runAction(CCMoveTo:create(0.3, self._goldP))
end

function QUIDialogTreasureChestDraw:onTriggerBackHandler(tag)
	self:_onTriggerBack()
end

function QUIDialogTreasureChestDraw:onTriggerHomeHandler(tag)
	self:_onTriggerHome()
end

function QUIDialogTreasureChestDraw:_onTriggerHome()
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

function QUIDialogTreasureChestDraw:_onTriggerBack()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogTreasureChestDraw:_backClickHandler()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogTreasureChestDraw