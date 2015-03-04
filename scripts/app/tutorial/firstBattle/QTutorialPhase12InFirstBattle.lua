
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase12InFirstBattle = class("QTutorialPhase12InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")

-- BOSS释放狂暴技能（复仇之怒）、然后释放群攻：神圣风暴，火焰法师和治疗挂掉
function QTutorialPhase12InFirstBattle:start()
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)

    kaelthas._hp = 3000
    kaelthas.basic_hp_ = 3000
    kaelthas._hpBeforeLastChange = 3000

    tyrande._hp = 3000
    tyrande.basic_hp_ = 3000
    tyrande._hpBeforeLastChange = 3000

    orc_warlord._hp = 3000
    orc_warlord.basic_hp_ = 3000
    orc_warlord._hpBeforeLastChange = 3000

    local enemies = app.battle:getEnemies()
    self._enemy = enemies[1]

    local skill = self._enemy:getSkillWithId("avenging_wrath")
    self._enemy:attack(skill)

    scheduler.performWithDelayGlobal(function()
        app.battle:pause()
        self._word = "我的爱人！你们都要为她陪葬！"
        self._dialogueRight = QUIWidgetBattleTutorialDialogue.new({isLeftSide = false, text = self._word, isSay = true, name = "莫格莱尼"})
        self._dialogueRight:setActorImage("ui/mograine.png")
        app.scene:addChild(self._dialogueRight)
        app.scene:hideHeroStatusViews()
--        self:_autoTouchEnded(TUTORIAL_WORD_TIME + (#self._word * TUTORIAL_ONEWORD_TIME), function() return self._dialogueRight ~= nil end)

        audio.playSound("audio/sound/vocal/sandtop_4.mp3", false)

        self._stage:enableTouch(handler(self, self._onTouch))
    end, 0.5)
end

function QTutorialPhase12InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._dialogueRight ~= nil and self._dialogueRight._isSaying == true and self._dialogueRight:isVisible() then 
          self._dialogueRight:stopSay()
          self._dialogueRight._ccbOwner.label_text:setString(q.autoWrap(self._word,26,13,312 * 2))
        else
          app.battle:resume()
          self._stage:disableTouch()
          self._dialogueRight:removeFromParent()
          self._dialogueRight = nil
          app.scene:showHeroStatusViews()
  
          local skill = self._enemy:getSkillWithId("divine_storm")
          self._enemy:attack(skill)
  
          scheduler.performWithDelayGlobal(function()
              self._enemy:attack(skill)
          end, 1.7)
  
          scheduler.performWithDelayGlobal(function()
              local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
              local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
              local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
  
              kaelthas._hp = 2
              kaelthas.basic_hp_ = 2
              kaelthas._hpBeforeLastChange = 2
  
              tyrande._hp = 2
              tyrande.basic_hp_ = 2
              tyrande._hpBeforeLastChange = 2
  
              orc_warlord._hp = 2
              orc_warlord.basic_hp_ = 2
              orc_warlord._hpBeforeLastChange = 2
  
              self._enemy:attack(skill)
          end, 3.4)
  
          scheduler.performWithDelayGlobal(function()
              local enemies = app.battle:getEnemies()
              if enemies[2]:isDead() == true then
                  local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
                  orc_warlord:setTarget(self._enemy)
                  scheduler.performWithDelayGlobal(function()
                      self:finished()
                  end, 0.5)
              else
                  self:finished()
              end
              
          end, 5.0)
        end
    end
end


return QTutorialPhase12InFirstBattle