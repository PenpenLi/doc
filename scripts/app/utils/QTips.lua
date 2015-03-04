local QTips = class("QTips")
local QUIDialogUnlockSucceed = import("..ui.dialogs.QUIDialogUnlockSucceed")
local QUIDialogMystoryStoreAppear = import("..ui.dialogs.QUIDialogMystoryStoreAppear")
local QNotificationCenter = import("..controllers.QNotificationCenter")
local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")

QTips.UNLOCK_TIP_ISTRUE = false --当前是否有解锁提示显示
QTips.SHOW_NEXT_UNLOCKTIP = "SHOW_NEXT_UNLOCKTIP" 
QTips.UNLOCK_TUTORIAL_CLOSE = 0
QTips.UNLOCK_TUTORIAL_OPEN = 1
QTips.UNLOCK_TUTORIAL_END = 2

function QTips:ctor()
  self.unLockTipsNum = 0
  self.unLockTipsType = {}
  self._floatTip = nil 
  self.unlockTutorial = {shopTutorial = 0, goblinTutorial = 0, blackTutorial = 0, spaceTutorial = 0, goldTutorial = 0, arenaTutorial = 0, sunwellTutorial = 0, endTutorial = 0}
  self.unLockInformation = {
                           {type = QUIDialogUnlockSucceed.UNLOCK_ELITECOPY, icon = "icon/item/jingyingfuben.png", name = "精英副本"},
                           {type = QUIDialogUnlockSucceed.UNLOCK_SKILL, icon = "icon/item/jinengshengji.png", name = "技能升级"},    
                           {type = QUIDialogUnlockSucceed.UNLOCK_GOBLIN_SHOP, icon = "icon/item/goblin_merchant.png", name = "地精商店开启"},
                           {type = QUIDialogUnlockSucceed.UNLOCK_BLACK_MARKET_SHOP, icon = "icon/item/black_marketeer.png", name = "黑市商人出现"},    
                           {type = QUIDialogMystoryStoreAppear.FIND_GOBLIN_SHOP, icon = "icon/item/goblin_merchant.png", name = "出售宝贵商品的特殊商人", description = "地精商店"},
                           {type = QUIDialogMystoryStoreAppear.FIND_BLACK_MARKET_SHOP, icon = "icon/item/black_marketeer.png", name = "出售稀有物品的特殊商人", description = "黑市商人"},
                           {type = QUIDialogUnlockSucceed.SPACE_TIME_TRANSMITTER, icon = "icon/item/space_time_transmitter.png", name = "时空传送器"},
                           {type = QUIDialogUnlockSucceed.GOLD_CHALLENGE, icon = "icon/item/gold_challenge.png", name = "黄金挑战"},
                           {type = QUIDialogUnlockSucceed.UNLOCK_SHOP, icon = "icon/item/shop.png", name = "商店"},  
                           {type = QUIDialogUnlockSucceed.UNLOCK_ARENA, icon = "icon/item/arena.png", name = "竞技场"},                             
                           {type = QUIDialogUnlockSucceed.UNLOCK_SUNWELL, icon = "icon/item/sunwell_building.png", name = "太阳之井"}                              
                           }
end

function QTips:getUnlockTutorial()
  return self.unlockTutorial
end

function QTips:setUnlockTutorial(unlockTutorial)
   self.unlockTutorial = unlockTutorial
   local tutorialIsFinished = true
   self.unlockTutorial.endTutorial = 0
   if self.unlockTutorial.endTutorial == 0 then
    for k, v in pairs(self.unlockTutorial) do
      if v ~= 2 then
        if k ~= "endTutorial" then 
          tutorialIsFinished = false
        end
      end
    end
   end
   
   if tutorialIsFinished == true then
     self.unlockTutorial.endTutorial = 1
   end
   
   local _value = table.formatString(self.unlockTutorial, "^", ";")
   remote.flag:set(remote.flag.FLAG_UNLOCK_TUTORIAL, _value)
end

function QTips:initUnlockTutorial(unlockTutorial)
  if unlockTutorial == nil then
    return
  end
  local value = string.split(unlockTutorial, ";")
  for _, v1 in pairs(value) do
    local val = string.split(v1, "^")
    self.unlockTutorial[val[1]] = tonumber(val[2])
  end
--  local _value = string.split(unlockTutorial, ";")
--  local num = table.nums(_value)
--  for i = 1, num, 1 do
--    self.unlockTutorial[i] = tonumber(_value[i]) 
--  end
--  self.unlockTutorial.goblinTutorial = tonumber(_value[1]) 
--  self.unlockTutorial.endTutorial = tonumber(_value[2]) 
--  self.unlockTutorial.goldTutorial = tonumber(_value[3])
--  self.unlockTutorial.shopTutorial = tonumber(_value[4])
--  self.unlockTutorial.spaceTutorial = tonumber(_value[5]) 
--  self.unlockTutorial.blackTutorial = tonumber(_value[6])
end

function QTips:isTutorialFinished()
  if self.unlockTutorial.endTutorial == 1 then
    return true
  end
  return false
end

function QTips:addTipEventListener()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QTips.SHOW_NEXT_UNLOCKTIP , QTips.showNextTip, self)
end

function QTips:removeTipEventListener()
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QTips.SHOW_NEXT_UNLOCKTIP , QTips.showNextTip, self)
end

function QTips:showUnlockTips(type)
  if type == QUIDialogMystoryStoreAppear.FIND_GOBLIN_SHOP or type == QUIDialogMystoryStoreAppear.FIND_BLACK_MARKET_SHOP then
    self._unlockTip = app:getNavigationThirdLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogMystoryStoreAppear", options = {type = type}})
  else
    self._unlockTip = app:getNavigationThirdLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogUnlockSucceed", options = {type = type}})
  end
end

function QTips:showNextTip()
   if self._unlockTip ~= nil then
      app:getNavigationThirdLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
      self._unlockTip = nil
   end
   if self.unLockTipsNum ~= 0 then
     local type = self.unLockTipsType[1]
     table.remove(self.unLockTipsType, 1)
     self.unLockTipsNum = self.unLockTipsNum - 1
     self:showUnlockTips(type)     
   end
end

function QTips:addUnlockTips(type)
    self.unLockTipsNum = self.unLockTipsNum + 1
    table.insert(self.unLockTipsType, type)
end

function QTips:getUnlockTipInformation(type)
   for k, value in pairs(self.unLockInformation) do
      if type == value.type then
        self.lockInformation = self.unLockInformation[k]
      end
   end   
   return self.lockInformation
end

function QTips:floatTip(content)
  if self._floatTip ~= nil then
    app:getNavigationThirdLayerController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
    self._floatTip = nil
  end
    self._floatTip = app:getNavigationThirdLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogFloatTip", options = {words = content}}, {isPopCurrentDialog = false})
end

function QTips:refreshTip()
  if self._floatTip ~= nil or self._unlockTip ~= nil then
      app:getNavigationThirdLayerController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
      self._floatTip = nil
      self._unlockTip = nil
    end
end

return QTips