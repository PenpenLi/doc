--
-- Author: wkwang
-- Date: 2014-08-27 10:28:31
-- 顶级弹窗 使用getNavigationMidLayerController
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogItemDropInfo = class("QUIDialogItemDropInfo", QUIDialog)

local QUIWidgetItemDropInfoCell = import("..widgets.QUIWidgetItemDropInfoCell")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")

function QUIDialogItemDropInfo:ctor(options)
 	local ccbFile = "ccb/Dialog_ItemDropInfo.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogItemDropInfo._onTriggerClose)},
    }
    QUIDialogItemDropInfo.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = true

    self._pageWidth = self._ccbOwner.node_info_mask:getContentSize().width
    self._pageHeight = self._ccbOwner.node_info_mask:getContentSize().height
    self._pageContent = self._ccbOwner.node_info
    self._orginalPosition = ccp(self._pageContent:getPosition())

    local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._pageWidth,self._pageHeight)
    local ccclippingNode = CCClippingNode:create()
    layerColor:setPositionX(self._ccbOwner.node_info_mask:getPositionX())
    layerColor:setPositionY(self._ccbOwner.node_info_mask:getPositionY())
    ccclippingNode:setStencil(layerColor)
    self._pageContent:removeFromParent()
    ccclippingNode:addChild(self._pageContent)
    self._ccbOwner.node_info_mask:getParent():addChild(ccclippingNode)

    self._touchLayer = QUIGestureRecognizer.new()
    self._touchLayer:setAttachSlide(true)
    self._touchLayer:attachToNode(self._ccbOwner.node_info_mask:getParent(),self._pageWidth, self._pageHeight, self._ccbOwner.node_info_mask:getPositionX(), 
        self._ccbOwner.node_info_mask:getPositionY(), handler(self, self.onTouchEvent))

    self._itemId = options.itemId
    if self:showItemInfo() == true then
        self:showItemDropInfo()
    end
end

function QUIDialogItemDropInfo:viewDidAppear()
    if self._isChild ~= true then
        QUIDialogItemDropInfo.super.viewDidAppear(self)
    end
    self:touchEnable()
end

function QUIDialogItemDropInfo:viewWillDisappear()
    self._touchLayer:removeAllEventListeners()
    self:touchDisable()
end

function QUIDialogItemDropInfo:touchEnable()
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
end

function QUIDialogItemDropInfo:touchDisable()
    self._touchLayer:disable()
    self._touchLayer:detach()
end

function QUIDialogItemDropInfo:viewAnimationOutHandler()
    self:removeSelfFromParent()
end

--显示物品信息
function QUIDialogItemDropInfo:showItemInfo()
	if self._itemIcon == nil then
		self._itemIcon = QUIWidgetItemsBox.new()
        self._itemIcon:resetAll()
		self._ccbOwner.node_item:addChild(self._itemIcon)
	end
    self._itemIcon:setGoodsInfo(self._itemId,ITEM_TYPE.ITEM,0)

    local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(self._itemId)
    self._ccbOwner.tf_name:setString(itemConfig.name)

    if itemConfig.type == ITEM_CATEGORY.SCRAP or itemConfig.type == ITEM_CATEGORY.SOUL then
        self._ccbOwner.tf_num:setString("已获得："..remote.items:getItemsNumByID(self._itemId).."/"..itemConfig.grid_limit)
    else
        self._ccbOwner.tf_num:setString("已拥有 "..remote.items:getItemsNumByID(self._itemId).." 件")
    end

    self._ccbOwner.tf_drop_info:setString("")
    if itemConfig.approach ~= nil then
        self._ccbOwner.tf_drop_info:setString(itemConfig.approach)
        return false
    end
    return true
end

--显示物品掉落信息
function QUIDialogItemDropInfo:showItemDropInfo()
	local dropInfo = remote.instance:getDropInfoByItemId(self._itemId, DUNGEON_TYPE.ALL)
	self._dropItem = {}
    self._totalHeight = 0
    table.sort(dropInfo,function (a,b)
        if a.map.isLock == true and b.map.isLock == false then
            return true
        end
        if a.map.isLock == false and b.map.isLock == true then
            return false
        end
        if a.map.dungeon_type == DUNGEON_TYPE.NORMAL and b.map.dungeon_type ~= DUNGEON_TYPE.NORMAL then
            return true
        end
        if a.map.dungeon_type ~= DUNGEON_TYPE.NORMAL and b.map.dungeon_type == DUNGEON_TYPE.NORMAL then
            return false
        end
        return a.map.id < b.map.id
    end)
	for _,value in pairs(dropInfo) do
		local index = #self._dropItem
		local item = QUIWidgetItemDropInfoCell.new(value)
		item:setPositionY(-self._totalHeight)
        self._totalHeight = self._totalHeight + item:getContentSize().height
		self._dropItem[index+1] = item
		self._pageContent:addChild(item)
	end
end

function QUIDialogItemDropInfo:onTouchEvent(event)
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
            if self._isMove == false then
                for _,item in pairs(self._dropItem) do
                    item:setEnabled(false)
                end
            end
            self._isMove = true
        end
        self:moveTo(offsetY, false)
    elseif event.name == "ended" then
        scheduler.performWithDelayGlobal(function ()
            if self._isMove == true then
                for _,item in pairs(self._dropItem) do
                    item:setEnabled(true)
                end
            end
            self._isMove = false
            end,0)
    end
end

function QUIDialogItemDropInfo:_removeAction()
    if self._actionHandler ~= nil then
        self._pageContent:stopAction(self._actionHandler)       
        self._actionHandler = nil
    end
end

function QUIDialogItemDropInfo:moveTo(posY, isAnimation)
    if isAnimation == false then
        self._pageContent:setPositionY(posY)
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

function QUIDialogItemDropInfo:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                                                self:_removeAction()
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
end

function QUIDialogItemDropInfo:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogItemDropInfo:_onTriggerClose()
    self:playEffectOut()
end

function QUIDialogItemDropInfo:removeSelfFromParent()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogItemDropInfo