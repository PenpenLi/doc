
q = q or {}

-- cocos2d-x
require("config")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")

-- extentions
require("CCBReaderLoad")
require("frameworkExtend")
require("lib.UUID")

-- game
require("app.utils.QFunctions")
require("app.utils.QCCUtils")

CCTexture2D:PVRImagesHavePremultipliedAlpha(true)

QUtility:setScriptCodeVersion(GAME_VERSION)

local sharedFileUtils = CCFileUtils:sharedFileUtils()

local LOCAL_VERSION_FILE = sharedFileUtils:getWritablePath() .. "version"
local VERSION_FILE = LOCAL_VERSION_FILE
if device.platform == "ios" then
    VERSION_FILE = sharedFileUtils:getWritablePath() .. "version_ios"
elseif device.platform == "android" then
    VERSION_FILE = sharedFileUtils:getWritablePath() .. "version_android"
end

if sharedFileUtils:isFileExist(LOCAL_VERSION_FILE) == false and sharedFileUtils:isFileExist(VERSION_FILE) == true then
    local content = sharedFileUtils:getFileData(VERSION_FILE)
    local wfile = io.open(LOCAL_VERSION_FILE, "w")
    wfile:write(content) 
    wfile:close()
end

sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/")
sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/pb/")
sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/ccb/")
sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/actor/")
sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/effect/")
sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/audio/bgm/")
sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/audio/sound/")
sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/audio/sound/ui/")
sharedFileUtils:addSearchPath(sharedFileUtils:getWritablePath() .. "res/audio/sound/skill/")

sharedFileUtils:addSearchPath("res/")
sharedFileUtils:addSearchPath("res/pb/")
sharedFileUtils:addSearchPath("res/ccb/")
sharedFileUtils:addSearchPath("res/actor/")
sharedFileUtils:addSearchPath("res/effect/")
sharedFileUtils:addSearchPath("res/audio/bgm/")
sharedFileUtils:addSearchPath("res/audio/sound/")
sharedFileUtils:addSearchPath("res/audio/sound/ui/")
sharedFileUtils:addSearchPath("res/audio/sound/skill/")

loadAllCustomShaders()

local MyApp = class("MyApp", cc.mvc.AppBase)

-- editor
local QEditorController = import(".editor.QEditorController")

local QNavigationController = import(".controllers.QNavigationController")
local QStaticDatabase = import(".controllers.QStaticDatabase")

local QHeroModel = import(".models.QHeroModel")
local QNpcModel = import(".models.QNpcModel")
local QUserData = import(".utils.QUserData")
local QWidgetCacheUtils = import(".utils.QWidgetCacheUtils")
local QCCBNodeCache = import(".utils.QCCBNodeCache")
local QClient = import(".network.QClient")
local QRemote = import(".models.QRemote")
local QUpdateStaticDatabase = import(".network.QUpdateStaticDatabase")
local QPromptTips = import(".utils.QPromptTips")
local QTips = import(".utils.QTips")
local QSound = import(".utils.QSound")
local QSystemSetting = import(".controllers.QSystemSetting")
local QProtocol = import(".network.QProtocol")

-- 远程数据挂载点
remote = QRemote.new()

local QUIScene = import(".ui.QUIScene")
local QUIViewController = import(".ui.QUIViewController")
local QUIPageEmpty = import(".ui.pages.QUIPageEmpty")
local QUIWidgetLoading = import(".ui.widgets.QUIWidgetLoading")
local QUIDialogRegister = import(".ui.dialogs.QUIDialogRegister")
local QUIDialogGameLogin = import(".ui.dialogs.QUIDialogGameLogin")
local QUIPageLogin = import(".ui.pages.QUIPageLogin")

-- tutorial
local QTutorialDirector = import(".tutorial.QTutorialDirector")

-- MyApp.BACKGROUND_TIME_BEFORE_RELAUNCH_WITHOUTDOWNLOAD = 30 * 60 -- 进入后台多久后(单位:秒)下次进入前台时relaunch game without download
MyApp.BACKGROUND_TIME_BEFORE_RELAUNCH = 60 * 60 -- 进入后台多久后(单位:秒)下次进入前台时relaunch game
-- assert(MyApp.BACKGROUND_TIME_BEFORE_RELAUNCH_WITHOUTDOWNLOAD < MyApp.BACKGROUND_TIME_BEFORE_RELAUNCH, "")

function MyApp:ctor()
    MyApp.super.ctor(self)
    self._objects = {}
    self._userData = QUserData.new()
    self._systemSetting = QSystemSetting.new()
    self.tutorial = QTutorialDirector.new()
    self.widgetCache = QWidgetCacheUtils.new()
    self.ccbNodeCache = QCCBNodeCache.new()
    self.tip = QTips.new()
    self._updater = nil
    self.sound = QSound.new()

    self._userData:setValueForKey("SERVER_URL", SERVER_URL)
    self._userData:setValueForKey("STATIC_URL", STATIC_URL)

    self._lastTimeEnterBackground = nil
    self._isClearSkeletonData = true
end

function MyApp:start()
    if NATIVE_CODE_VERSION ~= QUtility:getNativeCodeVersion() then
        return self:_exitForUpdate()
    end

    math.randomseed(os.time())
    local staticDatabase = QStaticDatabase.sharedDatabase()
    staticDatabase:reloadStaticDatabase()

    if DEBUG > 0 and CHECK_SKELETON_FILE == true then
        self:_checkResources()
    end
    
    if CURRENT_MODE == EDITOR_MODE then
        self:_startEditor()
    elseif CURRENT_MODE == GAME_MODE then
        QDeliveryWrapper:login(function ()
            self:_startGame()
        end)    
        
    end
end

function MyApp:_checkResources()
    -- effect
    for _, effectId in ipairs(staticDatabase:getEffectIds()) do
        local frontFile, backFile = staticDatabase:getEffectFileByID(effectId)
        if frontFile ~= nil then
            printInfo("chack effect resource: " .. frontFile)
            local skeletonFile = frontFile .. ".json"
            local atlasFile = frontFile .. ".atlas"
            QSkeletonDataCache:sharedSkeletonDataCache():cacheSkeletonData(skeletonFile, atlasFile)
        end
        if backFile ~= nil then
            printInfo("chack effect resource: " .. backFile)
            local skeletonFile = backFile .. ".json"
            local atlasFile = backFile .. ".atlas"
            QSkeletonDataCache:sharedSkeletonDataCache():cacheSkeletonData(skeletonFile, atlasFile)
        end
    end
    -- actor
    for _, characterDisplayId in ipairs(staticDatabase:getCharacterDisplayIds()) do
        local display = staticDatabase:getCharacterDisplayByID(characterDisplayId)
        assert(display.actor_file ~= nil, "actor_file in character_display id: " .. display.id .. " is not exist")
        printInfo("chack character display resource: " .. display.actor_file)
        local skeletonFile = display.actor_file .. ".json"
        local atlasFile = display.actor_file .. ".atlas"
        QSkeletonDataCache:sharedSkeletonDataCache():cacheSkeletonData(skeletonFile, atlasFile)
    end
end

function MyApp:_exitForUpdate()
    self._uiScene = display.newScene("UIScene")
    display.replaceScene(self._uiScene)

    local pageEmpty = QUIPageEmpty.new()
    self._uiScene:addChild(pageEmpty:getView())
    self._navigationController = QNavigationController.new(pageEmpty, "UI Main Navigation")

     pageEmpty = QUIPageEmpty.new()
    self._uiScene:addChild(pageEmpty:getView())
    self._navigationMidLayerController = QNavigationController.new(pageEmpty, "Top Layer Navigation")
    
    local newPageEmpty = QUIPageEmpty.new()
    self._uiScene:addChild(newPageEmpty:getView())
    self._navigationThirdLayerController = QNavigationController.new(newPageEmpty, "Third Layer Navigation")

    self._topLayerPage = pageEmpty
    self._thirdLayerPage = newPageEmpty

    self:alert({content="您的版本太低，请下载安装新版本",title="系统提示",callBack=nil,comfirmBack=nil})
end

function MyApp:_startEditor()
    self.editor = QEditorController.new()
    self.editor:start()
end

function MyApp:_startGame()
    print ("function MyApp:_startGame()")
    self:enableTextureCacheScheduler()
    self:setMusicSound()

    self._remoteEventProxy = cc.EventProxy.new(remote)
    self._remoteEventProxy:addEventListener(QRemote.USER_UPDATE_EVENT, handler(self, self._onUserDataUpdate))

    self._uiScene = QUIScene.new()
    display.replaceScene(self._uiScene)

    local logo = CCSprite:create("ui/logo.png")
    -- local logo = CCNode:create()
    self._uiScene:addChild(logo)
    logo:setPosition(display.cx, display.cy)
    logo:setVisible(true)
    local actions = CCArray:create()
    actions:addObject(CCDelayTime:create(0.2))
    actions:addObject(CCShow:create())
    actions:addObject(CCDelayTime:create(0.6))
    actions:addObject(CCEaseIn:create(CCFadeOut:create(0.4), 3))
    actions:addObject(CCDelayTime:create(0.1))
    actions:addObject(CCCallFunc:create(function()

        local pageEmpty = QUIPageEmpty.new()
        self._uiScene:addChild(pageEmpty:getView())
        self._navigationController = QNavigationController.new(pageEmpty, "UI Main Navigation")

        pageEmpty = QUIPageEmpty.new()
        self._uiScene:addChild(pageEmpty:getView())
        self._navigationMidLayerController = QNavigationController.new(pageEmpty, "Mid Layer Navigation")
        
        self.tutorialNode = CCNode:create()
        self._uiScene:addChild(self.tutorialNode)
        
        local newPageEmpty = QUIPageEmpty.new()
        self._uiScene:addChild(newPageEmpty:getView())
        self._navigationThirdLayerController = QNavigationController.new(newPageEmpty, "Third Layer Navigation")
        
        self._uiScene:addChild(QUIWidgetLoading.sharedLoading():getView())
        self._topLayerPage = pageEmpty
        self._thirdLayerPage = newPageEmpty -- 保存起来，在切换场景到战斗场景的时候使用

        self._autoLogin = false


        self._updater = QUpdateStaticDatabase.new()
        local updater = self._updater
        local updateProxy = cc.EventProxy.new(updater)
        updateProxy:addEventListener(QUpdateStaticDatabase.STATUS_COMPLETED, function(event)
            updateProxy:removeAllEventListeners()
            QUIWidgetLoading.sharedLoading():hide()
            QUIWidgetLoading.sharedLoading()._ccbOwner.node_text:setOpacity(255)

            -- 有新下载完成则重新启动
            if event.count > 0 then
                -- 所有下载已经完成，回收QDownload的资源
                updater:purge()
                app:relaunchGame(true)
                return
            else
                -- 所有下载已经完成，回收QDownload的资源
                updater:purge()
            end

            local appProxy = cc.EventProxy.new(self)
            appProxy:addEventListener(self.APP_ENTER_BACKGROUND_EVENT, handler(self, self._onEnterBackground))
            appProxy:addEventListener(self.APP_ENTER_FOREGROUND_EVENT, handler(self, self._onEnterForeground))

            self.sound:playMusic("main_interface")

            self._protocol = QProtocol.new()
            local serverLocation = string.split(SERVER_URL, ":")
            self._client = QClient.new(serverLocation[1], serverLocation[2])
            self._client:open(function()
                printInfo("connect success")
                QUIWidgetLoading.sharedLoading():setCustomString("加载中", false)
                local autoLogin = self._userData:getValueForKey(QUserData.AUTO_LOGIN)
                local my_acc = self:getUserId()
                local my_pass = self:getPassword()

                -- If there is any delivery integrated, do not show the login dialog of our own
                if self:isDeliveryIntegrated() then 
                    self:_login(my_acc, my_pass)
                else
                    if my_acc ~= nil and my_pass ~= nil and autoLogin and autoLogin == QUserData.STRING_TRUE then 
                        -- 自动登入
                        self:_login(my_acc, my_pass)
                        self._autoLogin = true
                    else
                        --todo
                        self._navigationController:pushViewController({uiType = QUIViewController.TYPE_PAGE, uiClass = "QUIPageEmpty"})
                        self._navigationController:pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogGameLogin"})
                    end
                end
            end, 

            function()

            end)
            
        end)
        
        updateProxy:addEventListener(QUpdateStaticDatabase.STATUS_FAILED, function()
            QUIWidgetLoading.sharedLoading():hide()
            self:alert({title = "网络错误", content = "无法下载最新的配置，请稍后重试", callBack = function()
                updater:update(false)
            end})
        end)
        updater:update(false)

    end))
    actions:addObject(CCRemoveSelf:create(true))
    
    logo:runAction(CCSequence:create(actions))    
end


-- Each delivery has its own name except for "Default"
function MyApp:isDeliveryIntegrated()
    local deliveryName = QDeliveryWrapper:deliveryName();

    return deliveryName ~= "Default" and deliveryName ~= "";
end

function MyApp:getUserId()
    if self:isDeliveryIntegrated() then
        return QDeliveryWrapper:getUserId()
    else
        return self._userData:getValueForKey(QUserData.USER_NAME)
    end
end

function MyApp:getPassword()
    if self:isDeliveryIntegrated() then
        return QDeliveryWrapper:getSessionId()
    else
        return self._userData:getValueForKey(QUserData.PASSWORD)
    end 
end

function MyApp:getNickName()
    if self:isDeliveryIntegrated() then
        return QDeliveryWrapper:getNickName()
    else
        return self._userData:getValueForKey(QUserData.USER_NAME)
    end 
end

-- state: 0 - depends on settings
--        1 - all on
--        2 - all off
function MyApp:setMusicSound(state)
    if state == 1 then
        audio.setMusicVolume(1)
        audio.setSoundsVolume(1)
    elseif state == 2 then
        audio.setMusicVolume(0)
        audio.setSoundsVolume(0)
    else
        audio.setMusicVolume(self._systemSetting:getMusicState() == "on" and 1 or 0)
        audio.setSoundsVolume(self._systemSetting:getSoundState() == "on" and 1 or 0)
    end
end

-- For Tongbutui, account is userId, pass is sessionId
function MyApp:_login(account, pass)
    printInfo("login account:" .. account .. " password:" .. pass)
    local uname = account
    local password = pass
    self._client:ctUserLogin(uname, password, QDeliveryWrapper:deliveryName(), function(result)
        remote.user:update({name = uname})
        self:_loginSucc(uname)

    end, function(err)

        if self._autoLogin and self._autoLogin == true then
             self._navigationController:pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogGameLogin",
                options = {acc = account, rem = true}})
        end
        
        -- if err.error == "USER_NAME_PASSWORD_NOT_MATCH" then
        --     self._navigationController:pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
        --             uiClass = "QUIDialogSystemPrompt", options = {string = "密码输入不正确"} })
        -- elseif err.error == "USER_NOT_EXISTS" then
        --     self._navigationController:pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
        --             uiClass = "QUIDialogSystemPrompt", options = {string = "帐号不存在"} })
        -- elseif err.error == "DATA_FORMAT_WRONG" then
        --     self._navigationController:pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
        --             uiClass = "QUIDialogSystemPrompt", options = {string = "数据格式化错误"} })
        -- else
        --     self._navigationController:pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
        --             uiClass = "QUIDialogSystemPrompt", options = {string = "未知错误"} })
        -- end
        
        --dump(err)
    end)
end

-- 登录成功
function MyApp:_loginSucc(uname)
    self:getUserData():setValueForKey(QUserData.USER_NAME, uname) -- 更新下拉框登入的帐号

    QUIWidgetLoading.sharedLoading():getView():setVisible(false)
    self:run()

    -- 通知App native code(iOS, Java) 用户登录了
    QUtility:notifyLogin(remote.user.name, remote.user.userId , remote.user.session)
    
    remote.task:init()
    remote.achieve:init()
end

function MyApp:_createUser(uname, password)
    self._client:userCreate(uname, password, function(result)
        self:_loginSucc(uname)
    end, function(err)
        printError("user creation failed, not logged in. ")
        self._navigationController:pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
                    uiClass = "QUIDialogSystemPrompt", options = {string = "帐号创建失败"} })
        dump(err)
    end)
end

function MyApp:run()
    QStaticDatabase.sharedDatabase():reloadStaticDatabase()

    BATTLE_AREA.bottom = global.screen_margin_bottom * global.pixel_per_unit + (CONFIG_SCREEN_HEIGHT * (BATTLE_SCREEN_WIDTH / UI_DESIGN_WIDTH) - BATTLE_SCREEN_HEIGHT) * 0.5
    BATTLE_AREA.top = BATTLE_AREA.bottom + BATTLE_AREA.height

    --self._navigationController:pushViewController({uiType=QUIViewController.TYPE_PAGE, uiClass="QUIPageMainMenu"})
    self._navigationController:pushViewController({uiType=QUIViewController.TYPE_PAGE, uiClass="QUIPageLogin", options={userName=self:getNickName()}})
    --    app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogLogin"})
end

function MyApp:_onUserDataUpdate(event)
    
end

function MyApp:readyLogin(event)
    remote.herosUtil:initHero()
    remote.activityInstance:init()
    remote.instance:updateInstanceInfo()
    remote.sunWell:init()
end

function MyApp:loginEnd(event)
    remote.teams:init()
    remote.sunWell:getNeedPass()
end

function MyApp:getNavigationController()
    return self._navigationController
end

function MyApp:getNavigationMidLayerController()
    return self._navigationMidLayerController
end

function MyApp:getNavigationThirdLayerController()
    return self._navigationThirdLayerController
end

function MyApp:resetRemote()
    remote = QRemote.new()
end

function MyApp:setObject(id, object)
    -- assert(self._objects[id] == nil, "MyApp:setObject() - id " .. id .. " already exists")
    self._objects[id] = object
end

function MyApp:getObject(id)
    assert(self._objects[id] ~= nil, "MyApp:getObject() - id " .. id .. " already exists")
    return self._objects[id]
end

function MyApp:hasObject(id)
    return self._objects[id] ~= nil
end

function MyApp:getUserData()
    return self._userData
end

function MyApp:getSystemSetting()
    return self._systemSetting
end

function MyApp:createHero(heroInfo)  
    local hero = nil

    if heroInfo ~= nil then
        if self:hasObject(heroInfo.actorId) == true then
            hero = self:getObject(heroInfo.actorId)
        else
            hero = QHeroModel.new(heroInfo)
            self:setObject(heroInfo.actorId, hero)
        end
    end
    
    return hero
end

function MyApp:removeHero(actorId)
    if actorId ~= nil then
        if self:hasObject(actorId) then
            self:setObject(actorId, nil)
        end
    end
end

function MyApp:createHeroWithoutCache(heroInfo)
    return QHeroModel.new(heroInfo)
end

function MyApp:createNpc(id, additional_skills, dead_skill)
    return QNpcModel.new(id, nil, nil, additional_skills, dead_skill)
end

function MyApp:promptTips()
  return QPromptTips.new(self._thirdLayerPage:getView())
end

--[[
    The function blew is some extension and utility function for AppBase
]]

function MyApp:createScene(sceneName, args)
    local scenePackageName = self.packageRoot .. ".scenes." .. sceneName
    local sceneClass = require(scenePackageName)
    return sceneClass.new(unpack(checktable(args)))
end

-- create controller at folder named controllers
function MyApp:createController(controllerName, args)
    local controllerPackageName = self.packageRoot .. ".controllers." .. controllerName
    local controllerClass = require(controllerPackageName)
    return controllerClass.new(unpack(checktable(args)))
end

function MyApp:setClient(client)
    self._client = client
end

-- get network client
function MyApp:getClient()
    return self._client
end

function MyApp:getProtocol()
    return self._protocol
end

-- 通用弹出框
-- options {content:"内容",title:"标题",callBack:关闭回调的响应函数,comfirmBack:确认回调按钮按下的响应函数，默认使用关闭按钮回调函数}
function MyApp:alert(options, isPopCurrentDialog, isTop)
    if isPopCurrentDialog == nil then
        isPopCurrentDialog = true
    end
    local controller = nil
    if isTop == true then
        options.canBackClick = false
        controller = self:getNavigationThirdLayerController()
    else
        options.canBackClick = true
        controller = self:getNavigationMidLayerController()
    end
    options.controller = controller
    return controller:pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAlert", options = options}, {isPopCurrentDialog = isPopCurrentDialog})
end

-- 获取该用户最大能连战的次数
function MyApp:getMaxQuickFightCount()
    return 10
end

-- 切换到战斗场景
function MyApp:enterIntoBattleScene(dungeonConfig, options)
    -- CCMessageBox("enter_before_collect " .. tostring(collectgarbage("count")*1024), "")
    collectgarbage()
    -- CCMessageBox("enter_after_collect " .. tostring(collectgarbage("count")*1024), "")
    self.ccbNodeCache:purgeCCBNodeCache()
    app:cleanTextureCache()

    self._enterBattleOptions = options
    QDeliveryWrapper:setToolBarVisible(false) -- Hide delivery tool bar in battle scene

    -- 切换到战斗场景后，整个scene会切换成战斗的scene，需要吧loading和网络出错对话框的层加到战斗场景中，否则
    -- loading会弹不出来
    QUIWidgetLoading.sharedLoading():getView():retain()
    QUIWidgetLoading.sharedLoading():getView():removeFromParent()
    
    self._thirdLayerPage:getView():retain()
    self._thirdLayerPage:getView():removeFromParent()
    app.tip:refreshTip()

    local scene = app:createScene("QBattleScene", {dungeonConfig})
    CCDirector:sharedDirector():pushScene(scene)
    
    scene:addChild(self._thirdLayerPage:getView())
    self._thirdLayerPage:getView():release()
    scene:addChild(QUIWidgetLoading.sharedLoading():getView())
    QUIWidgetLoading.sharedLoading():getView():release()
end

-- 从战斗场景中退出
function MyApp:exitFromBattleScene(isInBattle)
    QDeliveryWrapper:setToolBarVisible(true)

    QUIWidgetLoading.sharedLoading():getView():retain()
    QUIWidgetLoading.sharedLoading():getView():removeFromParent()
    
    self._thirdLayerPage:getView():retain()
    self._thirdLayerPage:getView():removeFromParent()
    app.tip:refreshTip()
    
    CCDirector:sharedDirector():popScene()

    if isInBattle then
        app:getNavigationController():popViewController(QNavigationController.POP_CURRENT_PAGE)
    end

    self._uiScene:addChild(self._thirdLayerPage:getView()) 
    self._thirdLayerPage:getView():release()
    self._uiScene:addChild(QUIWidgetLoading.sharedLoading():getView())
    QUIWidgetLoading.sharedLoading():getView():release()

    scheduler.performWithDelayGlobal(function()
        -- CCMessageBox("exit_before_collect " .. tostring(collectgarbage("count")*1024), "")
        collectgarbage()
        -- CCMessageBox("exit_after_collect " .. tostring(collectgarbage("count")*1024), "")
        app:cleanTextureCache()
        self.ccbNodeCache:cacheCCBNodeInOneFrame()
        if isInBattle then
            if self._enterBattleOptions ~= nil and self._enterBattleOptions.fromController ~= nil then
                app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
            end
        end

    end, 0)

end

-- 重启战斗场景
function MyApp:replaceBattleScene(dungeonConfig)
    QUIWidgetLoading.sharedLoading():getView():retain()
    QUIWidgetLoading.sharedLoading():getView():removeFromParent()
    
    self._thirdLayerPage:getView():retain()
    self._thirdLayerPage:getView():removeFromParent()
    app.tip:refreshTip()

    local scene = app:createScene("QBattleScene", {dungeonConfig})
    display.replaceScene(scene)

    scene:addChild(self._thirdLayerPage:getView())
    self._thirdLayerPage:getView():release()
    scene:addChild(QUIWidgetLoading.sharedLoading():getView())
    QUIWidgetLoading.sharedLoading():getView():release()
end

function MyApp:_onEnterBackground(event)
    print ("MyApp:_onEnterBackground")
    if event.name == self.APP_ENTER_BACKGROUND_EVENT then
        -- close socket 
        if self._client ~= nil then
            self._client:close()
        end

        self._lastTimeEnterBackground = q.time()
        self._systemSetting:enable()
    end
end

function MyApp:_onEnterForeground(event)
    if event.name == self.APP_ENTER_FOREGROUND_EVENT then
        
        if device.platform == "android" or device.platform == "ios" then
            print ("MyApp:_onEnterForeground")
            -- 进入background时间过长，则进入foreground的时候会去relaunch game
            if self._lastTimeEnterBackground and q.time() - self._lastTimeEnterBackground > MyApp.BACKGROUND_TIME_BEFORE_RELAUNCH then
                app:relaunchGame(true)
            -- elseif self._lastTimeEnterBackground and q.time() - self._lastTimeEnterBackground > MyApp.BACKGROUND_TIME_BEFORE_RELAUNCH_WITHOUTDOWNLOAD then
            --     app:relaunchGame(false)
            else
                self._lastTimeEnterBackground = nil

                if device.platform == "android" then
                    CCShaderCache:sharedShaderCache():reloadDefaultShaders()
                    reloadAllCustomShaders()
                end

                -- cancel all notifications when application is active @qinyuanji
                self._systemSetting:disable()

                if self._client ~= nil then
                    self._client:reopen()
                end

            end
        end

    end
end

-- show ju hua
function MyApp:showLoading()
    if QUIWidgetLoading.sharedLoading() ~= nil then
        QUIWidgetLoading.sharedLoading():Show()
    end
end

-- hide ju hua
function MyApp:hideLoading()
    if QUIWidgetLoading.sharedLoading() ~= nil then
        QUIWidgetLoading.sharedLoading():Hide()
    end
end

function MyApp:getUpdater()
    return self._updater
end

function MyApp:recordNavigationStack()
    local stackInfo = ""
    stackInfo = stackInfo .. self._navigationController:dumpControllerStack()
    stackInfo = stackInfo .. self._navigationMidLayerController:dumpControllerStack()
    stackInfo = stackInfo .. self._navigationThirdLayerController:dumpControllerStack()
    QUtility:setUIStackInfo(stackInfo)
end

function MyApp:_getBattleRandomNumber(dungeon_id, npc_index)
    if self._battleRandomNumber == nil then
        self._battleRandomNumber = {}
    end

    if self._battleRandomNumber[dungeon_id] == nil then
        self._battleRandomNumber[dungeon_id] = {}
    end

    if self._battleRandomNumber[dungeon_id][npc_index] == nil then
        -- check user data
        local rand = app:getUserData():getUserValueForKey(dungeon_id .. "-" .. tostring(npc_index))
        if rand ~= nil and rand ~= "nil" then
            rand = tonumber(rand)
        else
            rand = math.random(1, 10000)
            app:getUserData():setUserValueForKey(dungeon_id .. "-" .. tostring(npc_index), tostring(rand))
        end
        self._battleRandomNumber[dungeon_id][npc_index] = rand
        -- self._battleRandomNumber[dungeon_id][npc_index] = math.random(1, 10000)
    end

    return self._battleRandomNumber[dungeon_id][npc_index]
end

function MyApp:_getBattleProbability(dungeon_id, npc_index)
    if self._battleProbability == nil then
        self._battleProbability = {}
    end

    if self._battleProbability[dungeon_id] == nil then
        self._battleProbability[dungeon_id] = {}
    end

    if self._battleProbability[dungeon_id][npc_index] == nil then
        self._battleProbability[dungeon_id][npc_index] = math.random(1, 100)
    end

    return self._battleProbability[dungeon_id][npc_index]
end

function MyApp:resetBattleRandomNumber(dungeon_id)
    if self._battleRandomNumber == nil then
        self._battleRandomNumber = {}
    end

    if self._battleRandomNumber[dungeon_id] then
        for npc_index, rand in pairs(self._battleRandomNumber[dungeon_id]) do
            app:getUserData():setUserValueForKey(dungeon_id .. "-" .. tostring(npc_index), "nil")
        end
    end

    self._battleRandomNumber[dungeon_id] = nil
end

function MyApp:resetBattleNpcProbability(dungeon_id)
    if self._battleProbability == nil then
        self._battleProbability = {}
    end

    self._battleProbability[dungeon_id] = nil
end

function MyApp:getBattleRandomNpc(dungeon_id, npc_index, npc_id)
    local ids = string.split(npc_id, ";")
    if #ids == 1 then
        return npc_id
    else
        local rand = self:_getBattleRandomNumber(dungeon_id, npc_index)
        local index = math.fmod(rand, #ids) + 1
        local id = ids[index]
        if id == nil then
          local i = 0
        end
        return ids[index]
    end
end

function MyApp:getBattleNpcProbability(dungeon_id, npc_index)
    return self:_getBattleProbability(dungeon_id, npc_index)
end

function MyApp:cleanTextureCache(countLimit)
    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
    if self._isClearSkeletonData == true then
        QSkeletonDataCache:sharedSkeletonDataCache():removeUnusedData()
    end

    if countLimit == nil then
        countLimit = 0
    end

    if countLimit <= 0 then
        CCTextureCache:sharedTextureCache():removeUnusedTextures()
    else
        CCTextureCache:sharedTextureCache():removeUnusedTexturesWithLimit(countLimit)
    end
    -- CCTextureCache:sharedTextureCache():dumpCachedTextureInfo()
end

function MyApp:enableTextureCacheScheduler()
    if self._textureCacheScheduler ~= nil then
        return
    end

    self._textureCacheScheduler = scheduler.scheduleGlobal(handler(self, MyApp.onTextureCacheSchedule), 0.2)
end

function MyApp:disableTextureCacheScheduler()
    if self._textureCacheScheduler == nil then
        return
    end

    scheduler.unscheduleGlobal(self._textureCacheScheduler)
    self._textureCacheScheduler = nil
end

function MyApp:onTextureCacheSchedule(dt)
    self:cleanTextureCache(5)
end

function MyApp:setIsClearSkeletonData(isClear)
    if isClear == nil then
        isClear = true 
    end

    self._isClearSkeletonData = isClear
end

function MyApp:relaunchGame(isDownload)
    self:disableTextureCacheScheduler()

    if self._client ~= nil then
        self._client:close()
    end

    if isDownload == true then
        QUtility:relaunchGame()
    else
        QUtility:relaunchGameWithoutDownload()
    end
end

-- android only
function MyApp:onClickBackButton()
    printInfo("click back button on android!")
end

if device.platform == "windows" then
    require("wxdebug.main")
end

return MyApp
