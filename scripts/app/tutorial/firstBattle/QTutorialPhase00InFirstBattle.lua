
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase00InFirstBattle = class("QTutorialPhase00InFirstBattle", QTutorialPhase)

local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QTimer = import("..utils.QTimer")

-- 三位英雄进场
function QTutorialPhase00InFirstBattle:start()
    local w = BATTLE_AREA.width / global.screen_big_grid_width
    local h = BATTLE_AREA.height / global.screen_big_grid_height

    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)

    app.grid:moveActorTo(orc_warlord, {x = BATTLE_AREA.left + w * 3.5 - w / 2, y = BATTLE_AREA.bottom + h * 1.6 - h / 2}) 
    app.grid:moveActorTo(kaelthas, {x = BATTLE_AREA.left + w * 2.4 - w / 2, y = BATTLE_AREA.bottom + h * 3.25 - h / 2}) 
    app.grid:moveActorTo(tyrande, {x = BATTLE_AREA.left + w * 1.5 - w / 2, y = BATTLE_AREA.bottom + h * 2.3 - h / 2}) 

    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    local kaelthas = self._stage:getHeroByTag(self._stage.Tag_kaelthas)
    local tyrande = self._stage:getHeroByTag(self._stage.Tag_tyrande)

    -- 锁住技能不让用
    app.scene:showHeroStatusViews()
    local bladestorm = orc_warlord:getSkillWithId("bladestorm_orc_warlord_1")
    local powerwordshield = tyrande:getSkillWithId("power_word_shield_tyrande_1")
    local pyroblast = kaelthas:getSkillWithId("pyroblast_kaelthas_1")
    bladestorm:set("cd", 120)
    powerwordshield:set("cd", 120)
    pyroblast:set("cd", 120)
    bladestorm:set("first_cd", 16)
    powerwordshield:set("first_cd", 14)
    pyroblast:set("first_cd", 30)
    bladestorm:coolDown()
    powerwordshield:coolDown()
    pyroblast:coolDown()
end

function QTutorialPhase00InFirstBattle:visit()
    local orc_warlord = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
    if not orc_warlord:isWalking() then
        self:finished()
    end
end

return QTutorialPhase00InFirstBattle