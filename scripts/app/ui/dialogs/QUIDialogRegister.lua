
local QUIDialog = import(".QUIDialog")
local QUIDialogRegister = class("QUIDialogRegister", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUserData = import("...utils.QUserData")

--帐号密码的字符串判断 只能是数字英文和下划线
local isStrValid = function(str)
    --把所有下划线替换成数字
    local s = string.gsub(str, "_", "0")
    --匹配非数字英文的字符位置
    local r = string.find(s, "%W")
    if r == nil then 
        --没有找到其他非英文数字返回true
        return true
    else
        return false
    end
end

function QUIDialogRegister:ctor(options)
    local ccbFile = "ccb/Dialog_Login.ccbi"
    local callBacks = {
        {ccbCallbackName = "onGameLogin", callback = handler(self, QUIDialogRegister.onGameLogin)},
        {ccbCallbackName = "onRegister", callback = handler(self, QUIDialogRegister.onRegister)},
        {ccbCallbackName = "onActive", callback = handler(self, QUIDialogRegister.onActive)},
        {ccbCallbackName = "onPullDown", callback = handler(self, QUIDialogRegister.onPullDown)}
    }
    QUIDialogRegister.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = false
    self._ccbOwner.btn_gamelogin:setHighlighted(true)
    self._ccbOwner.btn_reg:setHighlighted(false)
    --帐号edit
    self._edit1 = ui.newEditBox({
        image = "ui/none.png",
        listener = QUIDialogRegister.onEdit,
        size = CCSize(250, 48)})
    --密码edit
    self._edit2 = ui.newEditBox({
        image = "ui/none.png",
        listener = QUIDialogRegister.onEdit,
        size = CCSize(250, 48)})
        self._edit2:setInputFlag(kEditBoxInputFlagPassword)
    ----确认密码edit
    self._edit3 = ui.newEditBox({
        image = "ui/none.png",
        listener = QUIDialogRegister.onEdit,
        size = CCSize(250, 48)})
        self._edit3:setInputFlag(kEditBoxInputFlagPassword)

    --激活码edit
    self._code = ui.newEditBox({
        image = "ui/none.png",
        listener = QUIDialogRegister.onEdit,
        size = CCSize(250, 48)})

    self._ccbOwner.node_account:addChild(self._edit1)
    self._ccbOwner.node_pass1:addChild(self._edit2)
    self._ccbOwner.node_pass2:addChild(self._edit3)
    self._ccbOwner.node_acode:addChild(self._code)

    --默认不显示激活码
    self._ccbOwner.node_act:setVisible(false)
    self._ccbOwner.node_reg:setVisible(true)
    self._code:setEnabled(false)
    self._code:setVisible(false)
    self._activecode = "[]{}#"
end

function QUIDialogRegister:onEdit(editbox)
    --self._edit1:setText(editbox:getText())
    --self.node_account:setVisible(false)
    --printInfo("%s", editbox.getText())
    
end

function QUIDialogRegister:onPullDown()
    
end

function QUIDialogRegister:onActive()
    self._activecode = self._code:getText()
    if self._activecode and #self._activecode ~= 0 then
        self._ccbOwner.node_act:setVisible(false)
        self._ccbOwner.node_reg:setVisible(true)
    else
        app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
                    uiClass = "QUIDialogSystemPrompt", options = {string = "激活码为空"} })
    end
end

function QUIDialogRegister:viewDidAppear()
    QUIDialogRegister.super.viewDidAppear(self)
    self._remoteProxy = cc.EventProxy.new(remote)
    --self._remoteProxy:addEventListener(QRemote.HERO_UPDATE_EVENT, handler(self, self.onEvent))
end

function QUIDialogRegister:viewWillDisappear()
    QUIDialogRegister.super.viewWillDisappear(self)
    self._remoteProxy:removeAllEventListeners()
end


function QUIDialogRegister:onEvent(event)
    if event == nil or event.name == nil then
        return
    end
    -- if event.name == QUIGestureRecognizer.EVENT_SWIPE_GESTURE then
    -- end
end

function QUIDialogRegister:onGameLogin(tag, menuItem)
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    return app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogGameLogin"})
end

function QUIDialogRegister:onRegister(tag, menuItem)
    local acc = self._edit1:getText()
    local pass1 = self._edit2:getText()
    local pass2 = self._edit3:getText()

    if pass1 ~= pass2 then
        app:alert({content = "两次密码输入不一样", title = "系统提示", callBack = nil , comfirmBack = nil})
        return 
    end
    if isStrValid(acc) == false then
        app:alert({content = "用户名含有非法字符，用户名仅支持英文，数字和“_”", title = "系统提示", callBack = nil , comfirmBack = nil})
        return 
    end

    if isStrValid(pass1) == false then
        app:alert({content = "密码含有非法字符，密码仅支持英文，数字和“_”", title = "系统提示", callBack = nil , comfirmBack = nil})
        return 
    end

    app:getClient():ctUserCreateWithActivationCode(acc, pass1, self._activecode,
        function(data) 
            app:getUserData():setValueForKey(QUserData.USER_NAME, acc)
            app:getUserData():setValueForKey(QUserData.PASSWORD, crypto.md5(pass1))
            app:getUserData():setValueForKey(QUserData.AUTO_LOGIN, QUserData.STRING_TRUE)
            app:_loginSucc(acc)
        end)
end

return QUIDialogRegister