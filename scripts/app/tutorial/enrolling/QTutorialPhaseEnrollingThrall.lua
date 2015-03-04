local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhaseEnrollingThrall = class("QTutorialPhaseEnrollingThrall", QTutorialPhase)

local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QTimer = import("...utils.QTimer")
local QTeam = import("...utils.QTeam")
local QActor = import("...models.QActor")
local QHeroModel = import("...models.QHeroModel")
local QBaseActorView = import("...views.QBaseActorView")
local QBaseEffectView = import("...views.QBaseEffectView")
local QStaticDatabase = import("...controls.QStaticDatabase")

function QTutorialPhaseEnrollingThrall:start()
	local dungeon = app.battle._dungeonConfig
	if dungeon.monster_id == "wailing_caverns_12" then
    	self._eventProxy = cc.EventProxy.new(app.battle)
    	self._eventProxy:addEventListener(app.battle.WAVE_STARTED, function(event)
    		if event.wave == 2 then
				self:_hackAttack()
    			self._eventProxy:removeAllEventListeners()

                self._proxy = cc.EventProxy.new(self._stage._battle)
                self._proxy:addEventListener(self._stage._battle.END, handler(self, self._onBattleEnd))
			end
    	end)
	else
		self:finished()
	end
end

function QTutorialPhaseEnrollingThrall:_hackAttack()
    self._hackedHeroes = {}
	local heroes = app.battle:getHeroes()
	for _, hero in ipairs(heroes) do
		if hero:getTalentFunc() ~= "health" then
	        local phase = self
	        function hero:decreaseHp(hp)
	            -- hp = math.ceil(self:getMaxHp() / 10)

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
end

function QTutorialPhaseEnrollingThrall:_hackAttack2()
    self._hackedHeroes = {}
	local heroes = app.battle:getHeroes()
	for _, hero in ipairs(heroes) do
		if hero:getTalentFunc() ~= "health" then
	        local phase = self
	        function hero:hit(skill, attackee, split_number)
	        	if app.battle:getCurrentWave() ~= 2 then
	                QHeroModel.hit(self, skill, attackee, split_number)
	        	else
		            local damage, tip, critical, hit_status = calcDamage(self, skill, attackee, split_number)
		            if (attackee:getHp() - damage) / attackee:getMaxHp() > 0.05 then
                		QHeroModel.hit(self, skill, attackee, split_number, {damage = damage, tip = tip, critical = critical, hit_status = hit_status})
		            end
	        	end
	        end
        	table.insert(self._hackedHeroes, hero)
    	end
    end
end

function QTutorialPhaseEnrollingThrall:_dehackAttack()
    if self._hackedHeroes and #self._hackedHeroes > 0 then
        for _, hero in ipairs(self._hackedHeroes) do
            hero.decreaseHp = QActor.decreaseHp
		    hero.hit = QHeroModel.hit
        end
    end
end

function QTutorialPhaseEnrollingThrall:visit()
	if type(app.battle:getCurrentWave()) ~= "number" or app.battle:getCurrentWave() ~= 2 then
		return
	end

	local enemies = app.battle:getEnemies()
	for _, enemy in ipairs(enemies) do
		if not enemy:isDead() and enemy:getActorID() == 40031 then
			if  enemy._replaceCharacterId == 30003 or (enemy:getHp() / enemy:getMaxHp() < 0.45) then
				self:_unfoldPlot()
			end
		end
	end
end

function QTutorialPhaseEnrollingThrall:_unfoldPlot()
    if not self._unfold then
        self._unfold = true
    else
        return
    end

    self:_hackAttack2()
    app.battle:performWithDelay(function()
	    app.scene:pauseBattleAndDisplayDislog({"我已经在用双手双脚滚键盘了！", "快要扛不住了！速度dps掉！rush！rush！",}, {"ui/kaelthas.png", "ui/orc_warlord.png",}, {"凯尔萨斯", "督军杰克"},nil, function()
	    	-- 萨尔进场
	    	local heroes = app.battle:getHeroes()
	    	ghost = app.battle:summonGhosts(40583, heroes[1], 600, {x = 250, y = 300})
	    	self._ghost = ghost
	    	app.battle._aiDirector:removeBehaviorTree(app.battle._heroGhosts[1].ai)

	    	local view = app.scene:getActorViewFromModel(ghost)
	        local frontEffect, backEffect = QBaseEffectView.createEffectByID(global.hero_add_effect)
	        local dummy = QStaticDatabase.sharedDatabase():getEffectDummyByID(global.hero_add_effect)
	        local positionX, positionY = view:getPosition()
	        frontEffect:setPosition(positionX, positionY - 1)
	        app.scene:addEffectViews(frontEffect)
	        frontEffect:setVisible(true)
	        view:setVisible(true)
	        frontEffect:playAnimation(EFFECT_ANIMATION, false)
	        frontEffect:playSoundEffect(false)
	        frontEffect:afterAnimationComplete(function()
	            app.scene:removeEffectViews(frontEffect)
	        end)
	        view:runAction(CCFadeIn:create(0.8))
	        view:setDirection(QBaseActorView.DIRECTION_RIGHT)

	        app.battle:performWithDelay(function()
	            app.scene:pauseBattleAndDisplayDislog({"让我来引领你们走向胜利！"}, {"ui/Thrall.png"}, {"萨尔"},nil, function()
	    			app.battle._aiDirector:addBehaviorTree(app.battle._heroGhosts[1].ai)
	                ghost.attack(ghost:getSkillWithId("bloodthirsty_thrall_plot"))
	                app.battle:performWithDelay(function()
	            		self:_dehackAttack()
	                	app.scene:getActorViewFromModel(ghost):setVisible(false)
						app.scene:getActorViewFromModel(ghost):getSkeletonActor():setVisible(false)
	                	ghost:suicide()
                		app.battle:dispatchEvent({name = app.battle.NPC_CLEANUP, npc = ghost, is_hero = true})
                		self._ghost = nil
	                end, 1.5)
	                self:finished()
	            end)
	        end, 1.5)
	    end)
    end, 1.5)
end

function QTutorialPhaseEnrollingThrall:_onBattleEnd()
    self._proxy:removeAllEventListeners()
    self:_dehackAttack()
    local ghost = self._ghost
    if ghost then
		app.scene:getActorViewFromModel(ghost):setVisible(false)
		app.scene:getActorViewFromModel(ghost):getSkeletonActor():setVisible(false)
		ghost:suicide()
		app.battle:dispatchEvent({name = app.battle.NPC_CLEANUP, npc = ghost, is_hero = true})
	end
end

return QTutorialPhaseEnrollingThrall