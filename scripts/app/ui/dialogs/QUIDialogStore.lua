local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogStore = class("QUIDialogStore", QUIDialog)

local QNotificationCenter = import("...controllers.QNotificationCenter")
local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetStoreBoss = import("..widgets.QUIWidgetStoreBoss")
local QUIWidgetStoreItmeBox = import("..widgets.QUIWidgetStoreItmeBox")
local QUIWidgetShopTap = import("..widgets.QUIWidgetShopTap")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIViewController = import("..QUIViewController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIDialogStoreDetail = import("..dialogs.QUIDialogStoreDetail")
local QShop = import("...utils.QShop")

QUIDialogStore.ARENA_MONEY_REFRESH = "ARENA_MONEY_REFRESH"

function QUIDialogStore:ctor(options)
  local ccbFile = "ccb/Dialog_shop.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerNormal", callback = handler(self, QUIDialogStore._onTriggerNormal)}
  }
  QUIDialogStore.super.ctor(self, ccbFile, callBacks, options)
  local page = app:getNavigationController():getTopPage()
  if options.type == QShop.ARENA_SHOP then
    page:setAllUIVisible(false)
    self.arenaGold = QUIWidgetShopTap.new({money = options.info.arenaMoney})
    self._arenaMoney = options.info.arenaMoney
    self._ccbOwner.gold_node:addChild(self.arenaGold)
  elseif options.type == QShop.SUNWELL_SHOP then
    page:setAllUIVisible(false)
    self._sunwellMoney = remote.user.sunwellMoney or 0
    self.sunwellGold = QUIWidgetShopTap.new({money = self._sunwellMoney, type = "sunwell"})
    self._ccbOwner.gold_node:addChild(self.sunwellGold)
  else
    page:setManyUIVisible()
  end
  page._scaling:willPlayHide()
  
  self:resetAll()
  
  self._ccbOwner.sprite_scroll_cell:setOpacity(0)
  self._ccbOwner.scroll_bar:setOpacity(0)
  self._cellH = self._ccbOwner.sprite_scroll_cell:getContentSize().height
  self._scrollH = self._ccbOwner.scroll_bar:getContentSize().height
  self._isMove = false
  self._cellHeight = 144
  self._offsetHeight = -199
  self._offsetWidth= 318
  
  if options.type ~= nil then
    self.shopType = options.type
  end

  --初始化npc对话
  self.bossWord = QUIWidgetStoreBoss.new({type = self.shopType})
  self._ccbOwner.boss_head:addChild(self.bossWord) 
  
  self:chooseResources()
  self:setRefreshTime()
  local refreshShop =  remote.stores:checkCanRefreshShop(self.shopType)
  if refreshShop == true then
    self:getItem()
  end
  self:_initPageSwipe()
end

function QUIDialogStore:viewDidAppear()
  QUIDialogStore.super.viewDidAppear(self)
  if self._touchLayer ~= nil then
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
  end
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetStoreItmeBox.EVENT_CLICK, self.sellClickHandler, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogStoreDetail.ITEM_SELL_SCCESS, self.sellItemSuccess, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIDialogStoreDetail.ITEM_SELL_FAIL, self.getItem, self)
  self:addBackEvent(false)
end

function QUIDialogStore:viewWillDisappear()
  QUIDialogStore.super.viewWillDisappear(self)
  if self._touchLayer ~= nil then
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
  end
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetStoreItmeBox.EVENT_CLICK, self.sellClickHandler, self)
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogStoreDetail.ITEM_SELL_SCCESS, self.sellItemSuccess, self)
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIDialogStoreDetail.ITEM_SELL_FAIL, self.getItem, self)
  if self._timeHandler ~= nil then
    scheduler.unscheduleGlobal(self._timeHandler)
    self._timeHandler = nil
  end  
  self:removeBackEvent()
end

function QUIDialogStore:resetAll()
  self._ccbOwner.shop:setVisible(false)
  self._ccbOwner.goblin_shop:setVisible(false)
  self._ccbOwner.black_shop:setVisible(false)
  self._ccbOwner.arena_shop:setVisible(false)
  self._ccbOwner.sunwell_shop:setVisible(false)
  self._ccbOwner.shop_time:setVisible(false)
  self._ccbOwner.mystory_time:setVisible(false)
  self._ccbOwner.refresh_time:setString("")
  self._ccbOwner.black_refresh_time:setString("")
end

-- 初始化中间的物品框 swipe工能
function QUIDialogStore:_initPageSwipe()
  self._pageWidth = self._ccbOwner.sheet_layout:getContentSize().width
  self._pageHeight = self._ccbOwner.sheet_layout:getContentSize().height
  self._pageContent = CCNode:create()

  local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._pageWidth,self._pageHeight)
  local ccclippingNode = CCClippingNode:create()
  layerColor:setPositionX(self._ccbOwner.sheet_layout:getPositionX())
  layerColor:setPositionY(self._ccbOwner.sheet_layout:getPositionY())
  ccclippingNode:setStencil(layerColor)
  ccclippingNode:addChild(self._pageContent)

  self._ccbOwner.sheet:addChild(ccclippingNode)
  
  if self.shopType == QShop.GOBLIN_SHOP or self.shopType == QShop.BLACK_MARKET_SHOP or self.shopType == QShop.ARENA_SHOP or self.shopType == QShop.SUNWELL_SHOP then
    self._touchLayer = QUIGestureRecognizer.new()
    self._touchLayer:setAttachSlide(true)
    self._touchLayer:setSlideRate(0.3)
    self._touchLayer:attachToNode(self._ccbOwner.sheet,self._pageWidth, self._pageHeight, self._ccbOwner.sheet_layout:getPositionX(), self._ccbOwner.sheet_layout:getPositionY(), handler(self, self.onTouchEvent))
  end
  
  self._isAnimRunning = false
  self:_initItme()
end

--初始化物品格子
function QUIDialogStore:_initItme()
  if self.itmeBox ~= nil then
    for i = 1, table.nums(self.itmeBox), 1 do
      self.itmeBox[i]:removeFromParent()
    end
  end
  
  local storesInfo = remote.stores:getStoresById(self.shopType)
  self._storesInfo = clone(storesInfo)
  self.itmeBox = {}
  self._totalHeight = 0
  local line = 0
  local row = 1
  for i = 1, #self._storesInfo, 1 do
    line = line + 1
    self.itmeBox[i] = QUIWidgetStoreItmeBox.new({position = i, shopType = self.shopType}) 
    self.itmeBox[i]:setItmeBox(self._storesInfo[i])
    self.itmeBox[i]:setPosition(self._offsetWidth * line - self._offsetWidth/2, self._offsetHeight * row - self._offsetHeight/2) 
    self._pageContent:addChild(self.itmeBox[i])
    if i % 3 == 0 then
      line = 0
      row = row + 1
      self._totalHeight = self._totalHeight - self._offsetHeight
    end
  end
  
  --检查是否有可出售物品
  scheduler.performWithDelayGlobal(function()
    if self.sellDialog == nil then
      self:checkSellItem()
    end
  end, 0)
end

-- 处理各种touch event
function QUIDialogStore:onTouchEvent(event)
  if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
      self:moveTo(event.distance.y, true)
    elseif event.name == "began" then
      self._isMove = false
      self:_removeAction()
      self._startY = event.y
      self._pageY = self._pageContent:getPositionY()
    elseif event.name == "moved" then
      local offsetY = self._pageY + event.y - self._startY
        if math.abs(event.y - self._startY) > 10 then
            self._isMove = true
        end
    self:moveTo(offsetY, false)
  elseif event.name == "ended" then
      scheduler.performWithDelayGlobal(function ()
        self._isMove = false
        end,0)
    end
end

function QUIDialogStore:moveTo(posY, isAnimation)
   self._ccbOwner.sprite_scroll_cell:stopAllActions()
   self._ccbOwner.scroll_bar:stopAllActions()
   if   self._totalHeight <= self._pageHeight or (math.abs(posY) < 1 and self._scrollShow == false) then
    self._ccbOwner.sprite_scroll_cell:setOpacity(0)
    self._ccbOwner.scroll_bar:setOpacity(0)
   else
    self._ccbOwner.sprite_scroll_cell:setOpacity(255)
    self._ccbOwner.scroll_bar:setOpacity(255)
    self._scrollShow = true
   end
  if isAnimation == false then
    self._pageContent:setPositionY(posY)
    self:onFrame()
    return 
  end

  local contentY = self._pageContent:getPositionY()
  local targetY = 0
  if self._totalHeight <= self._pageHeight then
    targetY = 0
  elseif contentY + posY > self._totalHeight - self._pageHeight then
    targetY = self._totalHeight - self._pageHeight
  elseif contentY + posY < 0 then
    targetY = 0
  else
    targetY = contentY + posY
  end
  self:_contentRunAction(0, targetY)
end

function QUIDialogStore:_contentRunAction(posX,posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                          self:_removeAction()
                          self:onFrame()
                         if   self._totalHeight > self._pageHeight and self._scrollShow == true then
                          self._ccbOwner.sprite_scroll_cell:runAction(CCFadeOut:create(0.3))
                          self._ccbOwner.scroll_bar:runAction(CCFadeOut:create(0.3))
                          self._scrollShow = false
                         end
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self._pageContent:runAction(ccsequence)
    self:startEnter()
end

function QUIDialogStore:_removeAction()
  self:stopEnter()
  if self._actionHandler ~= nil then
    self._pageContent:stopAction(self._actionHandler)   
    self._actionHandler = nil
  end
end

function QUIDialogStore:startEnter()
  self:stopEnter()
    self._onFrameHandler = scheduler.scheduleGlobal(handler(self, self.onFrame), 0)
end

function QUIDialogStore:stopEnter()
    if self._onFrameHandler ~= nil then
      scheduler.unscheduleGlobal(self._onFrameHandler)
      self._onFrameHandler = nil
    end
end

function QUIDialogStore:onFrame()
   local contentY = self._pageContent:getPositionY()
  -- for index,value in pairs(self._virtualBox) do
  --  if value.posY + contentY < -self._pageHeight + self._offsetY or value.posY + contentY > -self._offsetY then
  --    self:setBox(value.icon)
  --      value.icon = nil
  --  end
  -- end
  -- for index,value in pairs(self._virtualBox) do
  --  if value.posY + contentY >= -self._pageHeight + self._offsetY and value.posY + contentY <= -self._offsetY then
  --    if value.icon == nil then
  --        value.icon = self:getBox()
  --        value.icon:setPosition(value.posX, value.posY)
  --        value.icon:setVisible(true)
  --        value.icon:resetAll()
  --        value.icon:setGoodsInfo(value.info.type, ITEM_TYPE.ITEM, value.info.count)
  --    end
  --  end
  -- end
   if   self._totalHeight > self._pageHeight and contentY > 0 and contentY <= self._totalHeight - self._pageHeight then
    local cellY = self._scrollH  * (1 - math.abs(contentY) / math.abs(self._totalHeight - self._pageHeight + 52)) - self._cellH/2
    self._ccbOwner.sprite_scroll_cell:setPositionY(cellY)
   end
end

--根据不同的商店显示不同的资源
function QUIDialogStore:chooseResources()
  if self.shopType == QShop.GENERAL_SHOP then
    self._ccbOwner.shop:setVisible(true)
    self._ccbOwner.shop_time:setVisible(true)
    self.bossWord:setActorImage("ui/boss2_shop.png")
  elseif self.shopType == QShop.GOBLIN_SHOP then
    self._ccbOwner.goblin_shop:setVisible(true)
    self._ccbOwner.mystory_time:setVisible(true)
    self.bossWord:setActorImage("ui/boss_shop.png")
  elseif self.shopType == QShop.BLACK_MARKET_SHOP then
    self._ccbOwner.black_shop:setVisible(true)
    self._ccbOwner.mystory_time:setVisible(true)
    self.bossWord:setActorImage("ui/boss3_shop.png")
  elseif self.shopType == QShop.ARENA_SHOP then
    self._ccbOwner.arena_shop:setVisible(true)
    self._ccbOwner.shop_time:setVisible(true)
    self.bossWord:setActorImage("ui/Arena_shop.png")
  elseif self.shopType == QShop.SUNWELL_SHOP then
    self._ccbOwner.sunwell_shop:setVisible(true)
    self._ccbOwner.shop_time:setVisible(true)
    self.bossWord:setActorImage("ui/SunWell_Shop.png")
  end
end

--设置下次刷新时间
function QUIDialogStore:setRefreshTime()
  if self._timeHandler ~= nil then
    scheduler.unscheduleGlobal(self._timeHandler)
    self._timeHandler = nil
  end
  
  self.nowTime = q.serverTime()
  local timeInfo = QStaticDatabase.sharedDatabase():getGeneralShopRefreshTime()
  local refreshTime = string.split(timeInfo, ";")
  
  local firstTime = string.split(refreshTime[1], ":")
  local secondTime = string.split(refreshTime[2], ":")
  local thirdTime = string.split(refreshTime[3], ":")
  local fourthTime = string.split(refreshTime[4], ":")
  firstTime = q.getTimeForHMS(firstTime[1], firstTime[2], firstTime[3]) + 60
  secondTime = q.getTimeForHMS(secondTime[1], secondTime[2], secondTime[3]) + 60
  thirdTime = q.getTimeForHMS(thirdTime[1], thirdTime[2], thirdTime[3]) + 60
  fourthTime = q.getTimeForHMS(fourthTime[1], fourthTime[2], fourthTime[3]) + 60
  local midnight = q.getTimeForHMS("24", "00", "00")
  
  if self.shopType == QShop.GOBLIN_SHOP or self.shopType == QShop.BLACK_MARKET_SHOP then
     self.storeRefreshTime = remote.stores:getRefreshAtTime(self.shopType) 
     self:_mystroyRefreshTime()
  elseif self.shopType == QShop.GENERAL_SHOP then
     if self.nowTime < firstTime then
      self._ccbOwner.refresh_time:setString("今日9点")
      self:_generalRefreshTime(firstTime)
      return
    elseif self.nowTime < secondTime and self.nowTime >= firstTime then
      self._ccbOwner.refresh_time:setString("今日12点")
      self:_generalRefreshTime(secondTime)
      return
    elseif self.nowTime < thirdTime and self.nowTime >= secondTime then
      self._ccbOwner.refresh_time:setString("今日18点")
      self:_generalRefreshTime(thirdTime)
      return
    elseif self.nowTime < fourthTime and self.nowTime >= thirdTime then
      self._ccbOwner.refresh_time:setString("今日21点")
      self:_generalRefreshTime(fourthTime)
      return
    elseif self.nowTime >= fourthTime and self.nowTime < midnight then
      self._ccbOwner.refresh_time:setString("明日9点")
      self:_generalRefreshTime(midnight)
      return
    end
  else
     local arenaTime = q.getTimeForHMS("21", "00", "00") + 60
     if self.nowTime < arenaTime then
      self._ccbOwner.refresh_time:setString("今日21点")
      self:_generalRefreshTime(arenaTime)
      return
    elseif self.nowTime >= arenaTime and self.nowTime < midnight then
      self._ccbOwner.refresh_time:setString("明日21点")
      self:_generalRefreshTime(midnight)
      return
    end
  end
end

--普通商店刷新时间
function QUIDialogStore:_generalRefreshTime(time)
      if self._timeHandler ~= nil then
        scheduler.unscheduleGlobal(self._timeHandler)
        self._timeHandler = nil
      end
      remote.stores:setNextRefershTime(self.shopType, time)
      local offsetTime = q.serverTime()
      if offsetTime < time then
        self._timeHandler = scheduler.performWithDelayGlobal(function()
          self:setRefreshTime()
          self._timeHandler = nil
          self:refreshItems()
        end,(time - offsetTime))
        printInfo(time - offsetTime)
      end
end

--特殊商店刷新时间
function QUIDialogStore:_mystroyRefreshTime()
      if self._timeHandler ~= nil then
        scheduler.unscheduleGlobal(self._timeHandler)
        self._timeHandler = nil
      end
      
      --获取商店停留时间
      local stayTime = QStaticDatabase.sharedDatabase():getConfiguration()
      if self.shopType == QShop.GOBLIN_SHOP then
        stayTime = stayTime["TIME_REFRESH_SHOP_1"].value * 60
      elseif self.shopType == QShop.BLACK_MARKET_SHOP then
        stayTime = stayTime["TIME_REFRESH_SHOP_2"].value * 60
      end
      
      self.CDTime = self.storeRefreshTime/1000 + stayTime
      self._timeFun = (function()
        self._timeHandler = nil
        local offsetTime = q.serverTime()
        
        if offsetTime < self.CDTime then
          self._timeHandler = scheduler.performWithDelayGlobal(self._timeFun, 1)
          local date = q.timeToHourMinuteSecond(self.CDTime - offsetTime)
          self._ccbOwner.black_refresh_time:setString(date)
        else
          self:closeCurrentDialog()
        end
      end)
      self._timeFun()
end

--自动关闭当前所有dialog
function QUIDialogStore:closeCurrentDialog()
  local dialog = app:getNavigationMidLayerController():getTopDialog()
  if dialog.class.__cname ~= "QUIPageEmpty" then
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
  end
  remote.stores:closeMystoryShop(self.shopType)
  self:onTriggerBackHandler()
  local page  = app:getNavigationController():getTopPage()
  page:_checkMystoryStores()
end


function QUIDialogStore:_onTriggerNormal()
  local refreshCount = remote.stores:getRefreshCountById(self.shopType) or 0
  local refreshToken = QStaticDatabase:sharedDatabase():getTokenByRefreshCount(self.shopType, refreshCount) or 0
     app:alert({content="显示新一批商品需要消耗"..refreshToken..self:currency(self.shopType).."，是否继续？（今日已刷新"..refreshCount.."次）",title="系统提示", comfirmBack=function()
        -- check if money is enough locally
        local money = self:getMoney()
        if money < refreshToken then
            app.tip:floatTip(self:currency(self.shopType).."不足")
            return
        end

        app:getClient():refreshShop(self.shopType, function(data)        
            if remote.stores:checkMystoryStoreTimeOut(self.shopType) == false then
              
            else
              self:_initItme()
              self.bossWord:showSpeakWord("refresh")

              if self.shopType == QShop.ARENA_SHOP then
                  self._arenaMoney = self._arenaMoney - refreshToken
                  self.arenaGold:setMoney(self._arenaMoney)
                  remote.user:update({arenaMoney = self._arenaMoney})
              elseif self.shopType == QShop.SUNWELL_SHOP then
                  self._sunwellMoney = self._sunwellMoney - refreshToken
                  self.sunwellGold:setMoney(self._sunwellMoney)
                  remote.user:update({sunwellMoney = self._sunwellMoney})
              end
            end

          end, 
          function(data)
            -- if data.code == "TOKEN_NOT_ENOUGH" then
            --   app.tip:floatTip(self:currency(self.shopType).."不足")
            -- end
          end)
    end, callBack = function ()
      end})
end

function QUIDialogStore:currency(shopType)
  if self.shopType == QShop.SUNWELL_SHOP then
    return "太阳之尘"
  elseif self.shopType == QShop.ARENA_SHOP then
    return "竞技场币"
  else
    return "符石"
  end
end

function QUIDialogStore:getMoney()
  if self.shopType == QShop.SUNWELL_SHOP then
    return remote.user.sunwellMoney
  elseif self.shopType == QShop.ARENA_SHOP then
    return remote.user.arenaMoney
  else
    return remote.user.token
  end
end

function QUIDialogStore:getItem()
   app:getClient():getStores(self.shopType, function(data)
          self:_initItme()
   end)
end

--自动刷新物品
function QUIDialogStore:refreshItems()
      app:getClient():getStores(self.shopType, function(data)
--          if self._storesInfo ~= nil then
--            self._storesInfo = nil
--          end
--          self._storesInfo = data.shops["1"].shelves
          self:_initItme()
          self.bossWord:showSpeakWord("refresh")
        end, 
        function()
        
        end)
end    


function QUIDialogStore:sellClickHandler(data)
  if self._isMove == false then
    if data.isSell == false then

      app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogStoreDetail",
        options = {shopId = self.shopType, itemInfo = data.itemInfo, itemConfig = data.itemConfig, position = data.position}},
              {isPopCurrentDialog = false})
    else
      self.bossWord:showSpeakWord("soldout")
    end   
  end
end

function QUIDialogStore:sellItemSuccess(data)
  if data ~= nil then
--    self.itmeBox[data.position]:_setItemIsSell()
    self.itmeBox[data.position]:_setItemIsSell()
    self.bossWord:showSpeakWord("soldout")
    if self.shopType == QShop.ARENA_SHOP then
      -- self.arenaGold:setMoney(data.info.arenaResponse.self.arenaMoney)
      -- remote.arena:updateArenaMoney(data.info.arenaResponse.self.arenaMoney)
      if data.item ~= nil then
        self._arenaMoney = self._arenaMoney - data.item.arena_money
        self.arenaGold:setMoney(self._arenaMoney)
        remote.user:update({arenaMoney = self._arenaMoney})
      end
    elseif self.shopType == QShop.SUNWELL_SHOP then
      if data.item ~= nil then
        self._sunwellMoney = self._sunwellMoney - data.item.sunwell_money
        self.sunwellGold:setMoney(self._sunwellMoney)
        remote.user:update({sunwellMoney = self._sunwellMoney})
      end
    end
  end
end

function QUIDialogStore:checkSellItem()
  local sellItems = remote.items:getItemsByType(ITEM_CATEGORY.CONSUM_MONEY)
  if next(sellItems) ~= nil then
    self.sellDialog =  app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogSellItems"},{isPopCurrentDialog = false})
  end
end

--返回
function QUIDialogStore:onTriggerBackHandler()
  app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogStore