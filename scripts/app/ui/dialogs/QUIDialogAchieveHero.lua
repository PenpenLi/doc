--
-- Author: wkwang
-- Date: 2014-08-07 12:34:26
--
local QUIDialog = import(".QUIDialog")
local QUIDialogAchieveHero = class("QUIDialogAchieveHero", QUIDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroInformation = import("..widgets.QUIWidgetHeroInformation")
local QUIWidgetHeroInformationStar = import("..widgets.QUIWidgetHeroInformationStar")
local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogAchieveHero:ctor(options)
	local ccbFile = "ccb/Dialog_AchieveHero.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerAgain", callback = handler(self, QUIDialogAchieveHero._onTriggerAgain)},
        {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogAchieveHero._onTriggerConfirm)},
    }
    QUIDialogAchieveHero.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = false

    self._ccbOwner.node_title_silver:setVisible(false)
    self._ccbOwner.node_title_normal:setVisible(false)
    self._ccbOwner.node_title_gold:setVisible(false)
    self._ccbOwner.node_buy:setVisible(false)
    self._ccbOwner.btn_ok:setVisible(false)
    self._ccbOwner.node_money:setVisible(false)
    self._ccbOwner.node_tokenMoney:setVisible(false)
    self._ccbOwner.node_next_tips:setVisible(false)
    self._ccbOwner.btn_ok:setVisible(false)
    self._ccbOwner.bule_light:setVisible(false)
    self._ccbOwner.orange_light:setVisible(false)
    self._ccbOwner.purple_light:setVisible(false)
    self._ccbOwner.node_buy_info:setVisible(false)
    self._ccbOwner.node_free:setVisible(false)
    self._ccbOwner.tf_name:setString("")
end

function QUIDialogAchieveHero:viewDidAppear()
    QUIDialogAchieveHero.super.viewDidAppear(self)
    self:initView()
    self.prompt = app:promptTips()
    self.prompt:addHeroEventListener(self)
end

function QUIDialogAchieveHero:viewWillDisappear()
    QUIDialogAchieveHero.super.viewWillDisappear(self)
    self.prompt:removeHeroEventListener()
end

function QUIDialogAchieveHero:initView()
    local options = self:getOptions()

    if options.freeNum ~= nil and options.freeNum > 1 then
        self._ccbOwner.node_free:setVisible(true)
    else
        self._ccbOwner.node_buy_info:setVisible(true)
    end
    
    self._againBack = options.againBack 
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

    local actorId = options.items[1].id
    self._information = QUIWidgetHeroInformation.new(actorId)
    self._information:setBattleForceVisible(false)
    self._ccbOwner.node_hero:addChild(self._information:getView())
    local heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(actorId)
    local heroInfo = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
    if heroInfo ~= nil then
        if heroInfo.colour == 3 then
            self._ccbOwner.bule_light:setVisible(true)
        elseif heroInfo.colour == 4 then
            self._ccbOwner.purple_light:setVisible(true)
        elseif heroInfo.colour == 5 then
            self._ccbOwner.orange_light:setVisible(true)
        end
    end
    if nil ~= heroDisplay then 
        self._information:setAvatar(actorId,1)
        self._information:avatarPlayAnimation(ANIMATION_EFFECT.VICTORY, true)
        self._ccbOwner.tf_name:setString(heroDisplay.name)
        self._ccbOwner.tf_name:setColor(EQUIPMENT_COLOR[heroInfo.colour])
    end
    self._informationStar = QUIWidgetHeroInformationStar.new()
    self._informationStar:hideBg()
    self._ccbOwner.node_star:addChild(self._informationStar:getView())
    self._informationStar:showStar(0)
end

function QUIDialogAchieveHero:_backClickHandler()
    self:_onTriggerConfirm()
end

function QUIDialogAchieveHero:_onTriggerConfirm()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    if self._callBack ~= nil then
        self._callBack()
    end
end

function QUIDialogAchieveHero:_onTriggerAgain()
    self:_onTriggerConfirm()
    if self._againBack ~= nil then
    	self._againBack()
    end
end

return QUIDialogAchieveHero