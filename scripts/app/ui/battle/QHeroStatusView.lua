
local QHeroStatusView = class("QHeroStatusView", function()
    return display.newNode()
end)

local QCircleUiMask = import(".QCircleUiMask")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QSkeletonViewController = import("...controllers.QSkeletonViewController")
local QUserData = import("...utils.QUserData")

function QHeroStatusView:ctor(hero)
    self._hero = hero

    self._heroEventProxy = cc.EventProxy.new(self._hero, self)
    self._heroEventProxy:addEventListener(self._hero.USE_MANUAL_SKILL_EVENT, handler(self, self._onUseSkill))

    local ccbFile = nil
    if hero:isNeedComboPoints() then
    	ccbFile = "ccb/Battle_Skill3.ccbi"
    else
    	ccbFile = "ccb/Battle_Skill.ccbi"
    end
    local proxy = CCBProxy:create()
    self._ccbOwner = {}
    if app.battle:isPVPMode() == false or app.battle:isInArena() == false then
        self._ccbOwner.clickSkill1 = handler(self, QHeroStatusView._onClickSkillButton1)
        self._ccbOwner.clickHead = handler(self, QHeroStatusView._onClickHeroHead)
    end

    local ccbView = CCBuilderReaderLoad(ccbFile, proxy, self._ccbOwner)
    if ccbView == nil then
        assert(false, "load ccb file:" .. ccbFile .. " faild!")
    end
    self:addChild(ccbView)
    self._ccbOwner.ccb_animationCoolDown:setVisible(false)
    self._ccbOwner.ccb_chooseAnimationNode:setVisible(false)
    self._ccbOwner.ccb_attentionAnimationNode:setVisible(false)
    self._isChooseAnimationPlaying = false
    self._isAttentionAnimationPlaying = false

    -- hero icon
    local iconFile = hero:getIcon()
    if iconFile ~= nil then
        local texture = CCTextureCache:sharedTextureCache():addImage(iconFile)
    	self._ccbOwner.sprite_heroIcon:setTexture(texture)
        local size = texture:getContentSize()
        local rect = CCRectMake(0, 0, size.width, size.height)
        self._ccbOwner.sprite_heroIcon:setTextureRect(rect)
    end

    -- hero skills
    local icons = {}
    self._skills = {}
    for _, skill in pairs(self._hero:getManualSkills()) do
        table.insert(icons, skill:getIcon())
        table.insert(self._skills, skill)
        break
    end

    if table.nums(icons) == 0 then
        table.insert(icons, global.ui_skill_icon_placeholder)
    end

    if icons[1] ~= nil then
        local texture = CCTextureCache:sharedTextureCache():addImage(icons[1])
        self._ccbOwner.sprite_skillIcon1:setTexture(texture)
        local size = texture:getContentSize()
        local rect = CCRectMake(0, 0, size.width, size.height)
        self._ccbOwner.sprite_skillIcon1:setDisplayFrame(CCSpriteFrame:createWithTexture(texture, rect))

        self._ccbOwner.sprite_highlight1:retain()
        self._ccbOwner.sprite_highlight1:removeFromParent()
        self._ccbOwner.sprite_skillIcon1:addChild(self._ccbOwner.sprite_highlight1)
        self._ccbOwner.sprite_highlight1:release()
        self._ccbOwner.sprite_highlight1:setPosition(self._ccbOwner.sprite_highlight1:getPositionX() + size.width / 2, self._ccbOwner.sprite_highlight1:getPositionY() + size.height / 2)
    end

    if icons[1] == global.ui_skill_icon_placeholder then
    	self._ccbOwner.node_gray1:setVisible(true)
    	self._ccbOwner.node_ok1:setVisible(false)
    	self._ccbOwner.button_skill1:setEnabled(false)
        self._ccbOwner.ccb_animationSkill1:setVisible(false)
    else
    	self._ccbOwner.node_gray1:setVisible(false)
    	self._ccbOwner.node_ok1:setVisible(true)
    	self._ccbOwner.button_skill1:setEnabled(true)
        self._ccbOwner.ccb_animationSkill1:setVisible(true)
    	self._skill1 = self._skills[1]

    	local sprite = CCSprite:create(icons[1])
	    sprite:updateDisplayedColor(global.ui_skill_icon_disabled_overlay)
	    self._cd1 = QCircleUiMask.new({hideWhenFull = true})
        self._cd1:setMaskSize(sprite:getContentSize())
	    self._cd1:addChild(sprite)
	    self._cd1:update(1)
	    self._ccbOwner.sprite_skillIcon1:addChild(self._cd1)
        local size = self._ccbOwner.sprite_skillIcon1:getContentSize()
        self._cd1:setPosition(size.width * 0.5, size.height * 0.5)
    end


    for _, skill in pairs(hero:getActiveSkills()) do
        if skill:getTriggerCondition() == "drag" or skill:getTriggerCondition() == "drag_attack" then
            local ccbProxy = CCBProxy:create()
            local ccbOwner = {}
            self._nodeSkillCooling = CCBuilderReaderLoad("Widget_SkillCooling.ccbi", ccbProxy, ccbOwner)
            self._nodeSkillCooling:setPosition(37, 90)
            self._nodeSkillCooling:setScale(0.85)
            ccbOwner.label_skill_name:setString(skill:getLocalName() .. "冷却")
            ccbOwner.sprite_skill_icon:setTexture(CCTextureCache:sharedTextureCache():addImage(skill:getIcon()))
            makeNodeOpacity(ccbOwner.label_skill_name:getParent(), 0)
            ccbOwner.label_skill_name:getParent():setOpacity(255)
            self:addChild(self._nodeSkillCooling)
            self._nodeSkillCoolingProxy = ccbProxy
            self._nodeSkillCoolingOwner = ccbOnwer
            self._skillActive = skill
            break
        end
    end

    self._needRefreshHp = false
    self._needRefreshSkillCD = false
    
    self._suffix = "-autoUseSkill"
    local dungeonConfig = app.battle:getDungeonConfig()
    local dungeonInfo = remote.activityInstance:getDungeonById(dungeonConfig.id)
    if dungeonInfo ~= nil then
        self._suffix = "-autoUseSkill-active"
    end
    if app.battle:isPVPMode() == true and app.battle:isInSunwell() == true then
        self._suffix = "-autoUseSkill-sunwell"
    end

    local autoUseSkill = app:getUserData():getUserValueForKey(self._hero:getActorID() .. self._suffix)
    if app.battle:isPVPMode() == true and app.battle:isInArena() == true then
        autoUseSkill = QUserData.STRING_TRUE
    end
    if autoUseSkill == nil or autoUseSkill ~= QUserData.STRING_TRUE then
        self._hero:setForceAuto(false)
        self._ccbOwner.ccb_animationAutoSkill1:setVisible(false)
    else
        self._hero:setForceAuto(true)
        self._ccbOwner.ccb_animationAutoSkill1:setVisible(true)
    end

    if hero:isNeedComboPoints() then
        self._ccbOwner.ccb_animationSkill1:setPosition(ccp(10000, 10000))
    end

    self:setNodeEventEnabled(true)
end

function QHeroStatusView:onEnter()
    if self._skill1 ~= nil then
        local skill = self._skill1
        self._skillEventProxy1 = cc.EventProxy.new(self._skill1)
        self._skillEventProxy1:addEventListener(QDEF.EVENT_CD_CHANGED, handler(self, self.onCdChanged))
        self._skillEventProxy1:addEventListener(QDEF.EVENT_CD_STARTED, handler(self, self.onCdStarted))
        self._skillEventProxy1:addEventListener(QDEF.EVENT_CD_STOPPED, handler(self, self.onCdStopped))
        self._skillEventProxy1:addEventListener(skill.EVENT_SKILL_DISABLE, handler(self, self.onSkillDisable))
        self._skillEventProxy1:addEventListener(skill.EVENT_SKILL_ENABLE, handler(self, self.onSkillEnable))
    end

    if self._skillActive ~= nil then
        self._skillEventProxy3 = cc.EventProxy.new(self._skillActive)
        self._skillEventProxy3:addEventListener(QDEF.EVENT_CD_STOPPED, handler(self, self.onCdStopped))
    end

    if self._hero ~= nil then
        self._heroEventProxy = cc.EventProxy.new(self._hero)
        self._heroEventProxy:addEventListener(self._hero.HP_CHANGED_EVENT, handler(self, self.onHpChanged))
        self._heroEventProxy:addEventListener(self._hero.CP_CHANGED_EVENT, handler(self, self.onCpChanged))
        self._heroEventProxy:addEventListener(self._hero.FORCE_AUTO_CHANGED_EVENT, handler(self, self.onForceChanged))
    end

    if self._ccbOwner.sprite_combo_1 then
        local cp = self._hero:getComboPoints()
        self._ccbOwner.sprite_combo_1:setVisible(cp >= 1)
        self._ccbOwner.sprite_combo_2:setVisible(cp >= 2)
        self._ccbOwner.sprite_combo_3:setVisible(cp >= 3)
        self._ccbOwner.sprite_combo_4:setVisible(cp >= 4)
        self._ccbOwner.sprite_combo_5:setVisible(cp >= 5)
    end

    -- TODO: test code for fore auto
    if app.battle:isInTutorial() == false and false then
        local hero = self._hero
        local _menu = CCMenu:create()
        _menu:setPosition(ccp(0, 0))
        self:addChild(_menu)
        local _btnAuto = CCMenuItemFont:create(" ")
        _btnAuto:retain()
        _btnAuto:setPosition(ccp(100, 100))
        _btnAuto:setString(hero:isForceAuto() and "AUTO ON" or "AUTO OFF")
        _menu:addChild(_btnAuto)
        self._btnAuto = _btnAuto

        _btnAuto:addNodeEventListener(cc.MENU_ITEM_CLICKED_EVENT, function()
            local force = hero:isForceAuto()
            hero:setForceAuto(not force)
            _btnAuto:setString((not force) and "AUTO ON" or "AUTO OFF")
        end)

        local _labelCombo = CCLabelTTF:create()
        _labelCombo:retain()
        _labelCombo:setPosition(ccp(100, 75))
        _labelCombo:setString(string.format("%d 连击点数", hero:getComboPoints()))
        _labelCombo:setFontSize(24)
        self:addChild(_labelCombo)
        self._labelCombo = _labelCombo

        self._labelCombo:setVisible(hero:isNeedComboPoints())
    end

    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()
end

function QHeroStatusView:onExit()
    if self._skillEventProxy1 ~= nil then
        self._skillEventProxy1:removeAllEventListeners()
        self._skillEventProxy1 = nil
    end

    if self._skillEventProxy3 ~= nil then
        self._skillEventProxy3:removeAllEventListeners()
        self._skillEventProxy3 = nil
    end

    if self._heroEventProxy ~= nil then
        self._heroEventProxy:removeAllEventListeners()
        self._heroEventProxy = nil
    end

    -- TODO: test code for fore auto
    if self._btnAuto then
        local _btnAuto = self._btnAuto
        _btnAuto:removeFromParent()
        _btnAuto:release()
        self._btnAuto = nil
        _btnAuto = nil
    end
    if self._labelCombo then
        local _labelCombo = self._labelCombo
        _labelCombo:removeFromParent()
        _labelCombo:release()
        self._labelCombo = nil
        _labelCombo = nil
    end

    if self._coolDownAnimatinoProxy ~= nil then
        self._coolDownAnimatinoProxy:disconnectAnimationEventSignal()
        self._coolDownAnimatinoProxy:release()
        self._coolDownAnimatinoProxy = nil
    end

    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
end

function QHeroStatusView:_onFrame(dt)
    if self._skill1 then
        if self._hero:isNeedComboPoints() then
            if self._skill1:isReady() then
                if (not self._hero:canAttack(self._skill1) or not self._hero:canAttackWithBuff(self._skill1)) then
                    makeNodeFromNormalToGray(self._ccbOwner.sprite_skillIcon1)
                else
                    makeNodeFromGrayToNormal(self._ccbOwner.sprite_skillIcon1)
                end
            else
                makeNodeFromNormalToGray(self._ccbOwner.sprite_skillIcon1)
            end
        else
            if self._skill1:isReady() then
                if (not self._hero:canAttack(self._skill1) or not self._hero:canAttackWithBuff(self._skill1)) then
                    self._ccbOwner.ccb_animationSkill1:setVisible(false)
                else
                    self._ccbOwner.ccb_animationSkill1:setVisible(true)
                end
            end
        end
    end
end

function QHeroStatusView:getActor()
    return self._hero
end

function QHeroStatusView:onSkillDisable(event)
    if event.skill == self._skill1 then
        local texture = CCTextureCache:sharedTextureCache():addImage(global.ui_skill_icon_placeholder)
        self._ccbOwner.sprite_skillIcon1:setTexture(texture)
        local size = texture:getContentSize()
        local rect = CCRectMake(0, 0, size.width, size.height)
        self._ccbOwner.sprite_skillIcon1:setDisplayFrame(CCSpriteFrame:createWithTexture(texture, rect))
        self._ccbOwner.sprite_highlight1:setVisible(false)
        self._ccbOwner.ccb_animationSkill1:setVisible(false)
    end
end

function QHeroStatusView:onSkillEnable(event)
    if event.skill == self._skill1 then
        if self._skill1 and self._skill1:getIcon() then
            local texture = CCTextureCache:sharedTextureCache():addImage(self._skill1:getIcon())
            self._ccbOwner.sprite_skillIcon1:setTexture(texture)
            local size = texture:getContentSize()
            local rect = CCRectMake(0, 0, size.width, size.height)
            self._ccbOwner.sprite_skillIcon1:setDisplayFrame(CCSpriteFrame:createWithTexture(texture, rect))
            self._ccbOwner.sprite_highlight1:setVisible(true)
            self._ccbOwner.ccb_animationSkill1:setVisible(true)
        end
    end
end

function QHeroStatusView:onCdStarted(event)

end

function QHeroStatusView:onCdStopped(event)
    if self._hero:isDead() == true then
        return
    end
    
	if event.skill == self._skill1 then
        local animationManager = tolua.cast(self._ccbOwner.ccb_animationSkill1:getUserObject(), "CCBAnimationManager")
        if animationManager ~= nil then 
            animationManager:runAnimationsForSequenceNamed(global.ui_skill_icon_effect_cdok)
        end
	elseif event.skill == self._skillActive then
        local animationManager = tolua.cast(self._nodeSkillCooling:getUserObject(), "CCBAnimationManager")
        if animationManager ~= nil then 
            self._ccbOwner.ccb_animationCoolDown:setVisible(false)
            self._nodeSkillCooling:setVisible(true)
            animationManager:runAnimationsForSequenceNamed("Default Timeline")
        end
    end
    
end

function QHeroStatusView:onCdChanged(event)
    if self._hero:isDead() == true then
        return
    end
    
	if event.skill == self._skill1 then
	    local percent = 1 - event.cd_progress
        if event.skill:isReadyAndConditionMet() then
            self._cd1:update(1)
        else
            self._cd1:update(percent)
        end
	end
end

function QHeroStatusView:onHpChanged(event)
    if self._hero:getHp() <= 0 then
        self._cd1:update(1)
        self._ccbOwner.sprite_hpFront:setScaleX(0)
        self._ccbOwner.sprite_hpBack:stopAllActions()
        self._ccbOwner.sprite_hpBack:setScaleX(0)
        makeNodeFromNormalToGray(self)
        self._ccbOwner.ccb_animationSkill1:setVisible(false)
        self._isGrayView = true
    else
        if self._isGrayView == true then
            makeNodeFromGrayToNormal(self)
            self._ccbOwner.ccb_animationSkill1:setVisible(true)
            self._isGrayView = false
        end
        local precent = self._hero:getHp() / self._hero:getMaxHp()
        self._ccbOwner.sprite_hpFront:setScaleX(precent)
        self._ccbOwner.sprite_hpBack:stopAllActions()
        self._ccbOwner.sprite_hpBack:runAction(CCScaleTo:create(0.5, precent, 1.0))

        if precent < 0.2 and self._isAttentionAnimationPlaying == false then
            local node = self._ccbOwner.ccb_attentionAnimationNode
            node:setVisible(true)
            local animationManager = tolua.cast(node:getUserObject(), "CCBAnimationManager")
            animationManager:runAnimationsForSequenceNamed("attention")
            self._isAttentionAnimationPlaying = true
        elseif precent >= 0.2 and self._isAttentionAnimationPlaying == true then
            local node = self._ccbOwner.ccb_attentionAnimationNode
            local animationManager = tolua.cast(node:getUserObject(), "CCBAnimationManager")
            animationManager:runAnimationsForSequenceNamed("normal")
            node:setVisible(false)
            self._isAttentionAnimationPlaying = false
        end
    end

end

function QHeroStatusView:onCpChanged(event)
    if self._labelCombo then
        self._labelCombo:setString(string.format("%d 连击点数", self._hero:getComboPoints()))
    end

    if self._ccbOwner.sprite_combo_1 then
    	local cp = self._hero:getComboPoints()
    	self._ccbOwner.sprite_combo_1:setVisible(cp >= 1)
    	self._ccbOwner.sprite_combo_2:setVisible(cp >= 2)
    	self._ccbOwner.sprite_combo_3:setVisible(cp >= 3)
    	self._ccbOwner.sprite_combo_4:setVisible(cp >= 4)
    	self._ccbOwner.sprite_combo_5:setVisible(cp >= 5)
    end
end

function QHeroStatusView:onForceChanged(event)
    if event.forceAuto == true then
        self._ccbOwner.ccb_animationAutoSkill1:setVisible(true)
    else
        self._ccbOwner.ccb_animationAutoSkill1:setVisible(false)
    end
end

-- attention: skill distance is not considered in manual skill

function QHeroStatusView:_onClickSkillButton1()
    if app.battle:isPausedBetweenWave() == true then
        return
    end

    if app.battle:isPVPMode() and app.battle:isInArena() then
        app.tip:floatTip("竞技场中只能自动战斗！") 
        return
    end

	if self._skill1 ~= nil and self._hero:isDead() == false and self._skill1:isReadyAndConditionMet() and self._hero:canAttack(self._skill1) then
        if self._hero:isInBulletTime() == true then
            self._hero:inBulletTime(false)
            local heroView = app.scene:getActorViewFromModel(self._hero)
            heroView:setAnimationScale(1.0, "bullet_time")
        end
        self._hero:attack(self._skill1)
    end
end

function QHeroStatusView:_onClickHeroHead()
    if app.battle:isPausedBetweenWave() == true or (app.battle:isPVPMode() and app.battle:isInArena()) then
        return
    end
    
    if app.scene:uiSelectHero(self._hero) == true then
       printInfo("on ui select hero") 
    end
end

function QHeroStatusView:_onUseSkill(event)
    if event == nil or event.skill == nil then
        return
    end

    local skillNode = nil
    if event.skill == self._skill1 then
        skillNode = self._ccbOwner.ccb_animationSkill1
    end

    if skillNode ~= nil then
        local animationManager = tolua.cast(skillNode:getUserObject(), "CCBAnimationManager")
        if animationManager ~= nil then 
            animationManager:runAnimationsForSequenceNamed(global.ui_skill_icon_effect_release)
        end
    end
end

function QHeroStatusView:onSelectHero(hero)
    if self._hero == hero then
        if self._isChooseAnimationPlaying == false then
            self._ccbOwner.ccb_chooseAnimationNode:setVisible(true)
            local animationManager = tolua.cast(self._ccbOwner.ccb_chooseAnimationNode:getUserObject(), "CCBAnimationManager")
            animationManager:runAnimationsForSequenceNamed("choose")
            self._isChooseAnimationPlaying = true
        end
    else
        self._ccbOwner.ccb_chooseAnimationNode:setVisible(false)
        self._isChooseAnimationPlaying = false
    end
end

function QHeroStatusView:playCoolDownAnimation()
    if self._skill1 == nil or self._skill1:isReady() == true then
        return
    end

    if self._coolDownAnimatinoProxy ~= nil then
        self._coolDownAnimatinoProxy:disconnectAnimationEventSignal()
        self._coolDownAnimatinoProxy:release()
        self._coolDownAnimatinoProxy = nil
    end

    if self._nodeSkillCooling ~= nil then 
        self._nodeSkillCooling:setVisible(false)
    end

    self._ccbOwner.ccb_animationCoolDown:setVisible(true)
    local animationManager = tolua.cast(self._ccbOwner.ccb_animationCoolDown:getUserObject(), "CCBAnimationManager")
    animationManager:runAnimationsForSequenceNamed("cool_down")

    self._coolDownAnimatinoProxy = QCCBAnimationProxy:create()
    self._coolDownAnimatinoProxy:retain()
    self._coolDownAnimatinoProxy:connectAnimationEventSignal(animationManager, function()
        self._ccbOwner.ccb_animationCoolDown:setVisible(false)
        self._coolDownAnimatinoProxy:disconnectAnimationEventSignal()
        scheduler.performWithDelayGlobal(function()
            self._coolDownAnimatinoProxy:release()
            self._coolDownAnimatinoProxy = nil
        end, 0)
    end)
end

function QHeroStatusView:playCoolDownAnimation_red(time)
    if self._label_cooldown_red == nil then
        self._label_cooldown_red = CCLabelBMFont:create("", "font/FontCooltime_red.fnt")
        self._label_cooldown_red:setString(string.format("冷却时间+%d秒", time))
        self._ccbOwner.ccb_animationCoolDown:getParent():addChild(self._label_cooldown_red)
        self._label_cooldown_red:setPosition(self._ccbOwner.ccb_animationCoolDown:getPositionX(), self._ccbOwner.ccb_animationCoolDown:getPositionY())
    end

    local arr = CCArray:create()
    arr:addObject(CCFadeIn:create(0.1667))
    arr:addObject(CCDelayTime:create(1.0))
    arr:addObject(CCFadeOut:create(0.3333))
    self._label_cooldown_red:runAction(CCSequence:create(arr))
end

return QHeroStatusView
