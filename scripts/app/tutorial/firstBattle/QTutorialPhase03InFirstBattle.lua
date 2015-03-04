
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase03InFirstBattle = class("QTutorialPhase03InFirstBattle", QTutorialPhase)

local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")
local QStaticDatabase = import("..controllers.QStaticDatabase")

-- local function _pauseNode(node, actionManager, scheduler)
--     actionManager:pauseTarget(node)
--     scheduler:pauseTarget(node)
--     local children = node:getChildren()
--     if children == nil then
--         return
--     end

--     local i = 0
--     local len = children:count()
--     for i = 0, len - 1, 1 do
--         local child = tolua.cast(children:objectAtIndex(i), "CCNode")
--         _pauseNode(child, actionManager, scheduler)
--     end
-- end

local function _resumeNode(node, actionManager, scheduler)
    actionManager:resumeTarget(node)
    scheduler:resumeTarget(node)
    local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
        local child = tolua.cast(children:objectAtIndex(i), "CCNode")
        _resumeNode(child, actionManager, scheduler)
    end
end

-- 骑士BOSS释放奉献技能，然后战斗画面暂停，MT弹出对话框“红圈为危险区域，需要躲避，选中英雄让他脱离危险区域”，一个点击动作的手型动画出现在一个英雄头顶，手型动画旁边显示“点击”字样，直到用户操作才消失
function QTutorialPhase03InFirstBattle:start()
    scheduler.performWithDelayGlobal(function()
        audio.playSound("audio/sound/vocal/sandtop_2.mp3", false)
        self._word = "用你们的鲜血来洗涤我的灵魂吧！奉献！"
        self._stage:enableTouch(handler(self, self._onTouch))
        self._dialogueLeft = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "莫格莱尼"})
        self._dialogueLeft:setActorImage("ui/mograine.png")
        app.scene:addChild(self._dialogueLeft)
        app.scene:hideHeroStatusViews()
--        self:_autoTouchEnded(TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME), function() return self._firstClick == false end)

        app.battle:pause()

        local enemies = app.battle:getEnemies()
        self._enemy = enemies[1]
        local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
        local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
        local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
        orc_warlord:setTarget(nil)
        kaelthas:setTarget(nil)
        tyrande:setTarget(nil)
        self._enemy:setTarget(nil)

        self._firstClick = false
    end, 3.6)
    self._secondClick = false
end

function QTutorialPhase03InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._dialogueLeft ~= nil and self._dialogueLeft._isSaying == true and self._dialogueLeft:isVisible() and self._word then 
          self._dialogueLeft:stopSay()
          self._dialogueLeft._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        elseif self._firstClick == false then
            self._dialogueLeft:removeFromParent()
            self._dialogueLeft = nil
            app.scene:showHeroStatusViews()

            self._hero = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
            local enemies = app.battle:getEnemies()
            local skill = enemies[1]:getSkillWithId("consecration")
            enemies[1]:attack(skill)
            self._stage:disableTouch()
            app.battle:resume()

            self._firstClick = true

            self._hero:setTarget(enemies[1])
            self._stage:getHeroByTag(self._stage.Tag_kaelthas):setTarget(enemies[1])
            self._stage:getHeroByTag(self._stage.Tag_tyrande):setTarget(self._hero)
            enemies[1]:setTarget(self._hero)
            
            scheduler.performWithDelayGlobal(function()              
                self:finished()
            end, 1.0)

       --      scheduler.performWithDelayGlobal(function()
       --          app.battle:pause()
       --          -- 奉献特效继续播放
       --          _G["_tutorial_allow_trap_play"] = true

       --          self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, text = "注意躲避伤害，看我风骚走位！", isSay = true, name = "督军杰克"})
       --          self._dialogueRight:setActorImage("ui/orc_warlord.png")
       --          app.scene:addChild(self._dialogueRight)
       --          app.scene:hideHeroStatusViews()
       --          self:_autoTouchEnded(3.0, function() return self._secondClick == false end)

       --          self._stage:enableTouch(handler(self, self._onTouch))
       --      end, 1.5)
       --  elseif self._secondClick == false then
       --      self._dialogueRight:removeFromParent()
       --      app.scene:showHeroStatusViews()

       --      self._handTouch = QUIWidgetTutorialHandTouch.new()
       --      local pos = self._hero:getCenterPosition_Stage()
       --      self._handTouch:setPosition(pos.x, pos.y)
       --      app.scene:addChild(self._handTouch)

       --      self._secondClick = true
       --  else
       --  	local boundingBox = self._hero:getBoundingBox_Stage()
       --  	if boundingBox:containsPoint(ccp(event.x, event.y)) == true and self._dialogueLeft ~= nil and self:oneTimeCheck() then
       --  		scheduler.performWithDelayGlobal(function()    				
       --              self._handTouch:removeFromParent()
    			-- 	self._stage:disableTouch()
    			-- 	self:finished()
    			-- end, 0)
       --  	end
        end
    end
end

return QTutorialPhase03InFirstBattle