
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase09InFirstBattle = class("QTutorialPhase09InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QBaseEffectView = import("...views.QBaseEffectView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")

-- 牧师血量50%时，群体睡眠，复活骑士的同时大喊“复活吧，我的勇士”, 骑士身上播复活特效，然后骑士高喊“为你而战，我的女士”
function QTutorialPhase09InFirstBattle:start()
    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
    local enemies = app.battle:getEnemies()
    self._enemy = enemies[2]

    self._enemy:setTarget(nil)
    orc_warlord:setTarget(nil)
    kaelthas:setTarget(nil)
    tyrande:setTarget(nil)

    self._enemy:removeAllBuff()
    local skill = self._enemy:getSkillWithId("sleep")
    self._enemy:attack(skill)

    local position = clone(enemies[1]:getPosition())
    position.y = position.y + 50
    app.grid:moveActorTo(self._enemy, position, nil, nil, nil)
    scheduler.performWithDelayGlobal(function()
        self._enemy:stopMoving()
        scheduler.performWithDelayGlobal(function()
            self._word = "复活吧，我的勇士"
            self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "怀特迈恩"})
            self._dialogueRight:setActorImage("ui/whitemane.png")
            app.scene:addChild(self._dialogueRight)
            app.scene:hideHeroStatusViews()
            app.battle:pause()
    --        self:_autoTouchEnded(4.0, function() return self._firstClick == false end)

            audio.playSound("audio/sound/vocal/gahzrilla_2.mp3", false)

            local enemyView = app.scene:getActorViewFromModel(self._enemy)
            enemyView._animationQueue = {"attack02", ANIMATION.STAND}
            enemyView:_changeAnimation()

            self._stage:enableTouch(handler(self, self._onTouch))

            self._firstClick = false
        end, 1.0)
    end, 4.4)
end

function QTutorialPhase09InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._dialogueRight ~= nil and self._dialogueRight._isSaying == true and self._dialogueRight:isVisible() then 
          self._dialogueRight:stopSay()
          self._dialogueRight._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        elseif self._firstClick == false then
            app.battle:resume()
            self._dialogueRight:removeFromParent()
            app.scene:showHeroStatusViews()
            local enemies = app.battle:getEnemies()
            local enemy = enemies[1]
            local actorView = app.scene:getActorViewFromModel(enemy)
            local frontEffect, backEffect = QBaseEffectView.createEffectByID("monster_born_3", actorView)
            if frontEffect then
                actorView:getSkeletonActor():attachNodeToBone(DUMMY.BODY, frontEffect, false)
                frontEffect:playAnimation(EFFECT_ANIMATION, false)
                frontEffect:playSoundEffect(false)
                frontEffect:afterAnimationComplete(function()
                    actorView:getSkeletonActor():detachNodeToBone(frontEffect)
                end)
            end
            local frontEffect, backEffect = QBaseEffectView.createEffectByID("monster_born_3_1", actorView)
            if frontEffect then
                actorView:getSkeletonActor():attachNodeToBone(DUMMY.BODY, frontEffect, false)
                frontEffect:playAnimation(EFFECT_ANIMATION, false)
                frontEffect:playSoundEffect(false)
                frontEffect:afterAnimationComplete(function()
                    actorView:getSkeletonActor():detachNodeToBone(frontEffect)
                end)
            end
            local frontEffect, backEffect = QBaseEffectView.createEffectByID("monster_born_3_2", actorView)
            if backEffect then
                actorView:getSkeletonActor():attachNodeToBone(DUMMY.BODY, backEffect, true)
                backEffect:playAnimation(EFFECT_ANIMATION, false)
                backEffect:playSoundEffect(false)
                backEffect:afterAnimationComplete(function()
                    actorView:getSkeletonActor():detachNodeToBone(backEffect)
                end)
            end

            scheduler.performWithDelayGlobal(function()
                app.battle:pause()
                self._word = "为你而战，我的女士！"
                self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "莫格莱尼"})
                self._dialogueRight:setActorImage("ui/mograine.png")
                app.scene:addChild(self._dialogueRight)
                app.scene:hideHeroStatusViews()
--                self:_autoTouchEnded(TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME), function() return self._dialogueRight ~= nil end)

                audio.playSound("audio/sound/vocal/sandtop_3.mp3", false)

                local enemy = enemies[1]
                local position = enemy:getPosition()
                enemy:resetStateForBattle()
                enemy:setActorPosition({x = position.x + 132, y = position.y})
                enemy:setTarget(nil)
                enemy._hp = 500
                enemy.basic_hp_ = 500
                enemy._hpBeforeLastChange = 500

                local enemyView = app.scene:getActorViewFromModel(enemy)
                enemyView._animationQueue = {"attack02", ANIMATION.STAND}
                enemyView:_changeAnimation()

                self._stage:enableTouch(handler(self, self._onTouch))
            end, 2.75)
                
            self._stage:disableTouch()
            self._firstClick = true
        elseif self._firstClick == true then
            app.battle:resume()
            self._stage:disableTouch()
            self._dialogueRight:removeFromParent()
            self._dialogueRight = nil
            app.scene:showHeroStatusViews()

            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
            local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
            local enemies = app.battle:getEnemies()

            enemies[2]:setTarget(orc_warlord)
            enemies[1]:setTarget(orc_warlord)
            orc_warlord:setTarget(enemies[2])
            kaelthas:setTarget(enemies[2])
            tyrande:setTarget(orc_warlord)

            scheduler.performWithDelayGlobal(function()
                self:finished()
            end, 0.0)
        end
    end
end


return QTutorialPhase09InFirstBattle