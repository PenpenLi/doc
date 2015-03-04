
local QUIPage = import(".QUIPage")
local QUIPageLogin = class("QUIPageLogin", QUIPage)

local QUIWidgetLoadBar = import("..widgets.QUIWidgetLoadBar")
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QClient = import("...network.QClient")
local QWebSocket = import("...network.QWebSocket")
local QUIViewController = import("..QUIViewController")
local QUserData = import("...utils.QUserData")
local QTutorialDirector = import("...tutorial.QTutorialDirector")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIPageLogin:ctor(options)
  local ccbFile = "ccb/Page_Login.ccbi"
  local callbacks = {
    {ccbCallbackName = "onLogin", callback = handler(self, QUIPageLogin._onLogin)},
    {ccbCallbackName = "onLogout", callback = handler(self, QUIPageLogin._onLogout)}
  }

  QUIPageLogin.super.ctor(self, ccbFile, callbacks, options)
  local userName = options.userName and options.userName or remote.user.name
  local str = string.format("欢迎， %s", userName)
  self._ccbOwner.label_welcome:setString(str)
  self._ccbOwner.node_panel:setVisible(true)
  self._ccbOwner.node_panel:setTouchEnabled(true)
  self._ccbOwner.node_panel:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
  self._ccbOwner.node_panel:setTouchSwallowEnabled(true)
  self._ccbOwner.node_panel:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIPageLogin.onTouch))

  --设置默认服务器信息
  local serverId = ""
  local serverName = ""
  local latestServerSid = app:getUserData():getValueForKey(QUserData.DEFAULT_SERVERID)
  if latestServerSid ~= nil then
    for _,serverInfo in pairs(remote.serverInfos) do
      if serverInfo.serverId == latestServerSid then
        serverId = serverInfo.serverId
        serverName = serverInfo.name
        break
      end
    end
  end
  if #remote.serverInfos > 0 then
    serverId = remote.serverInfos[1].serverId
    serverName = remote.serverInfos[1].name
  end
  self:setInfo({serverName = serverName})
  self:setServer({serverId = serverId})

  self._loadBar = QUIWidgetLoadBar.new()
  self._loadBar:setVisible(false)
  self._ccbOwner.node_loading:addChild(self._loadBar)
  self:showLogoutButton(true)

  if DEBUG > 0 then
    local label = CCLabelTTF:create("版本号:" .. GAME_VERSION .. GAME_BUILD_TIME, global.font_default, 20)
    label:setAnchorPoint(ccp(0.0, 0.5))
    label:setPosition(64, 15)
    self:getView():addChild(label)
  end

end

function QUIPageLogin:onTouch(event)
  if event.name == "began" then
    self:showControls(false)
    app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogChooseServer",
      options = remote.serverInfos})
    -- app:getClient():ctAppServerList(function(data)
    --   self:showControls(false)
    --   app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogChooseServer",
    --     options = remote.serverInfos})
    -- end)
  end
end

function QUIPageLogin:connected()
  self:readyLoading()
  app:readyLogin()
  app:getClient():userLogin(remote.user.userId, remote.user.session,
    function(data)
      remote.user.isLoginFrist = true 
      self._isWaiting = false
      --[[ 记录登录的用户数据到本地 ]]
      app:getUserData():setUserName(remote.user.userId)
      app:getUserData():setValueForKey(QUserData.DEFAULT_SERVERID,self._server.serverId)
      app:loginEnd()

--      app:getLoginData(app:getClient(), remote.user)
      -- get tutorial stage
      remote.flag:get({remote.flag.FLAG_TUTORIAL_STAGE, remote.flag.FLAG_TUTORIAL_LOCK, remote.flag.FLAG_UNLOCK_TUTORIAL, remote.flag.FLAG_TEAM_LOCK}, function(data)
        if data.FLAG_TUTORIAL_LOCK ~= "" then
          SKIP_TUTORIAL = true
        end
        if data.FLAG_TUTORIAL_STAGE == "" then
          local _value = table.join(app.tutorial:getStage(), ";")
          remote.flag:set(remote.flag.FLAG_TUTORIAL_STAGE, _value)
        else
          app.tutorial:initStage(data.FLAG_TUTORIAL_STAGE)
        end 
        if data.FLAG_UNLOCK_TUTORIAL == "" then
          local _value = table.formatString(app.tip:getUnlockTutorial(), "^", ";")
          remote.flag:set(remote.flag.FLAG_UNLOCK_TUTORIAL, _value)
        else
          app.tip:initUnlockTutorial(data.FLAG_UNLOCK_TUTORIAL)
        end
        remote.teams:herosMaxCount()
        
        self:startLoading()
      end)
      
    end,
    function(data)
      self:stopLoading()
      app:alert({content="连接服务器失败！"}, false)
      self._isWaiting = false
    end)
end

function QUIPageLogin:startLoading()
  self:loadingForCacheCCB()
end

--前面的20%留给widget缓存使用
function QUIPageLogin:loadingForCacheCCB()
  self._loadBar:setPercent(0)
  self._cacheCCBPercent = 1.0
  self._cacheCCBHandler = function(percent)
    self._loadBar:setPercent(percent)
    if percent == 1 then
      app:enableTextureCacheScheduler()
      self:loadingEnd()
    end
  end
  app:disableTextureCacheScheduler()
  -- app.widgetCache:cacheWidgetForList(self._cacheCCBHandler)
  app.ccbNodeCache:cacheCCBNode(self._cacheCCBHandler)
end

-- function QUIPageLogin:showLoading()
--   local showPercent = 1 - self._cacheCCBPercent
--   local percent = 0
--   self._handler = scheduler.scheduleGlobal(function()
--     percent = percent + math.random(5)
--     percent = percent > 100 and 100 or percent
--     self._loadBar:setPercent((showPercent * percent) / 100  + self._cacheCCBPercent)
--     if percent == 100 then
--       scheduler.unscheduleGlobal(self._handler)
--       self._handler = nil
--       self:loadingEnd()
--     end
--   end,0)
-- end

function QUIPageLogin:loadingEnd()
  app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
  if app.tutorial:isTutorialFinished() == false and app.tutorial:getStage().forcedGuide == QTutorialDirector.Stage_1_FirstBattle then
    app.tutorial:startTutorial(QTutorialDirector.Stage_1_FirstBattle)
    app:setMusicSound(1)
    app:getSystemSetting():setMusicState("on")
    app:getSystemSetting():setSoundState("on")
    app:getSystemSetting():reload()
  else
    app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_PAGE, uiClass="QUIPageMainMenu"})
    -- get user data when user is loaded
    app:getSystemSetting():reload()
  end
end

function QUIPageLogin:readyLoading()
  self._loadBar:setVisible(true)
  self._ccbOwner.btn_game:setVisible(false)
  self._ccbOwner.node_panel:setVisible(false)
  self:showLogoutButton(false)
end

function QUIPageLogin:stopLoading()
  self._loadBar:setVisible(false)
  self._ccbOwner.btn_game:setVisible(true)
  self._ccbOwner.node_panel:setVisible(true)
  self:showLogoutButton(true)
end

function QUIPageLogin:showLogoutButton(visible)
  if app:isDeliveryIntegrated() then 
    self._ccbOwner.btn_logout:setVisible(false)
  else
    self._ccbOwner.btn_logout:setVisible(visible)
  end
end

function QUIPageLogin:setInfo(tbl)
  if tbl.serverName then
    self._ccbOwner.label_areaname:setString(tbl.serverName)
  end
end

function QUIPageLogin:showControls(flag)
  self._ccbOwner.node_panel:setVisible(flag)
end

function QUIPageLogin:setServer(v)
  self._server = v
end


function QUIPageLogin:viewDidAppear()
-- audio.playBackgroundMusic("audio/bgm/bgm_login.mp3")
    QUIPageLogin.super.viewDidAppear(self)   
    scheduler.performWithDelayGlobal(function()
        if QStaticDatabase:sharedDatabase():getAnnouncement() ~= nil then
            app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAnnouncement"})
        else
            print("No announcement table is found")
        end end, 0)
end

function QUIPageLogin:viewWillDisappear()
end

function QUIPageLogin:_onLogout()
  return app:alert({content = "是否确定注销", title = "系统提示", comfirmBack = handler(self, self.logout), callBack = function ()
      end})
end


function QUIPageLogin:logout()
  app:getUserData():setValueForKey(QUserData.AUTO_LOGIN, QUserData.STRING_FALSE)
  --关闭服务器连接
  app:getClient():close()

  local serverLocation = string.split(SERVER_URL, ":")
  app:getClient():reopen(serverLocation[1], serverLocation[2], function()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    return app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG,
      uiClass = "QUIDialogGameLogin" })
    end)
end

function QUIPageLogin:_onLogin()
  if self._isWaiting == true then return end
  if self._server.serverId then
    local serverInfo = nil
    for _,value in pairs(remote.serverInfos) do
        if value.serverId == self._server.serverId then
            serverInfo = value
        end
    end
    --关闭中心服务器链接
    app:getClient():close()
    -- reconnect game server
    app:getClient():reopen(serverInfo.address.ipAddress, serverInfo.address.port, handler(self, self.connected))
    audio.stopBackgroundMusic()
    self._isWaiting = true
  else
    app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG,
      uiClass = "QUIDialogSystemPrompt", options = {string = "选择服务器失败"} })
  end

end

return QUIPageLogin



