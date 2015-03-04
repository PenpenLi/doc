--
-- Author: Your Name
-- Date: 2015-02-05 10:59:49
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetSunWellChest = class("QUIWidgetSunWellChest", QUIWidget)

local QUIViewController = import("..QUIViewController")
local QUIWidgetAnimationPlayer = import("..widgets.QUIWidgetAnimationPlayer")

function QUIWidgetSunWellChest:ctor(options)
  local ccbFile = "ccb/Widget_SunWell_Baoxiang.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerChest", callback = handler(self, QUIWidgetSunWellChest.onTriggerChest)}
  }
  QUIWidgetSunWellChest.super.ctor(self, ccbFile, callBacks, options)
  self._ccbOwner.node_gold:setVisible(false)
  self._ccbOwner.node_zi:setVisible(false)
  self._ccbOwner.node_wood:setVisible(false)
  self.animationIsFinish = false
end
function QUIWidgetSunWellChest:onExit()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
  if self._effectShow ~= nil then
    self._effectShow:disappear()
    self._effectShow = nil
  end
end

function QUIWidgetSunWellChest:setIndex(index)
  self._index = index
  self.open_node = nil
  self.close_node = nil
  self.readyAnimation = nil
  self.openAnimation = nil
  if self._index == 3 or self._index == 6 or self._index == 9 or self._index == 12 then
    self._ccbOwner.node_zi:setVisible(true)
    self.open_node = "node_zi_open"
    self.close_node = "node_zi_close"
    self.readyAnimation = "ccb/effects/sunwell_baoxiang_zi.ccbi"
    self.openAnimation = "ccb/effects/sunwell_baoxiang_zi_open.ccbi"
    self.disappearAnimation = "ccb/effects/sunwell_baoxiang_zi_disappear.ccbi"
  elseif self._index == 15 then
    self._ccbOwner.node_gold:setVisible(true)
    self.open_node = "node_gold_open"
    self.close_node = "node_gold_close"
    self.readyAnimation = "ccb/effects/sunwell_baoxiang.ccbi"
    self.openAnimation = "ccb/effects/sunwell_baoxiang_open.ccbi"
    self.disappearAnimation = "ccb/effects/sunwell_baoxiang_disappear.ccbi"
  else
    self._ccbOwner.node_wood:setVisible(true)
    self.open_node = "node_wood_open"
    self.close_node = "node_wood_close"
    self.readyAnimation = "ccb/effects/sunwell_baoxiang_wood.ccbi"
    self.openAnimation = "ccb/effects/sunwell_baoxiang_wood_open.ccbi"
    self.disappearAnimation = "ccb/effects/sunwell_baoxiang_wood_disappear.ccbi"
  end
end

function QUIWidgetSunWellChest:setIsDraw(b)
  self.isDraw = b
  self._ccbOwner[self.close_node]:setVisible(not b)
  self._ccbOwner[self.open_node]:setVisible(b)

  local needPass = remote.sunWell:getNeedPass()
  if self._index < needPass then
    if self.isDraw == false then
      self:readyToAnimation()
      self:playReadyAnimation()
    end
  end
end

function QUIWidgetSunWellChest:playReadyAnimation()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
  
  if self._effectShow == nil then
    self._effectShow = QUIWidgetAnimationPlayer.new()
    self:getView():addChild(self._effectShow)
  end
  if self.animationIsFinish == false then
    self._effectShow:playAnimation(self.readyAnimation)
  end
    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
    if self.animationIsFinish == false then
       self:playReadyAnimation()
    end
    end, 1.5)
end

function QUIWidgetSunWellChest:playOpenAnimation()
  if self._effectShow == nil then
    self._effectShow = QUIWidgetAnimationPlayer.new()
    self:getView():addChild(self._effectShow)
  end
    self._effectShow:playAnimation(self.openAnimation, nil, handler(self, QUIWidgetSunWellChest.openAnimationStop))
end

function QUIWidgetSunWellChest:playDisappearAnimation()
  if self._effectShow == nil then
    self._effectShow = QUIWidgetAnimationPlayer.new()
    self:getView():addChild(self._effectShow)
  end
    self._effectShow:playAnimation(self.disappearAnimation)
end

function QUIWidgetSunWellChest:readyToAnimation()
  self._ccbOwner[self.close_node]:setVisible(false)
end

function QUIWidgetSunWellChest:openAnimationEnded()
  if self._effectShow ~= nil then
    self._effectShow:disappear(true)
    self._effectShow = nil
  end
  self._ccbOwner[self.open_node]:setVisible(true)
end

--宝箱打开动画结束时调用
function QUIWidgetSunWellChest:openAnimationStop()
  local oldInfo = {money = remote.user:getPropForKey("money"), sunwellMoney = remote.user:getPropForKey("sunwellMoney")}
    app:getClient():sunwellLuckyDrawRequest(self._index, function(data)
      self:setIsDraw(true)
      self:openAnimationEnded()
      self:playDisappearAnimation()
      remote.sunWell:setSunwellLuckyDraw({self._index})
      app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogSunWellChestReceive", options = {index = self._index, data = data, oldInfo = oldInfo}})
  end)
end

function QUIWidgetSunWellChest:onTriggerChest()
  local needPass = remote.sunWell:getNeedPass()
  if math.floor(needPass/3) + 1 < math.ceil(self._index/3) then
    return
  end
  if self._index < needPass then
    if self.isDraw == false then
      if self._effectShow ~= nil then
        self._effectShow:disappear(true)
        self._effectShow = nil
      end
      self.animationIsFinish = true
      self:playOpenAnimation()
    end
  else
    app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogSunWellPrompt", options = {index = self._index}})
  end
end

return QUIWidgetSunWellChest
