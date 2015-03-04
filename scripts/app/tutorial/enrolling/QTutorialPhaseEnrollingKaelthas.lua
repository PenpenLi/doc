
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhaseEnrollingKaelthas = class("QTutorialPhaseEnrollingKaelthas", QTutorialPhase)

local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QTimer = import("...utils.QTimer")
local QTeam = import("...utils.QTeam")
local QActor = import("...models.QActor")
local QHeroModel = import("...models.QHeroModel")
local QBaseActorView = import("...views.QBaseActorView")
local QBaseEffectView = import("...views.QBaseEffectView")
local QStaticDatabase = import("...controls.QStaticDatabase")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

local entered = false
local checked = false
function QTutorialPhaseEnrollingKaelthas:start()
    self._hero = nil
        
    local dungeon = self._stage._battle._dungeonConfig
    if dungeon.monster_id ~= "wailing_caverns_9" then
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
                if hero:getTalentFunc() == "dps" and hero:isRanged() then
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

function QTutorialPhaseEnrollingKaelthas:_hackAttack()
    self._hackedHeroes = {}
    local heroes = app.battle:getHeroes()
    for _, hero in ipairs(heroes) do
        function hero:decreaseHp(hp)
            if (self:getHp() - hp) / self:getMaxHp() <= 0.2 then
                hp = math.ceil(self:getHp() - self:getMaxHp() * 0.2)
            end
            if hp > 0 then
                return QActor.decreaseHp(self, hp)
            else
                return self, hp, 0
            end
        end
        table.insert(self._hackedHeroes, hero)
    end
end

function QTutorialPhaseEnrollingKaelthas:_hackAttack2()
    self._hackedHeroes = {}
    local heroes = app.battle:getHeroes()
    for _, hero in ipairs(heroes) do
        function hero:hit(skill, attackee, split_number)
            local damage, tip, critical, hit_status = calcDamage(self, skill, attackee, split_number)
            if (attackee:getHp() - damage) / attackee:getMaxHp() > 0.05 then
                QHeroModel.hit(self, skill, attackee, split_number, {damage = damage, tip = tip, critical = critical, hit_status = hit_status})
            end
        end
        table.insert(self._hackedHeroes, hero)
    end
end

function QTutorialPhaseEnrollingKaelthas:_dehackAttack()
    if self._hackedHeroes and #self._hackedHeroes > 0 then
        for _, hero in ipairs(self._hackedHeroes) do
            hero.decreaseHp = QActor.decreaseHp
            hero.hit = QHeroModel.hit
        end
    end
end

function QTutorialPhaseEnrollingKaelthas:_unfoldPlot()
    if not self._unfold then
        self._unfold = true
    else
        return
    end

    self:_hackAttack2()
    app.scene:pauseBattleAndDisplayDislog({"经常看电视剧的都知道，剧情绝对不会这样发展的", "被电的天旋地转，是要挂在这里的节奏嘛",}, {"ui/bloodelf_prophecy.png", "ui/orc_warlord.png",}, {"莉莉娅", "督军杰克",},nil, function()
        local view = app.scene:getActorViewFromModel(self._hero)
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
            local old_attack = self._hero.attack
            function self._hero:attack(skill) end -- 阻止释放技能

            self._hero.behaviorNode = app.battle._aiDirector:createBehaviorTree(self._hero:getAIType(), self._hero)
            app.battle._aiDirector:addBehaviorTree(self._hero.behaviorNode)
            self._hero:setTarget(self._enemy)

            app.scene:pauseBattleAndDisplayDislog({"对的！每到这个时候就是男神出场的时候~是时候展现真正的力量了！"}, {"ui/kaelthas.png"}, {"凯尔萨斯",}, view:getModel(), function()
                self._hero.attack = old_attack

                skill:_stopCd()
                app.scene:pauseBattleAndUseSkill(self._hero, skills[next(skills)])

                checked = true
                self:finished()
            end)
        end, 1.0)
    end)
end

function QTutorialPhaseEnrollingKaelthas:_onBattleEnd()
    self._proxy:removeAllEventListeners()
    self:_dehackAttack()
end

function QTutorialPhaseEnrollingKaelthas:visit()
    if self._enemy ~= nil then
        return
    end

    local enemies = app.battle:getEnemies()
    for _, enemy in ipairs(enemies) do
        if not enemy:isDead() and enemy:getActorID() == 40029 then
            if self._enemy_skip == nil then
                self._enemy_skip = enemy
            elseif self._enemy == nil and enemy ~= self._enemy_skip then
                self._enemy = enemy
                app.battle:performWithDelay(handler(self, self._unfoldPlot), 2)
            end
        end
    end
end

return QTutorialPhaseEnrollingKaelthas