--
-- Author: wkwang
-- Date: 2014-10-28 10:08:39
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogBackpack = class("QUIDialogBackpack", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetItemsBox =  import("..widgets.QUIWidgetItemsBox")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetBackPackInfo =  import("..widgets.QUIWidgetBackPackInfo")
local QRemote = import("...models.QRemote")

QUIDialogBackpack.TAB_ALL = "TAB_ALL"
QUIDialogBackpack.TAB_EQUIP = "TAB_EQUIP"
QUIDialogBackpack.TAB_SOUL = "TAB_SOUL"
QUIDialogBackpack.TAB_CONSUM = "TAB_CONSUM"

function QUIDialogBackpack:ctor(options)
	local ccbFile = "ccb/Dialog_Packsack.ccbi"
	local callBacks = {
		-- {ccbCallbackName = "onTriggerBack", 				callback = handler(self, QUIDialogBackpack._onTriggerBack)},
		-- {ccbCallbackName = "onTriggerHome", 				callback = handler(self, QUIDialogBackpack._onTriggerHome)},
		{ccbCallbackName = "onTriggerTabAll", 				callback = handler(self, QUIDialogBackpack._onTriggerTabAll)},
		{ccbCallbackName = "onTriggerTabEquip", 				callback = handler(self, QUIDialogBackpack._onTriggerTabEquip)},
		{ccbCallbackName = "onTriggerTabSoul", 				callback = handler(self, QUIDialogBackpack._onTriggerTabSoul)},
		{ccbCallbackName = "onTriggerTabConsum", 				callback = handler(self, QUIDialogBackpack._onTriggerTabConsum)},

	}
	QUIDialogBackpack.super.ctor(self,ccbFile,callBacks,options)
	app:getNavigationController():getTopPage():setManyUIVisible()
	self:setLock(true)

	self._offsetY = -48
	self._offsetX = 48
	self._scrollShow = false

	self._cellH = self._ccbOwner.sprite_scroll_cell:getContentSize().height
	self._scrollH = self._ccbOwner.sprite_scroll_bar:getContentSize().height - self._cellH

	-- 初始化中间英雄页面滑动框
	self:_initPageSwipe()

end

function QUIDialogBackpack:startEnter()
	self:stopEnter()
    self._onFrameHandler = scheduler.scheduleGlobal(handler(self, self.onFrame), 0)
end

function QUIDialogBackpack:stopEnter()
    if self._onFrameHandler ~= nil then
    	scheduler.unscheduleGlobal(self._onFrameHandler)
    	self._onFrameHandler = nil
    end
end

function QUIDialogBackpack:viewDidAppear()
	QUIDialogBackpack.super.viewDidAppear(self)
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
    QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetItemsBox.EVENT_CLICK, self._itemClickHandler, self)

    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(QRemote.ITEMS_UPDATE_EVENT, handler(self, self.onEvent))
	self:addBackEvent()
end

function QUIDialogBackpack:viewWillDisappear()
  	QUIDialogBackpack.super.viewWillDisappear(self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetItemsBox.EVENT_CLICK, self._itemClickHandler,self)
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
    self._remoteProxy:removeAllEventListeners()
	self:releaseBox()
	self:removeBackEvent()
end

-- 初始化中间的英雄选择框 swipe工能
function QUIDialogBackpack:_initPageSwipe()
	self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
	self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
	self._pageContent = CCNode:create()

	local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._pageWidth,self._pageHeight)
	local ccclippingNode = CCClippingNode:create()
	layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
	layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
	ccclippingNode:setStencil(layerColor)
	ccclippingNode:addChild(self._pageContent)

	self._ccbOwner.sheet:addChild(ccclippingNode)
	
	self._touchLayer = QUIGestureRecognizer.new()
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:setAttachSlide(true)
	self._touchLayer:attachToNode(self._ccbOwner.sheet,self._pageWidth, self._pageHeight, 0, -self._pageHeight, handler(self, self.onTouchEvent))

	self._isAnimRunning = false
	self:_selectTab(QUIDialogBackpack.TAB_ALL)
end

-- 处理各种touch event
function QUIDialogBackpack:onEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == QRemote.ITEMS_UPDATE_EVENT then
		self:_selectTab(self.tab, true)
		if self._infoPanel ~= nil then
			self._infoPanel:refreshInfo()
		end
	end
end

function QUIDialogBackpack:onTouchEvent(event)
	if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
		self:moveTo(event.distance.y, true)
  	elseif event.name == "began" then
  		self:_removeAction()
  		self._startY = event.y
  		self._pageY = self._pageContent:getPositionY()
    elseif event.name == "moved" then
    	local offsetY = self._pageY + event.y - self._startY
        if math.abs(event.y - self._startY) > 10 then
            self._isMove = true
        end
		self:moveTo(offsetY, false)
	elseif event.name == "ended" then
    	scheduler.performWithDelayGlobal(function ()
    		self._isMove = false
    		end,0)
    end
end

function QUIDialogBackpack:_removeAction()
	self:stopEnter()
	if self._actionHandler ~= nil then
		self._pageContent:stopAction(self._actionHandler)		
		self._actionHandler = nil
	end
end

function QUIDialogBackpack:moveTo(posY, isAnimation)
	self._ccbOwner.sprite_scroll_cell:stopAllActions()
	self._ccbOwner.sprite_scroll_bar:stopAllActions()
	if 	self._totalHeight <= self._pageHeight or (math.abs(posY) < 1 and self._scrollShow == false) then
		self._ccbOwner.sprite_scroll_cell:setOpacity(0)
		self._ccbOwner.sprite_scroll_bar:setOpacity(0)
	else
		self._ccbOwner.sprite_scroll_cell:setOpacity(255)
		self._ccbOwner.sprite_scroll_bar:setOpacity(255)
		self._scrollShow = true
	end
	if isAnimation == false then
		self._pageContent:setPositionY(posY)
		self:onFrame()
		return 
	end

	local contentY = self._pageContent:getPositionY()
	local targetY = 0
	if self._totalHeight <= self._pageHeight then
		targetY = 0
	elseif contentY + posY > self._totalHeight - self._pageHeight then
		targetY = self._totalHeight - self._pageHeight
	elseif contentY + posY < 0 then
		targetY = 0
	else
		targetY = contentY + posY
	end
	self:_contentRunAction(0, targetY)
end

function QUIDialogBackpack:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    											self:_removeAction()
    											self:onFrame()
												if 	self._totalHeight > self._pageHeight and self._scrollShow == true then
													self._ccbOwner.sprite_scroll_cell:runAction(CCFadeOut:create(0.3))
													self._ccbOwner.sprite_scroll_bar:runAction(CCFadeOut:create(0.3))
													self._scrollShow = false
												end
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
    self:startEnter()
end

function QUIDialogBackpack:_selectTab(tab, isRefresh)
	if tab ~= self.tab or isRefresh == true then
		self._ccbOwner.node_tab_all:setHighlighted(false)
		self._ccbOwner.node_tab_equip:setHighlighted(false)
		self._ccbOwner.node_tab_soul:setHighlighted(false)
		self._ccbOwner.node_tab_consum:setHighlighted(false)
		self._ccbOwner.node_tab_all:setEnabled(true)
		self._ccbOwner.node_tab_equip:setEnabled(true)
		self._ccbOwner.node_tab_soul:setEnabled(true)
		self._ccbOwner.node_tab_consum:setEnabled(true)
		self.tab = tab
		if tab == QUIDialogBackpack.TAB_ALL then
			self._ccbOwner.node_tab_all:setHighlighted(true)
			self._ccbOwner.node_tab_all:setEnabled(false)
			self._items = remote.items:getItemsByType()
		elseif tab == QUIDialogBackpack.TAB_EQUIP then
			self._ccbOwner.node_tab_equip:setHighlighted(true)
			self._ccbOwner.node_tab_equip:setEnabled(false)
			self._items = remote.items:getItemsByType(ITEM_CATEGORY.EQUIPMENT)
		elseif tab == QUIDialogBackpack.TAB_SOUL then
			self._ccbOwner.node_tab_soul:setHighlighted(true)
			self._ccbOwner.node_tab_soul:setEnabled(false)
			self._items = remote.items:getItemsByType(ITEM_CATEGORY.SOUL)
		elseif tab == QUIDialogBackpack.TAB_CONSUM then
			self._ccbOwner.node_tab_consum:setHighlighted(true)
			self._ccbOwner.node_tab_consum:setEnabled(false)
			self._items = remote.items:getItemsByType(ITEM_CATEGORY.CONSUM)
			table.mergeForArray(self._items, remote.items:getItemsByType(ITEM_CATEGORY.CONSUM_MONEY))
		end
		self:_initPage()
	end
end

function QUIDialogBackpack:_initPage()
	--释放现有的BOX
	if self._virtualBox ~= nil then
		for index,value in pairs(self._virtualBox) do
			if value.icon ~= nil then
				self:setBox(value.icon)
		    	value.icon = nil
			end
		end
	end
	self._virtualBox = {}
	self._ccbOwner.sprite_scroll_cell:setOpacity(0)
	self._ccbOwner.sprite_scroll_bar:setOpacity(0)
	local line = 4
	local posX = self._offsetX
	local posY = self._offsetY
	local cellWidth = 103
	local cellHeight = -100
	local index = 1
	self._totalHeight = 0
	for _,value in pairs(self._items) do
		table.insert(self._virtualBox, {info = value, posX = posX, posY = posY})
		if index%line == 0 then
			posX = self._offsetX
			posY = posY + cellHeight
		else
			posX = posX + cellWidth
		end
		index = index + 1
	end
	self._totalHeight = math.abs(posY + self._offsetY)
	self._pageContent:setPosition(0, 0)
	self:onFrame()
end

function QUIDialogBackpack:onFrame()
	local contentY = self._pageContent:getPositionY()
	for index,value in pairs(self._virtualBox) do
		if value.posY + contentY < -self._pageHeight + self._offsetY or value.posY + contentY > -self._offsetY then
			self:setBox(value.icon)
	    	value.icon = nil
		end
	end
	for index,value in pairs(self._virtualBox) do
		if value.posY + contentY >= -self._pageHeight + self._offsetY and value.posY + contentY <= -self._offsetY then
			if value.icon == nil then
			    value.icon = self:getBox()
			    value.icon:setPosition(value.posX, value.posY)
			    value.icon:setVisible(true)
			    value.icon:resetAll()
			    value.icon:setGoodsInfo(value.info.type, ITEM_TYPE.ITEM, value.info.count)
			end
		end
	end
	if 	self._totalHeight > self._pageHeight and contentY > 0 and contentY <= self._totalHeight - self._pageHeight then
		local cellY = self._scrollH  * (1 - math.abs(contentY) / math.abs(self._totalHeight - self._pageHeight)) + self._cellH/2
		self._ccbOwner.sprite_scroll_cell:setPositionY(cellY)
	end
end

--[[获取BOX从滑动容器中]]
function QUIDialogBackpack:getBox()
	local box = nil
	if self._boxCache ~= nil and #self._boxCache > 0 then
		box = self._boxCache[1]
		table.remove(self._boxCache,1)
	else
		box = QUIWidgetItemsBox.new()
		self._pageContent:addChild(box)
		-- box = app.widgetCache:getWidgetForName("QUIWidgetItemsBox", self._pageContent)
		box:setVisible(false)
	end
	return box
end

--[[移除BOX从滑动容器中]]
function QUIDialogBackpack:setBox(box)
	if box ~= nil then
		if self._boxCache == nil then
			self._boxCache = {}
		end
		table.insert(self._boxCache, box)
		box:setVisible(false)
	end
end

--[[释放BOX到cache中]]
function QUIDialogBackpack:releaseBox()
	if self._boxCache ~= nil then
		-- for _,box in pairs(self._boxCache) do
		-- 	app.widgetCache:setWidgetForName(box, box:getName())
		-- end
		self._boxCache = {}
	end

	-- for index,value in pairs(self._virtualBox) do
	-- 	if value.icon ~= nil then
	-- 		app.widgetCache:setWidgetForName(value.icon, value.icon:getName())
	-- 	end
	-- end
	self._virtualBox = {}
end

function QUIDialogBackpack:_itemClickHandler(event)
	if self._isMove == true then return end
	app.sound:playSound("common_item")
	if self._infoPanel == nil then
		self._infoPanel = QUIWidgetBackPackInfo.new()
		self._infoPanel:setPositionX(-424)
		self._ccbOwner.node_info:addChild(self._infoPanel)
		self._infoPanel:runAction(CCMoveTo:create(0.3,ccp(0,0)))
	end
	if self._infoPanel:isVisible() == false then
		self._infoPanel:setVisible(true)
		self._infoPanel:setPositionX(-424)
		self._infoPanel:runAction(CCMoveTo:create(0.3,ccp(0,0)))
	end
	self._infoPanel:setItemId(event.itemID)
end

-- Tab 全部
function QUIDialogBackpack:_onTriggerTabAll(tag, menuItem)
	if self.tab ~= QUIDialogBackpack.TAB_ALL then
		app.sound:playSound("common_switch")
		self:_selectTab(QUIDialogBackpack.TAB_ALL)
	end
end

-- Tab 全部
function QUIDialogBackpack:_onTriggerTabEquip(tag, menuItem)
	if self.tab ~= QUIDialogBackpack.TAB_EQUIP then
		app.sound:playSound("common_switch")
		self:_selectTab(QUIDialogBackpack.TAB_EQUIP)
	end
end
-- Tab 全部
function QUIDialogBackpack:_onTriggerTabSoul(tag, menuItem)
	if self.tab ~= QUIDialogBackpack.TAB_SOUL then
		app.sound:playSound("common_switch")
		self:_selectTab(QUIDialogBackpack.TAB_SOUL)
	end
end
-- Tab 全部
function QUIDialogBackpack:_onTriggerTabConsum(tag, menuItem)
	if self.tab ~= QUIDialogBackpack.TAB_CONSUM then
		app.sound:playSound("common_switch")
		self:_selectTab(QUIDialogBackpack.TAB_CONSUM)
	end
end

function QUIDialogBackpack:onTriggerBackHandler(tag)
	self:_onTriggerBack()
end

function QUIDialogBackpack:onTriggerHomeHandler(tag)
	self:_onTriggerHome()
end

-- 对话框退出
function QUIDialogBackpack:_onTriggerBack(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- 对话框退出
function QUIDialogBackpack:_onTriggerHome(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

return QUIDialogBackpack