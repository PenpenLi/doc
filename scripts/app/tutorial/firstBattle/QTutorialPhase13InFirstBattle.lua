
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase13InFirstBattle = class("QTutorialPhase13InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

-- MT弹出对话框“为了部落！输出技能名称”，点击的手型动画出现在输出技能图标上，显示“点击释放技能”字样，知道用户操作后才消失
function QTutorialPhase13InFirstBattle:start()

    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    -- orc_warlord._hp = 300
    -- orc_warlord.basic_hp_ = 300
    -- orc_warlord._hpBeforeLastChange = 300

    scheduler.performWithDelayGlobal(function()
        app.battle:pause()
        self._stage:enableTouch(handler(self, self._onTouch))
        self._word = "剑！刃！风！暴！"
        self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "督军杰克"})
        self._dialogueRight:setActorImage("ui/orc_warlord.png")
        app.scene:addChild(self._dialogueRight)
        app.scene:hideHeroStatusViews()
--        self:_autoTouchEnded(TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME), function() return self._firstClick == false end)

        self._firstClick = false
        self._secondClick = false
        self._thirdClick = false
    end, 5.0)
end

function QTutorialPhase13InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._dialogueRight ~= nil and self._dialogueRight._isSaying == true and self._dialogueRight:isVisible() then 
          self._dialogueRight:stopSay()
          self._dialogueRight._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        elseif self._firstClick == false then
            self._dialogueRight:removeFromParent()
            self._dialogueRight = nil
            app.scene:showHeroStatusViews()

            local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local skill = orc_warlord:getSkillWithId("bladestorm_orc_warlord_1")
            skill:_stopCd()

            local heroStatusView = app.scene._heroStatusViews[self._stage.Tag_orc_warlord]
            local skillNode = heroStatusView._ccbOwner.node_skill1
            local positionX = heroStatusView:getPositionX() + skillNode:getPositionX()
            local positionY = heroStatusView:getPositionY() + skillNode:getPositionY()
            self._handTouch = QUIWidgetTutorialHandTouch.new()
            self._handTouch:setPosition(positionX, positionY)
            self._handTouch:handRightUp()
            self._handTouch:tipsLeftUp()
            app.scene:addChild(self._handTouch)

            self._skillRect = CCRectMake(positionX - 50, positionY - 50, 100, 100)
            self._firstClick = true

        elseif self._skillRect and self._skillRect:containsPoint(ccp(event.x, event.y)) == true and self:oneTimeCheck() then
            app.battle:resume()
            self._handTouch:removeFromParent()

            local hero = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local skill = hero:getSkillWithId("bladestorm_orc_warlord_1")
            hero:attack(skill)

            local handle
            handle = scheduler.scheduleGlobal(function()
                local enemies = app.battle:getEnemies()
                self._enemy = enemies[2]
                if self._enemy:isDead() then
                    scheduler.unscheduleGlobal(handle)

                    scheduler.performWithDelayGlobal(function()
                        app.battle:pause()
                        if self._word ~= nil then
                          self._word = nil 
                        end
                        self._word = "再见了，我的勇士"
                        self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "怀特迈恩"})
                        self._dialogueRight:setActorImage("ui/whitemane.png")
                        app.scene:addChild(self._dialogueRight)
                        app.scene:hideHeroStatusViews()
--                        self:_autoTouchEnded(TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME), function() return self._secondClick and self._thirdClick == false end)

                        self._stage:enableTouch(handler(self, self._onTouch))

                        self._stage:getHeroByTag(self._stage.Tag_orc_warlord):setTarget(enemies[1])
                        self._stage:getHeroByTag(self._stage.Tag_kaelthas):setTarget(enemies[1])
                    end, 0.7)
                end
            end, 0)

            self._stage:disableTouch()

            self._secondClick = true

        elseif self._secondClick == true and self._thirdClick == false then
            self._dialogueRight:removeFromParent()
            app.scene:showHeroStatusViews()
            app.battle:resume()

            scheduler.performWithDelayGlobal(function()
                if self._word ~= nil then
                    self._word = nil 
                end
                self._word = "我的爱人！你们都要为她陪葬"
                self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "莫格莱尼"})
                self._dialogueRight:setActorImage("ui/mograine.png")
                app.scene:addChild(self._dialogueRight)
                app.scene:hideHeroStatusViews()
--                self:_autoTouchEnded(TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME), function() return self._dialogueRight ~= nil end)

                app.battle:pause()
                self._stage:enableTouch(handler(self, self._onTouch))
            end, 2.0)

            self._stage:disableTouch()

            self._thirdClick = true
        elseif self._thirdClick == true then
            app.battle:resume()
            self._dialogueRight:removeFromParent()
            self._dialogueRight = nil
            app.scene:showHeroStatusViews()
            self._stage:disableTouch()
            self:finished()
        end
    end
end

return QTutorialPhase13InFirstBattle