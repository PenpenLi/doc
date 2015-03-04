--
-- Author: Your Name
-- Date: 2014-11-28 17:33:14
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetActivityInstance = class("QUIWidgetActivityInstance", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")

QUIWidgetActivityInstance.EVENT_END = "EVENT_END"

function QUIWidgetActivityInstance:ctor()
	local ccbFile = "ccb/Widget_TimeMachine_choose.ccbi"
	local callBacks = {
			-- {ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetActivityInstance._onTriggerClick)},
		}
	QUIWidgetActivityInstance.super.ctor(self,ccbFile,callBacks,options)

  	cc.GameObject.extend(self)
  	self:addComponent("components.behavior.EventProtocol"):exportMethods()
end

function QUIWidgetActivityInstance:setInfo(info)
  	self._info = info
    local headImageTexture =CCTextureCache:sharedTextureCache():addImage(self._info.dungeon_icon)
    self._imgSp = CCSprite:createWithTexture(headImageTexture)
    local size = self._ccbOwner.head_cricle_di:getContentSize()
    local ccclippingNode = QFullCircleUiMask.new()
    ccclippingNode:setRadius(size.width/2)
    ccclippingNode:addChild(self._imgSp)
    self._ccbOwner.content:addChild(ccclippingNode)

    self.dungeonInfo = QStaticDatabase:sharedDatabase():getDungeonConfigByID(self._info.dungeon_id)
    for i=1,6,1 do
        self._ccbOwner["node_"..i]:setVisible(false)
    end
    local unlockLevel = self._info.unlock_team_level or 0
    if unlockLevel <= remote.user.level then
        self._ccbOwner.node_lock:setVisible(false)
        if self.dungeonInfo.name == "难度I" then
          self._ccbOwner.node_1:setVisible(true)
        elseif self.dungeonInfo.name == "难度II" then
          self._ccbOwner.node_2:setVisible(true)
        elseif self.dungeonInfo.name == "难度III" then
          self._ccbOwner.node_3:setVisible(true)
        elseif self.dungeonInfo.name == "难度IV" then
          self._ccbOwner.node_4:setVisible(true)
        elseif self.dungeonInfo.name == "难度V" then
          self._ccbOwner.node_5:setVisible(true)
        elseif self.dungeonInfo.name == "难度VI" then
          self._ccbOwner.node_6:setVisible(true)
        end
        makeNodeFromGrayToNormal(self)
    else
        self._ccbOwner.node_lock:setVisible(true)
        makeNodeFromNormalToGray(self)
    end
end

function QUIWidgetActivityInstance:onEnter()
    self._ccbOwner.head_cricle_di:setTouchEnabled(true)
    self._ccbOwner.head_cricle_di:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._ccbOwner.head_cricle_di:setTouchSwallowEnabled(false)
    self._ccbOwner.head_cricle_di:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIWidgetActivityInstance._onTouch))
end

function QUIWidgetActivityInstance:onExit()
  self._ccbOwner.head_cricle_di:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
end

function QUIWidgetActivityInstance:_onTouch(event)
  	if event.name == "began" then
    	-- QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetActivityInstance.EVENT_BEGAIN , eventTarget = self, info = self.info, config = self.config})
    	return true
  	elseif event.name == "ended" or event.name == "cancel" then
      local unlockLevel = self._info.unlock_team_level or 0
      if unlockLevel <= remote.user.level then
    	   self:dispatchEvent({name = QUIWidgetActivityInstance.EVENT_END , info = self._info})
      else
        app.tip:floatTip("战队"..unlockLevel.."级解锁")
      end
  	end
end

return QUIWidgetActivityInstance