--
-- Author: Qinyuanji
-- Date: 2015-02-28
-- 
-- This class is to pop up the corresponding page/dialog in terms of guide for battle lose

local QTutorialDefeatedGuide = class("QTutorialDefeatedGuide")

local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIDialogHeroInformation = import("...ui.dialogs.QUIDialogHeroInformation")

QTutorialDefeatedGuide.TAVERN = "Tavern"
QTutorialDefeatedGuide.SKILL = "Skill"
QTutorialDefeatedGuide.EQUIPMENT = "Equipment"
QTutorialDefeatedGuide.FARM = "Farm"
QTutorialDefeatedGuide.STARUP = "StarUp"
QTutorialDefeatedGuide.UPGRADE = "Upgrade"

local function getPosByHeroID(heroes, heroId)
    local pos = 1
    for i, actorId in ipairs(heroes) do
        if actorId == heroId then
            pos = i
            break
        end
    end

    return pos
end

function QTutorialDefeatedGuide:ctor()
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialDefeatedGuide.SKILL, self.onSkill,self) 
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialDefeatedGuide.EQUIPMENT, self.onEquipment,self) 
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialDefeatedGuide.FARM, self.onFarm,self) 
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialDefeatedGuide.STARUP, self.onStarup,self) 
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialDefeatedGuide.UPGRADE, self.onUpgrade,self) 
    QNotificationCenter.sharedNotificationCenter():addEventListener(QTutorialDefeatedGuide.TAVERN, self.onTavern,self) 
end

function QTutorialDefeatedGuide:detach()
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialDefeatedGuide.SKILL, self.onSkill,self) 
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialDefeatedGuide.EQUIPMENT, self.onEquipment,self) 
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialDefeatedGuide.FARM, self.onFarm,self) 
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialDefeatedGuide.STARUP, self.onStarup,self) 
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialDefeatedGuide.UPGRADE, self.onUpgrade,self) 
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QTutorialDefeatedGuide.TAVERN, self.onTavern,self) 
end

function QTutorialDefeatedGuide:onSkill(event)
    print("onSkill " .. event.options)
    local pos = getPosByHeroID(remote.herosUtil:getHaveHeroKey(), event.options)
    app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogHeroInformation",
         options = {hero = remote.herosUtil:getHaveHeroKey(), pos = pos, detailType = QUIDialogHeroInformation.HERO_SKILL}})
end

function QTutorialDefeatedGuide:onEquipment()
    print("onEquipment")
end

function QTutorialDefeatedGuide:onFarm()
    print("onFarm")
end

-- event.options is hero Id
function QTutorialDefeatedGuide:onStarup(event)
    print("onStarup " .. event.options)
    local pos = getPosByHeroID(remote.herosUtil:getHaveHeroKey(), event.options)
    app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogHeroInformation",
         options = {hero = remote.herosUtil:getHaveHeroKey(), pos = pos}})
end

-- event.options is hero Id
function QTutorialDefeatedGuide:onUpgrade(event)
    print("onUpgrade " .. event.options)
     local pos = getPosByHeroID(remote.herosUtil:getHaveHeroKey(), event.options)
   app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogHeroInformation",
         options = {hero = remote.herosUtil:getHaveHeroKey(), pos = pos, detailType = QUIDialogHeroInformation.HERO_UPGRADE}})
end

function QTutorialDefeatedGuide:onTavern()
    return app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogTreasureChestDraw"})
end

return QTutorialDefeatedGuide
