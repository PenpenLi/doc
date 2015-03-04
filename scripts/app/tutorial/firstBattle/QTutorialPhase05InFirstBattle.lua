
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase05InFirstBattle = class("QTutorialPhase05InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

-- BOSS释放群攻：神圣风暴技能，集体伤血，治疗弹出对话框“注意血量！治疗技能名称”，点击的手型动画出现在“真言术盾”技能图标上，显示“点击释放技能”字样，直到用户操作后才消失
function QTutorialPhase05InFirstBattle:start()
    local enemies = app.battle:getEnemies()
    local skill = enemies[1]:getSkillWithId("divine_storm")
    enemies[1]:attack(skill)

    scheduler.performWithDelayGlobal(function()
        app.battle:pause()

        self._stage:enableTouch(handler(self, self._onTouch))

        audio.playSound("audio/sound/vocal/tyrande_1.mp3", false)
        self._word = "注意血量！真言术盾！"
        self._dialogueLeft = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, name = "泰兰德"})
        self._dialogueLeft:setActorImage("ui/tyrande.png")
        app.scene:addChild(self._dialogueLeft)
        app.scene:hideHeroStatusViews()
--        self:_autoTouchEnded(3.0, function() return self._firstClick == false end)

        self._firstClick = false
    end, 2.3)
end

function QTutorialPhase05InFirstBattle:_onTouch(event)
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

            local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
            local skill = tyrande:getSkillWithId("power_word_shield_tyrande_1")
            skill:_stopCd()

            local heroStatusView = app.scene._heroStatusViews[self._stage.Tag_tyrande]
            local skillNode = heroStatusView._ccbOwner.node_skill1
            local positionX = heroStatusView:getPositionX() + skillNode:getPositionX()
            local positionY = heroStatusView:getPositionY() + skillNode:getPositionY()
            self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击释放技能", direction = "up"})
            self._handTouch:setPosition(positionX, positionY)
--            self._handTouch:handRightUp()
--            self._handTouch:tipsLeftUp()
            app.scene:addChild(self._handTouch)

            self._skillRect = CCRectMake(positionX - 50, positionY - 50, 100, 100)

            self._firstClick = true

        elseif self._skillRect and self._skillRect:containsPoint(ccp(event.x, event.y)) == true and self:oneTimeCheck() then
            self._handTouch:removeFromParent()

            local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local skill = tyrande:getSkillWithId("power_word_shield_tyrande_1")
            tyrande:setTarget(orc_warlord)
            scheduler.performWithDelayGlobal(function()
                tyrande:attack(skill)
            end, 0.0)
            app.battle:resume()
            app.grid:pauseMoving()

            local enemies = app.battle:getEnemies()
            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
            local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)

            scheduler.performWithDelayGlobal(function()
                self._stage:disableTouch()   
                app.grid:continueMoving()
                self:finished()
            end, 1.5)
        end
    end
end

return QTutorialPhase05InFirstBattle