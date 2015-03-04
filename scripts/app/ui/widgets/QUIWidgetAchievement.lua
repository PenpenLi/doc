--
-- Author: wkwang
-- Date: 2014-08-16 10:44:32
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetAchievement = class("QUIWidgetAchievement", QUIWidget)
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIDialogEliteBoxAlert = import("..dialogs.QUIDialogEliteBoxAlert")
local QUIViewController = import("..QUIViewController")

function QUIWidgetAchievement:ctor(options)
	local ccbFile = "ccb/Widget_achievement.ccbi"
	local callbacks = {
                        {ccbCallbackName = "onTriggerBoxCopper", callback = handler(self, QUIWidgetAchievement._onTriggerBoxCopper)},
                        {ccbCallbackName = "onTriggerBoxSilver", callback = handler(self, QUIWidgetAchievement._onTriggerBoxSilver)},
                        {ccbCallbackName = "onTriggerBoxGold", callback = handler(self, QUIWidgetAchievement._onTriggerBoxGold)},
                    }
	QUIWidgetAchievement.super.ctor(self, ccbFile, callbacks, options)


    self._size = self._ccbOwner.node_bar:getContentSize()
    self._scaleX = self._ccbOwner.node_bar:getScaleX()
    self._size.width = self._size.width * self._scaleX
    if self._starMaskLayer == nil then
        self._ccbOwner.node_bar:removeFromParent()
        self._starMaskLayer = CCLayerColor:create(ccc4(0,0,255,150),0, self._size.height)
        local ccclippingNode = CCClippingNode:create()
        self._starMaskLayer:setPositionY(-self._size.height/2)
        self._starMaskLayer:setPositionX(-self._size.width/2)
        ccclippingNode:setStencil(self._starMaskLayer)
        ccclippingNode:addChild(self._ccbOwner.node_bar)
        self._ccbOwner.node_mask:addChild(ccclippingNode)
    end
    self._positions= {}
    table.insert(self._positions, ccp(self._ccbOwner.node_copper:getPosition()))
    table.insert(self._positions, ccp(self._ccbOwner.node_silver:getPosition()))
    table.insert(self._positions, ccp(self._ccbOwner.node_gold:getPosition()))
    self:resetAll()
end

function QUIWidgetAchievement:resetAll()
    self._ccbOwner.node_copper:setVisible(false)
    self._ccbOwner.node_silver:setVisible(false)
    self._ccbOwner.node_gold:setVisible(false)
    self._ccbOwner.node_copper:setPosition(self._positions[1])
    self._ccbOwner.node_silver:setPosition(self._positions[2])
    self._ccbOwner.node_gold:setPosition(self._positions[3])
    self._ccbOwner.node_copper_open:setVisible(false)
    self._ccbOwner.node_copper_close:setVisible(false)
    self._ccbOwner.node_copper_light:setVisible(false)

    self._ccbOwner.node_silver_open:setVisible(false)
    self._ccbOwner.node_silver_close:setVisible(false)
    self._ccbOwner.node_silver_light:setVisible(false)

    self._ccbOwner.node_gold_open:setVisible(false)
    self._ccbOwner.node_gold_close:setVisible(false)
    self._ccbOwner.node_gold_light:setVisible(false)
    self._starMaskLayer:setContentSize(CCSize(0,self._size.height))
end

--设置宝箱掉落信息
function QUIWidgetAchievement:starDrop(instanceId,currentStar,totalStar)
    self:resetAll()
    self._instanceId = instanceId
    self._currentStar = currentStar or 0
    self._totalStar = totalStar or 0

    remote.instance:getDropBoxInfoById(self._instanceId,handler(self, self.getDropInfo))
end

function QUIWidgetAchievement:getDropInfo(info)
    self._dropInfo = info
    local achievementConfig = QStaticDatabase:sharedDatabase():getMapAchievement(self._instanceId)
    if achievementConfig ~= nil then
        self:_starShow(self._ccbOwner.node_copper_close, self._ccbOwner.node_copper_open, self._ccbOwner.node_copper_light, self._ccbOwner.tf_copper, self._ccbOwner.node_copper, achievementConfig.box1, info.isDraw1)
        self:_starShow(self._ccbOwner.node_silver_close, self._ccbOwner.node_silver_open, self._ccbOwner.node_silver_light, self._ccbOwner.tf_silver, self._ccbOwner.node_silver, achievementConfig.box2, info.isDraw2)
        self:_starShow(self._ccbOwner.node_gold_close, self._ccbOwner.node_gold_open, self._ccbOwner.node_gold_light, self._ccbOwner.tf_gold, self._ccbOwner.node_gold, achievementConfig.box3, info.isDraw3)

        local offsetX = 50

        if achievementConfig.box3 ~= nil then
            self._ccbOwner.node_gold:setPositionX(self._ccbOwner.node_copper:getPositionX() - offsetX + self._size.width * self._scaleX * achievementConfig.box3 / self._totalStar)
        end
        if achievementConfig.box2 ~= nil then
            self._ccbOwner.node_silver:setPositionX(self._ccbOwner.node_copper:getPositionX() - offsetX + self._size.width * self._scaleX * achievementConfig.box2 / self._totalStar)
        end
        if achievementConfig.box1 ~= nil then
            self._ccbOwner.node_copper:setPositionX(self._ccbOwner.node_copper:getPositionX() - offsetX + self._size.width * self._scaleX * achievementConfig.box1 / self._totalStar)
        end
        -- if achievementConfig.box1 ~= nil and achievementConfig.box2 ~= nil and achievementConfig.box3 == nil then
        --     self._ccbOwner.node_silver:setPositionX(self._ccbOwner.node_gold:getPositionX())
        -- elseif achievementConfig.box1 ~= nil and achievementConfig.box2 == nil and achievementConfig.box3 == nil then
        --     self._ccbOwner.node_copper:setPositionX(self._ccbOwner.node_gold:getPositionX())
        -- end
        self._starMaskLayer:setContentSize(CCSize(self._size.width * self._scaleX * self._currentStar / self._totalStar, self._size.height))
    end
end

function QUIWidgetAchievement:_starShow(closeNode,openNode,lightNode,tf,node,value,b)
    if value ~= nil then
        tf:setString(tostring(value))
        node:setVisible(true)
        if b == true then
            openNode:setVisible(true)
        else
            closeNode:setVisible(true)
            if tonumber(value) > self._currentStar then
                makeNodeFromNormalToGray(closeNode)
                -- closeNode:setEnabled(false)
            else
                makeNodeFromGrayToNormal(closeNode)
                lightNode:setVisible(true)
                -- closeNode:setEnabled(true)
            end
        end
    end
end

function QUIWidgetAchievement:luckyDrawMap(index)
    if self._alert ~= nil then
        self._alert:removeAllEventListeners()
        self._alert = nil
    end
    self._alert = app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogEliteBoxAlert",
        options = {starNum = self._currentStar, isGet = self._dropInfo["isDraw"..index], index = index, instance_id = self._instanceId}},{isPopCurrentDialog = false})
    if self._alert ~= nil then
        self._alert:addEventListener(QUIDialogEliteBoxAlert.EVENT_GET_SUCC, handler(self, self._onCheckSucc))
    end
end

function QUIWidgetAchievement:_onCheckSucc(event)
    for id,value in pairs(event.data.mapStars) do
        remote.instance:setDropBoxInfoById(id,value)
    end
    self:resetAll()
    remote.instance:getDropBoxInfoById(self._instanceId,handler(self, self.getDropInfo))
end

--开铜箱
function QUIWidgetAchievement:_onTriggerBoxCopper()
    app.sound:playSound("battle_starbox")
    self:luckyDrawMap(1)
end

--开银箱
function QUIWidgetAchievement:_onTriggerBoxSilver()
    app.sound:playSound("battle_starbox")
    self:luckyDrawMap(2)
end

--开金箱
function QUIWidgetAchievement:_onTriggerBoxGold()
    app.sound:playSound("battle_starbox")
    self:luckyDrawMap(3)
end

return QUIWidgetAchievement