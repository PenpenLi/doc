--
-- Author: wkwang
-- Date: 2014-08-07 12:34:26
--
local QUIDialog = import(".QUIDialog")
local QUIDialogAchieveItem = class("QUIDialogAchieveItem", QUIDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogAchieveItem:ctor(options)
	local ccbFile = "ccb/Dialog_AchieveProp.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogAchieveItem._onTriggerConfirm)},
        {ccbCallbackName = "onTriggerAgain", callback = handler(self, QUIDialogAchieveItem._onTriggerAgain)},
        {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogAchieveItem._onTriggerClose)},
    }
    QUIDialogAchieveItem.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = false    

    self._ccbOwner.node_title_silver:setVisible(false)
    self._ccbOwner.node_title_normal:setVisible(false)
    self._ccbOwner.node_title_gold:setVisible(false)
    self._ccbOwner.node_buy:setVisible(false)
    self._ccbOwner.btn_ok:setVisible(false)
    self._ccbOwner.node_money:setVisible(false)
    self._ccbOwner.node_tokenMoney:setVisible(false)
    self._ccbOwner.node_next_tips:setVisible(false)
    self._ccbOwner.bule_light:setVisible(false)
    self._ccbOwner.orange_light:setVisible(false)
    self._ccbOwner.purple_light:setVisible(false)
    self._ccbOwner.node_buy_info:setVisible(false)
    self._ccbOwner.node_free:setVisible(false)
    self._ccbOwner.tf_name:setString("")
    app.sound:playSound("common_award")
end

function QUIDialogAchieveItem:viewDidAppear()
    QUIDialogAchieveItem.super.viewDidAppear(self)
    self.prompt = app:promptTips()
    self.prompt:addItemEventListener(self)
    self:initView()
end

function QUIDialogAchieveItem:viewWillDisappear()
  QUIDialogAchieveItem.super.viewWillDisappear(self)
  self.prompt:removeItemEventListener()
end

function QUIDialogAchieveItem:initView()
    local options = self:getOptions()
    self._callBack = options.callBack
    self._againBack = options.againBack 

    if options.freeNum ~= nil and options.freeNum > 0 then
        self._ccbOwner.node_free:setVisible(true)
    else
        self._ccbOwner.node_buy_info:setVisible(true)
    end

    if options.cost ~= nil then
        self._ccbOwner.node_buy:setVisible(true)
        self._ccbOwner.tf_money:setString(options.cost)
    else    
        self._ccbOwner.btn_ok:setVisible(true)
    end

    if options.tokenType == ITEM_TYPE.TOKEN_MONEY then
        self._ccbOwner.node_title_gold:setVisible(true)
        self._ccbOwner.node_tokenMoney:setVisible(true)
        self._ccbOwner.node_next_tips:setVisible(true)
        self._ccbOwner.tf_count:setString(10 - (remote.user.totalLuckyDrawAdvanceCount or 0)%10)
    elseif options.tokenType == ITEM_TYPE.MONEY then
        self._ccbOwner.node_title_silver:setVisible(true)
        self._ccbOwner.node_money:setVisible(true)
    else
        self._ccbOwner.node_title_normal:setVisible(true)
    end

    local itemID = options.items[1].id
    local itemType = options.items[1].type
    local itemNum = options.items[1].count
    self._item = QUIWidgetItemsBox.new()
    self._item:setPromptIsOpen(true)
    self._ccbOwner.node_item:addChild(self._item:getView())
    self._item:setGoodsInfo(itemID,itemType,itemNum)
    local config = QStaticDatabase:sharedDatabase():getItemByID(itemID)
    if config ~= nil then
        self._ccbOwner.tf_name:setString(config.name)
        self._ccbOwner.tf_name:setColor(EQUIPMENT_COLOR[config.colour])
        if config.colour == 3 then
            self._ccbOwner.bule_light:setVisible(true)
        elseif config.colour == 4 then
            self._ccbOwner.purple_light:setVisible(true)
        elseif config.colour == 5 then
            self._ccbOwner.orange_light:setVisible(true)
        end
    end
end

function QUIDialogAchieveItem:_backClickHandler()
--    self:_onTriggerConfirm()
end

function QUIDialogAchieveItem:_onTriggerConfirm()
    self:checkGuid()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    if self._callBack ~= nil then
    	self._callBack()
    end
end

function QUIDialogAchieveItem:_onTriggerAgain()
    self:_onTriggerConfirm()
    if self._againBack ~= nil then
        self._againBack()
    end
end

function QUIDialogAchieveItem:_onTriggerClose()
    self:_onTriggerConfirm()
    if self._againBack ~= nil then
        self._againBack()
    end
end

function QUIDialogAchieveItem:checkGuid()
  if app.tutorial:isTutorialFinished() == false then
    local page = app:getNavigationController():getTopPage()
    page:checkGuiad()
  end
end

return QUIDialogAchieveItem