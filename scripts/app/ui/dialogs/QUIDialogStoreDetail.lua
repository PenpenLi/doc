local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogStoreDetail = class("QUIDialogStoreDetail", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QShop = import("...utils.QShop")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIDialogStoreDetail.ITEM_SELL_SCCESS = "ITEM_SELL_SCCESS"
QUIDialogStoreDetail.ITEM_SELL_FAIL = "ITEM_SELL_FAIL"

function QUIDialogStoreDetail:ctor(options)
  local ccbFile = "ccb/Widget_BuyItem.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerSell", callback = handler(self, QUIDialogStoreDetail._onTriggerSell)},
    {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogStoreDetail._onTriggerClose)}
  }
  QUIDialogStoreDetail.super.ctor(self, ccbFile, callBacks, options)
  self.isAnimation = true
  self.isSell = false
  
  if options ~= nil then
    self._shopId = options.shopId
    self._itemInfo = options.itemInfo
    self._itemConfig = options.itemConfig
    self._position = options.position
  end
  
  self._wallet = 0
  self:resetAll()
  self:setInfo()
end

function QUIDialogStoreDetail:viewAnimationOutHandler()
    self:removeSelfFromParent()
    if self.isSell == true then  
      app:getClient():buyShopItme(self._shopId, self._position - 1, self._itemInfo.id, self._itemInfo.count, function(data)
          if remote.stores:checkMystoryStoreTimeOut(self._shopId) or self._shopId == QShop.GENERAL_SHOP or self._shopId == QShop.ARENA_SHOP or self._shopId == QShop.SUNWELL_SHOP then
            QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIDialogStoreDetail.ITEM_SELL_SCCESS, info = data, position = self._position, item = self._itemInfo})
          end
      end, 
      function(data)
--        if data.code == "SHOP_GOOD_INVALIDATE" then
--          QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIDialogStoreDetail.ITEM_SELL_FAIL}) 
--        elseif data.code == "MONEY_NOT_ENOUGH" then
--          app.tip:floatTip("金钱不足")
--        elseif data.code == "TOKEN_NOT_ENOUGH" then
--          app.tip:floatTip("符石不足")
--        elseif data.error == "ARENA_MONEY_NOT_ENOUGH" then
--          app.tip:floatTip("竞技场币不足")
--        end
      end)
   end
end

function QUIDialogStoreDetail:resetAll()
  self._ccbOwner.tf_name:setString("")
  self._ccbOwner.tf_num:setString(0)
  self._ccbOwner.tf_introduce:setString("")
  self._ccbOwner.itme_num:setString(0)
  self._ccbOwner.tf_money:setString(0)
  self._ccbOwner.stone:setVisible(false)
  self._ccbOwner.gold:setVisible(false)
  self._ccbOwner.arena_gold:setVisible(false)
  self._ccbOwner.sunwell_icon:setVisible(false)
end

function QUIDialogStoreDetail:setInfo()
  self._itemNum = remote.items:getItemsNumByID(self._itemInfo.id)
  
  local itmeBox = QUIWidgetItemsBox.new()
  itmeBox:setGoodsInfo(self._itemInfo.id, ITEM_TYPE.ITEM, 0)
  self._ccbOwner.node_icon:addChild(itmeBox)
  
  self._ccbOwner.tf_name:setString(self._itemConfig.name)
  self._ccbOwner.tf_num:setString(self._itemNum)
--  self._ccbOwner.tf_introduce:setString(self._itemConfig.description or "")
  self._ccbOwner.itme_num:setString(self._itemInfo.count)
  if self._itemInfo.money ~= nil then
    self._ccbOwner.gold:setVisible(true)
    self._ccbOwner.tf_money:setString(self._itemInfo.money)
    self._wallet = remote.user.money
  elseif self._itemInfo.arena_money ~= nil then
    self._ccbOwner.arena_gold:setVisible(true)
    self._ccbOwner.tf_money:setString(self._itemInfo.arena_money)
    self._wallet = remote.user.arenaMoney
  elseif self._itemInfo.sunwell_money ~= nil then
    self._ccbOwner.sunwell_icon:setVisible(true)
    self._ccbOwner.tf_money:setString(self._itemInfo.sunwell_money)
    self._wallet = remote.user.sunwellMoney
  else
    self._ccbOwner.stone:setVisible(true)
    self._ccbOwner.tf_money:setString(self._itemInfo.token)
    self._wallet = remote.user.token
  end
  
  local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(self._itemInfo.id)

  self.detailStr = ""
  self._index = 1
  self:setTFValue("生        命", math.floor(itemConfig.hp or 0))
  self:setTFValue("攻        击", math.floor(itemConfig.attack or 0))
  self:setTFValue("命        中", math.floor(itemConfig.hit_rating or 0))
  self:setTFValue("闪        避", math.floor(itemConfig.dodge_rating or 0))
  self:setTFValue("暴        击", math.floor(itemConfig.critical_rating or 0))
  self:setTFValue("格        挡", math.floor(itemConfig.block_rating or 0))
  self:setTFValue("急        速", math.floor(itemConfig.haste_rating or 0))
  self:setTFValue("物        抗", math.floor(itemConfig.armor_physical or 0))
  self:setTFValue("魔        抗", math.floor(itemConfig.armor_magic or 0))
  
  if self.detailStr == "" then
    self._ccbOwner.tf_introduce:setString(itemConfig.description or "")
  else
    self._ccbOwner.tf_introduce:setString(self.detailStr)
  end
  
--  if self._itemInfo.count == 0 then
--    self._ccbOwner.sale_empty:setVisible(true)
--    self.isSell = true
--  end
end

function QUIDialogStoreDetail:setTFValue(name, value)
  if self._index > 4 then return end
  if value ~= nil then
    if type(value) ~= "number" or value > 0 then
      self.detailStr = self.detailStr .. name.."          ＋"..value.."\n"
      -- self._ccbOwner["tf_name"..self._index]:setString(name)
      -- self._ccbOwner["tf_value"..self._index]:setString("＋"..value)
      self._index = self._index + 1
    end
  end
end

function QUIDialogStoreDetail:_onTriggerSell()
  local price = tonumber(self._ccbOwner.tf_money:getString())
  if price > self._wallet then
     if self._itemInfo.money ~= nil then
       app.tip:floatTip("金钱不足")
     elseif self._itemInfo.sunwell_money ~= nil then
       app.tip:floatTip("太阳之尘不足")
     elseif self._itemInfo.arena_money ~= nil then
       app.tip:floatTip("竞技场币不足")
     else
        app.tip:floatTip("符石不足")
     end   
     return
  end

    self.isSell = true
    self:_onTriggerClose()
end

function QUIDialogStoreDetail:_backClickHandler()
    self:_onTriggerClose()
end

function QUIDialogStoreDetail:_onTriggerClose()
    app.sound:playSound("common_close")
    self:playEffectOut()
end

function QUIDialogStoreDetail:removeSelfFromParent()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogStoreDetail