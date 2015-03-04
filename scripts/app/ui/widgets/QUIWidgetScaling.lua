
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetScaling = class("QUIWidgetScaling", QUIWidget)

local QRemote = import("...models.QRemote")
local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")

function QUIWidgetScaling:ctor(options)
	local ccbFile = "ccb/Widget_scaling.ccbi"
	local callbacks = {
                        {ccbCallbackName = "onTriggerOffSideMenu", callback = handler(self, QUIWidgetScaling._onTriggerOffSideMenu)},
                        {ccbCallbackName = "onButtondownSideMenuAchieve", callback = handler(self, QUIWidgetScaling._onButtondownSideMenuAchieve)},
                        {ccbCallbackName = "onButtondownSideMenuHero", callback = handler(self, QUIWidgetScaling._onButtondownSideMenuHero)},
                        {ccbCallbackName = "onButtondownSideMenuBag", callback = handler(self, QUIWidgetScaling._onButtondownSideMenuBag)},
                        {ccbCallbackName = "onButtondownSideMenuTask", callback = handler(self, QUIWidgetScaling._onButtondownSideMenuTask)}
                        }
	QUIWidgetScaling.super.ctor(self, ccbFile, callbacks, options)
	
    -- if options.chat then
    --     self._oldPositonX = options.chat:getPositionX()
    --     self._newPositonX = options.chat:getPositionX() + 120
    --     self._chat = options.chat
    -- end
    self._layer = options.stencil
    self.tips = nil

    self._ccbOwner.node_tips_all:setVisible(false)
    self._ccbOwner.node_tips_hero:setVisible(false)
    self._ccbOwner.node_tips_task:setVisible(false)
    self._ccbOwner.node_tips_achieve:setVisible(false)
	-- handle side menu
    self._DisplaySideMenu = true
    self._isSideMenuDoAnimation = false
    self._animationProxy = QCCBAnimationProxy:create()
    self._animationProxy:retain()
    self._animationManager = tolua.cast(self._ccbView:getUserObject(), "CCBAnimationManager")
    self._animationProxy:connectAnimationEventSignal(self._animationManager, function(name)
        self._name = name
        self:checkTips()
        -- if name == "side_menu_off" or name == "side_menu_on" then
        --     self._isSideMenuDoAnimation = false
        -- end
        self._isSideMenuDoAnimation = false
    end)
    
    self:checkTips()
    self._layer:setVisible(false)
end

function QUIWidgetScaling:checkTips()
    self._ccbOwner.node_tips_all:setVisible(false)
    self._ccbOwner.node_tips_hero:setVisible(false)
    self._ccbOwner.node_tips_task:setVisible(false)
    self._ccbOwner.node_tips_achieve:setVisible(false)
    local heroTips = remote.herosUtil:checkAllHerosIsTip()
    local taskTips = remote.task:checkAllTask()
    local achieveTips = remote.achieve.achieveDone
    if self._name ~= nil and self._name == "side_menu_on" then
        self._ccbOwner.node_tips_hero:setVisible(heroTips)
        self._ccbOwner.node_tips_task:setVisible(taskTips)
        self._ccbOwner.node_tips_achieve:setVisible(achieveTips)
        self._ccbOwner.node_tips_all:setVisible(false)
    else
        if heroTips == true then
            self._ccbOwner.node_tips_all:setVisible(heroTips)
        elseif taskTips == true then
            self._ccbOwner.node_tips_all:setVisible(taskTips)
        elseif achieveTips == true then
            self._ccbOwner.node_tips_all:setVisible(achieveTips)
        end
    end
end

function QUIWidgetScaling:onEnter()    
    self._layer:setTouchEnabled(true)
    self._layer:setTouchSwallowEnabled(true)
    self._layer:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIWidgetScaling._onTouch))
    --数据更新监听
    self._remoteEventProxy = cc.EventProxy.new(remote)
    self._remoteEventProxy:addEventListener(QRemote.ITEMS_UPDATE_EVENT, handler(self, self._onUserDataUpdate))
    self._remoteEventProxy:addEventListener(QRemote.HERO_UPDATE_EVENT, handler(self, self._onUserDataUpdate))
    self._remoteEventProxy:addEventListener(QRemote.TASK_UPDATE_EVENT, handler(self, self._onUserDataUpdate))

    self._taskEventProxy = cc.EventProxy.new(remote.task)
    self._taskEventProxy:addEventListener(remote.task.EVENT_DONE, handler(self, self._onTaskDone))
    self._taskEventProxy:addEventListener(remote.task.EVENT_TIME_DONE, handler(self, self._onUserDataUpdate))

    self._achieveEventProxy = cc.EventProxy.new(remote.achieve)
    self._achieveEventProxy:addEventListener(remote.achieve.EVENT_STATE_UPDATE, handler(self, self._onUserDataUpdate))
end

function QUIWidgetScaling:onExit()
	self._animationProxy:disconnectAnimationEventSignal()
    self._animationProxy:release()
    self._animationProxy = nil
    self._remoteEventProxy:removeAllEventListeners()
    self._taskEventProxy:removeAllEventListeners()
    self._achieveEventProxy:removeAllEventListeners()
    self._taskEventProxy = nil
end

function QUIWidgetScaling:_onTouch(event)
    if event.name == "began" then
        self._layer:setVisible(false)
        self:_onTriggerOffSideMenu()
        return true
    end
end

function QUIWidgetScaling:_onUserDataUpdate(event)
   self:checkTips()
end

function QUIWidgetScaling:_onTaskDone(event)
    if self._name ~= nil and self._name == "side_menu_on" then
        self._ccbOwner.node_tips_task:setVisible(true)
        self._ccbOwner.node_tips_all:setVisible(false)
    else
        self._ccbOwner.node_tips_all:setVisible(true)
    end
end

function QUIWidgetScaling:_onButtondownSideMenuBag( tag, menuItem)
    app.sound:playSound("common_small")
   self._layer:setVisible(false)
   self:willPlayHide()
   return app:getNavigationController():pushViewController(
                        {uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogBackpack"})
end

function QUIWidgetScaling:_onButtondownSideMenuAchieve( tag, menuItem)
    app.sound:playSound("common_small")
  self._layer:setVisible(false)
  self:willPlayHide()
  return app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogAchievement"})  
end

function QUIWidgetScaling:_onButtondownSideMenuTask( tag, menuItem)
    app.sound:playSound("common_small")
   self._layer:setVisible(false)
   self:willPlayHide()
  return app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogDailyTask"})
end

function QUIWidgetScaling:_onButtondownSideMenuHero( tag, menuItem)
    app.sound:playSound("common_small")
   self._layer:setVisible(false)
   self:willPlayHide()
   return app:getNavigationController():pushViewController(
                        {uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogHeroOverview"},
                        {transitionClass = "QUITransitionDialogHeroOverview"})
end

function QUIWidgetScaling:_onTriggerOffSideMenu(tag, menuItem)
	if self._isSideMenuDoAnimation == true then
		return
	end
	local animationName = nil
	if self._DisplaySideMenu == true then
		self._DisplaySideMenu = false
		animationName = "side_menu_off"
        self._layer:setVisible(false)
        app.sound:playSound("common_menu_back")
	else
		self._DisplaySideMenu = true
		animationName = "side_menu_on"
        
        --当前界面是dialog且不是下拉条派生出来的则加一层遮罩
        local dlg = app:getNavigationController():getTopDialog()
        if "UI_TYPE_PAGE" ~= dlg._type and dlg:getLock() == false then
            self._layer:setVisible(true)
        end
        if self._auto and self._auto == true then
            self._animationManager:runAnimationsForSequenceNamed("default")
            self._isSideMenuDoAnimation = true
        end
        app.sound:playSound("common_menu")
	end
    self:scalingDisplay()
	
    self._animationManager:runAnimationsForSequenceNamed(animationName)
    self._isSideMenuDoAnimation = true


end

function QUIWidgetScaling:getScalingStatus()
    return self._DisplaySideMenu
end

function QUIWidgetScaling:scalingDisplay()
   if self._DisplaySideMenu == true then
        self._ccbOwner.button_scaling_down:setVisible(false)
        self._ccbOwner.button_scaling:setVisible(true)
    else
        self._ccbOwner.button_scaling_down:setVisible(true)
        self._ccbOwner.button_scaling:setVisible(false)
    end
end

function QUIWidgetScaling:willPlayShow()
    if self._DisplaySideMenu == false then
        self._animationManager:runAnimationsForSequenceNamed("default")
        self._DisplaySideMenu = true
        self:scalingDisplay()
    end
end

function QUIWidgetScaling:willPlayHide()
    if self._DisplaySideMenu == true then
        self._animationManager:runAnimationsForSequenceNamed("off")
        self._DisplaySideMenu = false
        self:scalingDisplay()
    end
end

function QUIWidgetScaling:getWidth()
	return self:getView():getContentSize().width
end

return QUIWidgetScaling