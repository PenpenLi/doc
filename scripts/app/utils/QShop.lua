local QShop = class("QShop")

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QShop.GENERAL_SHOP = "1"
QShop.GOBLIN_SHOP = "2"
QShop.BLACK_MARKET_SHOP = "3"
QShop.ARENA_SHOP = "4"
QShop.SUNWELL_SHOP = "5"
QShop.SHOP_CLOSE = "SHOP_CLOSE"
QShop.MYSTORY_SHOP_UPDATE_EVENT = "MYSTORY_SHOP_UPDATE_EVENT"

function QShop:ctor() 
  cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
  self._generalShop = {}
  self._goblinShop = {}
  self._blackMarketShop = {}
  self._arenaShop = {}
  self._sunwellShop = {}
  self._generalShopRefreshTime = nil
  self._goblinShopRefreshTime = nil
  self._blackMarketShopRefreshTime = nil
  self._arenaShopRefreshTime = nil
  self._sunwellShopRefreshTime = nil
end

function QShop:updateComplete(stores)
  for _,value in pairs(stores) do
    if tostring(value.id) == QShop.GENERAL_SHOP then
        self._generalShop = clone(value)
    elseif tostring(value.id) == QShop.GOBLIN_SHOP then
        self._goblinShop = clone(value)
        self:dispatchEvent({name = QShop.MYSTORY_SHOP_UPDATE_EVENT})
    elseif tostring(value.id) == QShop.BLACK_MARKET_SHOP then
        self._blackMarketShop = clone(value)
        self:dispatchEvent({name = QShop.MYSTORY_SHOP_UPDATE_EVENT})
    elseif tostring(value.id) == QShop.ARENA_SHOP then
        self._arenaShop = clone(value)
    elseif tostring(value.id) == QShop.SUNWELL_SHOP then
        self._sunwellShop = clone(value)
    end
  end
end

--关闭特殊商店
function QShop:closeMystoryShop(shopId)
  if shopId == QShop.GENERAL_SHOP then
    self._generalShop = {}
  elseif shopId == QShop.GOBLIN_SHOP then
    self._goblinShop = {}
  elseif shopId == QShop.BLACK_MARKET_SHOP then
    self._blackMarketShop = {}
  end
end

--传入stores获取shopId
function QShop:getStoresShopId(stores)
  if stores[1].id == tonumber(QShop.GENERAL_SHOP) then
    return QShop.GENERAL_SHOP
  end
  if stores[1].id == tonumber(QShop.GOBLIN_SHOP) ~= nil then
    return QShop.GOBLIN_SHOP
  end
  if stores[1].id == tonumber(QShop.BLACK_MARKET_SHOP) ~= nil then
    return QShop.BLACK_MARKET_SHOP
  end
  if stores[1].id == tonumber(QShop.ARENA_SHOP) ~= nil then
    return QShop.ARENA_SHOP
  end
  if stores[1].id == tonumber(QShop.SUNWELL_SHOP) ~= nil then
    return QShop.SUNWELL_SHOP
  end
end

--获取物品信息
function QShop:getStoresById(shopId)
  if shopId == QShop.GENERAL_SHOP then
    return self._generalShop.shelves
  elseif shopId == QShop.GOBLIN_SHOP then
    return self._goblinShop.shelves
  elseif shopId == QShop.BLACK_MARKET_SHOP then
    return self._blackMarketShop.shelves
  elseif shopId == QShop.ARENA_SHOP then
    return self._arenaShop.shelves
  elseif shopId == QShop.SUNWELL_SHOP then
    return self._sunwellShop.shelves
  end
end

--获取手动刷新次数
function QShop:getRefreshCountById(shopId)
  if shopId == QShop.GENERAL_SHOP then
    return self._generalShop.buyRefreshCount
  elseif shopId == QShop.GOBLIN_SHOP then
    return self._goblinShop.buyRefreshCount
  elseif shopId == QShop.BLACK_MARKET_SHOP then
    return self._blackMarketShop.buyRefreshCount
  elseif shopId == QShop.ARENA_SHOP then
    return self._arenaShop.buyRefreshCount
  elseif shopId == QShop.SUNWELL_SHOP then
    return self._sunwellShop.buyRefreshCount
  end
end

--获取自动刷新时间
function QShop:getRefreshAtTime(shopId)
  if shopId == QShop.GENERAL_SHOP then
    return self._generalShop.refreshedAt
  elseif shopId == QShop.GOBLIN_SHOP then
    return self._goblinShop.refreshedAt
  elseif shopId == QShop.BLACK_MARKET_SHOP then
    return self._blackMarketShop.refreshedAt
  elseif shopId == QShop.ARENA_SHOP then
    return self._arenaShop.refreshedAt
  elseif shopId == QShop.SUNWELL_SHOP then
    return self._sunwellShop.refreshedAt -- TODO @qinyuanji
  end
end

--检查是否存在特殊商店
function QShop:checkMystoryStore(shopId)
  if shopId == QShop.GOBLIN_SHOP then
    if self._goblinShop.shelves ~= nil then
      return true
    end
    return false
  elseif shopId == QShop.BLACK_MARKET_SHOP then
    if self._blackMarketShop.shelves ~= nil then
      return true
    end
    return false
  end
end

--检查特殊商店存在是否超时
function QShop:checkMystoryStoreTimeOut(shopId)
  local time = q.serverTime()

  --获取商店停留时间
  local stayTime = QStaticDatabase.sharedDatabase():getConfiguration()
  if shopId == QShop.GOBLIN_SHOP then
    stayTime = stayTime["TIME_REFRESH_SHOP_1"].value * 60
  elseif shopId == QShop.BLACK_MARKET_SHOP then
    stayTime = stayTime["TIME_REFRESH_SHOP_2"].value * 60
  end

  if shopId == QShop.GOBLIN_SHOP and self._goblinShop.refreshedAt ~= nil then
    local CDTime = self._goblinShop.refreshedAt/1000 + stayTime
    if time < CDTime then
      return true
    end
    return false
  elseif shopId == QShop.BLACK_MARKET_SHOP and self._blackMarketShop.refreshedAt ~= nil then
    local CDTime = self._blackMarketShop.refreshedAt/1000 + stayTime
    if time < CDTime then
      return true
    end
    return false
  end
end

function QShop:mystoryStoreCountDown(shopId)
  if shopId == QShop.GOBLIN_SHOP then
     if self._goblinTimeHandler ~= nil then
        scheduler.unscheduleGlobal(self._goblinTimeHandler)
        self._goblinTimeHandler = nil
     end
     
     local stayTime = QStaticDatabase.sharedDatabase():getConfiguration()
     stayTime = stayTime["TIME_REFRESH_SHOP_1"].value * 60
      
     local CDTime = self._goblinShop.refreshedAt/1000 + stayTime
     
     self._goblinTimeFun = function()
        self._goblinTimeHandler = nil
        local offsetTime = q.serverTime()
        if offsetTime < CDTime then  
          self._goblinTimeHandler = scheduler.performWithDelayGlobal(self._goblinTimeFun, 1)
          local date = q.timeToHourMinuteSecond(CDTime - offsetTime)
--          printInfo("地精商店："..date)
        else
          if self._goblinTimeHandler ~= nil then
            scheduler.unscheduleGlobal(self._goblinTimeHandler)
            self._goblinTimeHandler = nil
          end
          self:closeMystoryShop(QShop.GOBLIN_SHOP)
          QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QShop.SHOP_CLOSE, shopId = QShop.GOBLIN_SHOP}) 
        end
        -- self:closeMystoryShop(QShop.GOBLIN_SHOP)
        -- QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QShop.SHOP_CLOSE, shopId = QShop.GOBLIN_SHOP})
      end
    self._goblinTimeFun()

  elseif shopId == QShop.BLACK_MARKET_SHOP then
     if self._blackTimeHandler ~= nil then
        scheduler.unscheduleGlobal(self._blackTimeHandler)
        self._blackTimeHandler = nil
     end
     
     local stayTime = QStaticDatabase.sharedDatabase():getConfiguration()
     stayTime = stayTime["TIME_REFRESH_SHOP_2"].value * 60
      
     local CDTime = self._blackMarketShop.refreshedAt/1000 + stayTime
     
     self._blackTimeFun = function()
        self._blackTimeHandler = nil
        local offsetTime = q.serverTime()
        if offsetTime < CDTime then  
          self._blackTimeHandler = scheduler.performWithDelayGlobal(self._blackTimeFun, 1)
          local date = q.timeToHourMinuteSecond(CDTime - offsetTime)
--          printInfo("黑市商人："..date)
        else
          if self._blackTimeHandler ~= nil then
            scheduler.unscheduleGlobal(self._blackTimeHandler)
            self._blackTimeHandler = nil
          end
          self:closeMystoryShop(QShop.BLACK_MARKET_SHOP)
          QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QShop.SHOP_CLOSE, shopId = QShop.BLACK_MARKET_SHOP})
        end
        -- self:closeMystoryShop(QShop.BLACK_MARKET_SHOP)
        -- QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QShop.SHOP_CLOSE, shopId = QShop.BLACK_MARKET_SHOP})
      end
    self._blackTimeFun()
  end
end

--根据商店ID保存相应商店下个刷新节点
function QShop:setNextRefershTime(shopId, time)
   if shopId == QShop.GENERAL_SHOP then
      self._generalShopRefreshTime = time
  elseif shopId == QShop.GOBLIN_SHOP then
      self._goblinShopRefreshTime = time
  elseif shopId == QShop.BLACK_MARKET_SHOP then
      self._blackMarketShopRefreshTime = time
  elseif shopId == QShop.ARENA_SHOP then
      self._arenaShopRefreshTime = time
  elseif shopId == QShop.SUNWELL_SHOP then
      self._sunwellShopRefreshTime = time
  end
end

--根据商店ID获取相应商店下个刷新节点
function QShop:getNextRefershTime(shopId)
   if shopId == QShop.GENERAL_SHOP then
     return self._generalShopRefreshTime
  elseif shopId == QShop.GOBLIN_SHOP then
     return self._goblinShopRefreshTime
  elseif shopId == QShop.BLACK_MARKET_SHOP then
     return self._blackMarketShopRefreshTime
  elseif shopId == QShop.ARENA_SHOP then
     return self._arenaShopRefreshTime
  elseif shopId == QShop.SUNWELL_SHOP then
     return self._sunwellShopRefreshTime
  end
end

--根据商店ID判断当前商店是否需要刷新
function QShop:checkCanRefreshShop(shopId)
  local shopRefreshAt = self:getRefreshAtTime(shopId)
  local nextRefreshTime = self:getNextRefershTime(shopId)
  if nextRefreshTime ~= nil and shopRefreshAt/1000 >= nextRefreshTime then
    return true 
  end
  return false
end

return QShop
