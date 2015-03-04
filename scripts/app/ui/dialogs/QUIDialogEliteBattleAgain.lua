--
-- Author: wkwang
-- Date: 2014-07-14 16:04:20
--
local QUIDialog = import(".QUIDialog")
local QUIDialogEliteBattleAgain = class("QUIDialogEliteBattleAgain", QUIDialog)

local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")
local QUIWidgetEliteBattleAgain = import("..widgets.QUIWidgetEliteBattleAgain")
local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogEliteBattleAgain:ctor(options)

	local ccbFile = "ccb/Dialog_EliteBattleAgain.ccbi"
	local callBacks = {
						{ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogEliteBattleAgain._onTriggerNext)}
					}
    QUIDialogEliteBattleAgain.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true

    self._size = self._ccbOwner.layer_content:getContentSize()

    self._content = CCNode:create()
    local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._size.width,self._size.height)
    local ccclippingNode = CCClippingNode:create()
    layerColor:setPositionY(-self._size.height + 10)
    ccclippingNode:setStencil(layerColor)
    ccclippingNode:addChild(self._content)
    self._ccbOwner.node_contain:addChild(ccclippingNode)

    self._touchLayer = QUIGestureRecognizer.new()
    self._touchLayer:attachToNode(self._ccbOwner.node_contain, self._size.width, self._size.height, 0, layerColor:getPositionY(), handler(self, self._onEvent))

    self._ccbOwner.btn_close:setVisible(false)

    if options ~= nil then
    	if options.awards ~= nil then
    		self:setAwards(options.awards)
    	end

        self.info = options.info
        self.config = options.config
        self._ccbOwner.label_name:setString(self.info.number.." "..self.config.name)
    end 

    self._offsetMoveH = 60
    self._isShowEnd = false
end

function QUIDialogEliteBattleAgain:viewDidAppear()
	QUIDialogEliteBattleAgain.super.viewDidAppear(self)

    self._touchLayer:enable()
    self._touchLayer:setAttachSlide(true)
    self._touchLayer:setSlideRate(0.3)
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self._onEvent))
end

function QUIDialogEliteBattleAgain:viewWillDisappear()

    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
end

function QUIDialogEliteBattleAgain:setAwards(awards)
	self._awardPanels = {}
  self._awardItems = {}
	self._moveIndex = 1
	local numY = 0
	local index = 1
	for _,award in pairs(awards) do
		local panel = QUIWidgetEliteBattleAgain.new()
		self._awardPanels[#self._awardPanels+1] = panel
		panel:setPositionY(numY)
		-- panel:setPositionX(self._size.width/2)
		panel:setTitle(index)
		panel:setInfo(award.awards)
		panel:setVisible(false)
		self._content:addChild(panel)
		
		--将所有奖励物品保存起来
		for _, value in pairs(panel._itemsBox) do
		  table.insert(self._awardItems,value)
    end
		
		numY = numY - panel:getHeight()
        self._panelWidth = panel:getWidth()
        self._panelHeight = panel:getHeight()
		index = index + 1
	end
	self._totalHeight = math.abs(numY)
	self:autoMove()
end

function QUIDialogEliteBattleAgain:autoMove()
    if #self._awardPanels == 1 then
        self._content:setPositionY(0)
        self._touchLayer:disable()
        self._awardPanels[self._moveIndex]:setVisible(true)
        self._awardPanels[self._moveIndex]:startAnimation(function()
            self:_autoMoveWithFinishedAnimation()
        end)
    else
    	if self._moveIndex <= #self._awardPanels  then
    	    self._touchLayer:disable()
    	    self._awardPanels[self._moveIndex]:setVisible(true)
    	    self._awardPanels[self._moveIndex]:startAnimation(function()
                local rate = 1
                if self._moveIndex < 2 then
                    rate = 0
                end
                local actionArrayIn = CCArray:create()
                actionArrayIn:addObject(CCMoveBy:create(0.3, ccp(0,rate * self._panelHeight)))
                actionArrayIn:addObject(CCCallFunc:create(function () 
                    self:_removeAction()
                    self:autoMove()
                end))
                local ccsequence = CCSequence:create(actionArrayIn)
                self.actionHandler = self._content:runAction(ccsequence)
                self._moveIndex = self._moveIndex + 1
            end)
    	else
    	    -- self._awardPanels[self._moveIndex]:setVisible(true)
    	    -- self._awardPanels[self._moveIndex]:startAnimation(function()
         --        self._content:setPositionY(self._totalHeight - self._size.height)
         --        self._touchLayer:disable()
         --        self:_autoMoveWithFinishedAnimation()
         --    end)
            self:_autoMoveWithFinishedAnimation()
    	end
    end
end

function QUIDialogEliteBattleAgain:_autoMoveWithFinishedAnimation()
    local ccbProxy = CCBProxy:create()
    local ccbOwner = {}
    local node = CCBuilderReaderLoad("ccb/effects/saodangwancheng.ccbi", ccbProxy, ccbOwner)
    self._content:addChild(node)
    node:setPosition(self._panelWidth * 0.5, -self._totalHeight - self._panelHeight/4)
    -- node:setPosition(self._panelWidth * 0.5, -self._totalHeight - self._panelHeight)
    self._touchLayer:disable()
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveBy:create(0.3, ccp(0, self._offsetMoveH)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
        self:_removeAction()
        self:_autoMoveWithExtraReward()
    end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self.actionHandler = self._content:runAction(ccsequence)
    self._totalHeight = self._totalHeight + self._panelHeight/2
end

function QUIDialogEliteBattleAgain:_autoMoveWithExtraReward()
    local database = QStaticDatabase:sharedDatabase()
    local config = database:getConfig()
    local dungeonConfig = database:getDungeonConfigByID(self.config.id)
    local reward = {{type = ITEM_TYPE.ITEM, id = dungeonConfig.sweep_id, count = tonumber(dungeonConfig.sweep_num) * (#self._awardPanels)}}
    
    local panel = QUIWidgetEliteBattleAgain.new()
    panel:setPositionY(-self._totalHeight)
    panel:setTitleExtra()
    panel:setInfo(reward)
    self._content:addChild(panel)
    panel:startAnimation(function()
            self._touchLayer:enable()
            remote.user:checkTeamUp()
            self._ccbOwner.btn_close:setVisible(true)
            self._isShowEnd = true
            
            --当动画结束时给物品添加悬浮提示
            for _, value in pairs(panel._itemsBox) do
              table.insert(self._awardItems,value)
            end
            for _, value in pairs(self._awardItems) do
              value:setPromptIsOpen(true)
            end
            
        -- if #self._awardPanels == 1 then
        --     self._touchLayer:enable()
        --     remote.user:checkTeamUp()
        --     self._ccbOwner.btn_close:setVisible(true)
        -- else
        --     self._touchLayer:disable()
        --     local actionArrayIn = CCArray:create()
        --     actionArrayIn:addObject(CCMoveBy:create(0.3, ccp(0, self._panelHeight)))
        --     actionArrayIn:addObject(CCCallFunc:create(function () 
        --         self._touchLayer:enable()
        --         self:_removeAction()
        --         remote.user:checkTeamUp()
        --         self._ccbOwner.btn_close:setVisible(true)
        --     end))
        --     local ccsequence = CCSequence:create(actionArrayIn)
        --     self.actionHandler = self._content:runAction(ccsequence)
        -- end
    end)
    
    self._totalHeight = self._totalHeight + self._panelHeight
end

-- 移除动作
function QUIDialogEliteBattleAgain:_removeAction()
	if self._actionHandler ~= nil then
		self._content:stopAction(self._actionHandler)
		self._actionHandler = nil
	end
end

function QUIDialogEliteBattleAgain:moveTo(time,x,y,callback)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveBy:create(time, ccp(x,y)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    	self:_removeAction()
    	if callback ~= nil then
    		callback()
    	end
    end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self.actionHandler = self._content:runAction(ccsequence)
end

function QUIDialogEliteBattleAgain:_backClickHandler()
    if self._isShowEnd == true then 
        self:_onTriggerClose()
    end
end

function QUIDialogEliteBattleAgain:_onTriggerClose()
    app.sound:playSound("common_close")
    self:playEffectOut()
end

function QUIDialogEliteBattleAgain:_onTriggerNext()
    -- 注释掉 因为如果从装备界面跳转过去贼引导过程中会报错
    -- if app.tutorial:isTutorialFinished() == false then
    -- end
    self:_onTriggerClose()
end

function QUIDialogEliteBattleAgain:viewAnimationOutHandler()
    local page  = app:getNavigationController():getTopPage()
    page:_checkUnlock()
    page:_checkMystoryStores()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_SPECIFIC_CONTROLLER, nil, self)
end

function QUIDialogEliteBattleAgain:_onEvent(event)
	if event.name == "began" then
    	self:_removeAction()
    	self._lastSlidePositionY = event.y
        return true

    elseif event.name == "moved" then
    	local deltaY = event.y - self._lastSlidePositionY
    	local positionY = self._content:getPositionY()
    	self._content:setPositionY(positionY + deltaY * .5)
        self._lastSlidePositionY = event.y
    elseif event.name == "ended" or event.name == "cancelled" then
    elseif event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
		local offset = event.distance.y
        if self._content:getPositionY() + offset > self._totalHeight - self._size.height  then
            if self._totalHeight - self._size.height > 0 then
    		    offset = self._totalHeight - self._size.height - self._content:getPositionY()
            else
                offset = 0 - self._content:getPositionY()
            end
        elseif self._content:getPositionY() + offset < 0 then
    		offset = 0 - self._content:getPositionY()
        end
        self:moveTo(0.3,0,offset)
    end
end

return QUIDialogEliteBattleAgain