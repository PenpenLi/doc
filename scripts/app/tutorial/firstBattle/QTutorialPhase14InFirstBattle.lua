
local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QTutorialPhase = import("..QTutorialPhase")

local QTutorialPhase14InFirstBattle = class("QTutorialPhase14InFirstBattle", QTutorialPhase)

-- BOSS弹出对话框“下次再战，逃为上策！”，BOSS撤退
function QTutorialPhase14InFirstBattle:start()

    local enemies = app.battle:getEnemies()
    enemies[1]:setTarget(nil)
    enemies[2]:setTarget(nil)

    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
    kaelthas:setTarget(nil)
    tyrande:setTarget(nil)

    orc_warlord:setTarget(nil)
    audio.playSound("audio/sound/vocal/orc_warlord_3.mp3", false)
    self._word = "玩...玩...玩过火了"
    self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "督军杰克"})
    self._dialogueRight:setActorImage("ui/orc_warlord.png")
    app.scene:addChild(self._dialogueRight)
    app.scene:hideHeroStatusViews()
--    self:_autoTouchEnded(3, function() return self._dialogueRight ~= nil end)

    app.grid:moveActorTo(enemies[1], {x = 1280, y = enemies[1]:getPosition().y})
    if enemies[2]:isDead() == false then
        app.grid:moveActorTo(enemies[2], {x = 1280, y = enemies[2]:getPosition().y})
    end

    self._stage:enableTouch(handler(self, self._onTouch))
end

function QTutorialPhase14InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" and self._dialogueRight ~= nil then
        if self._dialogueRight ~= nil and self._dialogueRight._isSaying == true and self._dialogueRight:isVisible() then 
          self._dialogueRight:stopSay()
          self._dialogueRight._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        else
          self._dialogueRight:removeFromParent()
          self._dialogueRight = nil
          app.scene:showHeroStatusViews()
          self:finished()
        end
    end
end


return QTutorialPhase14InFirstBattle