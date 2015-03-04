
local QUIPage = import(".QUIPage")
local QUIPageLoadResources = class("QUIPageLoadResources", QUIPage)

local QUIWidgetLoadBar = import("..widgets.QUIWidgetLoadBar")
local QUIWidgetLoadTF = import("..widgets.QUIWidgetLoadTF")
local QUIWidgetGameTips = import("..widgets.QUIWidgetGameTips")
local QUIWidgetLoadingAnimation = import("..widgets.QUIWidgetLoadingAnimation")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QSkeletonViewController = import("...controllers.QSkeletonViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QFileCache = import("...utils.QFileCache")
local QTeam = import("...utils.QTeam")

function QUIPageLoadResources:ctor(options)
    QUIPageLoadResources.super.ctor(self, nil, nil, options)
    self._view = CCNode:create()
    self._view:addChild(CCLayerColor:create(ccc4(0, 0, 0, 255), display.width, display.height))
    if options ~= nil then
    	self._dungeonConfig = options.dungeon
    end

    self.fromController = options.fromController

    self._bar = QUIWidgetLoadBar.new()
    self._bar:setVisible(false)
    self._view:addChild(self._bar)

    self._loadingAnimation = QUIWidgetLoadingAnimation.new()
    self._view:addChild(self._loadingAnimation)
    self._loadingAnimation:setPosition(display.cx, display.cy)

    self._loadingTF = QUIWidgetLoadTF.new()
    self._view:addChild(self._loadingTF)
    self._loadingTF:setPosition(display.cx, display.height * 0.4)
    self._loadingTF:update(0)

    self._gameTips = QUIWidgetGameTips.new()
    self._view:addChild(self._gameTips)
    self._gameTips:setPosition(display.cx, display.height * 0.15)
    self._gameTips:setVisible(false)
end

function QUIPageLoadResources:loadBattleResources()
    scheduler.performWithDelayGlobal(function()
        scheduler.performWithDelayGlobal(function()
            -- clean texture cache
            app:cleanTextureCache()
            self:_prepareBattleData()
            self:_enterBattle()
        end, 0)
    end, 0)
end

function QUIPageLoadResources:_prepareBattleData()
	if self._dungeonConfig == nil then
		return
	end

	local dataBase = QStaticDatabase.sharedDatabase()
    
    self._skeletonFile = {}

    -- hero actor
    if remote.teams ~= nil then
      	for i, heroId in ipairs(remote.teams:getTeams(QTeam.INSTANCE_TEAM)) do
            local hero = remote.herosUtil:getHeroByID(heroId)
            if hero~= nil then
                local character = dataBase:getCharacterByID(hero.actorId)
                if character ~= nil then
                    local characterDisplay = dataBase:getCharacterDisplayByID(character.display_id)
                    if characterDisplay ~= nil then
                        local actorFile = characterDisplay.actor_file
                        local skeletonFile = actorFile .. ".json"
                        local atlasFile = actorFile .. ".atlas"
                        table.insert(self._skeletonFile, {skeletonFile, atlasFile})
                    end
                end
            end
        end
    end

    -- enemy actor
    local dungeon = dataBase:getMonstersById(self._dungeonConfig.monster_id)
    if dungeon ~= nil then
	    for i, monsterInfo in ipairs(dungeon) do
            local character = dataBase:getCharacterByID(app:getBattleRandomNpc(self._dungeonConfig.monster_id, i, monsterInfo.npc_id))
            if character ~= nil then
            	local characterDisplay = dataBase:getCharacterDisplayByID(character.display_id)
            	if characterDisplay ~= nil then
            		local actorFile = characterDisplay.actor_file
            		local skeletonFile = actorFile .. ".json"
            		local atlasFile = actorFile .. ".atlas"
                    table.insert(self._skeletonFile, {skeletonFile, atlasFile})
            	end
            end
	    end
    end

    local skillIds = {}
    -- hero skill
    if remote.teams ~= nil then
        for i, heroId in ipairs(remote.teams:getTeams(QTeam.INSTANCE_TEAM)) do
            local hero = remote.herosUtil:getHeroByID(heroId)
            if hero~= nil then
                for _, skillId in ipairs(hero.skills) do
                    if skillId ~= nil and string.len(skillId) > 0 then
                        skillIds[skillId] = skillId
                    end
                end
            end
        end
    end

    -- enemy skill
     if dungeon ~= nil then
        for i, monsterInfo in ipairs(dungeon) do
            local character = dataBase:getCharacterByID(app:getBattleRandomNpc(self._dungeonConfig.monster_id, i, monsterInfo.npc_id))
            if character ~= nil then
                if character.innate_skill ~= nil and string.len(character.innate_skill) > 0 then
                    skillIds[character.innate_skill] = character.innate_skill
                end
                if character.npc_skill ~= nil and string.len(character.npc_skill) > 0 then
                    skillIds[character.npc_skill] = character.npc_skill
                end
                if character.npc_skill_2 ~= nil and string.len(character.npc_skill_2) > 0 then
                    skillIds[character.npc_skill_2] = character.npc_skill_2
                end
                if character.npc_ai ~= nil then
                    local config = QFileCache.sharedFileCache():getAIConfigByName(character.npc_ai)
                    if config ~= nil then
                        local skillIdsInAi = {}
                        self:_getSkillIdWithAi(config, skillIdsInAi)
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
                    self:_getEffectIdWithSkill(config, effectIdInSkill)
                    for _, effectId in ipairs(effectIdInSkill) do
                        effectIds[effectId] = effectId
                    end
                end
            end

            -- effect of buff
            if skillData.buff_id_1 ~= nil then
                local buffData = dataBase:getBuffByID(skillData.buff_id_1)
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
            table.insert(self._skeletonFile, {skeletonFile, atlasFile})
        end
        if backFile ~= nil then
            local skeletonFile = backFile .. ".json"
            local atlasFile = backFile .. ".atlas"
            table.insert(self._skeletonFile, {skeletonFile, atlasFile})
        end
    end

    -- game tips, maximum 10 tips @qinyuanji
    self._gameTipsText = {}
    local rawGameTips = dataBase:getGameTipsByID(self._dungeonConfig.id)
    if rawGameTips ~= nil then
        for i = 1, 10 do
            local gametip = rawGameTips["gametips_" .. tostring(i)]
            if gametip ~= nil then
                table.insert(self._gameTipsText, gametip)
            else 
                break
            end
        end
        self._randomIndex = math.random(#self._gameTipsText)
        self:_setRandomeTips()
        self._gameTips:setVisible(true)
    end

    -- loading cost 1.5s at least
    if #self._skeletonFile < 90 then
        local nilCount = 90 - #self._skeletonFile
        for i = 1, nilCount do
            table.insert(self._skeletonFile, {nil, nil})
        end
    end

end

function QUIPageLoadResources:_getSkillIdWithAi(aiConfig, skillIds)
    if aiConfig == nil or skillIds == nil then
        return
    end
    if aiConfig.OPTIONS ~= nil and aiConfig.OPTIONS.skill_id ~= nil then
        table.insert(skillIds, aiConfig.OPTIONS.skill_id)
    end

    if aiConfig.ARGS ~= nil then
        for _, conf in pairs(aiConfig.ARGS) do
            self:_getSkillIdWithAi(conf, skillIds)
        end
    end
end

function QUIPageLoadResources:_getEffectIdWithSkill(skillConfig, effectIds)
    if skillConfig == nil or effectIds == nil then
        return
    end
    if skillConfig.OPTIONS ~= nil and skillConfig.OPTIONS.effect_id ~= nil then
        table.insert(effectIds, skillConfig.OPTIONS.effect_id)
    end

    if skillConfig.ARGS ~= nil then
        for _, conf in pairs(skillConfig.ARGS) do
            self:_getEffectIdWithSkill(conf, effectIds)
        end
    end
end

function QUIPageLoadResources:_enterBattle()
	if self._dungeonConfig == nil then
		return
	end
    self._loadingIndex = 1
    self._frameId = scheduler.scheduleUpdateGlobal(handler(self, QUIPageLoadResources._onLoadingFrame))

    -- add game tips scheduler @qinyuanji
    if self._gameTips ~= nil and #self._gameTipsText > 0 then
        local config = QStaticDatabase:sharedDatabase():getConfiguration()
        self._tipSwitchingId = scheduler.scheduleGlobal(handler(self, QUIPageLoadResources._onTipSwitching), config.TIPS and config.TIPS.value or 2)
    end
end

function QUIPageLoadResources:_onLoadingFrame(dt)
    if self._skeletonFile == nil or self._loadingIndex > #self._skeletonFile then
        scheduler.unscheduleGlobal(self._frameId)
        self._frameId = nil

        -- When loading is done, remove scheduler for switching game tips @qinyuanji
        if self._tipSwitchingId ~= nil then
            scheduler.unscheduleGlobal(self._tipSwitchingId)
            self._tipSwitchingId = nil
        end

        app:enterIntoBattleScene(self._dungeonConfig)
        return
    end

    self._loadingTF:update(self._loadingIndex/#self._skeletonFile)

    local item = self._skeletonFile[self._loadingIndex]
    if item[1] ~= nil and item[2] ~= nil then
        QSkeletonDataCache:sharedSkeletonDataCache():cacheSkeletonData(item[1], item[2])
    end
    self._loadingIndex = self._loadingIndex + 1
end

-- switch tips intermittently @qinyuanji
function QUIPageLoadResources:_onTipSwitching(dt)
    self:_setRandomeTips()
 end

-- update game tips text and center the tips @qinyuanji
function QUIPageLoadResources:_setRandomeTips()
    local newTipsWidth = self._gameTips:setString(self._gameTipsText[self._randomIndex])   
    self._randomIndex = ((self._randomIndex == #self._gameTipsText) and 1) or self._randomIndex + 1

    -- center the tips
    local originalTipsWidth = self._gameTips:getTipsOriginalWidth()
    local newPosX = display.cx + (originalTipsWidth - newTipsWidth)/2
    self._gameTips:setPosition(newPosX, self._gameTips:getPositionY())
end

return QUIPageLoadResources
