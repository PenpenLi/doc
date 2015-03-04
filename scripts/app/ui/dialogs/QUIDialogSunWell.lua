--
-- Author: wkwang
-- Date: 2015-01-28 17:14:49
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogSunWell = class("QUIDialogSunWell", QUIDialog)
local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetSunWell = import("..widgets.QUIWidgetSunWell")
local QUIWidgetInstanceHead = import("..widgets.QUIWidgetInstanceHead")
local QShop = import("...utils.QShop")

function QUIDialogSunWell:ctor(options)
	local ccbFile = "ccb/Dialog_SunWell.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerStore", callback = handler(self, QUIDialogSunWell._onTriggerStore)},
		{ccbCallbackName = "onTriggerReset", callback = handler(self, QUIDialogSunWell._onTriggerReset)},
		{ccbCallbackName = "onTriggerRule", callback = handler(self, QUIDialogSunWell._onTriggerRule)},
	}
	QUIDialogSunWell.super.ctor(self,ccbFile,callBacks,options)
	app:getNavigationController():getTopPage():setManyUIVisible()
	self:initScrollArea()
end

function QUIDialogSunWell:viewDidAppear()
    QUIDialogSunWell.super.viewDidAppear(self)
  	self:addBackEvent()

    self._touchLayer:enable()
	self._touchLayer:setSlideRate(0.3)
	self._touchLayer:setAttachSlide(true)
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))

    self.sunwellProxy = cc.EventProxy.new(remote.sunWell)
    self.sunwellProxy:addEventListener(remote.sunWell.EVENT_INSTANCE_UPDATE, handler(self, self.updateSunWellHandler))

    self.userProxy = cc.EventProxy.new(remote.user)
    self.userProxy:addEventListener(remote.user.EVENT_USER_PROP_CHANGE, handler(self, self.updateUserHandler))

    self:initContent()
end

function QUIDialogSunWell:viewWillDisappear()
    QUIDialogSunWell.super.viewWillDisappear(self)
	self:removeBackEvent()

    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()

    self.sunwellProxy:removeAllEventListeners()

    self.userProxy:removeAllEventListeners()

    self:_removeAction()

    if self._content ~= nil then
        self._content:removeAllEventListeners()
    end
end

-- 滑动区域
function QUIDialogSunWell:initScrollArea()
    self.areaSize = self._ccbOwner.sheet_layout:getContentSize()
    self.areaOriginPoint = ccp(self._ccbOwner.sheet_layout:getPosition())
    self._areaContent = CCNode:create()
    self._layerColor = CCLayerColor:create(ccc4(0,0,0,150),self.areaSize.width,self.areaSize.height)
    local ccclippingNode = CCClippingNode:create()
    self._layerColor:setPosition(self.areaOriginPoint.x, self.areaOriginPoint.y)
    ccclippingNode:setStencil(self._layerColor)
    ccclippingNode:addChild(self._areaContent)
    self._ccbOwner.sheet:addChild(ccclippingNode)
    self._touchLayer = QUIGestureRecognizer.new()
    self._touchLayer:attachToNode(self._ccbOwner.sheet, self.areaSize.width, self.areaSize.height, self.areaOriginPoint.x, self.areaOriginPoint.y, handler(self, self.onTouchEvent))

    self._areaWidth = self.areaSize.width
    self._totalWidth = 0
end

function QUIDialogSunWell:initContent()
	self._content = QUIWidgetSunWell.new()
    self._content:addEventListener(QUIWidgetSunWell.EVENT_CLICK, handler(self,self._headClickHandler))
    self._content:addEventListener(QUIWidgetSunWell.EVENT_UI_RESET, handler(self,self._uiResetHandler))
	self._totalWidth = self._content:getContentWidth()
	self._content:setPosition(0, -517)
	self._areaContent:addChild(self._content)
    self:updateSunWellHandler()
    self:updateUserHandler()
end

function QUIDialogSunWell:onTouchEvent(event)
    if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
        self:moveTo(event.distance.x, true)
    elseif event.name == "began" then
        self:_removeAction()
        self._startX = event.x
        self._pageX = self._areaContent:getPositionX()
    elseif event.name == "moved" then
        local offsetX = self._pageX + event.x - self._startX
        self:moveTo(offsetX, false)
        if math.abs(event.x - self._startX) > 10 then
            self._isMove = true
        end
    elseif event.name == "ended" then
        scheduler.performWithDelayGlobal(function ()
            self._isMove = false
            end,0)
    end
end

function QUIDialogSunWell:moveTo(posX, isAnimation)
    if isAnimation == false then
    	if self._totalWidth <= self._areaWidth or posX > 0  then
        	posX = 0
        elseif posX < self._areaWidth - self._totalWidth then
        	posX = self._areaWidth - self._totalWidth
    	end
        self._areaContent:setPositionX(posX)
        return 
    end
    local contentX = self._areaContent:getPositionX()
    local contentY = self._areaContent:getPositionY()
    local targetX = 0
    if self._totalWidth <= self._areaWidth then
        targetX = 0
    elseif contentX + posX < self._areaWidth - self._totalWidth then
        targetX = self._areaWidth - self._totalWidth
    elseif contentX + posX > 0 then
        targetX = 0
    else
        targetX = contentX + posX
    end
    self:_contentRunAction(targetX, contentY)
end

function QUIDialogSunWell:_contentRunAction(posX,posY)
    self:_removeAction()
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                                                self:_removeAction()
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._areaContent:runAction(ccsequence)
end

function QUIDialogSunWell:_removeAction()
    if self._actionHandler ~= nil then
        self._areaContent:stopAction(self._actionHandler)       
        self._actionHandler = nil
    end
end

function QUIDialogSunWell:updateSunWellHandler()
    self._ccbOwner.tf_count:setString(remote.sunWell:getCount() or 0)
end

function QUIDialogSunWell:updateUserHandler()
    self._ccbOwner.tf_money:setString(q.micrometer(remote.user.sunwellMoney or 0))
end

function QUIDialogSunWell:_headClickHandler(event)
    if self._isMove == true then return end
    local index = event.index
  	app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogSunWellChoose", options = {index = index}})
end

function QUIDialogSunWell:_uiResetHandler(event)
    self._totalWidth = self._content:getContentWidth()
    local offsetX = (self._areaWidth/2 - self._content:getNeedPassNode()) - self._areaContent:getPositionX()
    local isAnimation = event.isAnimation
    self:moveTo(offsetX, isAnimation)
end

function QUIDialogSunWell:_onTriggerStore()
  app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogStore", 
  	options = {type = QShop.SUNWELL_SHOP, info = {sunwellMoney = remote.user.sunwellMoney or 0}}}) 
end

function QUIDialogSunWell:_onTriggerReset()
    if remote.sunWell:getCount() > 0 then
        app:alert({content="是否要重置决战太阳之井的进度，重新开始征程？", title="系统提示", comfirmBack=function()
            app:getClient():sunwellResetRequest(function ()
                remote.sunWell:resetCount()
            end)
        end}, false)
    end
end

function QUIDialogSunWell:_onTriggerRule()
  app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogSunWellRule"})
end

function QUIDialogSunWell:onTriggerBackHandler(tag)
	self:_onTriggerBack()
end

function QUIDialogSunWell:onTriggerHomeHandler(tag)
	self:_onTriggerHome()
end

function QUIDialogSunWell:_onTriggerBack()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogSunWell:_onTriggerHome()
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end
	
return QUIDialogSunWell