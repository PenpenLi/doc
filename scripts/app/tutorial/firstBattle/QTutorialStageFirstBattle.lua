
local QTutorialStage = import("..QTutorialStage")
local QTutorialStageFirstBattle = class("QTutorialStageFirstBattle", QTutorialStage)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("...ui.QUIViewController")
local QSkeletonViewController = import("...controllers.QSkeletonViewController")
local QFileCache = import("...utils.QFileCache")

local QTutorialPhase00InFirstBattle = import(".QTutorialPhase00InFirstBattle")
local QTutorialPhase01InFirstBattle = import(".QTutorialPhase01InFirstBattle")
local QTutorialPhase02InFirstBattle = import(".QTutorialPhase02InFirstBattle")
local QTutorialPhase03InFirstBattle = import(".QTutorialPhase03InFirstBattle")
local QTutorialPhase04InFirstBattle = import(".QTutorialPhase04InFirstBattle")
local QTutorialPhase05InFirstBattle = import(".QTutorialPhase05InFirstBattle")
local QTutorialPhase06InFirstBattle = import(".QTutorialPhase06InFirstBattle")
local QTutorialPhase07InFirstBattle = import(".QTutorialPhase07InFirstBattle")
local QTutorialPhase08InFirstBattle = import(".QTutorialPhase08InFirstBattle")
local QTutorialPhase09InFirstBattle = import(".QTutorialPhase09InFirstBattle")
local QTutorialPhase10InFirstBattle = import(".QTutorialPhase10InFirstBattle")
local QTutorialPhase11InFirstBattle = import(".QTutorialPhase11InFirstBattle")
local QTutorialPhase12InFirstBattle = import(".QTutorialPhase12InFirstBattle")
local QTutorialPhase13InFirstBattle = import(".QTutorialPhase13InFirstBattle")
local QTutorialPhase14InFirstBattle = import(".QTutorialPhase14InFirstBattle")


QTutorialStageFirstBattle.Tag_orc_warlord = 1
QTutorialStageFirstBattle.Tag_kaelthas = 2
QTutorialStageFirstBattle.Tag_tyrande = 3

local function getSkillIdWithAi(aiConfig, skillIds)
    if aiConfig == nil or skillIds == nil then
        return
    end
    if aiConfig.OPTIONS ~= nil and aiConfig.OPTIONS.skill_id ~= nil then
        table.insert(skillIds, aiConfig.OPTIONS.skill_id)
    end

    if aiConfig.ARGS ~= nil then
        for _, conf in pairs(aiConfig.ARGS) do
            getSkillIdWithAi(conf, skillIds)
        end
    end
end

local function getEffectIdWithSkill(skillConfig, effectIds)
    if skillConfig == nil or effectIds == nil then
        return
    end
    if skillConfig.OPTIONS ~= nil and skillConfig.OPTIONS.effect_id ~= nil then
        table.insert(effectIds, skillConfig.OPTIONS.effect_id)
    end

    if skillConfig.ARGS ~= nil then
        for _, conf in pairs(skillConfig.ARGS) do
            getEffectIdWithSkill(conf, effectIds)
        end
    end
end

local function QTutorialStagePrecache(heroActors, dungeonConfig)
	local dataBase = QStaticDatabase.sharedDatabase()
    
    skeletonFiles = {}
    skillIds = {}

    -- hero actor
  	for i, hero in ipairs(heroActors) do
        local character = dataBase:getCharacterByID(hero.actorId)
        if character ~= nil then
            local characterDisplay = dataBase:getCharacterDisplayByID(character.display_id)
            if characterDisplay ~= nil then
                local actorFile = characterDisplay.actor_file
                local skeletonFile = actorFile .. ".json"
                local atlasFile = actorFile .. ".atlas"
                table.insert(skeletonFiles, {skeletonFile, atlasFile})
            end
        end
        for _, skillId in ipairs(hero.skills) do
            if skillId ~= nil then
                skillIds[skillId] = skillId
            end
        end
    end

    -- enemy actor
    local dungeon = dataBase:getMonstersById(dungeonConfig.monster_id)
    if dungeon ~= nil then
	    for i, monsterInfo in ipairs(dungeon) do
            local character = dataBase:getCharacterByID(monsterInfo.npc_id)
            if character ~= nil then
            	local characterDisplay = dataBase:getCharacterDisplayByID(character.display_id)
            	if characterDisplay ~= nil then
            		local actorFile = characterDisplay.actor_file
            		local skeletonFile = actorFile .. ".json"
            		local atlasFile = actorFile .. ".atlas"
                    table.insert(skeletonFiles, {skeletonFile, atlasFile})
            	end
            end
	    end
    end

    -- enemy skill
     if dungeon ~= nil then
        for i, monsterInfo in ipairs(dungeon) do
            local character = dataBase:getCharacterByID(monsterInfo.npc_id)
            if character ~= nil then
                if character.innate_skill ~= nil then
                    skillIds[character.innate_skill] = character.innate_skill
                end
                if character.npc_skill ~= nil then
                    skillIds[character.npc_skill] = character.npc_skill
                end
                if character.npc_skill_2 ~= nil then
                    skillIds[character.npc_skill_2] = character.npc_skill_2
                end
                if character.npc_ai ~= nil then
                    local config = QFileCache.sharedFileCache():getAIConfigByName(character.npc_ai)
                    if config ~= nil then
                        local skillIdsInAi = {}
                        getSkillIdWithAi(config, skillIdsInAi)
                        for _, skillId in ipairs(skillIdsInAi) do
                            skillIds[skillId] = skillId
                        end
                    end
                end
            end
        end
    end

    local effectIds = {}
    for _, skillId in pairs(skillIds) do
        -- effect of skill
        local skillData = dataBase:getSkillByID(skillId)
        assert(skillData ~= nil, "can not find skill data with id:" .. skillId)
        if skillData ~= nil then
            if skillData.attack_effect ~= nil then
                effectIds[skillData.attack_effect] = skillData.attack_effect
            end
            if skillData.bullet_effect ~= nil then
                effectIds[skillData.bullet_effect] = skillData.bullet_effect
            end
            if skillData.hit_effect ~= nil then
                effectIds[skillData.hit_effect] = skillData.hit_effect
            end
            if skillData.second_hit_effect ~= nil then
                effectIds[skillData.second_hit_effect] = skillData.second_hit_effect
            end
            if skillData.skill_behavior ~= nil then
                local config = QFileCache.sharedFileCache():getSkillConfigByName(skillData.skill_behavior)
                if config ~= nil then
                    local effectIdInSkill = {}
                    getEffectIdWithSkill(config, effectIdInSkill)
                    for _, effectId in ipairs(effectIdInSkill) do
                        effectIds[effectId] = effectId
                    end
                end
            end

            -- effect of buff
            if skillData.buff_id_1 ~= nil then
                local buffData = dataBase:getBuffByID(skillData.buff_id_1)
                assert(buffData ~= nil, "can not find buff data with id:" .. skillData.buff_id_1)
                if buffData.begin_effect_id ~= nil then
                    effectIds[buffData.begin_effect_id] = buffData.begin_effect_id
                end
                if buffData.effect_id ~= nil then
                    effectIds[buffData.effect_id] = buffData.effect_id
                end
                if buffData.finish_effect_id ~= nil then
                    effectIds[buffData.finish_effect_id] = buffData.finish_effect_id
                end
            end
            if skillData.buff_id_2 ~= nil then
                local buffData = dataBase:getBuffByID(skillData.buff_id_2)
                assert(buffData ~= nil, "can not find buff data with id:" .. skillData.buff_id_2)
                if buffData.begin_effect_id ~= nil then
                    effectIds[buffData.begin_effect_id] = buffData.begin_effect_id
                end
                if buffData.effect_id ~= nil then
                    effectIds[buffData.effect_id] = buffData.effect_id
                end
                if buffData.finish_effect_id ~= nil then
                    effectIds[buffData.finish_effect_id] = buffData.finish_effect_id
                end
            end

            -- effect of trap 
            if skillData.trap_id ~= nil then
                local trapData = dataBase:getTrapByID(skillData.trap_id)
                if trapData.start_effect ~= nil then
                    effectIds[trapData.start_effect] = trapData.start_effect
                end
                if trapData.execute_effect ~= nil then
                    effectIds[trapData.execute_effect] = trapData.execute_effect
                end
                if trapData.finish_effect ~= nil then
                    effectIds[trapData.finish_effect] = trapData.finish_effect
                end
            end
        end
    end 

    for _, effectId in pairs(effectIds) do
        local frontFile, backFile = dataBase:getEffectFileByID(effectId)
        if frontFile ~= nil then
            local skeletonFile = frontFile .. ".json"
            local atlasFile = frontFile .. ".atlas"
            table.insert(skeletonFiles, {skeletonFile, atlasFile})
        end
        if backFile ~= nil then
            local skeletonFile = backFile .. ".json"
            local atlasFile = backFile .. ".atlas"
            table.insert(skeletonFiles, {skeletonFile, atlasFile})
        end
    end

    for _, skeleton in pairs(skeletonFiles) do
        QSkeletonDataCache:sharedSkeletonDataCache():cacheSkeletonData(skeleton[1], skeleton[2])
     end
end

function QTutorialStageFirstBattle:ctor()
	QTutorialStageFirstBattle.super.ctor(self)
	local dungeonId = "tutorial"
	local database = QStaticDatabase:sharedDatabase()
	local config = database:getDungeonConfigByID(dungeonId)
	assert(config, "no dungeon for tutorial!")

	-- 兽人战士
	local orc_warlord = {
		actorId = 20002, 
		heroId = "tutorial_orc_warlord", 
		level = 1,
		skills = {"phyattack_chop_weapon_1", "bladestorm_orc_warlord_1", "charge_1"},
		rankCode = "R0",
		exp = 100,
		position = {x = -1, x_ = 3.5, y = 1.6}
	}
	-- 凯尔萨斯
	local kaelthas = {
		actorId = 20001, 
		heroId = "tutorial_kaelthas", 
		level = 1,
		skills = {"fireball_1","blink_1","pyroblast_kaelthas_1"},
		rankCode = "R0",
		exp = 100,
		position = {x = -1, x_ = 2.4, y = 3.25}
	}
	-- 泰兰德
	local tyrande = {
		actorId = 20003, 
		heroId = "tutorial_tyrande", 
		level = 1,
		skills = {"flash_heal_1","power_word_shield_tyrande_1","penance_1"},
		rankCode = "R0",
		exp = 100,
		position = {x = -1, x_ = 1.5, y = 2.3}
	}

	config.heroInfos = {}
	table.insert(config.heroInfos, orc_warlord)
	table.insert(config.heroInfos, kaelthas)
	table.insert(config.heroInfos, tyrande)

	config.isTutorial = true

	app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_PAGE, uiClass = "QUIPageLoadResources", options = {dungeon = config}})
	app:enterIntoBattleScene(config)
    scheduler.performWithDelayGlobal(function()
        scheduler.performWithDelayGlobal(function()
            -- clean texture cache
            app:cleanTextureCache()
        end, 0)
    end, 0)

	QTutorialStagePrecache(config.heroInfos, config)

    self._enableTouch = false

end

function QTutorialStageFirstBattle:_createTouchNode()
	local touchNode = CCNode:create()
    touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
    touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    touchNode:setTouchSwallowEnabled(true)
    app.scene:addChild(touchNode)
    self._touchNode = touchNode
end

function QTutorialStageFirstBattle:enableTouch(func)
	self._enableTouch = true
	self._touchCallBack = func
end

function QTutorialStageFirstBattle:disableTouch()
	self._enableTouch = false
	self._touchCallBack = nil
end

function QTutorialStageFirstBattle:getHeroByTag(tag)
	if tag <= 0 then
		return nil
	end

	local heros = app.battle:getHeroes()
	if table.nums(heros) < tag then
		return nil
	end

	return heros[tag]
end

function QTutorialStageFirstBattle:_createPhases()
    table.insert(self._phases, QTutorialPhase00InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase01InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase02InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase03InFirstBattle.new(self))
	-- table.insert(self._phases, QTutorialPhase04InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase05InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase06InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase07InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase08InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase09InFirstBattle.new(self))
	-- table.insert(self._phases, QTutorialPhase10InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase11InFirstBattle.new(self))
	-- table.insert(self._phases, QTutorialPhase13InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase12InFirstBattle.new(self))
	table.insert(self._phases, QTutorialPhase14InFirstBattle.new(self))

	self._phaseCount = table.nums(self._phases)
end

function QTutorialStageFirstBattle:start()
	self:_createTouchNode()
	self._touchNode:setTouchEnabled(true)
	self._touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QTutorialStageFirstBattle._onTouch))
	QTutorialStageFirstBattle.super.start(self)
end

function QTutorialStageFirstBattle:ended()
    local stage = app.tutorial:getStage()
    stage.forcedGuide = 1
    app.tutorial:setStage(stage)
    app.tutorial:setFlag(stage)
    app.scene:setBattleEnded(true)
    app:exitFromBattleScene(false)
    app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_PAGE, uiClass="QUIPageMainMenu"})
end

function QTutorialStageFirstBattle:_onTouch(event)
	if self._enableTouch == true and self._touchCallBack ~= nil then
		return self._touchCallBack(event)
    elseif event.name == "began" then
        return true
    end
end

return QTutorialStageFirstBattle