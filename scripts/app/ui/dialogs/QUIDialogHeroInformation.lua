
local QUIDialog = import(".QUIDialog")
local QUIDialogheroInformation = class("QUIDialogheroInformation", QUIDialog)

local QRemote = import("...models.QRemote")
local QHeroModel = import("...models.QHeroModel")
local QHerosUtils = import("...utils.QHerosUtils")
local QUIViewController = import("..QUIViewController")
local QUIWidgetScaling = import("..widgets.QUIWidgetScaling")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroFrame = import("..widgets.QUIWidgetHeroFrame")
local QUIDialogGrade = import(".QUIDialogGrade")
local QUIDialogHeroOverview = import(".QUIDialogHeroOverview")
local QUIDialogBreakthrough = import(".QUIDialogBreakthrough")
local QUIWidgetEquipmentBox = import("..widgets.QUIWidgetEquipmentBox")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetHeroIntroduce = import("..widgets.QUIWidgetHeroIntroduce")
local QUIWidgetHeroUpgrade = import("..widgets.QUIWidgetHeroUpgrade")
local QUIWidgetHeroSkillUpgrade = import("..widgets.QUIWidgetHeroSkillUpgrade")
local QUIWidgetHeroEquipment = import("..widgets.QUIWidgetHeroEquipment")
local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetHeroInformation = import("..widgets.QUIWidgetHeroInformation")
local QUIWidgetHeroCard = import("..widgets.QUIWidgetHeroCard")
local QUIWidgetHeroInformationName = import("..widgets.QUIWidgetHeroInformationName")
local QUIWidgetHeroInformationStar = import("..widgets.QUIWidgetHeroInformationStar")
local QUIWidgetAnimationPlayer = import("..widgets.QUIWidgetAnimationPlayer")
local QUIDialogHeroEquipmentDetail = import("..dialogs.QUIDialogHeroEquipmentDetail")
local QTutorialDirector = import("...tutorial.QTutorialDirector")
local QTutorialEvent = import("..event.QTutorialEvent")

QUIDialogheroInformation.HERO_DETAIL = "HERO_DETAIL" --英雄详细面板
QUIDialogheroInformation.HERO_CARD = "HERO_CARD" --装备卡牌
QUIDialogheroInformation.EQUIPMENT_DETAIL = "EQUIPMENT_DETAIL" --装备详细面板
QUIDialogheroInformation.HERO_UPGRADE = "HERO_UPGRADE" --升级详细面板
QUIDialogheroInformation.HERO_SKILL = "HERO_SKILL" --技能详细面板

function QUIDialogheroInformation:ctor(options)
    local ccbFile = "ccb/Dialog_HeroInformation.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerRight", callback = handler(self, QUIDialogheroInformation._onTriggereRight)},
        {ccbCallbackName = "onTriggerLeft", callback = handler(self, QUIDialogheroInformation._onTriggereLeft)},
        -- {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogheroInformation._onTriggerClose)},

        {ccbCallbackName = "onPlus", callback = handler(self, QUIDialogheroInformation._onPlus)},
        {ccbCallbackName = "onAdvance", callback = handler(self, QUIDialogheroInformation._onAdvance)}, --进阶 
        {ccbCallbackName = "onUpgrade", callback = handler(self, QUIDialogheroInformation._onUpgrade)}, --升级
        {ccbCallbackName = "onBreakthrough", callback = handler(self, QUIDialogheroInformation._onBreakthrough)}, --突破
        {ccbCallbackName = "onHeroCard", callback = handler(self, QUIDialogheroInformation._onHeroCard)}, --打开卡牌
        {ccbCallbackName = "onHeroIntroduction", callback = handler(self, QUIDialogheroInformation._onHeroIntroduction)}, --打开资料
        {ccbCallbackName = "onSkill", callback = handler(self, QUIDialogheroInformation._onSkill)}, --打开技能
    }
    QUIDialogheroInformation.super.ctor(self, ccbFile, callBacks, options)
    app:getNavigationController():getTopPage():setManyUIVisible()

    self._informationStar = QUIWidgetHeroInformationStar.new()
    self._ccbOwner.node_star:addChild(self._informationStar:getView())

    self._information = QUIWidgetHeroInformation.new()
    self._ccbOwner.node_heroinformation:addChild(self._information:getView())

    self._informationName = QUIWidgetHeroInformationName.new()
    self._ccbOwner.node_heroname:addChild(self._informationName:getView())

    self._equipBox = {}
    for i = 1, 6 do
        self._equipBox[i] = QUIWidgetEquipmentBox.new()
        self._ccbOwner["node_equip"..i]:addChild(self._equipBox[i])
        -- self._equipBox[i] = app.widgetCache:getWidgetForName("QUIWidgetEquipmentBox",self._ccbOwner["node_equip"..i])
    end
    --头 衣服 脚 武器 护手 饰品
    self._equipBox[1]:setType(EQUIPMENT_TYPE.HAT)
    self._equipBox[2]:setType(EQUIPMENT_TYPE.CLOTHES)
    self._equipBox[3]:setType(EQUIPMENT_TYPE.SHOES)
    self._equipBox[4]:setType(EQUIPMENT_TYPE.WEAPON)
    self._equipBox[5]:setType(EQUIPMENT_TYPE.BRACELET)
    self._equipBox[6]:setType(EQUIPMENT_TYPE.JEWELRY)

    --装备控制器
    self._equipmentUtils = QUIWidgetHeroEquipment.new()
    self:getView():addChild(self._equipmentUtils) --此处添加至节点没有显示需求
    self._equipmentUtils:setUI(self._equipBox)

    self:_allButtonNormal()

    if options ~= nil and options.hero ~= nil and options.pos ~= nil then
        self._pos = options.pos
        self._herosID = options.hero
    end
    if options ~= nil and options.detailType ~= nil then
        self._detailType = options.detailType
    end

    self._ccbOwner.node_mask_btn:setVisible(false)

    if #self._herosID == 1 then
        self._ccbOwner.arrowLeft:setVisible(false)
        self._ccbOwner.arrowRight:setVisible(false)
    end
end

function QUIDialogheroInformation:viewDidAppear()
    QUIDialogheroInformation.super.viewDidAppear(self)
    self._equipmentUtils:addEventListener(QUIWidgetEquipmentBox.EVENT_EQUIPMENT_BOX_CLICK, handler(self, self.onEvent))

    self._heroProxy = cc.EventProxy.new(remote.herosUtil)
    self._heroProxy:addEventListener(QHerosUtils.EVENT_HERO_PROP_UPDATE, handler(self, self.heroPropUpdateHandler))
    self._heroProxy:addEventListener(QHerosUtils.EVENT_HERO_EXP_UPDATE, handler(self, self.heroPropUpdateHandler))
    self._heroProxy:addEventListener(QHerosUtils.EVENT_HERO_LEVEL_UPDATE, handler(self, self.heroPropUpdateHandler))

    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(QRemote.HERO_UPDATE_EVENT, handler(self, self.onEvent))

    self:refreshHero()
    self:addBackEvent()
end

function QUIDialogheroInformation:viewWillDisappear()
    QUIDialogheroInformation.super.viewWillDisappear(self)
    self._heroProxy:removeAllEventListeners()
    self._equipmentUtils:removeAllEventListeners()
    self._remoteProxy:removeAllEventListeners()

    if self._breakthrough ~= nil then
        self._breakthrough:removeAllEventListeners()
        self._breakthrough = nil
    end
    if self._grade ~= nil then
        self._grade:removeAllEventListeners()
        self._grade = nil
    end
    -- for _,value in pairs(self._equipBox) do
    --     app.widgetCache:setWidgetForName(value, value:getName())
    -- end
    self._equipBox = {}

    if self._expHandler ~= nil then
        scheduler.unscheduleGlobal(self._expHandler)
        self._expHandler = nil
    end
    self:removeBackEvent()
end

function QUIDialogheroInformation:refreshHero()
    if self._pos ~= nil and self._herosID ~= nil then
        self:showInformation(remote.herosUtil:getHeroByID(self._herosID[self._pos]))
    end
end

function QUIDialogheroInformation:onEvent(event)
    if event.name == QUIWidgetEquipmentBox.EVENT_EQUIPMENT_BOX_CLICK then
        app.sound:playSound("common_item")
        app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogHeroEquipmentDetail", 
            options = {itemId=event.info.id, heros = self._herosID, pos = self._pos, parentOptions = self:getOptions()}})
    end
end

function QUIDialogheroInformation:showInformation(hero)
    self._hero = hero
    self._heroModel = app:createHero(self._hero)
    self._oldHero = clone(hero)
    self._targetExp = 0
    self:showBaseInfo()
    self:showBattleForce()
    self._informationName:setHeroIcon(self._hero)
    self:_checkTips()
    local characherConfig = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self._hero.actorId)
    if characherConfig ~= nil then
        self._information:setAvatar(self._hero.actorId, 1.287)
    end
    --默认打开英雄卡牌界面
    if self._detailType == nil then
        self:_switchDetail(QUIDialogheroInformation.HERO_CARD)
    else
        self:_switchDetail(self._detailType)
    end
    self._informationStar:showStar(self._hero.grade, true)

    local heroInfo = QStaticDatabase:sharedDatabase():getCharacterByID(self._hero.actorId)
    if nil ~= heroInfo then 
        local heroTalent = QStaticDatabase:sharedDatabase():getTalentByID(heroInfo.talent)
        if nil ~= heroTalent then
            self._ccbOwner.label_talent:setString(heroTalent.name)
        end
        -- self._ccbOwner.label_level:setString(tostring(heroInfo.aptitude))
        self._equipmentUtils:setHero(self._hero.actorId) -- 装备显示
    end

    self:_refreshGradInfo()

    if self._introduce ~= nil then
        self._introduce:setHero(self._hero,self._heroModel)
    end
    if self._card ~= nil then
        self._card:setHero(self._hero.actorId)
    end
    if self._upgrade ~= nil then
        self._upgrade:showById(self._herosID[self._pos], self._ccbOwner.node_heroinformation:convertToWorldSpaceAR(ccp(0,0)))
    end
    if self._skill ~= nil then
        self._skill:setHero(self._hero.actorId)
    end
end

--显示英雄的基本信息 等级 经验等
function QUIDialogheroInformation:showBaseInfo()
    self._ccbOwner.level_prior:setString(self._oldHero.level)
    self._ccbOwner.level_rear:setString("/"..tostring(remote.herosUtil:getHeroMaxLevel()))
    self._maxexp = QStaticDatabase:sharedDatabase():getExperienceByLevel(self._oldHero.level)
    self._ccbOwner.tf_exp:setString(self._oldHero.exp.."/"..tostring(self._maxexp))
end

--显示战斗力
function QUIDialogheroInformation:showBattleForce()
    self._information:setBattleForce(self._heroModel:getBattleForce())
end

function QUIDialogheroInformation:_refreshGradInfo()
    if self._hero.grade < GRAD_MAX then
        self._ccbOwner.btn_grade:setVisible(true)
        self._gradeConfig = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(self._hero.actorId, self._hero.grade+1)
        if self._gradeConfig == nil then
            printError(self._hero.actorId.." can't find in grade config !")
            return 
        end

        local soulNum = remote.items:getItemsNumByID(self._gradeConfig.soul_gem) -- 灵魂碎片的数量
        soulNum = soulNum >= self._gradeConfig.soul_gem_count and self._gradeConfig.soul_gem_count or soulNum

        -- self._ccbOwner.node_status1:setVisible(true)
        self._ccbOwner.status1_bar:setScaleX(soulNum/self._gradeConfig.soul_gem_count)
        self._ccbOwner.status1_tf:setString(soulNum.."/"..self._gradeConfig.soul_gem_count)
        self:_addIcon(self._ccbOwner.status1_icon,ITEM_ID.CRYSTAL)
    else
        -- self._ccbOwner.node_status1:setVisible(false)
        self._ccbOwner.btn_grade:setVisible(false)
        self._ccbOwner.status1_bar:setScaleX(1)
        self._ccbOwner.status1_tf:setString("已升星到顶级")
    end
end

function QUIDialogheroInformation:_addIcon(node,itemID)
    local iconURL = QStaticDatabase:sharedDatabase():getItemByID(tonumber(itemID)).icon
    if iconURL ~= nil then
        local texture = CCTextureCache:sharedTextureCache():addImage(iconURL)
        local ccsprite = CCSprite:createWithTexture(texture)
    end
    if ccsprite ~= nil then
        node:addChild(ccsprite)
    end
end

--[[
    穿装备效果显示
]]
function QUIDialogheroInformation:_wearEffect(itemId)
    app.sound:playSound("hero_put_on")
    if self._wearEquipEffect == nil then
        self._wearEquipEffect = QUIWidgetAnimationPlayer.new()
        self:getView():addChild(self._wearEquipEffect)
    end
    for _,box in pairs(self._equipBox) do
        if box:getItemId() == itemId then
            local p = box:convertToWorldSpaceAR(ccp(0, 0))
            p = self:getView():convertToNodeSpaceAR(p)
            self._wearEquipEffect:setPosition(p.x, p.y)
            self._wearEquipEffect:playAnimation("ccb/effects/EquipmentUpgarde.ccbi", nil, function()
                    self._equipmentUtils:refreshBox()
                end)
            break
        end
    end
    self._information:avatarPlayAnimation(ANIMATION_EFFECT.VICTORY)

    local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(itemId)

    self:_showEffectToAvatar("生命：", itemInfo.hp)
    self:_showEffectToAvatar("攻击：", itemInfo.attack)
    self:_showEffectToAvatar("命中：", itemInfo.hit_rating)
    self:_showEffectToAvatar("闪避：", itemInfo.dodge_rating)
    self:_showEffectToAvatar("暴击：", itemInfo.critical_rating)
    self:_showEffectToAvatar("格挡：", itemInfo.block_rating)
    self:_showEffectToAvatar("急速：", itemInfo.haste_rating)
    self:_showEffectToAvatar("物抗：", itemInfo.armor_physical)
    self:_showEffectToAvatar("魔抗：", itemInfo.armor_magic)
    self:refreshHero()
end

function QUIDialogheroInformation:_showEffectToAvatar(name,value)
    if value ~= nil then
        if type(value) == "number" then
            if value > 0 then
                self._information:playPropEffect(name.."+ "..value)
            end
        else
            self._information:playPropEffect(name.."+ "..value)
        end
    end
end

function QUIDialogheroInformation:heroPropUpdateHandler(event)
    if event.actorId == self._herosID[self._pos] then
        if event.name == QHerosUtils.EVENT_HERO_PROP_UPDATE then 
            self._information:playPropEffect(event.value)
        elseif event.name == QHerosUtils.EVENT_HERO_LEVEL_UPDATE then
            self._information:playLevelUp()
            local hero = remote.herosUtil:getHeroByID(self._herosID[self._pos])
            self._information:battleForceAnimation(QHeroModel.new(hero):getBattleForce())
            self._equipmentUtils:refreshBox()
            self:_checkTips()
        elseif event.name == QHerosUtils.EVENT_HERO_EXP_UPDATE then
            self:_expEffect(event.exp)
        end
    end
end

--[[
    经验滚动效果显示
]]
function QUIDialogheroInformation:_expEffect(exp)
    app.sound:playSound("hero_eat_off")
    self._runTime = 1
    self._targetExp = self._targetExp + exp
    self._expPreNum = math.floor(self._targetExp / (self._runTime*60))
    self._startTime = q.time()
    self._expEffectForEach = function ()
        if q.time() - self._startTime > self._runTime then
            if self._expHandler ~= nil then
                scheduler.unscheduleGlobal(self._expHandler)
                self._expHandler = nil
            end
            self._oldHero.exp = self._oldHero.exp + self._targetExp
            self._targetExp = 0
        else
            if self._targetExp > self._expPreNum then
                self._targetExp = self._targetExp - self._expPreNum
                self._oldHero.exp = self._oldHero.exp + self._expPreNum
            else
                self._oldHero.exp = self._oldHero.exp + self._targetExp
                self._targetExp = 0
            end
        end
        while true do
            local maxExp = QStaticDatabase:sharedDatabase():getExperienceByLevel(self._oldHero.level)
            if self._oldHero.exp >= maxExp then
                self._oldHero.exp = self._oldHero.exp - maxExp
                self._oldHero.level = self._oldHero.level + 1
            else
                break
            end
        end
        self:showBaseInfo()
    end
    if self._expHandler == nil then
        self._expHandler = scheduler.scheduleGlobal(self._expEffectForEach,0)
    end
end

function QUIDialogheroInformation:_checkTips()
    local isGrade = remote.herosUtil:checkHerosGradeByID(self._hero.actorId)
    local isBreakthrough = remote.herosUtil:checkHerosBreakthroughByID(self._hero.actorId)
    self._ccbOwner.node_tips_breakthrough:setVisible(isBreakthrough)
    self._ccbOwner.node_tips_grade:setVisible(isGrade)

        if app.tutorial:isTutorialFinished() == false then
            if app.tutorial:getStage().breakthroughGuide == QTutorialDirector.Guide_Start and remote.herosUtil:checkAllHerosBreakthroughNeedEqu() ~= nil  then
                app.tutorial:startTutorial(QTutorialDirector.Stage_7_Breakthrough)
            end
        end
end

--切换详细信息面板
function QUIDialogheroInformation:_switchDetail(detailType)
    if self._isRunAnimation == true then
        return
    end
    self:_allButtonNormal()
    self._detailType = detailType
    if detailType == QUIDialogheroInformation.HERO_DETAIL then
        if self._introduce == nil then
            self._introduce = QUIWidgetHeroIntroduce.new()
            self._introduce:setHero(self._hero,self._heroModel)
            self._ccbOwner.node_herointroduce:addChild(self._introduce)
        end
        self:_switchDetailForAnimation(self._introduce)
        self._ccbOwner.heroIntroduce_normal:setVisible(false)
        self._ccbOwner.heroIntroduce_select:setVisible(true)
    elseif detailType == QUIDialogheroInformation.HERO_CARD then
        if self._card == nil then
            self._card = QUIWidgetHeroCard.new()
            self._card:setIsEffect(true)
            self._ccbOwner.node_herointroduce:addChild(self._card)
            self._card:setHero(self._hero.actorId)
        end
        self:_switchDetailForAnimation(self._card)
        self._ccbOwner.card_normal:setVisible(false)
        self._ccbOwner.card_select:setVisible(true)
    elseif detailType == QUIDialogheroInformation.HERO_UPGRADE then
        if self._upgrade == nil then
            self._upgrade = QUIWidgetHeroUpgrade.new()
            self._upgrade:showById(self._herosID[self._pos], self._ccbOwner.node_heroinformation:convertToWorldSpaceAR(ccp(0,0)))
            self._ccbOwner.node_herointroduce:addChild(self._upgrade)
        end
        self:_switchDetailForAnimation(self._upgrade)
        self._ccbOwner.upgrade_normal:setVisible(false)
        self._ccbOwner.upgrade_select:setVisible(true)
    elseif detailType == QUIDialogheroInformation.HERO_SKILL then
        if self._skill == nil then
            self._skill = QUIWidgetHeroSkillUpgrade.new()
            self._ccbOwner.node_herointroduce:addChild(self._skill)
            self._skill:setHero(self._hero.actorId)
        end
        self:_switchDetailForAnimation(self._skill)
        self._ccbOwner.skill_normal:setVisible(false)
        self._ccbOwner.skill_select:setVisible(true)
    end
end

function QUIDialogheroInformation:_switchDetailForAnimation(view)
    if self._detailView == nil then
        self._detailView = view
        self._detailView:setVisible(true)
        self._detailView:setPosition(0, 0)
    elseif self._detailView == view then
        return        
    else
        self._isRunAnimation = true
        view:setVisible(false)
        view:setPositionX(400)
        self._nextView = view
        local arrOut = CCArray:create()
        arrOut:addObject(CCMoveTo:create(0.2, ccp(400,0)))
        arrOut:addObject(CCCallFunc:create(function ()
            self._nextView:setVisible(true)
            self._detailView:setVisible(false)
            local arrOut = CCArray:create()
            arrOut:addObject(CCMoveTo:create(0.2, ccp(0,0)))
            arrOut:addObject(CCCallFunc:create(function ()
                self._isRunAnimation = false
                self._detailView = self._nextView
            end))
            local ccsequence = CCSequence:create(arrOut)
            self._nextView:runAction(ccsequence)
        end))
        local ccsequence = CCSequence:create(arrOut)
        self._detailView:runAction(ccsequence)
    end
end

function QUIDialogheroInformation:_onTriggereRight()
    app.sound:playSound("common_change")
    local n = table.nums(self._herosID)
    if nil ~= self._pos and n > 1 then
        self._pos = self._pos + 1
        if self._pos > n then
            self._pos = 1
        end
        local options = self:getOptions()
        options.pos = self._pos
        self:showInformation(remote.herosUtil:getHeroByID(self._herosID[self._pos]))
    end
end

function QUIDialogheroInformation:_onTriggereLeft()
    app.sound:playSound("common_change")
    local n = table.nums(self._herosID)
    if nil ~= self._pos and n > 1 then
        self._pos = self._pos - 1
        if self._pos < 1 then
            self._pos = n
        end
        local options = self:getOptions()
        options.pos = self._pos
        self:showInformation(remote.herosUtil:getHeroByID(self._herosID[self._pos]))
    end
end

function QUIDialogheroInformation:_allButtonNormal()
    self._ccbOwner.node_advance:setHighlighted(false)

    self._ccbOwner.heroIntroduce_normal:setVisible(true)
    self._ccbOwner.heroIntroduce_select:setVisible(false)
    self._ccbOwner.card_normal:setVisible(true)
    self._ccbOwner.card_select:setVisible(false)
    self._ccbOwner.upgrade_normal:setVisible(true)
    self._ccbOwner.upgrade_select:setVisible(false)
    self._ccbOwner.skill_normal:setVisible(true)
    self._ccbOwner.skill_select:setVisible(false)
end

function QUIDialogheroInformation:_onPlus()
    app.sound:playSound("common_increase")
    local config = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(self._hero.actorId, 1)
    if config == nil then return end
    app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogItemDropInfo", 
        options = {itemId = config.soul_gem}}, {isPopCurrentDialog = false})
end

--进阶
function QUIDialogheroInformation:_onAdvance()
    app.sound:playSound("common_hero")
    if self._hero.grade < GRAD_MAX then
        if remote.herosUtil:checkHerosGradeByID(self._herosID[self._pos]) == true then
            local characherConfig = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self._hero.actorId)
            app:alert({content="是否确认要升星"..characherConfig.name, title = "系统提示", comfirmBack = handler(self, self._onAdvanceSucc), callBack = function ()
            end}, false)
        else
            app.tip:floatTip("灵魂碎片不足，无法升星")
        end
    else
        app.tip:floatTip("英雄已升星到顶级")
    end
end

function QUIDialogheroInformation:_onAdvanceSucc()
    app:getClient():grade(self._herosID[self._pos], function(data)
            app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogGrade",options = { actorId = self._herosID[self._pos]}},
                {isPopCurrentDialog = false})
            self:refreshHero()
            self:_checkTips()
        end)
end

--突破
function QUIDialogheroInformation:_onBreakthrough()
    app.sound:playSound("common_hero")
    if remote.herosUtil:checkHerosBreakthroughByID(self._herosID[self._pos]) == true then
        local characherConfig = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self._hero.actorId)
        app:alert({content="是否确认要突破"..characherConfig.name, title = "系统提示", comfirmBack = handler(self, self._onBreakthroughSucc), callBack = function ()
            end}, false)
    else
        app.tip:floatTip("装备未穿齐，无法突破")
    end
end

function QUIDialogheroInformation:_onBreakthroughSucc()
    app:getClient():breakthrough(self._herosID[self._pos], function(data)
            self:_onBreakthroughEffect()
        end)
end

function QUIDialogheroInformation:_onBreakthroughEffect()
    -- self._ccbOwner.node_mask_btn:setVisible(true)
    -- local effect = QUIWidgetAnimationPlayer.new()
    -- local p = self._ccbOwner.node_heroinformation:convertToWorldSpaceAR(ccp(0,0))
    -- p = self:getView():convertToNodeSpaceAR(p)
    -- effect:setPosition(p.x+1, p.y-109)
    -- self:getView():addChild(effect)
    -- effect:playAnimation("ccb/effects/Equipment1.ccbi", function(ccbOwner,ccbView)
    --     local index = 1
    --     for _,value in pairs(self._equipBox) do
    --         local box = QUIWidgetEquipmentBox.new()
    --         local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(value:getItemId())
    --         box:setEquipmentInfo(itemInfo,true)
    --         ccbOwner["node_equip"..index]:addChild(box)
    --         index = index + 1
    --     end
    --     self._equipmentUtils:refreshBox()
    -- end,function()
    --     self._ccbOwner.node_mask_btn:setVisible(false)
    --     app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogBreakthrough",options = { actorId = self._herosID[self._pos]}},
    --         {isPopCurrentDialog = false})
    -- end)
    -- self._animationHandler = scheduler.performWithDelayGlobal(function()
    --     local oldHero = self._oldHero 
    --     self:refreshHero()
    --     remote.herosUtil:heroUpdate(oldHero,self._hero)
    --     self._information:avatarPlayAnimation(ANIMATION_EFFECT.VICTORY)
    --     self._animationHandler = nil

    --     end,1.5)
    self._ccbOwner.node_mask_btn:setVisible(true)
    local oldHero = self._oldHero 
    self:refreshHero()
    remote.herosUtil:heroUpdate(oldHero,self._hero)
    self._information:avatarPlayAnimation(ANIMATION_EFFECT.VICTORY)
    self._animationHandler = scheduler.performWithDelayGlobal(function()
            self._ccbOwner.node_mask_btn:setVisible(false)
            app:getNavigationMidLayerController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogBreakthrough",options = { actorId = self._herosID[self._pos]}},
                {isPopCurrentDialog = false})
        end,1.5)
end

function QUIDialogheroInformation:_onCheckSucc()
    self:_checkTips()
end 

--升级
function QUIDialogheroInformation:_onUpgrade()
    app.sound:playSound("common_hero")
    self:_switchDetail(QUIDialogheroInformation.HERO_UPGRADE)    
end

-- function QUIDialogheroInformation:_backClickHandler()
--     self:_onTriggerClose()
-- end

-- function QUIDialogheroInformation:_onTriggerClose()
--     app.sound:playSound("common_close")
--     app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
-- end

function QUIDialogheroInformation:_onHeroCard()
    app.sound:playSound("common_hero")
    self:_switchDetail(QUIDialogheroInformation.HERO_CARD)
end

function QUIDialogheroInformation:_onHeroIntroduction()
    app.sound:playSound("common_hero")
    self:_switchDetail(QUIDialogheroInformation.HERO_DETAIL)    
end

function QUIDialogheroInformation:_onSkill() 
    app.sound:playSound("common_hero")
    local config = QStaticDatabase:sharedDatabase():getConfiguration()
    if remote.instance:checkIsPassByDungeonId(config.UNLOCK_SKILLS.value) == false then
        local dungeonInfo = remote.instance:getDungeonById(config.UNLOCK_SKILLS.value)
        app.tip:floatTip("通关关卡"..dungeonInfo.number.."解锁")
        return
    end
    remote.herosUtil:dispatchEvent({name = QHerosUtils.EVENT_HERO_EXP_CHECK})
    self:_switchDetail(QUIDialogheroInformation.HERO_SKILL)    
end

function QUIDialogheroInformation:onTriggerBackHandler(tag)
    self:_onTriggerBack()
end

function QUIDialogheroInformation:onTriggerHomeHandler(tag)
    self:_onTriggerHome()
end

-- 对话框退出
function QUIDialogheroInformation:_onTriggerBack(tag, menuItem)
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- 对话框退出
function QUIDialogheroInformation:_onTriggerHome(tag, menuItem)
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

return QUIDialogheroInformation