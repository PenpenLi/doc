
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase06InFirstBattle = class("QTutorialPhase06InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

-- 施放完增强防御力的图标后连续指引施放“治疗之环”技能
function QTutorialPhase06InFirstBattle:start()

    scheduler.performWithDelayGlobal(function()
        self._stage:enableTouch(handler(self, self._onTouch))

        audio.playSound("audio/sound/vocal/orc_warlord_1.mp3", false)
        self._word = "趁势攻击！剑！刃！风！暴！"
        self._dialogueLeft = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, name = "督军杰克"})
        self._dialogueLeft:setActorImage("ui/orc_warlord.png")
        app.scene:addChild(self._dialogueLeft)
        app.scene:hideHeroStatusViews()
        self._firstClick = false
--        self:_autoTouchEnded(3.0, function() return self._firstClick == false end)

        app.battle:pause()
    end, 2.3)
end

function QTutorialPhase06InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._dialogueLeft ~= nil and self._dialogueLeft._isSaying == true and self._dialogueLeft:isVisible() then 
          self._dialogueLeft:stopSay()
          self._dialogueLeft._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        elseif self._firstClick == false then
            self._dialogueLeft:removeFromParent()
            app.scene:showHeroStatusViews()
            self._firstClick = true

            local heroStatusView = app.scene._heroStatusViews[self._stage.Tag_orc_warlord]
            local skillNode = heroStatusView._ccbOwner.node_skill1
            local positionX = heroStatusView:getPositionX() + skillNode:getPositionX()
            local positionY = heroStatusView:getPositionY() + skillNode:getPositionY()
            self._handTouch = QUIWidgetTutorialHandTouch.new({word = "点击释放技能", direction = "up"})
            self._handTouch:setPosition(positionX, positionY)
--            self._handTouch:handRightUp()
--            self._handTouch:tipsLeftUp()
            app.scene:addChild(self._handTouch)
            self._skillRect = CCRectMake(positionX - 50, positionY - 50, 100, 100)
            
            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local skill = orc_warlord:getSkillWithId("bladestorm_orc_warlord_1")
            skill:_stopCd()

        elseif self._skillRect and self._skillRect:containsPoint(ccp(event.x, event.y)) == true then
            self._handTouch:removeFromParent()
            self._stage:disableTouch()
            app.battle:resume()

            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local skill = orc_warlord:getSkillWithId("bladestorm_orc_warlord_1")
            orc_warlord:_cancelCurrentSkill()
            orc_warlord:attack(skill)

            self:finished()
        end
    end
end

return QTutorialPhase06InFirstBattle