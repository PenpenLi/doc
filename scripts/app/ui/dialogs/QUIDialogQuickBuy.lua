
local QUIDialog = import(".QUIDialog")
local QUIDialogQuickBuy = class("QUIDialogQuickBuy", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
--local QUIDialogSystemPrompt = import("..dialogs.QUIDialogSystemPrompt")
--local QUIDialogQuickBuy = import("..dialogs.QUIDialogQuickBuy")

function QUIDialogQuickBuy:ctor(options)
    local ccbFile = "ccb/Dialog_QuickBuy.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerCancel", callback = handler(self, QUIDialogQuickBuy._onTriggerCancel)},
        {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogQuickBuy._onTriggerConfirm)},
        {ccbCallbackName = "onMinus", callback = handler(self, QUIDialogQuickBuy._onMinus)},
        {ccbCallbackName = "onPlus", callback = handler(self, QUIDialogQuickBuy._onPlus)}
    }
    QUIDialogQuickBuy.super.ctor(self, ccbFile, callBacks, options)

    self._cost = 0
    self._ccbOwner.label_flaginfo:setString("")
    if options then
        self._id = options.id
        self._icon = options.icon
        self._cost = options.cost
        self._itemname = options.itemname
        self._quickBattle = options.quickBattle
        self._flag = options.flag
        self._data = options.battledata
    end
    if self._quickBattle == nil or self._quickBattle == false then
        self._ccbOwner.label_btntext:setString("购买")
        
        self:setInfo("")
        --self._ccbOwner.label_buyinfo:setVisible(false)
    end
    self._number = 1
    self._ccbOwner.label_num:setString(tostring(self._number))

    if self._icon then
        local texture =CCTextureCache:sharedTextureCache():addImage(self._icon)
        local sprite = CCSprite:createWithTexture(texture)
        self._ccbOwner.node_icon:removeAllChildren()
        self._ccbOwner.node_icon:addChild(sprite)
    end

    self._ccbOwner.label_cost:setString(tostring(self._number * self._cost))

    if self._flag then
        local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("icon_fushi.png")
        if spriteFrame ~= nil then
           self._ccbOwner["sprite_icon"]:setDisplayFrame(spriteFrame)
        end
        local str = string.format("今日可购买次数 %d/999", 999 - remote.user.buyFlagCount)
        self._ccbOwner.label_flaginfo:setString(str)
        
        
        self._ccbOwner.node_minus:setVisible(true)
        self._ccbOwner.node_plus:setVisible(true)
    else
        self._ccbOwner.node_minus:setVisible(true)
        self._ccbOwner.node_plus:setVisible(true)
    end
end

function QUIDialogQuickBuy:setNumber(num)
    self._number = num
    self._ccbOwner.label_num:setString(tostring(self._number))
end

function QUIDialogQuickBuy:setInfo(info)
    self._ccbOwner.label_buyinfo:setString(info)
end

function QUIDialogQuickBuy:_onMinus()
    self._number = self._number - 1
    if self._number < 1 then
        self._number = 1
    end
    self._ccbOwner.label_num:setString(tostring(self._number))
    self._ccbOwner.label_cost:setString(tostring(self._number * self._cost))
end

function QUIDialogQuickBuy:_onPlus()
    self._number = self._number + 1
    self._ccbOwner.label_num:setString(tostring(self._number))
    self._ccbOwner.label_cost:setString(tostring(self._number * self._cost))
end

function QUIDialogQuickBuy:_onTriggerCancel()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogQuickBuy:_onTriggerConfirm()

    if self._flag then
        app:getClient():buyFlag(self._number, function() 
                if self._quickBattle then
                    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
                    app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAdjust",
                        options = self._data})
                else
                    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
                end
            end
            ,
            function(data)
            app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
            local str = "购买失败"
            if data.code == "TOKEN_MONEY_NOT_ENOUGH" then
                str = string.format("拥有 %s 不足以购买", self._itemname)
            end
            app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
                    uiClass = "QUIDialogSystemPrompt", options = {string = str} })
            end)
    else
        app:getClient():buyFlag(self._number, function() 
            if self._quickBattle then
                app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
                app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAdjust",
                    options = self._data})
            else
                app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
            end
        end, function(data)
            app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
            local str = "购买失败"
            if data.code == "TOKEN_MONEY_NOT_ENOUGH" then
                str = string.format("拥有 %s 不足以购买", self._itemname)
            end
            app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
                    uiClass = "QUIDialogSystemPrompt", options = {string = str} })
            end)

        
    end
    return "QUIDialogAdjust"

end

return QUIDialogQuickBuy