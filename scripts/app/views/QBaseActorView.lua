--[[
    Class name QBaseActorView 
    Create by julian 
    This class is a base class of actor.
    Other actor class is inherit from this.
--]]

local QBaseActorView = class("QBaseActorView", function()
    return display.newNode()
end)

local QSkeletonViewController = import("..controllers.QSkeletonViewController")
local QActorHpView = import("..ui.battle.QActorHpView")
local QBaseEffectView = import(".QBaseEffectView")
local QSkill = import("..models.QSkill")
local QNotificationCenter = import("..controllers.QNotificationCenter")
local QStaticDatabase = import("..controllers.QStaticDatabase")
local QOneTrackView = import(".QOneTrackView")

QBaseActorView.DIRECTION_LEFT  = "left"
QBaseActorView.DIRECTION_RIGHT  = "right"

QBaseActorView.HIDE_CIRCLE = "HIDE_CIRCLE"
QBaseActorView.SOURCE_CIRCLE = "SOURCE_CIRCLE"
QBaseActorView.TARGET_CIRCLE = "TARGET_CIRCLE"
QBaseActorView.HEALTH_CIRCLE = "HEALTH_CIRCLE"

QBaseActorView.SELECT_EFFECT_SOURCE_FILE = "circle_hero_select"

--[[
    actor: actor object
--]]
function QBaseActorView:ctor(actor, skeletonView)
    self._actor = actor

    local actorScale = actor:getActorScale()

    self._direction = QBaseActorView.DIRECTION_LEFT
    self._firsttime_walking = true

    self._selectSourceCircle = QBaseEffectView.new(QBaseActorView.SELECT_EFFECT_SOURCE_FILE, nil, nil, {scale = actorScale, sizeRenderTexture = CCSize(96, 32)})
    self._selectSourceCircle:setScale(1.2)
    self:addChild(self._selectSourceCircle, -1)
    self._selectSourceCircle:setVisible(false)

    self._targetCircle = CCSprite:create(global.ui_actor_select_target)
    self._targetCircle:setScale(actorScale)
    self:addChild(self._targetCircle, -2)
    self._targetCircle:setVisible(false)

    self._targetHealthCircle = CCSprite:create(global.ui_actor_select_target_health)
    self._targetHealthCircle:setScale(actorScale)
    self:addChild(self._targetHealthCircle, -2)
    self._targetHealthCircle:setVisible(false)

    self._animationQueue = {}
    local skeletonViewController = QSkeletonViewController.sharedSkeletonViewController()
    self._skeletonActor = skeletonViewController:createSkeletonActorWithFile(actor:getActorFile())
    self._skeletonActor:setSkeletonScaleX(actorScale)
    self._skeletonActor:setSkeletonScaleY(actorScale)
    self:addChild(self._skeletonActor)

    local weaponFile = actor:getActorWeaponFile()
    if weaponFile ~= nil then
        local parentBone = self._skeletonActor:getParentBoneName(DUMMY.WEAPON)
        self._skeletonActor:replaceSlotWithFile(weaponFile, parentBone, ROOT_BONE, EFFECT_ANIMATION)
    end
    
    self._currentAnimation = nil

    self._buffEffects = {}
    self._skillAttackEffects = {}
    self._skillLoopEffects = {}
    self._skillEffectsTimeStop = {}

    self._hpView = QActorHpView.new(actor)

    -- cache for future use
    local width = self:getModel():getSelectRectWidth()
    local height = self:getModel():getSelectRectHeight()
    local rect = CCRectMake(-width*0.5, 0, width, height)
    if actorScale ~= 1.0 then
        rect.origin.x = rect.origin.x * actorScale
        rect.size.width = rect.size.width * actorScale
        rect.size.height = rect.size.height * actorScale
    end
    self:setSize( CCSizeMake(width * actorScale, height * actorScale) )
    self._actor:setRect(rect)
    local coreScale = 0.8
    local coreRect = CCRectMake(rect.origin.x * coreScale, 0, rect.size.width * coreScale, rect.size.height * coreScale)
    self._actor:setCoreRect(coreRect)

    self._hpView:setPosition(0, self:getSize().height)
    self:addChild(self._hpView)

    self:setNodeEventEnabled(true)

    self._actorEventProxy = cc.EventProxy.new(actor, self)
    self._actorEventProxy:addEventListener(actor.CHANGE_STATE_EVENT, handler(self, self._onStateChanged))
    self._actorEventProxy:addEventListener(actor.ATTACK_EVENT, handler(self, self._onAttack))
    self._actorEventProxy:addEventListener(actor.UNDER_ATTACK_EVENT, handler(self, self._onHit))
    self._actorEventProxy:addEventListener(actor.HP_CHANGED_EVENT, handler(self, self._onHpChanged))
    self._actorEventProxy:addEventListener(actor.SET_POSITION_EVENT, handler(self, self._onPositionChanged))
    self._actorEventProxy:addEventListener(actor.MOVE_EVENT, handler(self, self._onMove))
    self._actorEventProxy:addEventListener(actor.BUFF_STARTED, handler(self, self._onBuffStarted))
    self._actorEventProxy:addEventListener(actor.BUFF_ENDED, handler(self, self._onBuffEnded))
    self._actorEventProxy:addEventListener(actor.PLAY_SKILL_ANIMATION, handler(self, self._onChangeAnimationForSkill))
    self._actorEventProxy:addEventListener(actor.PLAY_SKILL_EFFECT, handler(self, self._onPlayEffectForSkill))
    self._actorEventProxy:addEventListener(actor.STOP_SKILL_EFFECT, handler(self, self._onRemoveEffectForSkill))
    self._actorEventProxy:addEventListener(actor.CANCEL_SKILL, handler(self, self._onSkillCancel))

    self._isKeepAnimation = false
    if skeletonView ~= nil then
        local animation = skeletonView:getCurrentAnimationName()
        local time = skeletonView:getCurrentAnimationTime()
        if animation ~= nil then
            self._animationQueue = {animation}
            self:_changeAnimation()
            self._skeletonActor:updateAnimation(time)
        end
    else
        self._animationQueue = {ANIMATION.STAND}
        self:_changeAnimation()
    end

    self._colorOverlay = display.COLOR_WHITE

    self._lastTipTime = app.battle:getTime() --上次显示伤害数值的时间，不要设置为0，因为os.clock可能返回负值（在小米2A上出现的问题）

    if DISPLAY_ACTOR_MOVE then
        self._moveDirection = CCDrawNode:create()
        self:addChild(self._moveDirection)
    end

    self._oneTrackView = QOneTrackView.new(actor)
    self._oneTrackView:setPosition(0, self:getSize().height + 20)
    self:addChild(self._oneTrackView)

    if skeletonView ~= nil then
        skeletonView:release()
    end

    self._waitingHitTips = {}

    self._scales = {}
end

function QBaseActorView:getModel()
    return self._actor
end

function QBaseActorView:getSkeletonActor()
    return self._skeletonActor
end

function QBaseActorView:onEnter()
    if app.battle:isPVPMode() == true then
        local effectID = nil
        if self:getModel():getType() == ACTOR_TYPES.HERO then
            effectID = global.alliance_arena_flag_effect
        else
            effectID = global.horde_arena_flag_effect
        end
        local frontEffect, backEffect = QBaseEffectView.createEffectByID(effectID, self)
        -- ignore frontEffect
        local dummy = (QStaticDatabase.sharedDatabase():getEffectDummyByID(effectID) or DUMMY.BODY)
        local isFlipWithActor = QStaticDatabase.sharedDatabase():getEffectIsFlipWithActorByID(effectID)
        if backEffect ~= nil then
            self:attachEffectToDummy(dummy, backEffect, true, isFlipWithActor)
            backEffect:playAnimation(EFFECT_ANIMATION, true)
            self._flagEffect = backEffect
        end
    end

    self._skeletonActor:connectAnimationEventSignal(handler(self, self._onSkeletonActorAnimationEvent))
    -- 注册帧事件
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()

    -- local maskRect = CCRect(-200, -200, 400, 500)
    -- self:setScissorEnabled(true)
    -- self:setScissorRects(
    --     maskRect,
    --     CCRect(0, 0, 0, 0),
    --     CCRect(0, 0, 0, 0),
    --     CCRect(0, 0, 0, 0)
    -- )
    -- local func = ccBlendFunc()
    -- func.src = GL_DST_ALPHA
    -- func.dst = GL_DST_ALPHA
    -- self:setScissorBlendFunc(func)
    -- self:setScissorColor(ccc3(255, 255, 255))
    -- self:setScissorOpacity(0)
    -- func.src = GL_SRC_ALPHA
    -- func.dst = GL_ONE_MINUS_SRC_ALPHA
    -- self:setRenderTextureBlendFunc(func)
    -- self:setOpacityActor(16)
end

function QBaseActorView:onExit()
    if app.battle:isPVPMode() == true and self._flagEffect ~= nil then
        self._skeletonActor:detachNodeToBone(self._flagEffect)
    end

    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
    self:unscheduleUpdate()
    self._skeletonActor:disconnectAnimationEventSignal()
end

function QBaseActorView:onCleanup()
    QSkeletonViewController.sharedSkeletonViewController():removeSkeletonActor(self._skeletonActor)
    
    self._selectSourceCircle:removeFromParent()
    self._targetCircle:removeFromParent()
    self._targetHealthCircle:removeFromParent()
    self._skeletonActor:removeFromParent()
    self._hpView:removeFromParent()
    self._oneTrackView:removeFromParent()
end

function QBaseActorView:setSize(size)
    self._size = size
end

function QBaseActorView:getSize()
    return self._size
end

function QBaseActorView:setIsKeepAnimation(isKeepAnimation)
    if isKeepAnimation == nil then
        isKeepAnimation = false
    end
    self._isKeepAnimation = isKeepAnimation
end

function QBaseActorView:visibleSelectCircle(circleMode)
    if circleMode ~= QBaseActorView.HEALTH_CIRCLE then
        self._selectSourceCircle:setVisible(false)
    end
    self._targetCircle:setVisible(false)
    self._targetHealthCircle:setVisible(false)

    if circleMode == QBaseActorView.SOURCE_CIRCLE then
        self._selectSourceCircle:setVisible(true)
        self._selectSourceCircle:playAnimation(EFFECT_ANIMATION)

    elseif circleMode == QBaseActorView.TARGET_CIRCLE then
        self._targetCircle:setVisible(true)
        self._targetCircle:stopAllActions()
        self._targetCircle:setScale(0)

        local arr = CCArray:create()
        arr:addObject(CCScaleTo:create(0.1, 2.5))
        arr:addObject(CCScaleTo:create(0.05, 2))
        self._targetCircle:runAction(CCSequence:create(arr))

    elseif circleMode == QBaseActorView.HEALTH_CIRCLE then
        self._targetHealthCircle:setVisible(true)
        self._targetHealthCircle:stopAllActions()
        self._targetHealthCircle:setScale(0)

        local arr = CCArray:create()
        arr:addObject(CCScaleTo:create(0.1, 2.5))
        arr:addObject(CCScaleTo:create(0.05, 2))
        self._targetHealthCircle:runAction(CCSequence:create(arr))
    end
end

function QBaseActorView:invisibleSelectCircle(circleMode)
    if circleMode == QBaseActorView.TARGET_CIRCLE then
        self._targetCircle:setVisible(true)
        self._targetCircle:stopAllActions()
        self._targetCircle:setScale(2)
        self._targetCircle:runAction(CCScaleTo:create(0.1, 0))

    elseif circleMode == QBaseActorView.HEALTH_CIRCLE then
        self._targetHealthCircle:setVisible(true)
        self._targetHealthCircle:stopAllActions()
        self._targetHealthCircle:setScale(2)
        self._targetHealthCircle:runAction(CCScaleTo:create(0.1, 0, 0))
    end
end

function QBaseActorView:displayHpView()
    if self._actor:getHp() >= 0 and self._actor:isDead() == false then
        self._hpView:update(self._actor:getHp()/self._actor:getMaxHp())
    end
end

function QBaseActorView:_checkReverse()
    if self._actor:getState() == "walking" and self._actor:getTarget() ~= nil and self._actor:getTarget():isDead() == false 
        and table.find(app.battle:getMyEnemies(self._actor), self._actor:getTarget()) 
        and self._actor:getCurrentSkill() == nil then

        if self._actor:getTalentSkill():isRemoteSkill() == false then
            if self._actor:getManualMode() ~= self._actor.STAY then
                if self._actor.gridPos then
                    local distance = q.distOf2Points(self._actor:getTarget():getPosition(), app.grid:_toScreenPos(self._actor.gridPos))
                    local left_distance = q.distOf2Points(self._actor:getPosition(), app.grid:_toScreenPos(self._actor.gridPos))
                    if left_distance < 1.414 * distance then
                        if self:getModel():isReverseWalk() == false then
                            self:_verifyFlip()
                            self:_playWalkingAnimation()
                            return true
                        end
                    end
                end
            elseif self._actor:getTargetPosition() then 
                local actor = self._actor
                local target = self._actor:getTarget()
                local talentSkill = actor:getTalentSkill()
                if talentSkill then
                    local actorWidth = actor:getRect().size.width / 2
                    local targetWidth = target:getRect().size.width / 2
                    local _, skillRange = talentSkill:getSkillRange(false)

                    local dx = math.abs(actor:getTargetPosition().x - target:getPosition().x)
                    local dy = math.abs(actor:getTargetPosition().y - target:getPosition().y)

                    if dx - actorWidth - targetWidth < skillRange and dy < skillRange * 0.6 then
                        local distance = q.distOf2Points(self._actor:getTarget():getPosition(), self._actor:getTargetPosition())
                        local left_distance = q.distOf2Points(self._actor:getPosition(), self._actor:getTargetPosition())
                        if left_distance < 1.414 * distance then
                            if self:getModel():isReverseWalk() == false then
                                self:_verifyFlip()
                                self:_playWalkingAnimation()
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
end

function QBaseActorView:_onFrame(dt)
    if self._actor:isInTimeStop() then
        return
    end

    dt = dt * app.battle:getTimeGear()

    self:_checkReverse()

    if DISPLAY_ACTOR_MOVE then
        if self._moveDirection and self:getModel():isWalking() then
            self._moveDirection:clear()
            local to = self._actor:getTargetPosition()
            if to ~= nil then
                local x, y = self:getPosition()
                self._moveDirection:drawSegment(ccp(0,0), ccp(to.x - x, to.y - y), 3, ccc4f(1, 0, 0, 0.5))
            end
        end
    end

    self:updateSprint(dt)

    for _, v in ipairs(self._buffEffects) do
        if v.isGroundEffect then
            if v.front_effect then
                v.front_effect:setPosition(self:getPosition())
            end
            if v.back_effect then
                v.back_effect:setPosition(self:getPosition())
            end
        end
    end
end

function QBaseActorView:_onAttack(event)
    -- play the attack animation of the actor for the specified skill
    self:_verifyFlip()

    if event.skill:getSkillType() == QSkill.MANUAL 
        and self._skeletonActor:isHitAnimationPlaying() == true then
        self._skeletonActor:stopHitAnimation()
    end
end

function QBaseActorView:_onHit(event)
    if event.tip == "0" then return end
    
    local font = global.ui_hp_change_font_damage_hero
    if self:getModel():getType() == ACTOR_TYPES.NPC then
        font = global.ui_hp_change_font_damage_npc
    end
    if event.isTreat == false then
        if DISPLAY_HIT_ANIMATION == true
            and self:getModel():isDead() == false  
            and self:getModel():isWalking()== false 
            and self._skeletonActor:isHitAnimationPlaying() == false
            and self._isKeepAnimation == false then

            if self:getModel():getCurrentSkill() == nil 
                or self:getModel():getCurrentSkill():getSkillType() ~= QSkill.MANUAL then

                if app.battle:isInBulletTime() == false then
                    self._skeletonActor:playHitAnimation(ANIMATION.HIT)
                end
            end
        end

        local arr = CCArray:create()
        arr:addObject(CCTintTo:create(0.1, 255, 100, 100))
        arr:addObject(CCTintTo:create(0.1, self._colorOverlay.r, self._colorOverlay.g, self._colorOverlay.b))
        self._skeletonActor:runAction(CCSequence:create(arr))
    else
        font = global.ui_hp_change_font_treat
    end

    local tip = nil
    local ccbOwner = {}
    local appearDistance = 20 -- 伤害数字向上移动出现的距离
    if event.isCritical then
        if event.isTreat then
            -- tip = CCBuilderReaderLoad("effects/Attack_shanbi.ccbi", CCBProxy:create(), ccbOwner):addTo(self)
            tip = app.scene:getTip("effects/Attack_shanbi.ccbi"):addTo(self)
            ccbOwner = tip.ccbOwner
            tip:setPosition(0, self:getSize().height - appearDistance)
       else
            if self:getModel():getType() == ACTOR_TYPES.NPC then
                -- tip = CCBuilderReaderLoad("effects/Attack_Ybaoji.ccbi", CCBProxy:create(), ccbOwner):addTo(self)
                tip = app.scene:getTip("effects/Attack_Ybaoji.ccbi"):addTo(self)
                ccbOwner = tip.ccbOwner
            else
                -- tip = CCBuilderReaderLoad("effects/Attack_baoji.ccbi", CCBProxy:create(), ccbOwner):addTo(self)
                tip = app.scene:getTip("effects/Attack_baoji.ccbi"):addTo(self)
                ccbOwner = tip.ccbOwner
            end
        end
        tip:setPosition(-10, self:getSize().height)
    else
        if event.isTreat then
            -- tip = CCBuilderReaderLoad("effects/Heal_number.ccbi", CCBProxy:create(), ccbOwner):addTo(self)
            tip = app.scene:getTip("effects/Heal_number.ccbi"):addTo(self)
            ccbOwner = tip.ccbOwner
            tip:setScale(0.8)
        else
            if string.find(event.tip, "闪避") then
                if self:getModel():getType() == ACTOR_TYPES.NPC then
                    -- tip = CCBuilderReaderLoad("effects/Attack_Ynumber.ccbi", CCBProxy:create(), ccbOwner):addTo(self)
                tip = app.scene:getTip("effects/Attack_Ynumber.ccbi"):addTo(self)
                ccbOwner = tip.ccbOwner
                    tip:setScale(0.8)
                else
                    -- tip = CCBuilderReaderLoad("effects/Attack_shanbi.ccbi", CCBProxy:create(), ccbOwner):addTo(self)
                tip = app.scene:getTip("effects/Attack_shanbi.ccbi"):addTo(self)
                ccbOwner = tip.ccbOwner
                end
            else
                if self:getModel():getType() == ACTOR_TYPES.NPC then
                    -- tip = CCBuilderReaderLoad("effects/Attack_Ynumber.ccbi", CCBProxy:create(), ccbOwner):addTo(self)
                tip = app.scene:getTip("effects/Attack_Ynumber.ccbi"):addTo(self)
                ccbOwner = tip.ccbOwner
                else
                    -- tip = CCBuilderReaderLoad("effects/Attack_number.ccbi", CCBProxy:create(), ccbOwner):addTo(self)
                tip = app.scene:getTip("effects/Attack_number.ccbi"):addTo(self)
                ccbOwner = tip.ccbOwner
                end
                tip:setScale(0.8)
            end
        end
        tip:setPosition(0, self:getSize().height - appearDistance)
    end
    ccbOwner.var_text:setString(event.tip)

    local appearTime = 0.2 -- 冒伤害数字的时间
    local stayTimeScale = 0.2 -- 数字的停留时间
    local stayTimeDelay = 0.1 -- 数字的停留时间
    local elapseTime = 0.5 -- 伤害数字的消失时间

    -- 计算上一次伤害到这一次伤害数字冒出需要等待的时间，避免重复
    local wait = stayTimeScale + stayTimeDelay - (app.battle:getTime() - self._lastTipTime)

    local sequence = CCArray:create()

    if wait < 0 then
        wait = 0
    elseif wait > 0 then
        self._waitingHitTips[tip] = tip
        sequence:addObject(CCDelayTime:create(wait))
        sequence:addObject(CCCallFunc:create(
            function()
                self._waitingHitTips[tip] = nil
            end))
    end
    self._lastTipTime = app.battle:getTime() + wait

    tip:setVisible(false)

    sequence:addObject(CCCallFunc:create(
        function ()
        tip:setVisible(true)
        local animationProxy = QCCBAnimationProxy:create()
        animationProxy:retain()
        local animationManager = tolua.cast(tip:getUserObject(), "CCBAnimationManager")
        animationManager:runAnimationsForSequenceNamed("Default Timeline")
        animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
            animationProxy:disconnectAnimationEventSignal()
            animationProxy:release()
            tip:removeFromParent()
            if tip.need_return then
                if app.scene then
                    app.scene:returnTip(tip)
                else
                    tip:release()
                end
            end
            -- CCRemoveSelf:create(true)
        end)
    end))
   
    tip:runAction(CCSequence:create(sequence))
end

function QBaseActorView:_onStateChanged(event)
    -- printf("=================QBaseActorView %s: state change from %s to %s", self:getModel():getId(), event.from, event.to)
    if event.to == "idle" then
        self._animationQueue = {ANIMATION.STAND}
        self:_changeAnimation()
        self:_verifyFlip()
    elseif event.to == "walking" then
        -- self:_playWalkingAnimation()
    elseif event.to == "dead" then
        self:_removeAllEffectForSkill()
        self._hpView:setVisible(false)
        self:stopAllActions()

        for _, tip in pairs(self._waitingHitTips) do
            tip:cleanup()
            tip:removeFromParent()
        end
        self._waitingHitTips = {}

        if self._isKeepAnimation == true then
            self._isKeepAnimation = false
            self._skeletonActor:resetActorWithAnimation(ANIMATION.DEAD, false)
        else
            self._animationQueue = {ANIMATION.DEAD}
            self:_changeAnimation()
        end

        -- 死亡音效
        local actor_display = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self:getModel():getActorID())
        if actor_display and actor_display.dead then
            audio.playSound( actor_display.dead, false)
            local front, back = QBaseEffectView.createEffectByID(actor_display.dead)
            local view = front or back
            if view then view:playSoundEffect() end
        end
        
    elseif event.to == "victorious" then
        self._hpView:setVisible(false)
        self:stopAllActions()
        self._animationQueue = {ANIMATION.VICTORY, ANIMATION.STAND}
        self:_changeAnimation()
        self:_playVictoryEffect()
        self._victory = true
    end
end

function QBaseActorView:_onHpChanged(event)
    self:displayHpView()
end

function QBaseActorView:_onPositionChanged(event)
    if event.position ~= nil then
        self:setPosition(event.position.x, event.position.y)
    end 
end

function QBaseActorView:_onMove(event)
    if event.from == nil then
        event.from = self._actor:getPosition()
    end

    local deltaX = event.to.x - event.from.x
    local deltaY = event.to.y - event.from.y

    if self._direction == QBaseActorView.DIRECTION_LEFT and deltaX > EPSILON then
        self:_setFlipX()
    elseif self._direction == QBaseActorView.DIRECTION_RIGHT and deltaX < -EPSILON then
        self:_setFlipX()
    end

    if not self:_checkReverse() then
        self:_playWalkingAnimation()
    end
end

function QBaseActorView:_verifyFlip()
    if not self._actor:isMovable() then
        return
    end
    if self._actor:getTarget() == nil then
        return
    end
    if self._actor:getTarget() == self._actor then
        return
    end

    local dx = self._actor:getPosition().x - self._actor:getTarget():getPosition().x
    if dx < EPSILON then
        if self._direction == QBaseActorView.DIRECTION_LEFT then
            self:_setFlipX()
        end
    elseif dx > EPSILON then
        if self._direction == QBaseActorView.DIRECTION_RIGHT then
            self:_setFlipX()
        end
    end
end

function QBaseActorView:_playWalkingAnimation()
    local actor = self._actor
    local self_pos = actor:getPosition()
    local target_pos = actor:getTargetPosition()

    if self._firsttime_walking == true or target_pos == nil or target_pos.x - self_pos.x == 0 or ((target_pos.x - self_pos.x < 0) == (self._direction == QBaseActorView.DIRECTION_LEFT)) then
        self._animationQueue = {ANIMATION.WALK}
        self._firsttime_walking = false
    else
        self._animationQueue = {ANIMATION.REVERSEWALK}
    end
    self:_changeAnimation()
end

function QBaseActorView:_onSkeletonActorAnimationEvent(eventType, trackIndex, animationName, loopCount)
    if eventType == SP_ANIMATION_END or eventType == SP_ANIMATION_COMPLETE then
        self:getModel():onAnimationEnded(eventType, trackIndex, animationName, loopCount)
    end

    if eventType == SP_ANIMATION_END or eventType == SP_ANIMATION_COMPLETE then
        
    elseif eventType == SP_ANIMATION_START then
        self._currentAnimation = animationName
    end
    
end

function QBaseActorView:_changeAnimation(isLoop)
    if self._isKeepAnimation == true then
        return
    end

    if table.nums(self._animationQueue) == 0 then
        return
    end

    -- stand and walk is loop
    if self._animationQueue[1] == self._currentAnimation 
        and (self._currentAnimation == ANIMATION.STAND or self._currentAnimation == ANIMATION.WALK or self._currentAnimation == ANIMATION.REVERSEWALK) then
        return
    end

    if self:getModel():getTalentFunc() == "" or self:getModel():getTalentFunc() == nil then
        local _animation = self._animationQueue[1]
        if _animation == ANIMATION.STAND then
            -- printInfo("==================ANIMATION.STAND==================")
        elseif _animation == ANIMATION.WALK then
            -- printInfo("==================ANIMATION.WALK==================")
        elseif _animation == ANIMATION.REVERSEWALK then
            -- printInfo("==================ANIMATION.REVERSEWALK==================")
        elseif _animation == ANIMATION.ATTACK then
            -- printInfo("==================ANIMATION.ATTACK==================")
        end
    end

    for i, animation in ipairs(self._animationQueue) do
        local isLoop = (isLoop or animation == ANIMATION.STAND or animation == ANIMATION.WALK or animation == ANIMATION.REVERSEWALK)
        if i == 1 then
            self._skeletonActor:playAnimation(animation, isLoop)
        else
            self._skeletonActor:appendAnimation(animation, isLoop)
        end
    end
end

function QBaseActorView:_onChangeAnimationForSkill(event)
    self._animationQueue = event.animations
    self:_changeAnimation(event.isLoop)
end

-- use for leave battle scene 
function QBaseActorView:changToWalkAnimationAndRightDirection()
    if self._direction == QBaseActorView.DIRECTION_LEFT then
        self:_setFlipX()
    end

    self._animationQueue = {ANIMATION.WALK}
    self:_changeAnimation(true)
end

function QBaseActorView:_onPlayEffectForSkill(event)
    if event == nil then
        return
    end

    local effectID = event.effectID
    if effectID == nil then
        return
    end

    local options = {}
    if event.options.rotateToPosition ~= nil then
        local positionX, positionY = self:getPosition()
        local dummy = QStaticDatabase.sharedDatabase():getEffectDummyByID(effectID)
        if dummy == DUMMY.BOTTOM or dummy == DUMMY.TOP or dummy == DUMMY.CENTER then
            dummy = nil
        end
        local bonePosition = self:getSkeletonActor():getBonePosition(dummy)
        positionX = positionX + bonePosition.x
        positionY = positionY + bonePosition.y
        local deltaX = event.options.rotateToPosition.x - positionX
        local deltaY = event.options.rotateToPosition.y - positionY
        options.externalRotate = math.deg(-1.0*math.atan2(deltaY, deltaX))
    end

    options.time_scale = event.options.time_scale

    local frontEffect = nil
    local backEffect = nil
    frontEffect, backEffect = QBaseEffectView.createEffectByID(effectID, self, QBaseEffectView, options)

    if event.options.isRandomPosition == true then
        local size = self:getModel():getCoreRect().size
        local deltaX = math.random(math.floor(size.width * 0.8)) - size.width * 0.8 * 0.5
        local deltaY = math.random(math.floor(size.height * 0.8)) - size.height * 0.8 * 0.5
        if frontEffect ~= nil and frontEffect:getSkeletonView() ~= nil then
            local positionX, positionY = frontEffect:getSkeletonView():getPosition()
            positionX = positionX + deltaX
            positionY = positionY + deltaY
            frontEffect:getSkeletonView():setPosition(positionX, positionY)
        end
        if backEffect ~= nil and backEffect:getSkeletonView() ~= nil then
            local positionX, positionY = backEffect:getSkeletonView():getPosition()
            positionX = positionX + deltaX
            positionY = positionY + deltaY
            backEffect:getSkeletonView():setPosition(positionX, positionY)
        end
    end

    if frontEffect ~= nil then
        self:_attachEffectForSkill(event, frontEffect, false)
    end
    if backEffect ~= nil then
        self:_attachEffectForSkill(event, backEffect, true)
    end
end

function QBaseActorView:_attachEffectForSkill(event, effect, isAtBackSide)
    if event == nil or effect == nil then
        return
    end

    local effectID = event.effectID
    if effectID == nil then
        return
    end

    if event.options.isFlipX == true then
        local scale = effect:getScale()
        scale = scale * -1
        effect:setScaleX(scale)
    end

    -- attack to dummy
    local dummy = QStaticDatabase.sharedDatabase():getEffectDummyByID(effectID)
    local isFlipWithActor = QStaticDatabase.sharedDatabase():getEffectIsFlipWithActorByID(effectID)
    if event.options.targetPosition == nil and dummy ~= nil then
        self:attachEffectToDummy(dummy, effect, isAtBackSide, isFlipWithActor)
    else
        if event.options.targetPosition ~= nil then
            effect:setPosition(event.options.targetPosition.x, event.options.targetPosition.y)
        else
            effect:setPosition(self:getPosition())
        end
        app.scene:addEffectViews(effect)
    end

    -- play animation and sound
    effect:playAnimation(EFFECT_ANIMATION, event.options.isLoop or false)
    effect:playSoundEffect(false)

    -- callback when animation complete
    
    if event.options.isLoop == true then
        table.insert(self._skillLoopEffects, {effectId = effectID, effect = effect, dummy = dummy, func = func})
    else
        local func = event.callFunc
        local isAttackEffect = event.options.isAttackEffect
        local skillId = event.options.skillId
        if isAttackEffect == true then
            if self._skillAttackEffects[skillId] == nil then
                self._skillAttackEffects[skillId] = {}
            end
            table.insert(self._skillAttackEffects[skillId], effect)
        end
        effect:afterAnimationComplete(function()
            if not self._skillAttackEffects then
                if dummy ~= nil then
                    app.scene:removeEffectViews(effect)
                    if func ~= nil then
                        func()
                    end
                    return
                end
            end
            if isAttackEffect == true then
                for i, attackEffect in ipairs(self._skillAttackEffects[skillId]) do
                    if effect == attackEffect then
                        table.remove(self._skillAttackEffects[skillId], i)
                        break
                    end
                end
            end

            if dummy ~= nil then
                if self.getSkeletonActor and self:getSkeletonActor() ~= nil then self:getSkeletonActor():detachNodeToBone(effect) end
            else
                app.scene:removeEffectViews(effect)
            end

            if func ~= nil then
                func()
            end
        end)
    end

    if event.options.followActorAnimation then
        effect:setFollowActor(self._actor)
    end
end

function QBaseActorView:_onSkillCancel(event)
    local skillId = event.skillId
    if self._skillAttackEffects[skillId] ~= nil then
        while(table.nums(self._skillAttackEffects[skillId]) > 0) do
            local effect = self._skillAttackEffects[skillId][1]
            if effect ~= nil and effect.stopAnimation ~= nil then effect:stopAnimation() end
        end
    end
end

function QBaseActorView:_onRemoveEffectForSkill(event)
    if event == nil then
        return
    end

    local effectID = event.effectID
    if effectID == nil then
        return
    end

    local index = 1
    while index > 0 do
        index = 0
        for i, skillEffect in ipairs(self._skillLoopEffects) do
            if skillEffect.effectId == effectID then
                index = i
                break
            end
        end
        if index > 0 then
            local skillEffect = self._skillLoopEffects[index]
            if skillEffect.effect ~= nil then
                skillEffect.effect:stopAnimation()
                if skillEffect.dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(skillEffect.effect)
                else
                    app.scene:removeEffectViews(skillEffect.effect)
                end
                if skillEffect.func ~= nil then
                    skillEffect.func()
                end
            end
            table.remove(self._skillLoopEffects, index)
        end
    end
end

function QBaseActorView:_removeAllEffectForSkill()
    while table.nums(self._skillLoopEffects) > 0 do
        self:_onRemoveEffectForSkill({effectID = self._skillLoopEffects[1].effectId})
    end
end

--[[
    set actor flipX.
--]]

function QBaseActorView:isFlipX()
    return (self._direction == QBaseActorView.DIRECTION_RIGHT)
end

function QBaseActorView:_setFlipX()
    if self._victory == true and self._direction == QBaseActorView.DIRECTION_RIGHT then
        return
    end

    self._skeletonActor:flipActor()
    if self._direction == QBaseActorView.DIRECTION_LEFT then
        self._direction = QBaseActorView.DIRECTION_RIGHT
    else
        self._direction = QBaseActorView.DIRECTION_LEFT
    end
end

function QBaseActorView:setDirection(direction)
    if direction ~= QBaseActorView.DIRECTION_LEFT and direction ~= QBaseActorView.DIRECTION_RIGHT then
        return
    end

    if self._direction == direction then
        return
    else
        self:_setFlipX()
    end

end

function QBaseActorView:getDirection()
    return self._direction
end

function QBaseActorView:_onBuffStarted(event)
    local buff = event.buff
    if buff == nil then
        return
    end

    if buff:isImmuned() then
        return
    end

    -- play begin effect
    local effectID = buff:getBeginEffectID()
    if effectID ~= nil and event.replace ~= true then
        local frontEffect, backEffect = QBaseEffectView.createEffectByID(effectID, self)
        local dummy = (QStaticDatabase.sharedDatabase():getEffectDummyByID(effectID) or DUMMY.BODY)
        local isFlipWithActor = QStaticDatabase.sharedDatabase():getEffectIsFlipWithActorByID(effectID)
        if frontEffect ~= nil then
            self:attachEffectToDummy(dummy, frontEffect, false, isFlipWithActor)
            frontEffect:playAnimation(EFFECT_ANIMATION, false)
            frontEffect:playSoundEffect(false)
            frontEffect:afterAnimationComplete(function()
                if dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(frontEffect)
                else
                    app.scene:removeEffectViews(frontEffect)
                end
            end)
        end
        if backEffect ~= nil then
            self:attachEffectToDummy(dummy, backEffect, true, isFlipWithActor)
            backEffect:playAnimation(EFFECT_ANIMATION, false)
            backEffect:afterAnimationComplete(function()
                if dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(backEffect)
                else
                    app.scene:removeEffectViews(backEffect)
                end
            end)
        end
    end  
    
    local effectID = buff:getEffectID()
    if effectID ~= nil then
        local frontEffect, backEffect = QBaseEffectView.createEffectByID(effectID, self)
        local dummy = (QStaticDatabase.sharedDatabase():getEffectDummyByID(effectID) or DUMMY.BODY)
        local isFlipWithActor = QStaticDatabase.sharedDatabase():getEffectIsFlipWithActorByID(effectID)
        local isGroundEffect = QStaticDatabase.sharedDatabase():getEffectIsLayOnTheGroundByID(effectID)
        if (dummy == DUMMY.BOTTOM or dummy == DUMMY.TOP or dummy == DUMMY.CENTER) and isGroundEffect then -- on the ground
            local actorScale = self:getModel():getActorScale()
            if frontEffect and frontEffect:getSkeletonView() ~= nil then
                local skeletonPositionX, skeletonPositionY = frontEffect:getSkeletonView():getPosition()
                if dummy == DUMMY.TOP then
                    if isFlipWithActor == true then
                        skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height / actorScale
                    else
                        skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height
                    end
                elseif dummy == DUMMY.CENTER then
                    if isFlipWithActor == true then
                        skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height * 0.5 / actorScale
                    else
                        skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height * 0.5
                    end
                end
                frontEffect:getSkeletonView():setPosition(skeletonPositionX, skeletonPositionY)
                app.scene:addEffectViews(frontEffect, {isGroundEffect = isGroundEffect})
                frontEffect:setPosition(self:getPosition())
                frontEffect:playAnimation(EFFECT_ANIMATION, true)
                frontEffect:playSoundEffect(true)
            end
            if backEffect and backEffect:getSkeletonView() ~= nil then
                local skeletonPositionX, skeletonPositionY = backEffect:getSkeletonView():getPosition()
                if dummy == DUMMY.TOP then
                    if isFlipWithActor == true then
                        skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height / actorScale
                    else
                        skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height
                    end
                elseif dummy == DUMMY.CENTER then
                    if isFlipWithActor == true then
                        skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height * 0.5 / actorScale
                    else
                        skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height * 0.5
                    end
                end
                backEffect:getSkeletonView():setPosition(skeletonPositionX, skeletonPositionY)
                app.scene:addEffectViews(backEffect, {isGroundEffect = isGroundEffect})
                backEffect:setPosition(self:getPosition())
                backEffect:playAnimation(EFFECT_ANIMATION, true)
            end
        else
            if frontEffect ~= nil then
                self:attachEffectToDummy(dummy, frontEffect, false, isFlipWithActor)
                frontEffect:playAnimation(EFFECT_ANIMATION, true)
                frontEffect:playSoundEffect(true)
            end
            if backEffect ~= nil then
                self:attachEffectToDummy(dummy, backEffect, true, isFlipWithActor)
                backEffect:playAnimation(EFFECT_ANIMATION, true)
            end
        end
        table.insert(self._buffEffects, {obj = buff, front_effect = frontEffect, back_effect = backEffect, isGroundEffect = isGroundEffect})
    end

    local color = buff:getColor()
    if color ~= nil then
        self._colorOverlay = color
        self._skeletonActor:runAction(CCTintTo:create(0.1, self._colorOverlay.r, self._colorOverlay.g, self._colorOverlay.b))
    end
end

function QBaseActorView:_onBuffTrigger(event)
    local buff = event.buff
    if buff == nil then
        return
    end

    if buff:isImmuned() or not buff:isAura() then
        return
    end

    local auraEffectID = buff:getAuraTargetEffectID()
    if auraEffectID ~= "" then
        local frontEffect, backEffect = QBaseEffectView.createEffectByID(auraEffectID, self)
        local dummy = (QStaticDatabase.sharedDatabase():getEffectDummyByID(auraEffectID) or DUMMY.BODY)
        local isFlipWithActor = QStaticDatabase.sharedDatabase():getEffectIsFlipWithActorByID(auraEffectID)
        if frontEffect ~= nil then
            self:attachEffectToDummy(dummy, frontEffect, false, isFlipWithActor)
            frontEffect:playAnimation(EFFECT_ANIMATION, false)
            frontEffect:playSoundEffect(true)
            frontEffect:afterAnimationComplete(function()
                if dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(frontEffect)
                else
                    app.scene:removeEffectViews(frontEffect)
                end
            end)
        end
        if backEffect ~= nil then
            self:attachEffectToDummy(dummy, backEffect, true, isFlipWithActor)
            backEffect:playAnimation(EFFECT_ANIMATION, false)
            backEffect:afterAnimationComplete(function()
                if dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(backEffect)
                else
                    app.scene:removeEffectViews(backEffect)
                end
            end)
        end
        table.insert(self._buffEffects, {obj = buff, front_effect = frontEffect, back_effect = backEffect})
    end

    -- local color = buff:getColor()
    -- if color ~= nil then
    --     self._colorOverlay = color
    --     self._skeletonActor:runAction(CCTintTo:create(0.1, self._colorOverlay.r, self._colorOverlay.g, self._colorOverlay.b))
    -- end
end

function QBaseActorView:_onBuffEnded(event)
    local buff = event.buff
    if buff == nil then
        return
    end
    
    if buff:isImmuned() then
        return
    end

    for i, v in ipairs(self._buffEffects) do
        if v.obj == buff then
            if v.isGroundEffect then
                if v.front_effect ~= nil then
                    v.front_effect:stopSoundEffect()
                    app.scene:removeEffectViews(v.front_effect)
                end
                if v.back_effect ~= nil then
                    app.scene:removeEffectViews(v.back_effect)
                end
            else
                if v.front_effect ~= nil then
                    v.front_effect:stopSoundEffect()
                    self._skeletonActor:detachNodeToBone(v.front_effect)
                end
                if v.back_effect ~= nil then
                    self._skeletonActor:detachNodeToBone(v.back_effect)
                end
            end
            table.remove(self._buffEffects, i)
            break
        end
    end

    local color = buff:getColor()
    if color ~= nil then
        self._colorOverlay = display.COLOR_WHITE
        self._skeletonActor:runAction(CCTintTo:create(0.1, self._colorOverlay.r, self._colorOverlay.g, self._colorOverlay.b))
    end

    -- play finish effect
    local effectID = buff:getFinishEffectID()
    if effectID ~= nil then
        local frontEffect, backEffect = QBaseEffectView.createEffectByID(effectID, self)
        local dummy = (QStaticDatabase.sharedDatabase():getEffectDummyByID(effectID) or DUMMY.BODY)
        local isFlipWithActor = QStaticDatabase.sharedDatabase():getEffectIsFlipWithActorByID(effectID)
        if frontEffect ~= nil then
            self:attachEffectToDummy(dummy, frontEffect, false, isFlipWithActor)
            frontEffect:playAnimation(EFFECT_ANIMATION, false)
            frontEffect:playSoundEffect(false)
            frontEffect:afterAnimationComplete(function()
                if dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(frontEffect)
                else
                    app.scene:removeEffectViews(frontEffect)
                end
            end)
        end
        if backEffect ~= nil then
            self:attachEffectToDummy(dummy, backEffect, true, isFlipWithActor)
            backEffect:playAnimation(EFFECT_ANIMATION, false)
            backEffect:afterAnimationComplete(function()
                if dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(backEffect)
                else
                    app.scene:removeEffectViews(backEffect)
                end
            end)
        end
    end    
end

function QBaseActorView:attachEffectToDummy(dummy, effectView, isBackSide, isFlipWithActor)
    if effectView == nil then
        return
    end

    dummy = dummy or DUMMY.BOTTOM
    if dummy == DUMMY.BOTTOM or dummy == DUMMY.TOP or dummy == DUMMY.CENTER then
        self._skeletonActor:attachNodeToBone(nil, effectView, isBackSide, isFlipWithActor)
        local actorScale = self:getModel():getActorScale()
        if effectView:getSkeletonView() ~= nil then
            local skeletonPositionX, skeletonPositionY = effectView:getSkeletonView():getPosition()
            if dummy == DUMMY.TOP then
                if isFlipWithActor == true then
                    skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height / actorScale
                else
                    skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height
                end
            elseif dummy == DUMMY.CENTER then
                if isFlipWithActor == true then
                    skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height * 0.5 / actorScale
                else
                    skeletonPositionY = skeletonPositionY + self:getModel():getRect().size.height * 0.5
                end
            end
            effectView:getSkeletonView():setPosition(skeletonPositionX, skeletonPositionY)
        end
    else
        if self._skeletonActor:isBoneExist(dummy) == false then
            assert(false, "Bone node not found: <" .. dummy .. "> does not exist in the bone provided by <" .. self._actor:getDisplayID() .. "> (character_displa) provides. The effect is <" .. effectView._effectID .. ".".. effectView._frontAndBack .. ">")
        end
        self._skeletonActor:attachNodeToBone(dummy, effectView, isBackSide, isFlipWithActor)
    end

end

function QBaseActorView:_playVictoryEffect()
    local effectId = self:getModel():getVictoryEffect()
    if effectId ~= nil and string.len(effectId) > 0 then
        local frontEffect, backEffect = QBaseEffectView.createEffectByID(effectId, self)
        local dummy = (QStaticDatabase.sharedDatabase():getEffectDummyByID(effectID) or DUMMY.CENTER)
        local isFlipWithActor = QStaticDatabase.sharedDatabase():getEffectIsFlipWithActorByID(effectID)
        if frontEffect ~= nil then
            self:attachEffectToDummy(dummy, frontEffect, false, isFlipWithActor)
            frontEffect:playAnimation(EFFECT_ANIMATION, false)
            frontEffect:playSoundEffect(false)
            frontEffect:afterAnimationComplete(function()
                if dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(frontEffect)
                else
                    app.scene:removeEffectViews(frontEffect)
                end
            end)
        end
        if backEffect ~= nil then
            self:attachEffectToDummy(dummy, backEffect, true, isFlipWithActor)
            backEffect:playAnimation(EFFECT_ANIMATION, false)
            backEffect:afterAnimationComplete(function()
                if dummy ~= nil then
                    self:getSkeletonActor():detachNodeToBone(backEffect)
                else
                    app.scene:removeEffectViews(backEffect)
                end
            end)
        end
    end
end

function QBaseActorView:pauseSoundEffect()
    for _, effect in ipairs(self._buffEffects) do
        if effect.front_effect and effect.front_effect.pauseSoundEffect then effect.front_effect:pauseSoundEffect() end
        if effect.back_effect and effect.back_effect.pauseSoundEffect then effect.back_effect:pauseSoundEffect() end
    end
    for _, skill in pairs(self._skillAttackEffects) do
        for _, effect in ipairs(skill) do
            if effect.pauseSoundEffect then effect:pauseSoundEffect() end
        end
    end
    for _, effect in ipairs(self._skillLoopEffects) do
        if effect.effect and effect.effect.pauseSoundEffect then effect.effect:pauseSoundEffect() end
    end
end

function QBaseActorView:resumeSoundEffect()
    for _, effect in ipairs(self._buffEffects) do
        if effect.front_effect and effect.front_effect.resumeSoundEffect then effect.front_effect:resumeSoundEffect() end
        if effect.back_effect and effect.back_effect.resumeSoundEffect then effect.back_effect:resumeSoundEffect() end
    end
    for _, skill in pairs(self._skillAttackEffects) do
        for _, effect in ipairs(skill) do
            if effect.resumeSoundEffect then effect:resumeSoundEffect() end
        end
    end
    for _, effect in ipairs(self._skillLoopEffects) do
        if effect.effect and effect.effect.resumeSoundEffect then effect.effect:resumeSoundEffect() end
    end
end

function QBaseActorView:setAnimationScale(scale, reason)
	if reason == nil then
		self._skeletonActor:setAnimation(scale)
	else
		if scale == 1.0 then
			self._scales[reason] = nil
		else
			self._scales[reason] = scale
		end
		local final_scale = 1.0
		for _, v in pairs(self._scales) do
			final_scale = final_scale * v
		end
	    self._skeletonActor:setAnimationScale(final_scale)
	end
end

function QBaseActorView:pauseAnimation()
    self._skeletonActor:pauseAnimation()
end

function QBaseActorView:resumeAnimation()
    self._skeletonActor:resumeAnimation()
end

function QBaseActorView:startSprint()
    self._sprintOn = true
end

function QBaseActorView:endSprint()
    self._sprintOn = false
end

function QBaseActorView:updateSprint(dt)
    if self._shadow == nil then
        self._shadow = {}
    end

    if self._shadowNode == nil then
        self._shadowNode = CCNode:create()
        app.scene:addChild(self._shadowNode)
    end

    local actor = self._actor
    -- 更新拖影的前端
    if self._sprintOn then
        local shadow = self._shadow
        local lastFront = shadow[#shadow]
        local height = 60
        local currentPos = actor:getPosition()
        local scene = self:getParent()
        local parent = self._shadowNode:getParent()
        local currentPos = parent:convertToNodeSpace(scene:convertToWorldSpace(ccp(currentPos.x, currentPos.y)))
        local width = lastFront == nil and 0 or math.abs(lastFront.pos.x - currentPos.x)

        if lastFront == nil then
            local node = CCNode:create()
            node:retain()
            node:setPosition(currentPos.x, currentPos.y)
            self._shadowNode:addChild(node)
            local pos = currentPos
            local time = q.time()
            local newFront = 
            {
                node = node,
                pos = pos,
                time = time,
            }
            table.insert(self._shadow, newFront)

        elseif lastFront and lastFront.pos.x ~= currentPos.x then
            local unit_width = 5
            local tan = (lastFront.pos.y - currentPos.y) / (lastFront.pos.x - currentPos.x)
            local skewY = math.deg(math.atan2(lastFront.pos.y - currentPos.y, lastFront.pos.x - currentPos.x))
            local startx = lastFront.pos.x
            local starty = lastFront.pos.y
            local currentTime = q.time()
            local lastTime = lastFront.time
            while width > unit_width do
                local thiswidth = math.min(unit_width, width)
                local node = CCLayerColor:create(ccc4(255, 255, 255, 64))
                node:retain()
                node:setContentSize(CCSize(thiswidth, height))
                if lastFront.pos.x > currentPos.x then
                    node:setAnchorPoint(ccp(0, 0.5))
                    node:setSkewY(skewY)
                    startx = startx - thiswidth
                    starty = starty + tan * (-thiswidth)
                    node:setPosition(startx, starty + 80 - height)
                else
                    node:setAnchorPoint(ccp(1.0, 0.5))
                    node:setSkewY(skewY)
                    startx = startx + thiswidth
                    starty = starty + tan * (thiswidth)
                    node:setPosition(startx, starty + 80 - height)
                end
                self._shadowNode:addChild(node)
                local pos = currentPos

                local newFront = 
                {
                    node = node,
                    pos = {x = startx, y = starty},
                    time = lastTime + (currentTime - lastTime) * (math.abs(startx - lastFront.pos.x) / math.abs(currentPos.x - lastFront.pos.x)),
                }
                table.insert(self._shadow, newFront)

                width = width - thiswidth
            end
        end
    end

    -- 更新拖影的后端
    local currentTime = q.time()
    local deleteCount = 0
    for i, ex in ipairs(self._shadow) do
        local node = ex.node
        local pos = ex.pos
        local time = ex.time

        local coefficient = (0.5 - (currentTime - time)) / 0.5
        -- coefficient = 1
        if coefficient > 0 then
            node:setOpacity(64 * coefficient)
        else
            node:removeFromParent()
            node:release()
            deleteCount = i
        end
    end
    local shadow = self._shadow
    local newShadow = {}
    for i = deleteCount + 1, #shadow do
        table.insert(newShadow, shadow[i])
    end
    self._shadow = newShadow
end

function QBaseActorView:setScissorEnabled(enabled)
    if self._skeletonActor.setScissorEnabled then
        self._skeletonActor:setScissorEnabled(enabled)
    end
end

function QBaseActorView:setScissorRects(mask1, grad1, grad2, mask2)
    if self._skeletonActor.setScissorRects then
        self._skeletonActor:setScissorRects(mask1, grad1, grad2, mask2)
    end
end

function QBaseActorView:setOpacityActor(opacity)
    if self._skeletonActor.setOpacityActor then
        self._skeletonActor:setOpacityActor(opacity)
    end
end

function QBaseActorView:setScissorBlendFunc(func)
    if self._skeletonActor.setScissorBlendFunc then
        self._skeletonActor:setScissorBlendFunc(func)
    end
end

function QBaseActorView:setScissorColor(color)
    if self._skeletonActor.setScissorColor then
        self._skeletonActor:setScissorColor(color)
    end
end

function QBaseActorView:setScissorOpacity(opacity)
    if self._skeletonActor.setScissorOpacity then
        self._skeletonActor:setScissorOpacity(opacity)
    end
end

function QBaseActorView:setRenderTextureBlendFunc(func)
    if self._skeletonActor.setRenderTextureBlendFunc then
        self._skeletonActor:setRenderTextureBlendFunc(func)
    end
end

function QBaseActorView:reloadSkeleton()
    if self._skeletonActor then
        self._skeletonActor:reloadWithFile(self._actor:getActorFile())
    end
end

return QBaseActorView

