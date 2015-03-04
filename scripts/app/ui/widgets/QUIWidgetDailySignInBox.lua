local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetDailySignInBox = class("QUIWidgetDailySignInBox", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUIWidgetDailySignInBox.EVENT_CLICK = "SIGNINBOX_EVENT_CLICK"

function QUIWidgetDailySignInBox:ctor(options)
  local ccbFile = "ccb/Widget_DailySignIn_Box.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetDailySignInBox._onTriggerClick)}
  }
  QUIWidgetDailySignInBox.super.ctor(self, ccbFile, callBacks, options)

--  self:resetAll()
  self.type = nil
  if options ~= nil then
    self.type = options.type
  end
  self:setItem()
end

function QUIWidgetDailySignInBox:resetAll()
  self._ccbOwner.box_bg:setVisible(false)
  self._ccbOwner.choose:setVisible(false)
  self._ccbOwner.is_ready:setVisible(false)
  self._ccbOwner.num:setString("")
end

function QUIWidgetDailySignInBox:setItem()
  self.itmeBox = QUIWidgetItemsBox.new()
  self._ccbOwner.node_itme:addChild(self.itmeBox)
end

function QUIWidgetDailySignInBox:setItmeBoxInfo(type, id, num, index)
  self.item_type = type
  self.item_id = id or nil
  self.item_num = num
  self.index = index or nil
  self.itmeBox:resetAll()
  if self.item_id ~= nil then
    self.itmeBox:setGoodsInfo(self.item_id, ITEM_TYPE.ITEM, 0)
  else
    self.itmeBox:setGoodsInfo(self.item_id, remote.items:getItemType(self.item_type), 0)
  end
  self._ccbOwner.num:setString("×"..self.item_num)
  
  if self._state == "IS_DONE" then
    self:setSignIsDone()
  elseif self._state == "IS_READY" then
    self:setSignIsReady()
  elseif self._state == "IS_WAITING" then
    self:setSignIsWaiting()
  end

end

--可以签到
function QUIWidgetDailySignInBox:setSignIsReady()
  self._ccbOwner.box_bg:setVisible(false)
  self._ccbOwner.choose:setVisible(false)
  self._ccbOwner.is_ready:setVisible(true)
  self.itmeBox:showSignInBoxEffect(true)
  self._state = "IS_READY"
end

--签到未完成
function QUIWidgetDailySignInBox:setSignIsWaiting()
  self._ccbOwner.box_bg:setVisible(false)
  self._ccbOwner.choose:setVisible(false)
  self._ccbOwner.is_ready:setVisible(false)
  self.itmeBox:showSignInBoxEffect(false)
  self._state = "IS_WAITING"
end

--签到完成
function QUIWidgetDailySignInBox:setSignIsDone()
  self._ccbOwner.box_bg:setVisible(true)
  self._ccbOwner.choose:setVisible(true)
  self._ccbOwner.is_ready:setVisible(false)
  self.itmeBox:showSignInBoxEffect(false)
  self._state = "IS_DONE"
end

function QUIWidgetDailySignInBox:getName()
  return "QUIWidgetDailySignInBox"
end

--设置当前物品签到状态
function QUIWidgetDailySignInBox:setState(state)
  self._state = state
end

function QUIWidgetDailySignInBox:getBoxSize()
  return self._ccbOwner.box_bg:getContentSize()
end

function QUIWidgetDailySignInBox:_onTriggerClick()
  QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetDailySignInBox.EVENT_CLICK, type = self.item_type, id = self.item_id, num = self.item_num, state = self._state, index = self.index, itemType = self.type})
end

return QUIWidgetDailySignInBox
