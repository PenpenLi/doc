local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogSunWellChestReceive = class("QUIDialogSunWellChestReceive", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")

function QUIDialogSunWellChestReceive:ctor(options)
  local ccbFile = "ccb/Dialog_DailySignInComplete2.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogSunWellChestReceive._onTriggerConfirm)}
  }
  QUIDialogSunWellChestReceive.super.ctor(self, ccbFile, callBacks, options)
  self.isAnimation = true
  self.isSignIn = false
  
  self.index = options.index
  local oldInfo = options.oldInfo
  local newInfo = {money = remote.user:getPropForKey("money"), sunwellMoney = remote.user:getPropForKey("sunwellMoney")}
  self.money = newInfo.money - oldInfo.money

  self.prizes = options.data.prizes[1]
  
  self.sunwellMoney = newInfo.sunwellMoney - oldInfo.sunwellMoney
  
--  self._ccbOwner.tf_value1:setString("x"..self.num)
  self:setItemInfo()
  
end

function QUIDialogSunWellChestReceive:viewDidAppear()
  QUIDialogSunWellChestReceive.super.viewDidAppear(self)
end

function QUIDialogSunWellChestReceive:viewAnimationOutHandler()
  self:removeSelfFromParent()
end

function QUIDialogSunWellChestReceive:setItemInfo()
  self.itmeBox = {}
  local boxNums = 3
  if self.sunwellMoney ~= 0 then
    self.itmeBox[2] = QUIWidgetItemsBox.new()
    self.itmeBox[2]:setGoodsInfo(0, ITEM_TYPE.SUNWELL_MONEY, self.sunwellMoney)
    self._ccbOwner.item2:addChild(self.itmeBox[2])
  end
    self.itmeBox[1] = QUIWidgetItemsBox.new()
    self.itmeBox[1]:setGoodsInfo(0, ITEM_TYPE.MONEY, self.money)
    self._ccbOwner.item1:addChild(self.itmeBox[1])
    
    self.itmeBox[3] = QUIWidgetItemsBox.new()
    self.itmeBox[3]:setGoodsInfo(self.prizes.id, self.prizes.type, self.prizes.count)
    self._ccbOwner.item3:addChild(self.itmeBox[3])
    
    if self.itmeBox[2] == nil then
      self._ccbOwner.item1:setPositionX(self._ccbOwner.item1:getPositionX() + 50)
      self._ccbOwner.item3:setPositionX(self._ccbOwner.item3:getPositionX() - 50)
    end
    
end

function QUIDialogSunWellChestReceive:_onTriggerConfirm()
  self:playEffectOut()
  self.isSignIn = true
end

function QUIDialogSunWellChestReceive:removeSelfFromParent()
  app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogSunWellChestReceive