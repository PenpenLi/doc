
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase07InFirstBattle = class("QTutorialPhase07InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")

-- 战斗继续，直到骑士BOSS死亡
function QTutorialPhase07InFirstBattle:start()
    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
    local enemies = app.battle:getEnemies()
    self._enemy = enemies[1]

    self._enemy:setTarget(orc_warlord)
    -- self._enemy._hp = 300
    -- self._enemy.basic_hp_ = 300
    -- self._enemy._hpBeforeLastChange = 300

    orc_warlord:setTarget(self._enemy)
    kaelthas:setTarget(self._enemy)
    tyrande:setTarget(orc_warlord)
end

function QTutorialPhase07InFirstBattle:visit()
    if not self.entered and self._enemy:isDead() == true then
        self.entered = true
        local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
        local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
        local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)
        orc_warlord:_cancelCurrentSkill()
        kaelthas:_cancelCurrentSkill()
        tyrande:_cancelCurrentSkill()
        orc_warlord:setTarget(nil)
        kaelthas:setTarget(nil)
        tyrande:setTarget(nil)

        -- 欢庆动作
        orc_warlord:onVictory()
        kaelthas:onVictory()
        tyrande:onVictory()
        app.scene:getActorViewFromModel(orc_warlord)._victory = false
        app.scene:getActorViewFromModel(kaelthas)._victory = false
        app.scene:getActorViewFromModel(tyrande)._victory = false 
        scheduler.performWithDelayGlobal(function()       
            self:finished()
        end, 3.0)
    end
end


return QTutorialPhase07InFirstBattle