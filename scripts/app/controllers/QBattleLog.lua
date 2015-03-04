
local QModelBase = import("..models.QModelBase")
local QBattleLog = class("QBattleLog", QModelBase)

local QActor = import("..models.QActor")
local QSkill = import("..models.QSkill")
local QTeam = import("..utils.QTeam")
local QAIDirector = import("..ai.QAIDirector")
local QStaticDatabase = import(".QStaticDatabase")
local QFileCache = import("..utils.QFileCache")
local QNotificationCenter = import(".QNotificationCenter")
local QSkeletonViewController = import(".QSkeletonViewController")
local QTutorialStageEnrolling = import("..tutorial.enrolling.QTutorialStageEnrolling")

function QBattleLog:ctor(dungeonId)
    QBattleLog.super.ctor(self)

    local log = {}

    -- 关卡ID
    log.dungeonId = dungeonId

    -- 关卡开始时间
    log.startTime = 0

    -- 关卡结束时间
    log.endTime = 0

    -- 关卡计时片段
    -- e.g. [in json style]
    --[[
		"timeFragment": {
			{
				"start_at": 123.45,
				"end_at": 123.456,
			}
		}
    --]]
    log.timeFragment = {}

    -- 关卡胜利
    -- e.g. true
    log.win = false

    -- 战斗持续时间，单位秒
    -- e.g. 12.87
    log.duration = 0

    -- 英雄状态
    -- e.g. [in json style]
    --[[
		"heroState": {
			"blood_elf": {
				"actor_id": "blood_elf",
				"create_time": 123.456,
				"dead_time": 123.456
			}
		}
    --]]
    log.heroState = {}

    -- 怪物状态
    -- e.g. [in json style]
    --[[
		"monsterState": {
			"normal_deviate_guardian_1_3": {
				"actor_id": "normal_deviate_guardian_1",
				"create_time": 123.456,
				"dead_time": 123.456,
				"monsterIndex" : 1 or nil
			}
		}
    --]]
    log.monsterState = {}

    -- 死亡人数（英雄）
    -- e.g. [in json style]
    --[[
    	"heroDeath": {
	    	"blood_elf": {
	    		"actor_id": "blood_elf"
			},
	    	"orc_warlord": {
	    		"actor_id": "orc_warlord"
			},
    	}
	]]--
    log.heroDeath = {}

    -- NPC直到死亡前存活时间，单位秒
    -- e.g. [in json style]
    --[[
    	"monsterDeath": {
	    	"normal_deviate_guardian_1": {
	    		"actor_id": "normal_deviate_guardian_1",
	    		"life_span": 8.2
			},
	    	"normal_nightmare_ectoplasm_1": {
	    		"actor_id": "normal_nightmare_ectoplasm_1",
	    		"life_span": 6.8
			},
    	}
	]]--
    log.monsterDeath = {}

    -- 上阵的英雄 & 上阵的英雄的战斗力
    -- e.g. [in json style]
    --[[
    	"heroOnStage": {
	    	"blood_elf": {
	    		"actor_id": "blood_elf",
	    		"battle_force": 100
			},
	    	"orc_warlord": {
	    		"actor_id": "orc_warlord",
	    		"battle_force": 100
			},
			"mouse_cute": {
	    		"actor_id": "mouse_cute",
	    		"battle_force": 5
			}
    	}
	]]--
    log.heroOnStage = {}

    -- 技能名，次数（英雄）
    -- e.g. [in json style]
    --[[
    	"heroSkillCast": {
	    	"blood_elf": {
	    		"actor_id": "blood_elf",
	    		"skill_cast": {
	    			"flash_heal_1": {
	    				"skill_id": "flash_heal_1",
	    				"cast_number": 17
	    			}
	    		}
			},
	    	"orc_warlord": {
	    		"actor_id": "orc_warlord",
	    		"skill_cast": {
	    			"phyattack_chop_weapon_1": {
	    				"skill_id": "phyattack_chop_weapon_1",
	    				"cast_number": 8
	    			}
	    		}
			},
			"mouse_cute": {
	    		"actor_id": "mouse_cute",
	    		"skill_cast": {
	    			"袖手旁观": {
	    				"skill_id": "袖手旁观",
	    				"cast_number": 100
	    			},
	    			"打喷嚏": {
	    				"skill_id": "打喷嚏",
	    				"cast_number": 1
	    			}
	    		}
			}
    	}
	]]--
    log.heroSkillCast = {}

    -- 完成最后一击的英雄、宠物、技能
    -- e.g. [in json style]
    --[[
    	"lastHeroAttack": {
    		"actor_id": "mouse_cute",
    		"skill_id": "打喷嚏"
    	}
	]]--
    log.lastHeroAttack = {}

    self._log = log
end

function QBattleLog:getBattleLog()
    return self._log
end

function QBattleLog:setStartTime(time)
	self._log.startTime = time
end

function QBattleLog:setEndTime(time)
	self._log.endTime = time
end

function QBattleLog:setStartCountDown(time)
	local length = #self._log.timeFragment
	if length > 0 then
		if self._log.timeFragment[length].end_at == nil then
			return 
		end
	end
	table.insert(self._log.timeFragment, {start_at = time})
end

function QBattleLog:setEndCountDown(time)
	local length = #self._log.timeFragment
	if length == 0 then
		return 
	end

	if self._log.timeFragment[length].end_at ~= nil then
		return 
	end

	self._log.timeFragment[length].end_at = time
end

function QBattleLog:setIsWin(win)
	self._log.win = win
end

function QBattleLog:setDuration(duration)
	self._log.duration = duration
end

function QBattleLog:addHeroDeath(hero_actor)
	local heroDeath = self._log.heroDeath

	local actor_id = hero_actor:getActorID()
	heroDeath[actor_id] = {actor_id = actor_id}
end

function QBattleLog:addMonsterLifeSpan(monster_actor, life_span)
	local monsterDeath = self._log.monsterDeath

	local actor_id = monster_actor:getActorID()
	monsterDeath[actor_id] = {actor_id = actor_id, life_span = life_span}
end

function QBattleLog:addHeroOnStage(hero_actor, battle_force)
	local heroOnStage = self._log.heroOnStage

	local actor_id = hero_actor:getActorID()
	heroOnStage[actor_id] = {actor_id = actor_id, battle_force = battle_force}
end

function QBattleLog:addHeroSkillCast(hero_actor, skill)
	local heroSkillCast = self._log.heroSkillCast

	local actor_id = hero_actor:getActorID()
	local skill_id = skill:getId()

	if heroSkillCast[actor_id] == nil then
		heroSkillCast[actor_id] = {actor_id = actor_id, skill_cast = {}}
	end

	if heroSkillCast[actor_id].skill_cast[skill_id] == nil then
		heroSkillCast[actor_id].skill_cast[skill_id] = {skill_id = skill_id, cast_number = 0}
	end

	local cast_number = heroSkillCast[actor_id].skill_cast[skill_id].cast_number
	cast_number = cast_number + 1
	heroSkillCast[actor_id].skill_cast[skill_id].cast_number = cast_number
end

function QBattleLog:setLastHeroAttack(hero_actor, skill)
	self._log.lastHeroAttack = {actor_id = hero_actor:getActorID(), skill_id = skill:getId()}
end

function QBattleLog:onHeroCreated(heroId, time)
	if heroId == nil then
		return
	end

	if self._log.heroState[heroId] == nil then
		self._log.heroState[heroId] = {}
	end

	self._log.heroState[heroId].actor_id = heroId
	self._log.heroState[heroId].create_time = time
end

function QBattleLog:onHeroDead(heroId, time)
	if heroId == nil then
		return
	end

	if self._log.heroState[heroId] == nil then
		self._log.heroState[heroId] = {}
	end

	self._log.heroState[heroId].actor_id = heroId
	self._log.heroState[heroId].dead_time = time
end

function QBattleLog:onMonsterCreated(monsterUDId, monsterId, monsterIndex, time)
	if monsterUDId == nil or monsterId == nil then
		return
	end

	if self._log.monsterState[monsterUDId] == nil then
		self._log.monsterState[monsterUDId] = {}
	end

	self._log.monsterState[monsterUDId].actor_id = monsterId
	self._log.monsterState[monsterUDId].create_time = time
	self._log.monsterState[monsterUDId].monsterIndex = monsterIndex
end

function QBattleLog:onMonsterDead(monsterUDId, monsterId, time)
	if monsterUDId == nil or monsterId == nil then
		return
	end

	if self._log.monsterState[monsterUDId] == nil then
		self._log.monsterState[monsterUDId] = {}
	end

	self._log.monsterState[monsterUDId].actor_id = monsterId
	self._log.monsterState[monsterUDId].dead_time = time
end

return QBattleLog