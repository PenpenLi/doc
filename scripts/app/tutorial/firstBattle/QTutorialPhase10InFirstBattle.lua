
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase10InFirstBattle = class("QTutorialPhase10InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

-- 牧师BOSS头顶出现箭头，并有文字框，点击BOSS，集火目标。用户点击牧师BOSS后，战斗继续，所有DPS英雄攻击牧师BOSS 
function QTutorialPhase10InFirstBattle:start()
    self._stage:enableTouch(handler(self, self._onTouch))

    app.battle:pause()
    self._word = "这货居然会复活，快速速集火！"
    self._dialogueLeft = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, name = "泰兰德"})
    self._dialogueLeft:setActorImage("ui/tyrande.png")
    app.scene:addChild(self._dialogueLeft)
    app.scene:hideHeroStatusViews()
--    self:_autoTouchEnded(TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME), function() return self._firstClick == false end)

    self._firstClick = false
end

function QTutorialPhase10InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._dialogueLeft ~= nil and self._dialogueLeft._isSaying == true and self._dialogueLeft:isVisible() then 
          self._dialogueLeft:stopSay()
          self._dialogueLeft._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        elseif self._firstClick == false then
            self._dialogueLeft:removeFromParent()
            self._dialogueLeft = nil
            app.scene:showHeroStatusViews()

            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local enemies = app.battle:getEnemies()
            enemies[1]:setTarget(orc_warlord)
            self._enemy = enemies[2]

            self._handTouch = QUIWidgetTutorialHandTouch.new()
            self._handTouch:setPosition(self._enemy:getCenterPosition_Stage())
            app.scene:addChild(self._handTouch)

            self._firstClick = true
        elseif self._firstClick == true then
            local boundingBox = self._enemy:getBoundingBox_Stage()
            if boundingBox:containsPoint(ccp(event.x, event.y)) == true and self:oneTimeCheck() then
                scheduler.performWithDelayGlobal(function()
                    self._stage:disableTouch()
                    self._handTouch:removeFromParent()

                    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
                    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
                    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
                    orc_warlord:setTarget(self._enemy)
                    kaelthas:setTarget(self._enemy)
                    tyrande:setTarget(orc_warlord)

                    self._enemy:setTarget(orc_warlord)

                    self._enemy:applyBuff(global.attack_mark_effect)
                    app.battle:resume()

                    scheduler.performWithDelayGlobal(function()
                        self:finished()
                    end, 5.0)
                end, 0)
            end
        end
    end
end


return QTutorialPhase10InFirstBattle