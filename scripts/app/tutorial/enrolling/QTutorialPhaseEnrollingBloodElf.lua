
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhaseEnrollingBloodElf = class("QTutorialPhaseEnrollingBloodElf", QTutorialPhase)

local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QTimer = import("...utils.QTimer")
local QTeam = import("...utils.QTeam")
local QActor = import("...models.QActor")
local QHeroModel = import("...models.QHeroModel")
local QBaseActorView = import("...views.QBaseActorView")
local QBaseEffectView = import("...views.QBaseEffectView")
local QStaticDatabase = import("...controls.QStaticDatabase")

local entered = false
local checked = false
function QTutorialPhaseEnrollingBloodElf:start()
    self._hero = nil
        
    local dungeon = self._stage._battle._dungeonConfig
    if dungeon.monster_id ~= "wailing_caverns_3" then
        self:finished()
        return
    end

    if checked == true then
        self:finished()
        return
    end

    app.battle:getHeroes()
    local joinHeroes = remote.teams:getJoinHero(QTeam.INSTANCE_TEAM)
    if (joinHeroes == nil or next(joinHeroes) == nil) then
        if entered == false then
            self:finished()
            return
        end
    end

    entered = true

    app.scene:setVisible(false)
    scheduler.performWithDelayGlobal(function()
        app.scene:setVisible(true)
        local heroes = app.battle:getHeroes()
        local joinHeroId = nil
        if joinHeroes ~= nil and next(joinHeroes) ~= nil then
            joinHeroId = joinHeroes[next(joinHeroes)]
        end
        for i, hero in ipairs(heroes) do
            if hero:getActorID() == joinHeroId then
                if hero:getTalentFunc() == "health" then
                    self._hero = hero
                    self._heroIndex = i
                    local view = app.scene:getActorViewFromModel(self._hero)
                    view:setVisible(false)
                    app.scene:hideHeroStatusView(i)
                    app.grid:removeActor(self._hero)
                    table.remove(heroes, i)
                    app.battle._aiDirector:removeBehaviorTree(self._hero.behaviorNode)
                    self._hero.behaviorNode = nil
                    self:_hackAttack()

                    self._proxy = cc.EventProxy.new(self._stage._battle)
                    self._proxy:addEventListener(self._stage._battle.END, handler(self, self._onBattleEnd))
                    return
                end
            end
        end

        self:finished()
    end, 0)
end

function QTutorialPhaseEnrollingBloodElf:_hackAttack()
    if self._hero and #app.battle:getHeroes() > 0 then
        local orc = app.battle:getHeroes()[1]
        local phase = self
        function orc:decreaseHp(hp)
            hp = math.ceil(self:getMaxHp() / 5)

            if (self:getHp() - hp) / self:getMaxHp() <= 0.5 then
                hp = math.ceil(self:getHp() - self:getMaxHp() / 2)
                -- 触发剧情
                phase:_unfoldPlot()
            end
            if hp > 0 then
                return QActor.decreaseHp(self, hp)
            else
                return self, hp, 0
            end
        end
        function orc:hit(skill, attackee, split_number)
            local damage, tip, critical, hit_status = calcDamage(self, skill, attackee, split_number)
            if (attackee:getHp() - damage) / attackee:getMaxHp() > 0.5 then
                QHeroModel.hit(self, skill, attackee, split_number, {damage = damage, tip = tip, critical = critical, hit_status = hit_status})
            else
                attackee:dispatchEvent({name = attackee.UNDER_ATTACK_EVENT, isTreat = false, tip = "闪避"})
            end
        end
        self._hackedHero = orc
    end
end

function QTutorialPhaseEnrollingBloodElf:_dehackAttack()
    if self._hackedHero then
        self._hackedHero.decreaseHp = QActor.decreaseHp
        self._hackedHero.hit = QHeroModel.hit
    end
end

function QTutorialPhaseEnrollingBloodElf:_unfoldPlot()
    if not self._unfold then
        self._unfold = true
    else
        return
    end

    local view = app.scene:getActorViewFromModel(self._hero)
    app.scene:pauseBattleAndDisplayDislog({"这飞蛇看着那么弱小，居然这么厉害！咬一下这么多血！"}, {"ui/orc_warlord.png"}, {"督军杰克"}, nil, function()
        table.insert(app.battle:getHeroes(), self._hero)
        app.grid:addActor(self._hero)
        local oldpos = self._hero:getPosition()
        app.grid:moveActorTo(self._hero, {x = oldpos.x + 300, y = oldpos.y}, true)
        app.scene:showHeroStatusView(self._heroIndex)

        local frontEffect, backEffect = QBaseEffectView.createEffectByID(global.hero_add_effect)
        local dummy = QStaticDatabase.sharedDatabase():getEffectDummyByID(global.hero_add_effect)
        local positionX, positionY = view:getPosition()
        frontEffect:setPosition(positionX, positionY - 1)
        app.scene:addEffectViews(frontEffect)
        
        frontEffect:setVisible(true)
        view:setVisible(true)
        -- play animation and sound
        frontEffect:playAnimation(EFFECT_ANIMATION, false)
        frontEffect:playSoundEffect(false)

        frontEffect:afterAnimationComplete(function()
            app.scene:removeEffectViews(frontEffect)
        end)
        view:runAction(CCFadeIn:create(0.8))
        view:setDirection(QBaseActorView.DIRECTION_RIGHT)

        local skills = self._hero:getManualSkills()
        local skill = skills[next(skills)]
        skill:coolDown()
        skill:reduceCoolDownTime(skill._cd_time - 1.1)

        app.battle:performWithDelay(function()
            self:_dehackAttack()

            self._hero.behaviorNode = app.battle._aiDirector:createBehaviorTree(self._hero:getAIType(), self._hero)
            app.battle._aiDirector:addBehaviorTree(self._hero.behaviorNode)

            local sentences = {}
            local imageFiles = {}
            local names = {}
            table.insert(sentences, "人帅就是没办法！请叫我无敌杰克~哈哈")
            table.insert(sentences, "一直在追寻你的身影，我的法杖愿为你挥舞")
            table.insert(imageFiles, "ui/orc_warlord.png")
            table.insert(imageFiles, "ui/bloodelf_prophecy.png")
            table.insert(names, "督军杰克")
            table.insert(names, "莉莉娅")
            app.scene:pauseBattleAndDisplayDislog(sentences, imageFiles, names, view:getModel(), function()
                local skill = skills[next(skills)]
                skill:_stopCd()
                app.scene:pauseBattleAndUseSkill(self._hero, skill)                
                local proxy = cc.EventProxy.new(self._hero)
                proxy:addEventListener(self._hero.USE_MANUAL_SKILL_EVENT, function(event)
                    -- if event.skill ~= skill then return end
                    proxy:removeAllEventListeners()
                    app.battle:performWithDelay(function()
                        app.scene:pauseBattleAndDisplayDislog({"有绑定奶就是不一样，顿时神清气爽，可以愉快的玩耍啦~"}, {"ui/orc_warlord.png"}, {"督军杰克"}, nil, function()
                            checked = true
                            self:finished()
                        end)
                    end, 1.8) 
                end)
            end)
        end, 1.0)
    end)
end

function QTutorialPhaseEnrollingBloodElf:_onBattleEnd()
    self._proxy:removeAllEventListeners()
    self:_dehackAttack()
end

function QTutorialPhaseEnrollingBloodElf:visit()

end

return QTutorialPhaseEnrollingBloodElf