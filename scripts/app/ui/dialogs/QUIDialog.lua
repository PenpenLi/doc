
local QUIViewController = import("..QUIViewController")
local QUIDialog = class("QUIDialog", QUIViewController)

local QUIWidgetOpenEffect = import("..widgets.QUIWidgetOpenEffect")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUIDialog.EFFECT_IN_SCALE = "showDialogScale" --缩放进场
QUIDialog.EFFECT_OUT_SCALE = "hideDialogScale" --缩放出场

function QUIDialog:ctor(ccbFile,callBacks,options)
	QUIDialog.super.ctor(self, QUIViewController.TYPE_DIALOG, ccbFile, callBacks, options)
    self:setOptions(options)

    self.isAnimation = false --是否动画显示
    self.effectInName = QUIDialog.EFFECT_IN_SCALE --采用的动画名称
    self.effectOutName = QUIDialog.EFFECT_OUT_SCALE --采用的动画名称
    self._isLock = false --是否唯一窗口
    if options ~= nil and options.isChild ~= nil then
        self._isChild = options.isChild
    else
        self._isChild =  false
    end

    --创建根节点的动画效果
    local rootCcbFile = "ccb/QBox/QDialog.ccbi"
    self._rootOwner = {}
    local proxy = CCBProxy:create()
    self._root = CCBuilderReaderLoad(rootCcbFile, proxy, self._rootOwner)
    if self._isChild ~= true then
        self._root:setPosition(display.cx, display.cy)
    end
    self._rootAnimationProxy = QCCBAnimationProxy:create()
    self._rootAnimationProxy:retain()
    self._rootAnimationManager = tolua.cast(self._root:getUserObject(), "CCBAnimationManager")
    self._rootAnimationProxy:connectAnimationEventSignal(self._rootAnimationManager, handler(self, self.viewAnimationEndHandler))
    self._rootOwner.dialogTarget:addChild(self._view)
end

function QUIDialog:getOptions()
    return self._options
end

function QUIDialog:setOptions(options)
    self._options = options
end

function QUIDialog:addBackEvent(isShowHome)
    local isShowHome = isShowHome
    if isShowHome == nil then isShowHome = true end
    local page = app:getNavigationController():getTopPage()
    if page ~= nil and page.setBackBtnVisible ~= nil then
        page:setBackBtnVisible(true)
        page:setHomeBtnVisible(isShowHome)
        QNotificationCenter.sharedNotificationCenter():addMainPageEvent(self)
            -- QNotificationCenter.sharedNotificationCenter():addEventListener(QNotificationCenter.EVENT_TRIGGER_BACK, self.onTriggerBackHandler, self)
            -- QNotificationCenter.sharedNotificationCenter():addEventListener(QNotificationCenter.EVENT_TRIGGER_HOME, self.onTriggerHomeHandler, self)
        -- scheduler.performWithDelayGlobal(function ()
        --     QNotificationCenter.sharedNotificationCenter():addEventListener(QNotificationCenter.EVENT_TRIGGER_BACK, self.onTriggerBackHandler, self)
        --     QNotificationCenter.sharedNotificationCenter():addEventListener(QNotificationCenter.EVENT_TRIGGER_HOME, self.onTriggerHomeHandler, self)
        -- end,0)
    end
end

function QUIDialog:removeBackEvent()
    QNotificationCenter.sharedNotificationCenter():removeMainPageEvent(self)
    -- QNotificationCenter.sharedNotificationCenter():removeEventListener(QNotificationCenter.EVENT_TRIGGER_BACK, self.onTriggerBackHandler, self)
    -- QNotificationCenter.sharedNotificationCenter():removeEventListener(QNotificationCenter.EVENT_TRIGGER_HOME, self.onTriggerHomeHandler, self)
    -- local page = app:getNavigationController():getTopPage()
    -- if page ~= nil and page.setBackBtnVisible ~= nil then
    --     page:setBackBtnVisible(false)
    --     page:setHomeBtnVisible(false)
    -- end
end

function QUIDialog:getView()
    return self._root
end

function QUIDialog:getChildView()
    return self._view
end

function QUIDialog:playEffectIn()
    if self._isPlay == true then
        return 
    end
    if self.isAnimation then
        self._isPlay = true
        self._rootAnimationManager:runAnimationsForSequenceNamed(self.effectInName)
    end
end

function QUIDialog:playEffectOut()
    if self._isPlay == true then
        return 
    end
    if self.isAnimation then
        self._isPlay = true
        self._rootAnimationManager:runAnimationsForSequenceNamed(self.effectOutName)
    end
end

--[[
    设置dialog是否锁住
    锁住的dialog同时只会存在一个
--]]
function QUIDialog:setLock(b)
    self._isLock = b
end

function QUIDialog:getLock()
    return self._isLock
end

function QUIDialog:viewDidAppear()
    QUIDialog.super.viewDidAppear(self)
    if self._isChild ~= true then
        self:_enableTouchSwallow()
    end
end

function QUIDialog:viewAnimationEndHandler(name)
    if name == self.effectInName then
        self._isPlay = false
        self:viewAnimationInHandler()
    elseif name == self.effectOutName then
        self:viewAnimationOutHandler()
        self._rootAnimationProxy:disconnectAnimationEventSignal()
        self._rootAnimationProxy:release()
        self._rootAnimationProxy = nil
    end
end

function QUIDialog:viewAnimationInHandler()

end

function QUIDialog:viewAnimationOutHandler()

end

function QUIDialog:onTriggerBackHandler()

end

function QUIDialog:onTriggerHomeHandler()

end

function QUIDialog:viewWillDisappear()
    QUIDialog.super.viewWillDisappear(self)
    self:_disableTouchSwallow()
end

function QUIDialog:_enableTouchSwallow()
    if(self:getView() == nil) then return end

    self._backTouchLayer = CCLayerColor:create(ccc4(0, 0, 0, 128), display.width, display.height)
    self._backTouchLayer:setPosition(-display.width/2, -display.height/2)
    self._backTouchLayer:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._backTouchLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIDialog._onTouchEnable))
    self._backTouchLayer:setTouchEnabled(true)

    self:getView():addChild(self._backTouchLayer,-1)
end

function QUIDialog:_disableTouchSwallow()
    if self._backTouchLayer ~= nil then
        self._backTouchLayer:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
        self._backTouchLayer:setTouchEnabled(false)
        self._backTouchLayer:removeFromParent()
        self._backTouchLayer = nil
    end
end

function QUIDialog:_backClickHandler()
    
end

function QUIDialog:_onTouchEnable(event)
	if event.name == "began" then
		return true
    elseif event.name == "moved" then
        
    elseif event.name == "ended" then
        if self.isAnimation == true and self._isPlay == true then
            return
        end
        scheduler.performWithDelayGlobal(function()
            self:_backClickHandler()
            end,0)
    elseif event.name == "cancelled" then
        
	end
end

return QUIDialog