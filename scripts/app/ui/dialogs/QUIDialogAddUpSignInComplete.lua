local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogAddUpSignInComplete = class("QUIDialogAddUpSignInComplete", QUIDialog)

local QNotificationCenter = import("...controllers.QNotificationCenter")
local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")

QUIDialogAddUpSignInComplete.RECEIVE_SUCCEED = "RECEIVE_SUCCEED"

function QUIDialogAddUpSignInComplete:ctor(options)
  local ccbFile = "ccb/Dialog_DailySignInComplete2.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogAddUpSignInComplete._onTriggerConfirm)}
  }
  QUIDialogAddUpSignInComplete.super.ctor(self, ccbFile, callBacks, options)
  self.isAnimation = true
  self.isReceive = false
  
  if options ~= nil then
    self.data = options
  end
  
  self:_initItme()
  
end

function QUIDialogAddUpSignInComplete:viewDidAppear()
  QUIDialogAddUpSignInComplete.super.viewDidAppear(self)
end

function QUIDialogAddUpSignInComplete:viewAnimationOutHandler()
  if self.isReceive == true then
    app:getClient():addUpSignIn(self.data.times, function(data)
       
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIDialogAddUpSignInComplete.RECEIVE_SUCCEED})
        
  self:removeSelfFromParent()
    end)
    else
    
  self:removeSelfFromParent()
  end
end

function QUIDialogAddUpSignInComplete:_initItme()
  self.itmeBox = {}
  for i = 1, 3, 1 do
    self.itmeBox[i] = QUIWidgetItemsBox.new()
    self._ccbOwner["item"..i]:addChild(self.itmeBox[i])
    if self.data["id_"..i] ~= nil then
      self.itmeBox[i]:setGoodsInfo(self.data["id_"..i], ITEM_TYPE.ITEM, self.data["num_"..i])
    else
      local typeName = remote.items:getItemType(self.data["type_"..i])
      if typeName == ITEM_TYPE.MONEY then
        self.itmeBox[i]:setGoodsInfo(self.data["id_"..i], ITEM_TYPE.MONEY, self.data["num_"..i])
      elseif typeName == ITEM_TYPE.TOKEN_MONEY then
        self.itmeBox[i]:setGoodsInfo(self.data["id_"..i], ITEM_TYPE.TOKEN_MONEY, self.data["num_"..i])
      end
    end 
  end
end

function QUIDialogAddUpSignInComplete:_onTriggerConfirm()
  self:_backClickHandler()
  self.isReceive = true
end

function QUIDialogAddUpSignInComplete:_backClickHandler()
  self:playEffectOut()
end

function QUIDialogAddUpSignInComplete:removeSelfFromParent()
  app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogAddUpSignInComplete