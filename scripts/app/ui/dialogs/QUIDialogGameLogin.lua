
local QUIDialog = import(".QUIDialog")
local QUIDialogGameLogin = class("QUIDialogGameLogin", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUserData = import("...utils.QUserData")

function QUIDialogGameLogin:ctor(options)
    local ccbFile = "ccb/Dialog_GameLogin.ccbi"
    local callBacks = {
        {ccbCallbackName = "onLogin", callback = handler(self, QUIDialogGameLogin.onLogin)},
        {ccbCallbackName = "onRemember", callback = handler(self, QUIDialogGameLogin.onRemember)},
        {ccbCallbackName = "onPullDown", callback = handler(self, QUIDialogGameLogin.onPullDown)},
        {ccbCallbackName = "onRegister", callback = handler(self, QUIDialogGameLogin.onRegister)}
    }
    QUIDialogGameLogin.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = false
    self._ccbOwner.btn_logingame:setHighlighted(false)
    self._ccbOwner.btn_reg:setHighlighted(true)
    self._ud = app:getUserData()
    self._remember = false
    

    --账号框
    self._edit1 = ui.newEditBox({
        image = "ui/none.png",
        listener = QUIDialogGameLogin.onEdit,
        size = CCSize(250, 48)})
    self._edit1:setReturnType(kKeyboardReturnTypeDone)
    --密码框
    self._edit2 = ui.newEditBox({
        image = "ui/none.png",
        listener = QUIDialogGameLogin.onEdit,
        size = CCSize(250, 48)})
        self._edit2:setInputFlag(kEditBoxInputFlagPassword)
        self._edit2:setReturnType(kKeyboardReturnTypeGo)
    
    self._ccbOwner.node_account:addChild(self._edit1)
    self._ccbOwner.node_pass1:addChild(self._edit2)

    if options then
        self:setAccount(options.acc)
        self._remember = options.rem
    end

    
    local account = self._ud:getValueForKey(QUserData.USER_NAME)
    local accounts = {account}
    self._accounts = accounts
    self._edits = {}
    self.node_account = CCNode:create()
    self._ccbOwner.node_account:addChild(self.node_account)
    local starty = self._ccbOwner.node_account:getPositionY() + 152
    --设置下拉框记录的帐号
    for i = 1, #accounts
    do
        str = accounts[i]
        self._edits[i] = CCLayerColor:create(ccc4(50, 0, 0, 128 + i *10), 320, 48)
        self._edits[i]:setAnchorPoint(ccp(.5,.5))
        self._edits[i]:setPositionX(- 140)
        self._edits[i]:setPositionY(466 - 48 * (i-1))
       
        self._edits[i]:setTouchEnabled(true)
        self._edits[i]:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
        self._edits[i]:setTouchSwallowEnabled(true)
        self._edits[i]:addNodeEventListener(cc.NODE_TOUCH_EVENT, function()
                self._edit1:setText(self._accounts[i])
                self.node_account:setVisible(false)
            end)

        self._edits[i].label = CCLabelTTF:create()
        self._edits[i].label:setString(str)
        self._edits[i].label:setFontSize(30)
        self._edits[i].label:setPositionX(140)
        self._edits[i].label:setPositionY(24)

        self.node_account:addChild(self._edits[i])
        self._edits[i]:addChild(self._edits[i].label)

        self._edits[i]:setPositionY(starty - (i)*48 - 26)
        self._edits[i]:setZOrder(10)
    end
    self.node_account:setVisible(false)

    -- self._ccbOwner.node_root:setTouchEnabled(true)
    -- self._ccbOwner.node_root:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    -- self._ccbOwner.node_root:setTouchSwallowEnabled(true)
    -- self._ccbOwner.node_root:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIDialogGameLogin.onTouchRoot))

    self._ccbOwner.node_rem:setTouchEnabled(true)
    self._ccbOwner.node_rem:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._ccbOwner.node_rem:setTouchSwallowEnabled(true)
    self._ccbOwner.node_rem:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIDialogGameLogin.onTouchRem))
    if self._remember == true then
        self._ccbOwner.btn_rem:setHighlighted(true)
    else
        self._ccbOwner.btn_rem:setHighlighted(false)
    end

end

function QUIDialogGameLogin:onTouchRem(event)
    if event.name == "began" then
        self._remember = not self._remember
        if self._remember == true then
            self._ccbOwner.btn_rem:setHighlighted(true)
        else
            self._ccbOwner.btn_rem:setHighlighted(false)
        end
        return true
    end
end

function QUIDialogGameLogin:onTouchRoot(event)
    if event.name == "began" then
    
        return true
    end
end

function QUIDialogGameLogin:setAccount(str)
    self._edit1:setText(str)
end

function QUIDialogGameLogin:onEdit(editbox)
    --self._edit1:setText(editbox:getText())
    --self.node_account:setVisible(false)
    --printInfo("%s", editbox:getText())
end

function QUIDialogGameLogin:viewDidAppear()
    QUIDialogGameLogin.super.viewDidAppear(self)
    self._remoteProxy = cc.EventProxy.new(remote)
end

function QUIDialogGameLogin:viewWillDisappear()
    QUIDialogGameLogin.super.viewWillDisappear(self)
    self._remoteProxy:removeAllEventListeners()
    -- self._ccbOwner.node_rem:removeAllEventListeners()
    -- for _,value in pairs(self._edits) do
    --     value:removeAllEventListeners()
    -- end
end

function QUIDialogGameLogin:onEvent(event)
    if event == nil or event.name == nil then
        return
    end
end

function QUIDialogGameLogin:onRegister()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    return app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogRegister"})
   
end

function QUIDialogGameLogin:onRemember()
    self._remember = not self._remember
    if self._remember == true then
        self._ccbOwner.btn_rem:setHighlighted(true)
    else
        self._ccbOwner.btn_rem:setHighlighted(false)
    end
end

function QUIDialogGameLogin:onPullDown()
    self.node_account:setVisible(true)
end

function QUIDialogGameLogin:onLogin()
    local acc = self._edit1:getText()
    local pass = self._edit2:getText()
    if #acc == 0 then
        app:alert({content="账号不能为空!"}, false)
        return 
    end
    if #pass == 0 then
        app:alert({content="密码不能为空!"}, false)
        return 
    end
    pass = crypto.md5(pass)

    if self._remember == true then
        self._ud:setValueForKey(QUserData.USER_NAME, acc)
        self._ud:setValueForKey(QUserData.PASSWORD, pass)
        self._ud:setValueForKey(QUserData.AUTO_LOGIN, QUserData.STRING_TRUE)
    else
        self._ud:setValueForKey(QUserData.AUTO_LOGIN, QUserData.STRING_FALSE)
    end
    app:_login(acc, pass)
    app:getNavigationController():setDialogOptions({acc = acc})

end

return QUIDialogGameLogin