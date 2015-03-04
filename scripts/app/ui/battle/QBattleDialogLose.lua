--
-- Author: Your Name
-- Date: 2014-05-20 10:08:48
--
local QBattleDialog = import(".QBattleDialog")
local QBattleDialogLose = class(".QBattleDialogLose", QBattleDialog)
local QTutorialDefeatedGuide = import("...tutorial.defeated.QTutorialDefeatedGuide")
local QStaticDatabase = import("...controllers.QStaticDatabase")

local function pass()
	return true
end

local function noPass()
	return false
end 

function QBattleDialogLose:ctor(data,owner)
	local ccbFile = "ccb/Battle_Dialog_Defeat.ccbi"
	local callBacks = {
						{ccbCallbackName = "onTriggerNext", callback = handler(self, QBattleDialogLose._onTriggerNext)},
						{ccbCallbackName = "onDefeatedGuide", callback = handler(self, QBattleDialogLose._onDefeatedGuide)}
					}

	if owner == nil then 
		owner = {}
	end

	QBattleDialogLose.super.ctor(self,ccbFile,owner,callBacks)

	self.guidePrompts = {
		{title = "装备穿戴", pic = "equipment", comment = "穿戴齐战甲才能英勇杀敌，\n快去穿装备！", condition = noPass, event = QTutorialDefeatedGuide.EQUIPMENT},
		{title = "英雄技能", pic = "skill", comment = "提升技能，才能愉快的biubiu\nbiu！快去提升再战！", condition = QBattleDialogLose.checkSkillPass, event = QTutorialDefeatedGuide.SKILL},
		{title = "装备获取", pic = "farm", comment = "点“+”号可以快捷刷装备，\n小伙伴你知道嘛！", condition = noPass, event = QTutorialDefeatedGuide.FARM},
		{title = "英雄升级", pic = "upgrade", comment = "升级才能滑行在风头浪尖！\n速速去升级吧！", condition = QBattleDialogLose.checkUpgradePass, event = QTutorialDefeatedGuide.UPGRADE},
		{title = "英雄升星", pic = "starUp", comment = "升星才是第一战斗力~！\n\\\(≧▽≦)/", condition = QBattleDialogLose.checkStarupPass, event = QTutorialDefeatedGuide.STARUP},
		{title = "酒馆", pic = "tavern", comment = "喝喝小酒，吹吹小牛，英雄\n美女都快到我碗里来！", condition = function () return true end, event = QTutorialDefeatedGuide.TAVERN}
	}
	self._actorId = nil
	self._availableHeroIDs = remote.herosUtil:getHaveHeroKey()

	-- app.battle:resume()
	-- self._ccbOwner.node_arena:setVisible(false)

	if data ~= nil and data.description ~= nil and data.description ~= "" then
		self._ccbOwner.description:setString("本关攻略：" .. data.description)
	else
		self._ccbOwner.description:setVisible(false)
	end

	self:hideAllPic()
	self:chooseBestGuide()

  	self._audioHandler = app.sound:playSound("battle_failed")
    audio.stopBackgroundMusic()
end

function QBattleDialogLose:hideAllPic()
	for _, v in ipairs(self.guidePrompts) do 
		self._ccbOwner[v.pic]:setVisible(false)
	end
end

function QBattleDialogLose:chooseBestGuide()
	for _, v in ipairs(self.guidePrompts) do 
		if v.condition(self) then
			self._ccbOwner.title:setString(v.title)
			self._ccbOwner.comment:setString(v.comment)
			self._ccbOwner[v.pic]:setVisible(true)
			self.guideEvent = v.event
			break
		end
	end
end

function QBattleDialogLose:checkSkillPass()
	-- Check if skill upgrade is unlocked
	local config = QStaticDatabase:sharedDatabase():getConfiguration()
	if remote.instance:checkIsPassByDungeonId(config.UNLOCK_SKILLS.value) == false then
        return false
    end

    -- Check if skill upgrade is available and 雕文 is enough
    for _, v in ipairs(self._availableHeroIDs) do 
	    local breakthroughConfig = QStaticDatabase:sharedDatabase():getBreakthroughHeroByActorId(v)
	    if breakthroughConfig ~= nil then
	        for _, value in pairs(breakthroughConfig) do
				local heroInfo = remote.herosUtil:getHeroByID(v)
			    for _, skillId in pairs(heroInfo.skills) do
			        local skillConfig = QStaticDatabase:sharedDatabase():getSkillByID(skillId)
			        if skillConfig.name == value.skills then
						local nextSkill = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(skillConfig.name, skillConfig.level+1)
						if nextSkill ~= nil and nextSkill.hero_level <= heroInfo.level and
							nextSkill.item_cost <= remote.items:getItemsNumByID(12) then
							self._actorId = v
							return true
						end
			        end
	            end
	        end
	    end
	end

    return false
end

function QBattleDialogLose:checkUpgradePass()
	-- Check if exp item exists
	local expItems = QStaticDatabase:sharedDatabase():getItemsByProp("exp")
	if expItems == nil or #expItems == 0 then
		return false
	end

	-- Check if any hero can upgrade
	for _, v in ipairs(self._availableHeroIDs) do
		if remote.herosUtil:heroCanUpgrade(v) == true then
			self._actorId = v
			return true
		end
	end

	return false
end

function QBattleDialogLose:checkStarupPass()
	-- Check if any hero can upgrade
	for _, v in ipairs(self._availableHeroIDs) do
		local hero = remote.herosUtil:getHeroByID(v)
		local maxGrade = QStaticDatabase:sharedDatabase():getGradeByHeroId(v)
		if hero.grade < (#maxGrade - 1) then
			self._actorId = v
			return true
		end
	end

	return false
end

function QBattleDialogLose:_backClickHandler()
    self:_onTriggerNext()
end

function QBattleDialogLose:_onTriggerNext()
  	app.sound:playSound("common_item")
	self._ccbOwner:onChoose()
end

function QBattleDialogLose:_onDefeatedGuide()
	self._ccbOwner:onChoose({name = self.guideEvent, options = self._actorId})
end

return QBattleDialogLose