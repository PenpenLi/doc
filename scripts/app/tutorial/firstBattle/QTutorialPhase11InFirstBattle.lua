
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase11InFirstBattle = class("QTutorialPhase11InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

-- 火焰法师头顶弹出对话框“技能全开，速度RUSH！”，点击的手型动画出现在输出技能图标上，显示“点击释放技能”字样，直到用户操作后才消失
function QTutorialPhase11InFirstBattle:start()
    self._stage:enableTouch(handler(self, self._onTouch))

    app.battle:pause()

    audio.playSound("audio/sound/vocal/kaelthas_1.mp3", false)
    self._word = "这货居然会复活，看我致命一击！炎爆术！"
    self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, text = self._word, isSay = true, name = "凯尔萨斯"})
    self._dialogueRight:setActorImage("ui/kaelthas.png")
    app.scene:addChild(self._dialogueRight)
    app.scene:hideHeroStatusViews()
--    self:_autoTouchEnded(3.0, function() return self._firstClick == false end)

    self._firstClick = false
end

function QTutorialPhase11InFirstBattle:_onTouch(event)
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

            local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
            local skill = kaelthas:getSkillWithId("pyroblast_kaelthas_1")
            skill:_stopCd()

            local heroStatusView = app.scene._heroStatusViews[self._stage.Tag_kaelthas]
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
            app.battle:resume()
            local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
            local skill = kaelthas:getSkillWithId("pyroblast_kaelthas_1")
            local whitemane = app.battle:getEnemies()[2]
            whitemane._hp = 150
            whitemane._hpBeforeLastChange = 150
            
            if kaelthas:getTarget() == nil or kaelthas:getTarget():isDead() then
                local enemies = app.battle:getEnemies()
                for _, enemy in ipairs(enemies) do
                    if enemy:isDead() == false then
                        kaelthas:setTarget(enemy)
                    end
                end
            end
            scheduler.performWithDelayGlobal(function()
                kaelthas:attack(skill)
            end, 0.0)
            self._handTouch:removeFromParent()

            -- local handle
            handle = scheduler.scheduleGlobal(function()
                local enemies = app.battle:getEnemies()
                self._enemy = enemies[2]
                if self._enemy:isDead() then
                    audio.playSound("audio/sound/vocal/gahzrilla_3.mp3", false)
                    scheduler.unscheduleGlobal(handle)

                    -- scheduler.performWithDelayGlobal(function()
                    --     app.battle:pause()
                    --     self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = "这次我上场的时间又这么短么。。。", isSay = true, name = "怀特迈恩"})
                    --     self._dialogueRight:setActorImage("ui/whitemane.png")
                    --     app.scene:addChild(self._dialogueRight)
                    --     app.scene:hideHeroStatusViews()
                    --     self:_autoTouchEnded(3.0, function() return self._secondClick == false end)

                    --     self._stage:enableTouch(handler(self, self._onTouch))
                    --     self._secondClick = false
                    -- end, 0.7)
            
                    self:finished()
                end
            end, 0)
            
            self._stage:disableTouch()
            -- self:finished()
        -- elseif self._secondClick == false then
        --     self._secondClick = true
        --     app.battle:resume()
        --     self._stage:disableTouch()
        --     self._dialogueRight:removeFromParent()
        --     app.scene:showHeroStatusViews()

        --     self:finished()
        end
    end
end


return QTutorialPhase11InFirstBattle