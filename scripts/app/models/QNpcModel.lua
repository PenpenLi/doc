
--[[--

“NPC”类

从“角色”类继承，增加了经验值等属性

]]

local QActor = import(".QActor")
local QNpcModel = class("QNpcModel", QActor)

local QStaticDatabase = import("..controllers.QStaticDatabase")
local QFileCache = import("..utils.QFileCache")

QNpcModel.schema = clone(QActor.schema)

function QNpcModel:ctor(id, events, callbacks, additional_skills, dead_skill)
    local properties = QStaticDatabase.sharedDatabase():getCharacterByID(id)
    if properties == nil then
        echoError("NPC with id: %s not found!", tostring(id))
    end

    properties = clone(properties)
    properties.actor_id = id
    properties.id = id .. "_" .. uuid()
    properties.udid = properties.id

    local actorInfo = {
        properties = properties,
        level = properties.npc_level,                                             
    }
	self._type = ACTOR_TYPES.NPC
	local dataBase = QStaticDatabase.sharedDatabase()
	local skillIds = {}
    if properties.innate_skill ~= nil then
        if dataBase:getSkillByID(properties.innate_skill) ~= nil then table.insert(skillIds, properties.innate_skill) end
    end
    if properties.npc_skill ~= nil then
        if dataBase:getSkillByID(properties.npc_skill) ~= nil then table.insert(skillIds, properties.npc_skill) end
    end
    if properties.npc_skill_2 ~= nil then
        if dataBase:getSkillByID(properties.npc_skill_2) ~= nil then table.insert(skillIds, properties.npc_skill_2)  end
    end
    local skillIdsForAi = self:getSkillIdWithAiType(properties.npc_ai)
    for _, skillId in ipairs(skillIdsForAi) do
        if dataBase:getSkillByID(skillId) ~= nil then table.insert(skillIds, skillId) end
    end
    if additional_skills then
        for _, skillId in pairs(additional_skills) do
            if dataBase:getSkillByID(skillId) ~= nil then table.insert(skillIds, skillId) end
        end
    end
    self._deadSkill = dead_skill

    actorInfo.skillIds = skillIds
    
    QNpcModel.super.ctor(self, actorInfo, events, callbacks)
end

function QNpcModel:hit(skill, target, split_number, override_damage, original_damage)
    -- 调用父类的 hit() 方法
    return QNpcModel.super.hit(self, skill, target, split_number, override_damage, original_damage)
end

return QNpcModel
