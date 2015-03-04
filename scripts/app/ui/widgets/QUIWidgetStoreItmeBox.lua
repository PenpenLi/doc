local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetStoreItmeBox = class("QUIWidgetStoreItmeBox", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNavigationController = import("...controllers.QNavigationController")
local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QShop = import("...utils.QShop")

QUIWidgetStoreItmeBox.EVENT_CLICK = "SOTRE_EVENT_CLICK"

function QUIWidgetStoreItmeBox:ctor(options)
  local ccbFile = "ccb/Widget_shop.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTirggerClick", callback = handler(self, QUIWidgetStoreItmeBox._onTirggerClick)}
  }
  QUIWidgetStoreItmeBox.super.ctor(self, ccbFile, callBacks, options)
  self.isSell = false
  
  if options ~= nil then
    self.position = options.position
    self.shopType = options.shopType
  end
  
  self:resetAll()
end

function QUIWidgetStoreItmeBox:resetAll()
  self._ccbOwner.goods_name:setString("")
  self._ccbOwner.sale_empty:setVisible(false)
  self._ccbOwner.sale_money:setString(0)
  self._ccbOwner.gold:setVisible(false)
  self._ccbOwner.stone:setVisible(false)
  self._ccbOwner.arena_gold:setVisible(false)
  self._ccbOwner.sunwell_icon:setVisible(false)
end

--初始化物品
function QUIWidgetStoreItmeBox:setItmeBox(itemInfo)
  local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(itemInfo.id)
  local itmeBox = QUIWidgetItemsBox.new()
  itmeBox:setGoodsInfo(itemInfo.id, ITEM_TYPE.ITEM, itemInfo.count)
  self._ccbOwner.itme_box:addChild(itmeBox)
  
  self._ccbOwner.goods_name:setString(itemConfig.name)
  
  if self.shopType == QShop.ARENA_SHOP then
    self._ccbOwner.arena_gold:setVisible(true)
    self._ccbOwner.sale_money:setString(itemInfo.arena_money or 0)
  elseif self.shopType == QShop.SUNWELL_SHOP then
    self._ccbOwner.sunwell_icon:setVisible(true)
    self._ccbOwner.sale_money:setString(itemInfo.sunwell_money or 0)
  else
    if itemInfo.token ~= nil and itemInfo.token ~= 0 then
      self._ccbOwner.stone:setVisible(true)
      self._ccbOwner.sale_money:setString(itemInfo.token or 0)
    else
      self._ccbOwner.gold:setVisible(true)
      self._ccbOwner.sale_money:setString(itemInfo.money or 0)
    end
  end
  if itemInfo.count == 0 then
    self._ccbOwner.sale_empty:setVisible(true)
    self.isSell = true
  end
  
  self._itemInfo = itemInfo
  self._itemConfig = itemConfig
end

--显示物品已出售
function QUIWidgetStoreItmeBox:_setItemIsSell()
   self._ccbOwner.sale_empty:setVisible(true)
   self.isSell = true
end

function QUIWidgetStoreItmeBox:_onTirggerClick()
    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetStoreItmeBox.EVENT_CLICK, itemInfo = self._itemInfo, itemConfig = self._itemConfig, position = self.position, isSell = self.isSell})
end

return QUIWidgetStoreItmeBox