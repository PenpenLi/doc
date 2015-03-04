
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase08InFirstBattle = class("QTutorialPhase08InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

-- 很快骑士BOSS死亡，牧师BOSS出场。牧师出场时给自己套真言术盾
function QTutorialPhase08InFirstBattle:start()
    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
    local enemies = app.battle:getEnemies()
    self._enemy = enemies[2]

    -- local skill = self._enemy:getSkillWithId("power_word_shield_whitemane")
    -- self._enemy:attack(skill)

    self._enemy:setTarget(orc_warlord)
    -- self._enemy._hp = 550
    -- self._enemy.basic_hp_ = 550
    -- self._enemy._hpBeforeLastChange = 550

    scheduler.performWithDelayGlobal(function()
        orc_warlord:setTarget(self._enemy)
        kaelthas:setTarget(self._enemy)
        tyrande:setTarget(orc_warlord)

        app.battle:pause()
        self._stage:enableTouch(handler(self, self._onTouch))

        audio.playSound("audio/sound/vocal/gahzrilla_1.mp3", false)
        self._word = "莫格莱尼倒下了？你们要为此付出代价！"
        self._dialogueLeft = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "怀特迈恩"})
        self._dialogueLeft:setActorImage("ui/whitemane.png")
--        self:_autoTouchEnded(3.0, function() return self._firstClick == false end)
        app.scene:addChild(self._dialogueLeft)
        app.scene:hideHeroStatusViews()
        self._firstClick = false
    end, 1.6)
end

function QTutorialPhase08InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._dialogueLeft ~= nil and self._dialogueLeft._isSaying == true and self._dialogueLeft:isVisible() then 
          self._dialogueLeft:stopSay()
          self._dialogueLeft._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        elseif self._firstClick == false then
            self._dialogueLeft:removeFromParent()
            self._firstClick = true

            audio.playSound("audio/sound/vocal/orc_warlord_2.mp3", false)
            self._word = "居然还有后援，快集火秒掉她！"
            self._dialogueLeft = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, name = "督军杰克"})
            self._dialogueLeft:setActorImage("ui/orc_warlord.png")
--            self:_autoTouchEnded(3.0, function() return self._secondClick == false end)
            app.scene:addChild(self._dialogueLeft)
            self._secondClick = false

        elseif self._secondClick == false then
            self._dialogueLeft:removeFromParent()
            app.scene:showHeroStatusViews()
            self._secondClick = true

            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local enemies = app.battle:getEnemies()
            enemies[1]:setTarget(orc_warlord)
            self._enemy = enemies[2]

            self._handTouch = QUIWidgetTutorialHandTouch.new({word = "选择集火对象", direction = "up"})
            self._handTouch:setPosition(self._enemy:getCenterPosition_Stage())
            app.scene:addChild(self._handTouch)

        elseif self._firstClick == true and self._secondClick == true then
            local boundingBox = self._enemy:getBoundingBox_Stage()
            if boundingBox:containsPoint(ccp(event.x, event.y)) == true and self:oneTimeCheck() then
                self._stage:disableTouch()
                self._handTouch:removeFromParent()

                local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
                local skill = orc_warlord:getSkillWithId("charge_1")
                orc_warlord:_cancelCurrentSkill()
                orc_warlord:attack(skill)
                self._enemy:applyBuff(global.attack_mark_effect)
                app.battle:resume()

                scheduler.performWithDelayGlobal(function()
                    self:finished()
                end, 1.5)
            end
        end
    end
end

-- function QTutorialPhase08InFirstBattle:visit()
--     if self._enemy:getHp() <= self._enemy:getMaxHp() * 0.8 then
--         self:finished()
--     end
-- end


return QTutorialPhase08InFirstBattle