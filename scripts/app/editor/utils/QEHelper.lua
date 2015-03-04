
local QEHelper = class("QEHelper")

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QEHelper:ctor()
	
end

function QEHelper:getHeroIds()
	local characterIds = QStaticDatabase:sharedDatabase():getCharacterIDs()
	local heroIds = {}
	for _, characterId in ipairs(characterIds) do
		local character = QStaticDatabase:sharedDatabase():getCharacterByID(characterId)
		if character ~= nil and character.talent ~= nil then
			if character.id ~= "kaelthas_new" 
				and character.id ~= "orc_warlord_new" 
				and character.id ~= "tyrande_new" 
				and character.id ~= "valeera_sanguinar" 
				and character.id ~= "blackdrake_bloodfang" 
				and character.id ~= "garona"
			then
				table.insert(heroIds, character.id)
			end
		end
	end
	
	return heroIds
end

function QEHelper:getHeroItems(heroId, breakthrough)
	local items = {}
	if heroId == nil or breakthrough == nil then
		return items
	end

	local characterInfo = QStaticDatabase:sharedDatabase():getCharacterByID(heroId)
	if characterInfo == nil then
		return items
	end

	local breakThroughInfo = QStaticDatabase:sharedDatabase():getBreakthroughByTalentLevel(characterInfo.talent, breakthrough + 1)
	if breakThroughInfo == nil then
		if breakthrough + 1 > 1 then
			for i = breakthrough + 1 - 1, 1, -1 do
				breakThroughInfo = QStaticDatabase:sharedDatabase():getBreakthroughByTalentLevel(characterInfo.talent, i)
				if breakThroughInfo ~= nil then
					break
				end
			end
		end
		
		if breakThroughInfo == nil then
			return items
		end
	end

	table.insert(items, breakThroughInfo.weapon)
	table.insert(items, breakThroughInfo.hat)
	table.insert(items, breakThroughInfo.clothes)
	table.insert(items, breakThroughInfo.bracelet)
	table.insert(items, breakThroughInfo.shoes)
	table.insert(items, breakThroughInfo.jewelry)

	return items
end

function QEHelper:getHeroSkills(heroId, heroLevel, breakthrough, isMaxLevel)
	local skills = {}
	if heroId == nil or breakthrough == nil then
		return skills
	end

	local breakThroughHeroInfo = QStaticDatabase:sharedDatabase():getBreakthroughHeroByActorId(heroId)
	if breakThroughHeroInfo == nil then
		return skills
	end

	if heroLevel == nil then
		heroLevel = 1
	end

	if isMaxLevel == nil then
		isMaxLevel = true 
	end

	if breakthrough < 0 then
		breakthrough = 0
	end

	local needLevel = heroLevel
	if isMaxLevel ~= true then
		needLevel = math.ceil(needLevel * 0.5)
	end

	local skillNames = {}
	for i = 0, breakthrough do
		local info = QStaticDatabase:sharedDatabase():getBreakthroughByHeroActorLevel(heroId, i)
		if info.skill_1 ~= nil and string.len(info.skill_1) > 0 then
			skillNames[info.skill_1] = info.skill_1
		end
		if info.skill_2 ~= nil and string.len(info.skill_2) > 0 then
			skillNames[info.skill_2] = info.skill_2
		end
		if info.skills ~= nil and string.len(info.skills) > 0 then
			skillNames[info.skills] = info.skills
		end
		if info.skills_2 ~= nil and string.len(info.skills_2) > 0 then
			skillNames[info.skills_2] = info.skills_2
		end
	end

	local skillIds = {}
	for _, skillName in pairs(skillNames) do
		local skill = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(skillName, needLevel)
		if skill == nil then
			if needLevel > 1  then
				for i = needLevel - 1, 1, -1 do
					skill = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(skillName, i)
					if skill ~= nil then
						table.insert(skillIds, skill.id)
						break
					end
				end
			end
		else
			table.insert(skillIds, skill.id)
		end
	end

	skills = skillIds

	return skills
end

return QEHelper