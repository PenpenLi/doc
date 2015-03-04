
local QUIDialog = import(".QUIDialog")
local QUIDialogChooseServer = class("QUIDialogChooseServer", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetChooseServer = import("..widgets.QUIWidgetChooseServer")

local serverSort = function(x, y)
    return x.startTime > y.startTime
end

function QUIDialogChooseServer:ctor(options)
    local ccbFile = "ccb/Dialog_ChooseServer.ccbi"
    local callBacks = {
        {ccbCallbackName = "onGameLogin", callback = handler(self, QUIDialogChooseServer.onGameLogin)},
        {ccbCallbackName = "onRegister", callback = handler(self, QUIDialogChooseServer.onRegister)},
        {ccbCallbackName = "onPullDown", callback = handler(self, QUIDialogChooseServer.onPullDown)}
    }
    QUIDialogChooseServer.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = true

    self._servers = options
    self._boards = {}
    if self._servers then
        --根据所有区的开服时间排序,新区在前面
        table.sort(self._servers, serverSort)
        for i, v in pairs(self._servers) do
            --设置每个区的服务器信息
            local point = self._ccbOwner["node_down"]:convertToWorldSpace(self._ccbOwner["node_board"..i]:getPositionInCCPoint())
            self._boards[i] = QUIWidgetChooseServer.new({point = point, server = v, number = v.serverNumber})
            self._boards[i]:addEventListener(QUIWidgetChooseServer.EVENT_SELECT, handler(self, self.closeHandler))
            self._boards[i]:setInfo(v)
            self._ccbOwner["node_board"..i]:addChild(self._boards[i]:getView())
        end
    end

    self._ccbOwner.node_up:setTouchEnabled(true)
    self._ccbOwner.node_up:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._ccbOwner.node_up:setTouchSwallowEnabled(true)
    self._ccbOwner.node_up:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIDialogChooseServer.onTouch))

    if remote.user.latestServerSid ~= nil then
        for _,serverInfo in pairs(remote.serverInfos) do
            if serverInfo.serverId == remote.user.latestServerSid then
                self._serverId = serverInfo.serverId
                self._serverName = serverInfo.name
                self._serverUrl = serverInfo.url
                self._serverSid = serverInfo.sid
                break
            end
        end
    end
    
    if self._serverUrl == nil then
        self._serverId = remote.serverInfos[1].serverId
        self._serverName = remote.serverInfos[1].name
        self._serverUrl = remote.serverInfos[1].url
        self._serverSid = remote.serverInfos[1].sid
    end

    --设置默认服务器信息
    self._ccbOwner.label_name:setString(self._serverName)
    --需要根据人数判断 现在默认显示流畅
    self._ccbOwner.label_status:setString("流畅")
    self._ccbOwner.label_status:setColor(ccc3(0, 255, 0))
end

function QUIDialogChooseServer:onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "moved" then
        
    elseif event.name == "ended" or event.name == "cancelled" then
        self:closeHandler()
        -- app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
        --把所选区信息设置到pageLogin界面上
        app:getNavigationController():getTopPage():showControls(true)
        app:getNavigationController():getTopPage():setInfo({areaname = remote.serverName, area = ""})
        app:getNavigationController():getTopPage():setServer({url = self._serverUrl, sid = self._serverSid })
    end
end

function QUIDialogChooseServer:scrollViewDidScroll(editbox)
    printInfo("scroll")
    
end

function QUIDialogChooseServer:onEdit(editbox)
    --self._edit1:setText(editbox:getText())
    --self.node_account:setVisible(false)
    --printInfo("%s", editbox.getText())
    
end

function QUIDialogChooseServer:viewDidAppear()
    QUIDialogChooseServer.super.viewDidAppear(self)
    self._remoteProxy = cc.EventProxy.new(remote)
end

function QUIDialogChooseServer:viewWillDisappear()
    QUIDialogChooseServer.super.viewWillDisappear(self)
    self._remoteProxy:removeAllEventListeners()
end


function QUIDialogChooseServer:onEvent(event)
    if event == nil or event.name == nil then
        return
    end
end

function QUIDialogChooseServer:onGameLogin(tag, menuItem)
    self:closeHandler()
    app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogGameLogin"})
end

function QUIDialogChooseServer:onRegister(tag, menuItem)
    local acc = self._edit1:getText()
    local pass1 = self._edit2:getText()
    local pass2 = self._edit3:getText()

    if pass1 ~= pass2 then
        app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
                    uiClass = "QUIDialogSystemPrompt", options = {string = "两次密码输入不一样"} })
        return 
    end

    app:_createUser(acc, pass1)
end

function QUIDialogChooseServer:closeHandler()
    self:playEffectOut()
end

function QUIDialogChooseServer:viewAnimationOutHandler()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogChooseServer