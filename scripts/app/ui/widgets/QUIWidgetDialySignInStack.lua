local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetDialySignInStack = class("QUIWidgetDialySignInStack", QUIWidget)

local QUIWidgetDailySignInBox = import("..widgets.QUIWidgetDailySignInBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")

function QUIWidgetDialySignInStack:ctor(options)
  local ccbFile = "ccb/Widget_DailySignIn_leiji.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTirrgerClickReceive", callback = handler(self, QUIWidgetDialySignInStack._onTirrgerClickReceive)}
  }
  QUIWidgetDialySignInStack.super.ctor(self, ccbFile, callBacks, options)
  
  self._ccbOwner.stack_sign_num:setString("")
  self:setSignNum()
end

function QUIWidgetDialySignInStack:onEnter()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetDailySignInBox.EVENT_CLICK, self._onTirrgerClickReceive, self)
end

function QUIWidgetDialySignInStack:onExit()
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetDailySignInBox.EVENT_CLICK, self._onTirrgerClickReceive, self)
end

function QUIWidgetDialySignInStack:setSignNum()
  local signNum, signAward = remote.daily:getAddUpSignIn()
  self.award, self.nowNum, self.maxNum = QStaticDatabase:sharedDatabase():getAddUpSignInItmeByMonth(signNum, signAward)
  self._ccbOwner.stack_sign_num:setString("（"..self.nowNum.."/"..self.maxNum.."）")
  self:setItem()
end

function QUIWidgetDialySignInStack:setItem()
  self.itemBox = {}
  for i = 1, 3, 1 do
    self.itemBox[i] = QUIWidgetDailySignInBox.new({type = "ADD_UP"})
    self._ccbOwner["node"..i]:addChild(self.itemBox[i])
    if self.nowNum == self.maxNum then
      self.itemBox[i]:setState("IS_READY")
    else
      self.itemBox[i]:setState("IS_WAITING")
    end
    self.itemBox[i]:setItmeBoxInfo(self.award["type_"..i], self.award["id_"..i], self.award["num_"..i], self.maxNum)
  end
end


function QUIWidgetDialySignInStack:_onTirrgerClickReceive(data)
  if data.itemType ~= nil then
    if self.nowNum == self.maxNum then
      app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAddUpSignInComplete" , options = self.award},
        {isPopCurrentDialog = false})
    else
      local typeName = remote.items:getItemType(data.type)
      if typeName == ITEM_TYPE.MONEY or typeName == ITEM_TYPE.TOKEN_MONEY then
        app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignInCurrencyPrompt" , options = {type = data.type, index = data.index,  isStack = true}},
          {isPopCurrentDialog = false})
      else
        local itemInfo = QStaticDatabase.sharedDatabase():getItemByID(data.id)
        if itemInfo.type == 3 then
          app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignInChipPrompt" , options = {itemInfo = itemInfo, id = data.id, index = data.index, isStack = true}},
            {isPopCurrentDialog = false})
        elseif itemInfo.type == 4 then
          app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignInItemPrompt" , options = {itemInfo = itemInfo, id = data.id, index = data.index, isStack = true}},
            {isPopCurrentDialog = false})
        end
      end
    end
  end
end

return QUIWidgetDialySignInStack