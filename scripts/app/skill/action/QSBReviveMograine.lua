local QSBAction = import(".QSBAction")
local QSBReviveMograine = class("QSBReviveMograine", QSBAction)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QBaseActorView = import("...views.QBaseActorView")
local QBaseEffectView = import("...views.QBaseEffectView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")

-- 这个技能只用来复活莫格莱尼，走向莫格莱尼，复活莫格莱尼，取消群体睡眠的过程 (不包含群体睡眠的释放)
-- 注意，莫格莱尼的尸体不消失在QBattleManager处理

function QSBReviveMograine:_execute(dt)
	local actor = self._attacker
	if self._set ~= true then
		local mates = app.battle:getEnemies()
		local mograine = nil
		for _, mate in ipairs(mates) do
			if mate:isDead() and mate:getDisplayID() == 140302 then
				mograine = mate
				self._mograine = mograine
				break
			end
		end

		if mograine == nil then
			assert(false, "找不到莫格莱尼的尸体")

			local heros = app.battle:getHeroes()
			for _, hero in ipairs(heros) do
				hero:removeBuffByID("sleep_forever")
			end

			self:finished()
			return
		end
		self._prevTarget = actor:getTarget()
		actor:setTarget(mograine)
		actor:setManualMode(actor.STAY)
		app.grid:moveActorToTarget(actor, mograine, false, false)
		self._set = true
	else
		local dist = q.distOf2Points(app.grid:_toScreenPos(actor.gridPos), actor:getPosition())
		-- if self._walk == nil then
		-- 	if actor:isWalking() then
		-- 		self._walk = true
		-- 	end
		-- else
		-- 	if actor:isWalking() == false then
				if self._revived ~= true and dist < 24 and not actor:isWalking() then
				    app.battle:performWithDelay(function()
				        self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = "复活吧，我的勇士", name = "怀特迈恩"})
				        self._dialogueRight:setActorImage("ui/whitemane.png")
				        app.scene:addChild(self._dialogueRight)
				        app.scene:hideHeroStatusViews()

				        audio.playSound("HighInquisitorWhitemaneRes01.mp3", false)

				        local enemyView = app.scene:getActorViewFromModel(actor)
				        enemyView._animationQueue = {"attack02", ANIMATION.STAND}
				        enemyView:_changeAnimation()
				    end, 0.0, self._attacker)

				    app.battle:performWithDelay(function()
				        local enemy = self._mograine
        				-- enemy:playSkillEffect("monster_born_3", nil, {})
        				-- enemy:playSkillEffect("monster_born_3_1", nil, {})
        				-- enemy:playSkillEffect("monster_born_3_2", nil, {})
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
				        self._dialogueRight:removeFromParent()
				        app.scene:showHeroStatusViews()
				    end, 2.0, self._attacker)

				    app.battle:performWithDelay(function()
				        self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = "为你而战，我的女士", name = "莫格莱尼"})
				        self._dialogueRight:setActorImage("ui/mograine.png")
				        app.scene:addChild(self._dialogueRight)
				        app.scene:hideHeroStatusViews()

				        audio.playSound("ScarletCommanderMograineAtRest01.mp3", false)

			        	local enemy = self._mograine
				        local position = enemy:getPosition()
				        enemy:resetStateForBattle(true)
				        enemy:setActorPosition(position)
				        enemy:setTarget(nil)
				        enemy._hp = enemy:getMaxHp()
				        enemy._hpBeforeLastChange = enemy:getMaxHp()
				        enemy:setManualMode(actor.STAY)

				        -- 莫格莱尼的AI重置
				        app.battle:reloadActorAi(enemy)

				        local enemyView = app.scene:getActorViewFromModel(enemy)
				        enemyView._animationQueue = {"attack02", ANIMATION.STAND}
				        enemyView:_changeAnimation()

						actor:setTarget(self._prevTarget)
				    end, 4.0, self._attacker)

				    app.battle:performWithDelay(function()
			        	local enemy = self._mograine

						actor:setManualMode(actor.AUTO)
				        enemy:setManualMode(actor.AUTO)

						local heros = app.battle:getHeroes()
						for _, hero in ipairs(heros) do
							hero:removeBuffByID("sleep_forever")
						end

						enemy:applyBuff("avenging_wrath_4", enemy)

				        self._dialogueRight:removeFromParent()
				        app.scene:showHeroStatusViews()
				        
				        self:finished()
				    end, 5.8, self._attacker)

			        self._revived = true
		    	end
		-- 	end
		-- end
	end
end

return QSBReviveMograine