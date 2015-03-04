
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase01InFirstBattle = class("QTutorialPhase01InFirstBattle", QTutorialPhase)

local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QTimer = import("..utils.QTimer")

-- 四位英雄每做一个胜利动作，说一句“为了部落”
function QTutorialPhase01InFirstBattle:start()
	self._stage:enableTouch(handler(self, self._onTouch))

    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
    local enemies = app.battle:getEnemies()
    self._enemy = enemies[1]

    self._enemy:setTarget(orc_warlord)
    -- self._enemy._hp = 300
    -- self._enemy.basic_hp_ = 300
    -- self._enemy._hpBeforeLastChange = 300

    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
    orc_warlord:setTarget(nil)
    kaelthas:setTarget(nil)
    tyrande:setTarget(nil)
    self._enemy:setTarget(nil)

    -- -- 锁住技能不让用
    -- local bladestorm = orc_warlord:getSkillWithId("bladestorm_orc_warlord_1")
    -- local powerwordshield = tyrande:getSkillWithId("power_word_shield_tyrande_1")
    -- local pyroblast = kaelthas:getSkillWithId("pyroblast_kaelthas_1")
    -- bladestorm:set("cd", 120)
    -- powerwordshield:set("cd", 120)
    -- pyroblast:set("cd", 120)
    -- bladestorm:set("first_cd", 14)
    -- powerwordshield:set("first_cd", 12)
    -- pyroblast:set("first_cd", 28)
    -- bladestorm:coolDown()
    -- powerwordshield:coolDown()
    -- pyroblast:coolDown()


	scheduler.performWithDelayGlobal(function()
		local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
		local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
		local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
		orc_warlord:onVictory()
		kaelthas:onVictory()
		tyrande:onVictory()

        app.scene:getActorViewFromModel(orc_warlord)._victory = false
        app.scene:getActorViewFromModel(kaelthas)._victory = false
        app.scene:getActorViewFromModel(tyrande)._victory = false
    end, 0.5)

	scheduler.performWithDelayGlobal(function()
	  self._word = "为了部落!"
		self._dialogueLeft = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, name = "督军杰克"})
		self._dialogueLeft:setActorImage("ui/orc_warlord.png")
		app.scene:addChild(self._dialogueLeft)
        app.scene:hideHeroStatusViews()
--        self:_autoTouchEnded(2.0, function() return self._dialogueLeft ~= nil end)

		audio.playSound("audio/sound/vocal/orc_warlord_cheer.mp3", false)
    end, 1.0)
end

function QTutorialPhase01InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
      if self._dialogueLeft ~= nil and self._dialogueLeft._isSaying == true and self._dialogueLeft:isVisible() then 
        self._dialogueLeft:stopSay()
        self._dialogueLeft._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
    	elseif self._dialogueLeft then
	    	self._dialogueLeft:removeFromParent()
            self._dialogueLeft = nil
            app.scene:showHeroStatusViews()
			self._stage:disableTouch()
	    	self:finished()
    	end
	end
end

return QTutorialPhase01InFirstBattle