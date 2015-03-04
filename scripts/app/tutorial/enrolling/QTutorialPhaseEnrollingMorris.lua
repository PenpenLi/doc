
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhaseEnrollingMorris = class("QTutorialPhaseEnrollingMorris", QTutorialPhase)

local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QTimer = import("...utils.QTimer")
local QTeam = import("...utils.QTeam")
local QHitLog = import("...utils.QHitLog")
local QActor = import("...models.QActor")
local QHeroModel = import("...models.QHeroModel")
local QBaseActorView = import("...views.QBaseActorView")
local QBaseEffectView = import("...views.QBaseEffectView")
local QStaticDatabase = import("...controls.QStaticDatabase")

local entered = false
local checked = false
function QTutorialPhaseEnrollingMorris:start()
    self._hero = nil
        
    local dungeon = self._stage._battle._dungeonConfig
    if dungeon.monster_id ~= "deadmine_9" then
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

    -- app.battle:performWithDelay(function()
    --     app.scene:pauseBattleAndDisplayDislog({"瑟芬斯特会召唤小怪，让我使用群体嘲讽帮你们拉怪！"}, {"ui/human_wrath.png"}, {"莫里斯"}, nil, nil)
    -- end, 1.5, nil, true)
    -- self:finished()
    -- do return end

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
                if hero:getTalentFunc() == "t" then
                    self._hero = hero
                    self._heroIndex = i
                end
            end
            if hero:getTalentFunc() == "health" then
                self._healer = hero
                self._healerIndex = i
            end
        end

        if self._hero and self._healer then
            local view = app.scene:getActorViewFromModel(self._hero)
            view:setVisible(false)
            app.scene:hideHeroStatusView(self._heroIndex)
            app.grid:removeActor(self._hero)
            table.remove(heroes, self._heroIndex)
            app.battle._aiDirector:removeBehaviorTree(self._hero.behaviorNode)
            self._hero.behaviorNode = nil

            self._proxy = cc.EventProxy.new(self._stage._battle)
            self._proxy:addEventListener(self._stage._battle.END, handler(self, self._onBattleEnd))
        else
            self:finished()
        end
    end, 0)
end

function QTutorialPhaseEnrollingMorris:_hackAttack()
    self._hackedHeroes = {}
    local heroes = app.battle:getHeroes()
    local phase = self
    for _, hero in ipairs(heroes) do
        function hero:decreaseHp(hp)
            hp = math.ceil(self:getMaxHp() / 3)

            if (self:getHp() - hp) / self:getMaxHp() <= 0.2 then
                hp = math.ceil(self:getHp() - self:getMaxHp() * 0.1)
                -- 触发剧情
                phase:_unfoldPlot()
            end
            if hp > 0 then
                return QActor.decreaseHp(self, hp)
            else
                return self, hp, 0
            end
        end
        if hero:getTalentFunc() ~= "health" then
            function hero:hit(skill, attackee, split_number)
                local damage, tip, critical, hit_status = calcDamage(self, skill, attackee, split_number)
                if (attackee:getHp() - damage) / attackee:getMaxHp() > 0.1 then
                    QHeroModel.hit(self, skill, attackee, split_number, {damage = damage, tip = tip, critical = critical, hit_status = hit_status})
                else
                    attackee:dispatchEvent({name = attackee.UNDER_ATTACK_EVENT, isTreat = false, tip = "闪避"})
                end
            end
        end
        table.insert(self._hackedHeroes, hero)
    end

    function self._hero:onDragAttack(target)
        return
    end
    table.insert(self._hackedHeroes, self._hero)
end

function QTutorialPhaseEnrollingMorris:_dehackAttack()
    if self._hackedHeroes and #self._hackedHeroes > 0 then
        for _, hero in ipairs(self._hackedHeroes) do
            hero.decreaseHp = QActor.decreaseHp
            hero.hit = QHeroModel.hit
            hero.onDragAttack = QActor.onDragAttack
        end
    end
end

function QTutorialPhaseEnrollingMorris:_unfoldPlot()
    if not self._unfold then
        self._unfold = true
    elseif not self._unfold2 then
        self._unfold2 = true
    else
        return
    end

    if not self._unfold2 then
        app.scene:pauseBattleAndDisplayDislog({"圣光普照！全场满血！", "有点扛不住了么，奶妈救我！"}, {"ui/bloodelf_prophecy.png", "ui/orc_warlord.png"}, {"莉莉娅", "督军杰克"}, nil, function()
            local skills = self._healer:getManualSkills()
            local heal_skill = skills[next(skills)]
            heal_skill:_stopCd()
            self._healer:attack(heal_skill)
            app.scene:hideHeroStatusView(self._heroIndex)
        end)
    else
        local view = app.scene:getActorViewFromModel(self._hero)
        app.scene:pauseBattleAndDisplayDislog({"技能CD！你叫破喉咙也没办法！！！", "谁说皮厚就可以当T的！奶妈，又要挂了，要挂了！！！"}, {"ui/bloodelf_prophecy.png", "ui/orc_warlord.png"}, {"莉莉娅", "督军杰克"}, nil, function()
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
                local skills = self._hero:getManualSkills()

                self._hero.behaviorNode = app.battle._aiDirector:createBehaviorTree(self._hero:getAIType(), self._hero)
                app.battle._aiDirector:addBehaviorTree(self._hero.behaviorNode)

                app.scene:pauseBattleAndDisplayDislog({"焦急的小伙伴们~抗怪还请找专业坦克~神T这就来拯救你们！"}, {"ui/human_wrath.png"}, {"莫利斯"}, view:getModel(), function()
                    skill:_stopCd()
                    app.scene:pauseBattleAndUseSkill(self._hero, skill)                
                    local proxy = cc.EventProxy.new(self._hero)
                    proxy:addEventListener(self._hero.USE_MANUAL_SKILL_EVENT, function(event)
                        proxy:removeAllEventListeners()
                        app.battle:performWithDelay(function()
                            self:_dehackAttack()
                            checked = true
                            self:finished()
                        end, 1.8) 
                    end)
                end)
            end, 1.0)
        end)
    end
end

function QTutorialPhaseEnrollingMorris:_onBattleEnd()
    self._proxy:removeAllEventListeners()
    self:_dehackAttack()
end

function QTutorialPhaseEnrollingMorris:visit()
    if type(app.battle:getCurrentWave()) ~= "number" or app.battle:getCurrentWave() ~= 1 or self._hacked or self._hero == nil then
        return
    end

    self:_hackAttack()
    self._hacked = true
end

return QTutorialPhaseEnrollingMorris