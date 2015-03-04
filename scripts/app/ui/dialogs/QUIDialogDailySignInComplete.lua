local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogDailySignInComplete = class("QUIDialogDailySignInComplete", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetDailySignInBox = import("..widgets.QUIWidgetDailySignInBox")

QUIDialogDailySignInComplete.SIGN_SUCCEED = "DAILYSIGN_SUCCEED"

function QUIDialogDailySignInComplete:ctor(options)
  local ccbFile = "ccb/Dialog_DailySignInComplete.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogDailySignInComplete._onTriggerConfirm)}
  }
  QUIDialogDailySignInComplete.super.ctor(self, ccbFile, callBacks, options)
  self.isAnimation = true
  self.isSignIn = false
  
  self.type = options.type
  self.id = options.id
  self.num = options.num
  self.index = options.index
  
  self._ccbOwner.tf_value1:setString("x"..self.num)
  self:setItemInfo()
  
end

function QUIDialogDailySignInComplete:viewDidAppear()
  QUIDialogDailySignInComplete.super.viewDidAppear(self)
end

function QUIDialogDailySignInComplete:viewAnimationOutHandler()
  self:removeSelfFromParent()
  if self.isSignIn == true then
    app:getClient():dailySignIn(self.index, function(data)
       self:_backClickHandler()
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIDialogDailySignInComplete.SIGN_SUCCEED, index = self.index})
    end)
  end
end

function QUIDialogDailySignInComplete:setItemInfo()
  self.itmeBox = QUIWidgetItemsBox.new()
  if self.id ~= nil then
    self.itmeBox:setGoodsInfo(self.id, ITEM_TYPE.ITEM, 0)
  else
    self.itmeBox:setGoodsInfo(self.id, remote.items:getItemType(self.type), 0)
  end
  self._ccbOwner.item1:addChild(self.itmeBox)
end

function QUIDialogDailySignInComplete:_onTriggerConfirm()
  self:_backClickHandler()
  self.isSignIn = true
end

function QUIDialogDailySignInComplete:_backClickHandler()
  self:playEffectOut()
end

function QUIDialogDailySignInComplete:removeSelfFromParent()
  app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end
return QUIDialogDailySignInComplete
