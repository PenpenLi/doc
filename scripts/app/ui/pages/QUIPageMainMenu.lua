
local QUIPage = import(".QUIPage")
local QUIPageMainMenu = class("QUIPageMainMenu", QUIPage)

local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIViewController = import("..QUIViewController")
local QRemote = import("...models.QRemote")
local QUIWidgetHead = import("..widgets.QUIWidgetHead")
local QUIWidgetTopStatusShow = import("..widgets.QUIWidgetTopStatusShow")
local QUIDialogHeroInformation = import("..dialogs.QUIDialogHeroInformation")
local QUIDialogUnlockSucceed = import("..dialogs.QUIDialogUnlockSucceed")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetScaling = import("..widgets.QUIWidgetScaling")
local QUIDialogMail = import("..dialogs.QUIDialogMail")
local QUIDialogStore = import("..dialogs.QUIDialogStore")
local QTutorialDirector = import("...tutorial.QTutorialDirector")
local QNavigationController = import("...controllers.QNavigationController")
local QTips = import(".utils.QTips")
local QShop = import("...utils.QShop")
local QUserProp = import("...utils.QUserProp")
local QSkeletonViewController = import("...controllers.QSkeletonViewController")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QUIWidgetUnlockTutorialHandTouch = import("..widgets.QUIWidgetUnlockTutorialHandTouch")
local QTutorialDefeatedGuide = import("...tutorial.defeated.QTutorialDefeatedGuide")
local QVIPUtil = import("...utils.QVIPUtil")
-- local QTutorialTeamAndDungeon = import("...tutorial.QTutorialTeamAndDungeon")


function QUIPageMainMenu:ctor(options)
  local ccbFile = "ccb/Page_Mainmenu.ccbi"
  local callbacks = {
    {ccbCallbackName = "onMilitaryRank", callback = handler(self, QUIPageMainMenu._onMilitaryRank)},
    {ccbCallbackName = "onArena", callback = handler(self, QUIPageMainMenu._onArena)},
    {ccbCallbackName = "onSunwell", callback = handler(self, QUIPageMainMenu._onSunwell)},
    {ccbCallbackName = "onRank", callback = handler(self, QUIPageMainMenu._onRank)},
    {ccbCallbackName = "onCheast", callback = handler(self, QUIPageMainMenu._onCheast)},
    {ccbCallbackName = "onMail", callback = handler(self, QUIPageMainMenu._onMail)},
    {ccbCallbackName = "onInstance", callback = handler(self, QUIPageMainMenu._onInstance)},
    {ccbCallbackName = "onChatButtonClick", callback = handler(self, QUIPageMainMenu._onChatButtonClick)},
    {ccbCallbackName = "onFuzou", callback = handler(self, QUIPageMainMenu._onFuzou)},
    {ccbCallbackName = "onZhuangbei", callback = handler(self, QUIPageMainMenu._onZhuangbei)},
    {ccbCallbackName = "onTimeMachine", callback = handler(self, QUIPageMainMenu._onTimeMachine)},
    {ccbCallbackName = "onYingxiong", callback = handler(self, QUIPageMainMenu._onYingxiong)},
    {ccbCallbackName = "onShangcheng", callback = handler(self, QUIPageMainMenu._onGeneralShop)},
    {ccbCallbackName = "onShenmi", callback = handler(self, QUIPageMainMenu._onGoblinShop)},
    {ccbCallbackName = "onGonghui", callback = handler(self, QUIPageMainMenu._onBlackMarketShop)},
    {ccbCallbackName = "onGoldBattle", callback = handler(self, QUIPageMainMenu._onGoldBattle)},
    {ccbCallbackName = "onTriggerBack", callback = handler(self, QUIPageMainMenu._onTriggerBack)},
    {ccbCallbackName = "onTriggerHome", callback = handler(self, QUIPageMainMenu._onTriggerHome)},
    {ccbCallbackName = "onTriggerDialy", callback = handler(self, QUIPageMainMenu._onTriggerDialy)}
  }

  QUIPageMainMenu.super.ctor(self, ccbFile, callbacks, options)
  self:buildLayer()
  
  -- QTutorialTeamAndDungeon.new()
  -- handel screen slide move
  self._touchLayer = QUIGestureRecognizer.new()
  self._touchLayer._mainMenu = true
  self._touchLayer:setSlideRate(0.3)
  self._touchLayer:setAttachSlide(true)
  self._touchLayer:attachToNode(self:getView(), display.width, display.height, 0, 0, handler(self, self._onTouch))

  self._lastSlidePositionX = 0
  self._slideMoveTemp = 0
  self._currentScreenIndex = 0
  self._screenIndexLeft = -1
  self._screenIndexRight = 1
  self._midTotalWidth = 0
  self._farTotalWidth = 0
  for i=1,3,1 do
    self._farTotalWidth = self._farTotalWidth +self._ccbOwner["bj_far"..i]:getContentSize().width * self._ccbOwner["bj_far"..i]:getScaleX()
  end
  self._farTotalWidth = self._farTotalWidth - 10
  for i=1,3,1 do
    self._midTotalWidth = self._midTotalWidth +self._ccbOwner["bj_mid"..i]:getContentSize().width * self._ccbOwner["bj_mid"..i]:getScaleX()
  end
  self._midTotalWidth = self._midTotalWidth * 0.88
  self._farTotalWidth = self._farTotalWidth * 0.9
  self._midOffsetX = -532
  self._farOffsetX = 80
  self._ccbOwner.node_far:setPositionX(self._farOffsetX)
  self.tips = nil

  -- add energy prompt @qinyuanji
  self._energyPrompt = app:promptTips()
  
  -- handle menu info
  --CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ui/Pagehome.plist");

  self._ccbOwner.node_fuzhoutext:setVisible(false)
  self._ccbOwner.node_zhuangbeitext:setVisible(false)
  self._ccbOwner.node_conghuitext:setVisible(false)
  self._ccbOwner.node_shenmitext:setVisible(false)
--  self._ccbOwner.node_storetext:setVisible(false)
  self._ccbOwner.btn_home:setVisible(false)
  self._ccbOwner.btn_back:setVisible(false)

  --数据更新监听
  self._remoteEventProxy = cc.EventProxy.new(remote)
  self._mailsEventProxy = cc.EventProxy.new(remote.mails)
  self._shopEventProxy = cc.EventProxy.new(remote.stores)

  local topRegionCCBLayer1 = QUIWidgetTopStatusShow.new(1)
  local topRegionCCBLayer2 = QUIWidgetTopStatusShow.new(2)
  local topRegionCCBLayer3 = QUIWidgetTopStatusShow.new(3)
  local headInfo = QUIWidgetHead.new()
  self._topRegion = {}
  table.insert(self._topRegion, topRegionCCBLayer1)
  table.insert(self._topRegion, topRegionCCBLayer2)
  table.insert(self._topRegion, topRegionCCBLayer3)

  self._headInfo = headInfo

  self._ccbOwner.CCNode_TopGameCurrency:addChild(topRegionCCBLayer1:getView())
  self._ccbOwner.CCNode_TopRunestone:addChild(topRegionCCBLayer2:getView())
  self._ccbOwner.CCNode_TopEnergy:addChild(topRegionCCBLayer3:getView())
  self._ccbOwner.node_tophead:addChild(headInfo:getView())

  self:setHeadInfo(remote.user)
  topRegionCCBLayer1:showIcon(1)
  topRegionCCBLayer2:showIcon(2)
  topRegionCCBLayer3:showIcon(3)

  --最牛B的玩家显示
  self._ccbOwner.label_player:setString("")
  self._ccbOwner.node_player:setVisible(false)

  --打开侧边栏显示的遮罩层
  self._layer = CCLayerColor:create(ccc4(0, 0, 0, 0.7 * 255), display.width, display.height)
  local scalingMaskPosition = ccp(0,0)
  scalingMaskPosition = self._ccbOwner.node_scaling:convertToNodeSpaceAR(scalingMaskPosition)
  self._layer:setPosition(scalingMaskPosition)

  --侧边栏 传入主界面聊天界面节点, 和遮罩
  self._scaling = QUIWidgetScaling.new({stencil = self._layer})
  self._ccbOwner.node_scaling:addChild(self._layer)
  self._ccbOwner.node_scaling:addChild(self._scaling:getView())
  --设置zorder使侧边栏一直保持在界面最上层
  self._ccbOwner.node_ui:setZOrder(9998)
  self._ccbOwner.node_scaling:setZOrder(9999)
  self._ccbOwner.node_btn:setZOrder(10000)

  if g_scalingFlag then
    self._scaling:willPlayHide()
  end

  
  -- self:_getTopData()
  app.sound:playBackgroundMusic("main_interface")
  
  scheduler.performWithDelayGlobal(function()
    self:checkGuiad()
  end, 0)
  self:_onMailDataUpdate()

--  self._ccbOwner.node_active:setVisible(false)
  self._ccbOwner.node_chat:setVisible(false)
  
  self:_checkUnlock()
  self:_checkMystoryStores()
  self:_checkRedTip()
  self:_checkUnlockTutorial()
  self:_checkLockBuilding()

  if DEBUG > 0 then
      self:_addDebugButton()
  end

  self.defeatedGuide = QTutorialDefeatedGuide.new()
end

function QUIPageMainMenu:viewDidAppear()
  self._remoteEventProxy:addEventListener(QRemote.USER_UPDATE_EVENT, handler(self, self._onUserDataUpdate))
  
  self._shopEventProxy:addEventListener(remote.stores.MYSTORY_SHOP_UPDATE_EVENT, handler(self, self._checkMystoryStores))
  
  self._mailsEventProxy:addEventListener(remote.mails.MAILS_UPDATE_EVENT, handler(self, self._onMailDataUpdate))

  self._touchLayer:enable()
  self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self._onTouch))

  self._headInfo:addEventListener(QUIWidgetHead.EVENT_HERO_HEAD_CLICK, handler(self, self._onUserHeadClickHandler))

  for _,topRegionCCBLayer in pairs(self._topRegion) do
    topRegionCCBLayer:addEventListener(QUIWidgetTopStatusShow.EVENT_CLICK, handler(self, QUIPageMainMenu._onTopRegionCCBLayerClick))
  end

  QNotificationCenter.sharedNotificationCenter():addEventListener(QNavigationController.EVENT_BACK_PAGE, self._backPageHandler, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QShop.SHOP_CLOSE, QUIPageMainMenu._shopClose,self) 
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUserProp.CHEST_IS_FREE, QUIPageMainMenu._chestIsFree,self) 
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetUnlockTutorialHandTouch.UNLOCK_TUTORIAL_EVENT_CLICK, QUIPageMainMenu._closeUnlockTutorial,self) 

  self._userEventProxy = cc.EventProxy.new(remote.user)
  self._userEventProxy:addEventListener(remote.user.EVENT_USER_PROP_CHANGE, handler(self, self._userPropUpdateHandler))

  QDeliveryWrapper:setToolBarVisible(true)

  self._energyPrompt:addEnergyEventListener()
  
  -- clean texture cache
  app:cleanTextureCache()
end

function QUIPageMainMenu:viewWillDisappear()
  self._touchLayer:removeAllEventListeners()
  self._touchLayer:disable()
  self._touchLayer:detach()

  self._remoteEventProxy:removeAllEventListeners()
  self._remoteEventProxy = nil

  self._mailsEventProxy:removeAllEventListeners()
  self._mailsEventProxy = nil
  
  self._shopEventProxy:removeAllEventListeners()
  self._shopEventProxy = nil

  self._headInfo:removeEventListener(QUIWidgetHead.EVENT_HERO_HEAD_CLICK, handler(self, self._onUserHeadClickHandler))
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QNavigationController.EVENT_BACK_PAGE, self._backPageHandler, self)
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QShop.SHOP_CLOSE, QUIPageMainMenu._shopClose,self) 
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUserProp.CHEST_IS_FREE, QUIPageMainMenu._chestIsFree,self) 
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetUnlockTutorialHandTouch.UNLOCK_TUTORIAL_EVENT_CLICK, QUIPageMainMenu._closeUnlockTutorial,self) 

  self._userEventProxy:removeAllEventListeners()

  self._energyPrompt:removeEnergyEventListener()

  self.defeatedGuide:detach()

  audio.stopBackgroundMusic()
end

function QUIPageMainMenu:hideScaling()
  self:setManyUIVisible()
  self._scalingStatus = self._scaling:getScalingStatus()
  if self._scalingStatus then
    self._scaling:willPlayHide()
  end
end

function QUIPageMainMenu:setBackBtnVisible(b)
  self._ccbOwner.btn_back:setVisible(b)
end

function QUIPageMainMenu:setHomeBtnVisible(b)
  self._ccbOwner.btn_home:setVisible(b)
end

function QUIPageMainMenu:setAllUIVisible(b)
  self._ccbOwner.CCNode_TopEnergy:setVisible(b)
  self._ccbOwner.CCNode_TopRunestone:setVisible(b)
  self._ccbOwner.CCNode_TopGameCurrency:setVisible(b)
  self._ccbOwner.node_tophead:setVisible(b)
   self._ccbOwner.node_active:setVisible(b)
  -- self._ccbOwner.node_chat:setVisible(b)
  if b and self._scalingStatus == true then
    self._scaling:willPlayShow()
  end
end

function QUIPageMainMenu:setManyUIVisible()
  self._ccbOwner.node_tophead:setVisible(false)
   self._ccbOwner.node_active:setVisible(false)
  -- self._ccbOwner.node_chat:setVisible(false)
  self._ccbOwner.CCNode_TopEnergy:setVisible(true)
  self._ccbOwner.CCNode_TopRunestone:setVisible(true)
  self._ccbOwner.CCNode_TopGameCurrency:setVisible(true)
end

function QUIPageMainMenu:setHeadInfo(userData)
  if nil ~= userData then
    self._headInfo:setInfo(userData)
    self._topRegion[1]:update(1, tostring(userData.money))
    self._topRegion[2]:update(1, tostring(userData.token))
    self._topRegion[3]:update(2, tostring(userData.energy), QStaticDatabase:sharedDatabase():getConfig().max_energy)
  end
end

--新建一个新手引导遮罩
function QUIPageMainMenu:buildLayer()
  if self.tutorialLayer == nil then
    self.tutorialLayer = CCLayerColor:create(ccc4(0, 0, 0, 0), display.width, display.height)
    self.tutorialLayer:setPosition(-display.width/2, -display.height/2)
    self.tutorialLayer:setTouchEnabled(true)
    app._uiScene:addChild(self.tutorialLayer)
  end
end

--清除新手引导遮罩
function QUIPageMainMenu:cleanBuildLayer()
  if self.tutorialLayer ~= nil then
    self.tutorialLayer:removeFromParent()
    self.tutorialLayer = nil
  end
end

function QUIPageMainMenu:checkGuiad()
  if app.tutorial:isTutorialFinished() == false then
    if app.tutorial:getStage().forcedGuide == QTutorialDirector.Stage_2_Treasure then
      app.tutorial:startTutorial(QTutorialDirector.Stage_2_Treasure)
    elseif app.tutorial:getStage().forcedGuide == QTutorialDirector.Stage_3_TeamAndDungeon and remote.instance:checkIsPassByDungeonId("wailing_caverns_1") == false then
      app.tutorial:startTutorial(QTutorialDirector.Stage_3_TeamAndDungeon)
    -- 暂时取消装备引导
    -- elseif app.tutorial:getStage().forcedGuide == QTutorialDirector.Stage_3_TeamAndDungeon and remote.instance:checkIsPassByDungeonId("wailing_caverns_1") == true then
    --   app.tutorial:startTutorial(QTutorialDirector.Stage_4_Equipment)
    --  elseif app.tutorial:getStage().forcedGuide == QTutorialDirector.Stage_4_Equipment then
    --   app.tutorial:startTutorial(QTutorialDirector.Stage_4_Equipment)
    elseif app.tutorial:getStage().skillGuide == QTutorialDirector.Guide_Start and remote.instance:checkIsPassByDungeonId("wailing_caverns_8") == true then
        if QTips.UNLOCK_TIP_ISTRUE == false then
          app.tip:showUnlockTips(QUIDialogUnlockSucceed.UNLOCK_SKILL) 
        else
          app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_SKILL)
        end
        app.tutorial:startTutorial(QTutorialDirector.Stage_5_Skill) 
    --暂时取消突破引导
    -- elseif app.tutorial:getStage().breakthroughGuide == QTutorialDirector.Guide_Start and remote.herosUtil:checkAllHerosBreakthroughNeedEqu() ~= nil then
    --   app.tutorial:startTutorial(QTutorialDirector.Stage_7_Breakthrough)
--    elseif app.tutorial:getStage().temaBoxGuide == QTutorialDirector.Guide_Start and remote.user.teamLevel >= 20 then
--      app.tutorial:startTutorial(QTutorialDirector.Stage_9_TeamBox)
    else 
      self:cleanBuildLayer()
    end
  else 
      self:cleanBuildLayer()
  end
end

--检查是否有解锁提示
function QUIPageMainMenu:_checkUnlock()
--  local unlockTutorial = app.tip:getUnlockTutorial()
--  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
--  if unlockTutorial.shopTutorial == QTips.UNLOCK_TUTORIAL_CLOSE and remote.instance:checkIsPassByDungeonId(unlockVlaue["UNLOCK_SHOP"].value) == true then
--    app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_SHOP)
--    unlockTutorial.shopTutorial = QTips.UNLOCK_TUTORIAL_OPEN
--    app.tip:setUnlockTutorial(unlockTutorial)
--  end
  if app.tip.unLockTipsNum ~= 0 then
       app.tip:showNextTip()
  end
end

--检查是否有解锁引导
function QUIPageMainMenu:_checkUnlockTutorial()
  if app.tip:isTutorialFinished() == false then
    local unlockTutorial = app.tip:getUnlockTutorial()
    if unlockTutorial.shopTutorial == QTips.UNLOCK_TUTORIAL_OPEN then
      if self.shopHandTouch == nil then
        self._CP = ccp(self._ccbOwner.btn_shangcheng:getPosition())
        self.shopHandTouch = QUIWidgetUnlockTutorialHandTouch.new({word = "新开启商店", direction = "up", type = "shop"})
        self.shopHandTouch:setPosition(self._CP.x + 150, self._CP.y + 50)
        self._ccbOwner.btn_shangcheng:addChild(self.shopHandTouch)
      end
    end
    if unlockTutorial.goblinTutorial == QTips.UNLOCK_TUTORIAL_OPEN then
      if self.goblinHandTouch == nil then
        self._CP = ccp(self._ccbOwner.node_shenmi:getPosition())
        self.goblinHandTouch = QUIWidgetUnlockTutorialHandTouch.new({word = "新开启地精商店", direction = "up", type = "goblinshop"})
        self.goblinHandTouch:setPosition(self._CP.x - 260, self._CP.y)
        self._ccbOwner.node_shenmi:addChild(self.goblinHandTouch)
      end
    end
    if unlockTutorial.blackTutorial == QTips.UNLOCK_TUTORIAL_OPEN then
      if self.blackHandTouch == nil then
        self._CP = ccp(self._ccbOwner.node_conghui:getPosition())
        self.blackHandTouch = QUIWidgetUnlockTutorialHandTouch.new({word = "新开启黑市商人", direction = "up", type = "blackshop"})
        self.blackHandTouch:setPosition(self._CP.x - 400, self._CP.y + 280)
        self._ccbOwner.node_conghui:addChild(self.blackHandTouch)
      end
    end 
    if unlockTutorial.spaceTutorial == QTips.UNLOCK_TUTORIAL_OPEN then
      if self.spaceHandTouch == nil then
        self._CP = ccp(self._ccbOwner.timeMachine_zhuan:getPosition())
        self.spaceHandTouch = QUIWidgetUnlockTutorialHandTouch.new({word = "新开启时空传送器", direction = "up", type = "space"})
        self.spaceHandTouch:setPosition(self._CP.x + 100, self._CP.y - 150)
        self._ccbOwner.timeMachine_zhuan:addChild(self.spaceHandTouch)
      end
    end
    if unlockTutorial.goldTutorial == QTips.UNLOCK_TUTORIAL_OPEN then
      if self.goldHandTouch == nil then
        self._CP = ccp(self._ccbOwner.btn_timeMachine:getPosition())
        self.goldHandTouch = QUIWidgetUnlockTutorialHandTouch.new({word = "新开启黄金挑战", direction = "up", type = "gold"})
        self.goldHandTouch:setPosition(self._CP.x + 50, self._CP.y + 20)
        self._ccbOwner.btn_goldbattle:addChild(self.goldHandTouch)
      end
    end
    if unlockTutorial.arenaTutorial == QTips.UNLOCK_TUTORIAL_OPEN then
      if self.arenaHandTouch == nil then
        self._CP = ccp(self._ccbOwner.btn_mrank:getPosition())
        self.arenaHandTouch = QUIWidgetUnlockTutorialHandTouch.new({word = "新开启竞技场", direction = "up", type = "arena"})
        self.arenaHandTouch:setPosition(self._CP.x, self._CP.y + 80)
        self._ccbOwner.node_junxian:addChild(self.arenaHandTouch)
      end
    end
    if unlockTutorial.sunwellTutorial == QTips.UNLOCK_TUTORIAL_OPEN then
      if self.sunwellHandTouch == nil then
        self.sunwellHandTouch = QUIWidgetUnlockTutorialHandTouch.new({word = "新开启太阳之井", direction = "down", type = "sunwell"})
        self.sunwellHandTouch:setPosition(self._ccbOwner.btn_sunwell:getContentSize().width/2, self._ccbOwner.btn_sunwell:getContentSize().height/2)
        self._ccbOwner.btn_sunwell:addChild(self.sunwellHandTouch, 10)
      end
    end
  end
end

--关闭解锁引导
function QUIPageMainMenu:_closeUnlockTutorial(data)
  if data.type == "shop" then
     self.shopHandTouch:removeFromParent()
     self:_onGeneralShop()
  elseif data.type == "goblinshop" then
     self.goblinHandTouch:removeFromParent()
     self:_onGoblinShop()
  elseif data.type == "blackshop" then
     self.blackHandTouch:removeFromParent()
     self:_onBlackMarketShop()
  elseif data.type == "space" then
     self.spaceHandTouch:removeFromParent()
     self:_onTimeMachine()
  elseif data.type == "gold" then
     self.goldHandTouch:removeFromParent()
     self:_onGoldBattle()
  elseif data.type == "arena" then
     self.arenaHandTouch:removeFromParent()
     self:_onArena()
  elseif data.type == "sunwell" then
     self.sunwellHandTouch:removeFromParent()
     self:_onSunwell()
  end
end

function QUIPageMainMenu:_checkMystoryStores()
  self._ccbOwner.shop_open:setVisible(false)
  self._ccbOwner.shop_close:setVisible(false)
  self._ccbOwner.shop2_close:setVisible(true)
  self._ccbOwner.shop1_close:setVisible(false)
  self._ccbOwner.node_chest:setVisible(false)
  self.goblinShop = false
  self.blackMarketShop = false
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  
  if remote.user.level >= unlockVlaue["UNLOCK_SHOP"].value == true then
    self._ccbOwner.shop_open:setVisible(true)
  else
    self._ccbOwner.shop_close:setVisible(true)
  end
  
  if remote.stores:checkMystoryStore(QShop.GOBLIN_SHOP) and remote.user.level >= unlockVlaue["UNLOCK_SHOP_1"].value and 
    (remote.stores:checkMystoryStoreTimeOut(QShop.GOBLIN_SHOP) or QVIPUtil:enableGoblinPermanent()) then
      self.goblinShop = true
      self._ccbOwner.shop1_close:setVisible(true)
      self:startGoblinShopAnimation()
  else
      self:stopShopAnimation(QShop.GOBLIN_SHOP)
  end
  if remote.stores:checkMystoryStore(QShop.BLACK_MARKET_SHOP) and remote.user.level >= unlockVlaue["UNLOCK_SHOP_2"].value and 
    (remote.stores:checkMystoryStoreTimeOut(QShop.BLACK_MARKET_SHOP) or QVIPUtil:enableBlackMarketPermanent()) then
      self.blackMarketShop = true
      self._ccbOwner.shop2_close:setVisible(false)
      self._ccbOwner.node_chest:setVisible(true)
      self:startBlackShopAnimation()
  else
      self:stopShopAnimation(QShop.BLACK_MARKET_SHOP)
  end
end

function QUIPageMainMenu:_checkRedTip()
  self._ccbOwner.sign_tips:setVisible(false)
  self._ccbOwner.chest_tip:setVisible(false)
  --检查签到的红点提示
  local signIn = remote.daily:checkTodaySignIn()
  if signIn == false then
    self._ccbOwner.sign_tips:setVisible(true)
  end
  if remote.daily:checkAddUpAward() then
    self._ccbOwner.sign_tips:setVisible(true)
  end
  if remote.user:getChestState() then
    self._ccbOwner.chest_tip:setVisible(true)
  end
  
end

function QUIPageMainMenu:_onMailDataUpdate(event)
  self._ccbOwner.mail_red_icon:setVisible(false)
  if remote.mails == nil then return end
  for _, mail in pairs(remote.mails:getMails()) do
    if mail.readed == false then
      self._ccbOwner.mail_red_icon:setVisible(true)
      return
    end
  end

end

function QUIPageMainMenu:_onUserDataUpdate(event)
  self._userData = event.target.user
  local userleveltext = self._ccbOwner.CCLabelTFF_CharacterLevel
  if nil ~= userleveltext then
  end

  --设置人物头像信息
  self:setHeadInfo(self._userData)

  self:_checkLockBuilding()
end

--设置建筑是否解锁
function QUIPageMainMenu:_checkLockBuilding()
    local config = QStaticDatabase:sharedDatabase():getConfiguration()
    self._ccbOwner.timeMachine_close:setVisible(remote.user.level < config["SPACE_TIME_TRANSMITTER"].value)
    self._ccbOwner.goldBattle_close:setVisible(remote.user.level < config["GOLD_CHALLENGE"].value)
    self._ccbOwner.arena_close:setVisible(remote.user.level < config["UNLOCK_ARENA"].value)
    self._ccbOwner.sunwell_disable:setVisible(remote.user.level < config["UNLOCK_SUNWELL"].value)
    self._ccbOwner.sunwell_enable:setVisible(remote.user.level >= config["UNLOCK_SUNWELL"].value)
end

-- 获取个人排名以及大元帅排行榜 
function QUIPageMainMenu:_getTopData()
  if remote.tops:getIsLast() then
    self:_responseGetRank(remote.tops:getTopData())
  else
    app:getClient():pvpGlobalTop(1,1,function(data)
      remote.tops:setFirstData(data.values.top)
      remote.tops:setMyRank(data.values.myGlobalRank)
      self:_responseGetRank(data.values.top)
    end,function(data)
      return
    end)
  end
end

function QUIPageMainMenu:_responseGetRank(data)
  if data ~= nil and #data > 0 then
    self._ccbOwner.label_player:setString(data[1].name)
    self._ccbOwner.node_player:setVisible(true)
  end
end

function QUIPageMainMenu:_onTouch(event)
    if event.name == "began" then
        self._sliderTemp = 0
        self._lastSlidePositionX = event.x
        self._farPositionX = self._ccbOwner.node_far:getPositionX()
        self._midPositionX = self._ccbOwner.node_mid:getPositionX()
        self._farNearPositionX = self._ccbOwner.node_far_near:getPositionX()
        self:_removeAction()
        return true
    elseif event.name == "moved" then
        self:screenMove(event.x - self._lastSlidePositionX, false)
        if self._isMoveing ~= true and math.abs(event.x - self._lastSlidePositionX) > 10 then
            self._isMoveing = true
        end
    elseif event.name == "ended" or event.name == "cancelled" then
        scheduler.performWithDelayGlobal(function ()
          self._isMoveing = false
        end, 0)
    elseif event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
        self._farPositionX = self._ccbOwner.node_far:getPositionX()
        self._midPositionX = self._ccbOwner.node_mid:getPositionX()
        self._farNearPositionX = self._ccbOwner.node_far_near:getPositionX()
        self:screenMove(event.distance.x, true)
    end 
end

--滑动距离，是否有惯性
function QUIPageMainMenu:screenMove(distance, isSlider)
    local isOffset = false
    if (self._midPositionX + distance) > - self._midOffsetX then
        distance =  - self._midPositionX - self._midOffsetX
        isOffset = true
    end
    if (self._midPositionX + distance) < (UI_DESIGN_WIDTH - self._midTotalWidth - self._midOffsetX) then
        distance = (UI_DESIGN_WIDTH - self._midTotalWidth) - self._midPositionX - self._midOffsetX
        isOffset = true
    end

    --远景移动
    local farDistance = distance*(self._farTotalWidth - UI_DESIGN_WIDTH)/(self._midTotalWidth - UI_DESIGN_WIDTH)
    local midDistance = distance * 0.5;
    if isSlider == false then
      self._ccbOwner.node_mid:setPositionX(self._midPositionX + distance)
      self._ccbOwner.node_far:setPositionX(self._farPositionX + farDistance)
      self._ccbOwner.node_far_near:setPositionX(self._farNearPositionX + midDistance)
    else
      self._midActionHandler = self:_contentRunAction(self._ccbOwner.node_mid, self._midPositionX + distance, self._ccbOwner.node_mid:getPositionY())
      self._farActionHandler = self:_contentRunAction(self._ccbOwner.node_far, self._farPositionX + farDistance, self._ccbOwner.node_far:getPositionY())
      self._farNearActionHandler = self:_contentRunAction(self._ccbOwner.node_far_near, self._farNearPositionX + midDistance, self._ccbOwner.node_far_near:getPositionY())
    end
end

function QUIPageMainMenu:_contentRunAction(node, posX, posY)
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveTo:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                          self:_removeAction()
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    return node:runAction(ccsequence)
    -- self:startEnter()
end

function QUIPageMainMenu:_removeAction()
    if self._midActionHandler ~= nil then
        self._ccbOwner.node_mid:stopAction(self._midActionHandler)
        self._midActionHandler = nil
    end
    if self._farActionHandler ~= nil then
        self._ccbOwner.node_mid:stopAction(self._farActionHandler)
        self._farActionHandler = nil
    end
    if self._farNearActionHandler ~= nil then
        self._ccbOwner.node_mid:stopAction(self._farNearActionHandler)
        self._farNearActionHandler = nil
    end
end

function QUIPageMainMenu:_backPageHandler(event)
  if event.currentTarget == app:getNavigationController() then
    self:setAllUIVisible(true)
    self:setBackBtnVisible(false)
    self:setHomeBtnVisible(false)
  end
end

function QUIPageMainMenu:_userPropUpdateHandler()
    self._topRegion[3]:update(2, tostring(remote.user.energy), global.config.max_energy)
end

--我的信息 @qinyuanji
function QUIPageMainMenu:_onUserHeadClickHandler()
  app.sound:playSound("common_small")
  return app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogMyInformation", 
              options = {avatar = remote.user.avatar, nickName = remote.user.nickname, exp = remote.user.exp, level = remote.user.level,
                        expToNextLevel = QStaticDatabase:sharedDatabase():getExperienceByTeamLevel(remote.user.level), 
                        heroMaxLevel = QStaticDatabase:sharedDatabase():getTeamConfigByTeamLevel(remote.user.level).hero_limit}})
end

--邮箱
function QUIPageMainMenu:_onMail()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  return app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogMail"})
end

--宝箱
function QUIPageMainMenu:_onCheast()
  if self._isMoveing == true then return end
  app.sound:playSound("map_tavern")
  self:hideScaling()
  return app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogTreasureChestDraw"})
end

function QUIPageMainMenu:_onChatButtonClick()
-- 临时disable 聊天室功能
-- QUtility:onChatButtonClick(remote.user.name, remote.user.rankCode, remote.user.icon, remote.user.teamLevel)
-- self:displayDesktop(false)
-- QUtility:registerShowDesktopHandler(handler(self, self.displayDesktop))
end

function QUIPageMainMenu:_onInstance()
  if self._isMoveing == true then return end
  app.sound:playSound("map_dungeon")
  self:hideScaling()
  return app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogInstance"})
end

function QUIPageMainMenu:_onArena()
  if self._isMoveing == true then return end
  app.sound:playSound("map_arena")
  remote.arena:openArena()

--  if true then return end
--  self:hideScaling()
--  app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogRankShowOff" })
end

function QUIPageMainMenu:_onMilitaryRank()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  --浮动提示条
  app.tip:floatTip("该功能暂未开放，敬请期待")
  
  
end

function QUIPageMainMenu:_onTopRegionCCBLayerClick(event)
  if event.kind == 3 then --购买体力
    return app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBuyVirtual",
      options = {typeName=ITEM_TYPE.ENERGY}})
  elseif event.kind == 1 then --购买金钱
    return app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBuyVirtual",
      options = {typeName=ITEM_TYPE.MONEY}})
  elseif event.kind == 2 then --充值
    return app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogVip"})
  end
end

function QUIPageMainMenu:_onTriggerBack()
  app.sound:playSound("common_return")
  QNotificationCenter.sharedNotificationCenter():triggerMainPageEvent(QNotificationCenter.EVENT_TRIGGER_BACK)
end

function QUIPageMainMenu:_onTriggerHome() 
  app.sound:playSound("common_home")
  QNotificationCenter.sharedNotificationCenter():triggerMainPageEvent(QNotificationCenter.EVENT_TRIGGER_HOME)
end

function QUIPageMainMenu:_onBlackMarketShop()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  if remote.user.level < unlockVlaue["UNLOCK_SHOP_2"].value then
      app.tip:floatTip("战队等级"..unlockVlaue["UNLOCK_SHOP_2"].value.."级解锁")
  else
    self:_checkMystoryStores()
    if self.blackMarketShop == false then
      app.tip:floatTip("尚未营业，通关副本有几率开启")
    else
      app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogStore", options = {type = QShop.BLACK_MARKET_SHOP}})
    end
  end
end

function QUIPageMainMenu:_onGoblinShop()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  if remote.user.level < unlockVlaue["UNLOCK_SHOP_1"].value then
      app.tip:floatTip("战队等级"..unlockVlaue["UNLOCK_SHOP_1"].value.."级解锁")
  else
    self:_checkMystoryStores()
    if self.goblinShop == false then
      app.tip:floatTip("尚未营业，通关副本有几率开启")
    else
      app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogStore", options = {type = QShop.GOBLIN_SHOP}})
    end
  end
end

function QUIPageMainMenu:_onGeneralShop()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  if remote.user.level < unlockVlaue["UNLOCK_SHOP"].value then
      app.tip:floatTip("战队等级"..unlockVlaue["UNLOCK_SHOP"].value.."级解锁")
  else
    app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogStore", options = {type = QShop.GENERAL_SHOP}})
  end
end

function QUIPageMainMenu:_onGoldBattle()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  if remote.user.level < unlockVlaue["GOLD_CHALLENGE"].value then
      app.tip:floatTip("战队等级"..unlockVlaue["GOLD_CHALLENGE"].value.."级解锁")
  else
    self:hideScaling()
    return app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogGoldBattle"})
  end
end

function QUIPageMainMenu:_onTimeMachine()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  if remote.user.level < unlockVlaue["SPACE_TIME_TRANSMITTER"].value then
      app.tip:floatTip("战队等级"..unlockVlaue["SPACE_TIME_TRANSMITTER"].value.."级解锁")
  else
    self:hideScaling()
    return app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogTimeMachine"})
  end
end

function QUIPageMainMenu:_onZhuangbei()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  app.tip:floatTip("该功能暂未开放，敬请期待")
end

function QUIPageMainMenu:_onFuzou()
  if self._isMoveing == true then return end
  app.sound:playSound("map_building")
  app.tip:floatTip("该功能暂未开放，敬请期待")
end

function QUIPageMainMenu:_onTriggerDialy()
  app.sound:playSound("common_small")
  app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogDailySignIn"})
end

function QUIPageMainMenu:_onSunwell()
  if self._isMoveing == true then return end
  app.sound:playSound("common_small")
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()

  if remote.user.level < unlockVlaue["UNLOCK_SUNWELL"].value then
      app.tip:floatTip("战队等级"..unlockVlaue["UNLOCK_SUNWELL"].value.."级解锁")
  else
      app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogSunWell"})
  end
end

function QUIPageMainMenu:_onRank()
  app.sound:playSound("common_small")
  app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogRank",
    options = {callbacks = {common = function ( ... ) print("common") end,
                            dailyArenaRankCallBack = function ( ... ) print("dailyArenaRankCallBack") end,
                            allFightCapacityCallBack = function ( ... ) print("allFightCapacityCallBack") end,
                            teamFightCapacityCallBack = function ( ... ) print("teamFightCapacityCallBack") end,
                            heroStarCallBack = function ( ... ) print("heroStarCallBack") end,
                            allStarCallBack = function ( ... ) print("allStarCallBack") end,
                            normalStarCallBack = function ( ... ) print("normalStarCallBack") end,
                            eliteStarCallBack = function ( ... ) print("eliteStarCallBack") end,
                            achievementPointCallBack = function ( ... ) print("achievementPointCallBack") end,}}}, 
    {isPopCurrentDialog = false})
end

function QUIPageMainMenu:_addDebugButton()
  local menu = CCMenu:create()
  menu:setPosition(0, 0)
  self:getView():addChild(menu)

  self._gmButton = ui.newTTFLabelMenuItem( {
    text = "GM Tools",
    font = global.font_monaco,
    size = 30,
    listener = handler(self, QUIPageMainMenu._onOpenGMTools),
    } )
  menu:addChild(self._gmButton)
  self._gmButton:setPosition(80, 100)

  self._relaunchButton = ui.newTTFLabelMenuItem( {
    text = "Relaunch",
    font = global.font_monaco,
    size = 30,
    listener = handler(self, QUIPageMainMenu._onRelaunchGame),
    } )
  menu:addChild(self._relaunchButton)
  self._relaunchButton:setPosition(80, 64)
end

function QUIPageMainMenu:_onOpenGMTools()
  QUtility:openURL("http://gm.xmoshou.com")
end

function QUIPageMainMenu:_onRelaunchGame()
  app:relaunchGame(false)
end

function QUIPageMainMenu:_shopClose(data)
  if data.shopId == QShop.GOBLIN_SHOP then
    self._ccbOwner.shop1_close:setVisible(false)
    self:stopShopAnimation(QShop.GOBLIN_SHOP)
  elseif data.shopId == QShop.BLACK_MARKET_SHOP then 
    self._ccbOwner.shop2_close:setVisible(true)
    self._ccbOwner.node_chest:setVisible(false)
    self:stopShopAnimation(QShop.BLACK_MARKET_SHOP)
  end
end

function QUIPageMainMenu:startGoblinShopAnimation()
  if self.goblin_animation ~= nil then
    return
  end
  remote.stores:mystoryStoreCountDown(QShop.GOBLIN_SHOP)
  self.goblin_animation = QSkeletonViewController.sharedSkeletonViewController():createSkeletonActorWithFile("goblin_merchant")
  self.goblin_animation:setScale(0.8)
  self._ccbOwner.node_shenmi:addChild(self.goblin_animation)
  local position = ccp(self._ccbOwner.btn_shenmi:getPosition())
  self.goblin_animation:setPosition(ccp(position.x + 35, position.y - 20))
  self.goblin_animation:playAnimation("walk", true)
  
  local arr = CCArray:create()
  arr:addObject(CCMoveTo:create(2, ccp(position.x, position.y - 20)))
  arr:addObject(CCCallFunc:create(function() 
    self.goblin_animation:stopAnimation()
    self.goblin_animation:playAnimation("stand", true) 
  end))
  arr:addObject(CCDelayTime:create(2)) 
  arr:addObject(CCCallFunc:create(function() 
    self.goblin_animation:stopAnimation()
    self.goblin_animation:playAnimation("walk", true) 
  end))
  arr:addObject(CCMoveTo:create(2, ccp(position.x - 35, position.y - 20)))
  arr:addObject(CCCallFunc:create(function() self.goblin_animation:setScaleX(-0.8) end))
  arr:addObject(CCMoveTo:create(2, ccp(position.x, position.y - 20)))
  arr:addObject(CCCallFunc:create(function() 
    self.goblin_animation:stopAnimation()
    self.goblin_animation:playAnimation("stand", true) 
  end))
  arr:addObject(CCDelayTime:create(2)) 
  arr:addObject(CCCallFunc:create(function() 
    self.goblin_animation:stopAnimation()
    self.goblin_animation:playAnimation("walk", true) 
  end))
  arr:addObject(CCMoveTo:create(2, ccp(position.x + 35, position.y - 20)))
  arr:addObject(CCCallFunc:create(function() self.goblin_animation:setScaleX(0.8) end))
  self.goblinShopHandler =  self.goblin_animation:runAction(CCRepeatForever:create(CCSequence:create(arr)))
  
end

function QUIPageMainMenu:startBlackShopAnimation()
  if self.black_animation ~= nil then
    return
  end
  remote.stores:mystoryStoreCountDown(QShop.BLACK_MARKET_SHOP)
  self.black_animation = QSkeletonViewController.sharedSkeletonViewController():createSkeletonActorWithFile("black_marketeer")
--  self.goblin_animation:setScale(-1)
  self._ccbOwner.node_conghui:addChild(self.black_animation)
  local position = ccp(self._ccbOwner.btn_gonghui:getPosition())
  self.black_animation:setPosition(ccp(position.x - 100, position.y + 20))
  self.black_animation:playAnimation("stand", true)
  
  self.action = {"stand01", "stand02"}
  local delayTime = 3
  local arr = CCArray:create()
  arr:addObject(CCDelayTime:create(3)) 
  arr:addObject(CCCallFunc:create(function()
    local i = math.random(2) 
    self.black_animation:stopAnimation()
    self.black_animation:playAnimation(self.action[i], true) 
    if i == 1 then
      delayTime = 2
    elseif i == 2 then
      delayTime = 3
    end 
  end))
  arr:addObject(CCDelayTime:create(delayTime)) 
  arr:addObject(CCCallFunc:create(function() 
    self.black_animation:stopAnimation() 
    self.black_animation:playAnimation("stand", true) 
  end))
  self.blackShophandler =  self.black_animation:runAction(CCRepeatForever:create(CCSequence:create(arr)))
end


function QUIPageMainMenu:stopShopAnimation(type)
  if type == "2" then 
    if self.goblin_animation ~= nil then
      self.goblin_animation:stopAction(self.goblinShopHandler)
      self.goblin_animation:removeFromParent()
      QSkeletonViewController.sharedSkeletonViewController():removeSkeletonActor(self.goblin_animation)
      self.goblin_animation = nil
    end
  elseif type == "3" then
    if self.black_animation ~= nil then
      self.black_animation:stopAction(self.blackShophandler)
      self.black_animation:removeFromParent()
      QSkeletonViewController.sharedSkeletonViewController():removeSkeletonActor(self.black_animation)
      self.black_animation = nil
    end
  end
end

function QUIPageMainMenu:_chestIsFree()
  self:_checkRedTip()
end

return QUIPageMainMenu


