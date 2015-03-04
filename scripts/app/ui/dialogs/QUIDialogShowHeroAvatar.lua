--
-- Author: wkwang
-- Date: 2014-08-07 12:34:26
--
local QUIDialog = import(".QUIDialog")
local QUIDialogShowHeroAvatar = class("QUIDialogShowHeroAvatar", QUIDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroInformation = import("..widgets.QUIWidgetHeroInformation")
local QUIWidgetHeroInformationStar = import("..widgets.QUIWidgetHeroInformationStar")
local QNavigationController = import("...controllers.QNavigationController")
local QUIDialogHeroOverview = import(".QUIDialogHeroOverview")
local QNotificationCenter = import(".QNotificationCenter")

function QUIDialogShowHeroAvatar:ctor(options)
	local ccbFile = "ccb/Dialog_AchieveHero.ccbi"
    local callBacks = {
    }
    QUIDialogShowHeroAvatar.super.ctor(self, ccbFile, callBacks, options)

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
    self._ccbOwner.tf_name:setString("")

    if options.tokenType == ITEM_TYPE.TOKEN_MONEY then
        self._ccbOwner.node_title_gold:setVisible(true)
    elseif options.tokenType == ITEM_TYPE.MONEY then
        self._ccbOwner.node_title_silver:setVisible(true)
    else
        self._ccbOwner.node_title_normal:setVisible(true)
    end
   
    self._information = QUIWidgetHeroInformation.new(options.actorId)
	self._information:setBattleForceVisible(false)
    self._ccbOwner.node_hero:addChild(self._information:getView())
    local characherConfig = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(options.actorId)
    if characherConfig ~= nil then
        self._information:setAvatar(options.actorId, 1)
        self._information:avatarPlayAnimation(ANIMATION_EFFECT.VICTORY, true)
    end
    local heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(options.actorId)
    local heroInfo = QStaticDatabase:sharedDatabase():getCharacterByID(options.actorId)
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
        self._ccbOwner.tf_name:setString(heroDisplay.name)
        self._ccbOwner.tf_name:setColor(EQUIPMENT_COLOR[heroInfo.colour])
    end
    self._informationStar = QUIWidgetHeroInformationStar.new()
    self._informationStar:hideBg()
    self._ccbOwner.node_star:addChild(self._informationStar:getView())
    local heroInfo = remote.herosUtil:getHeroByID(options.actorId)
    if heroInfo ~= nil then
        self._informationStar:showStar(heroInfo.grade)
    end
    self._heroInfo = options.actorId
    self.callBack = options.callBack
end

function QUIDialogShowHeroAvatar:viewDidAppear()
    QUIDialogShowHeroAvatar.super.viewDidAppear(self)
    self.prompt = app:promptTips()
    self.prompt:addHeroEventListener(self)
end

function QUIDialogShowHeroAvatar:viewWillDisappear()
    QUIDialogShowHeroAvatar.super.viewWillDisappear(self)
    self.prompt:removeHeroEventListener()
end

function QUIDialogShowHeroAvatar:_backClickHandler(options)
    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIDialogHeroOverview.TUTORIAL_HERO_UP_GRADE, upGradeHeroInfo = self._heroInfo})
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)

    if self.callBack ~= nil then
        self.callBack()
    end
end

return QUIDialogShowHeroAvatar