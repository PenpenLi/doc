
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase02InFirstBattle = class("QTutorialPhase02InFirstBattle", QTutorialPhase)

local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")

-- 骑士BOSS做一个胜利动作,说一句“来战”，然后开始战斗
function QTutorialPhase02InFirstBattle:start()
	self._stage:enableTouch(handler(self, self._onTouch))

	local enemies = app.battle:getEnemies()
	enemies[1]:onVictory()
    app.scene:getActorViewFromModel(enemies[1])._victory = false

    self._word = "来战!"
	scheduler.performWithDelayGlobal(function()
        audio.playSound("audio/sound/vocal/sandtop_1.mp3", false)
        self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "莫格莱尼"})
        self._dialogueRight:setActorImage("ui/mograine.png")
		    app.scene:addChild(self._dialogueRight)
        app.scene:hideHeroStatusViews()
--        self:_autoTouchEnded(2.0, function() return self._dialogueRight ~= nil end)
    end, 0.0)
end

function QTutorialPhase02InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._dialogueRight ~= nil and self._dialogueRight._isSaying == true and self._dialogueRight:isVisible() then 
          self._dialogueRight:stopSay()
          self._dialogueRight._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        elseif self._dialogueRight then
            self._dialogueRight:removeFromParent()
            self._dialogueRight = nil
            app.scene:showHeroStatusViews()
            self._stage:disableTouch()
            self:finished()

            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
            local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
            local enemies = app.battle:getEnemies()
            self._enemy = enemies[1]

            orc_warlord:setTarget(self._enemy)
            kaelthas:setTarget(self._enemy)
            tyrande:setTarget(orc_warlord)
            self._enemy:setTarget(orc_warlord)
        end
    end
end

return QTutorialPhase02InFirstBattle