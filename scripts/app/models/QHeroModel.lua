
--[[--

“英雄”类

从“角色”类继承，增加了经验值等属性

]]

local QActor = import(".QActor")
local QHeroModel = class("QHeroModel", QActor)

local QStaticDatabase = import("..controllers.QStaticDatabase")
local QUserData = import("..utils.QUserData")
local QSkill = import(".QSkill")

QHeroModel.EXP_CHANGED_EVENT = "EXP_CHANGED_EVENT"
QHeroModel.LEVEL_UP_EVENT = "LEVEL_UP_EVENT"

QHeroModel.schema = clone(QActor.schema)
QHeroModel.schema["exp"] = {"number", 0}

function QHeroModel:ctor(heroInfo, events, callbacks)
    
    local properties = QStaticDatabase.sharedDatabase():getCharacterByID(heroInfo.actorId)
    if properties == nil then
        echoError("Hero with id: %s not found!", tostring(heroInfo.actorId))
    end
    properties = clone(properties)
    properties.actor_id = properties.id
    properties.id = properties.id .. "_" .. uuid()
    properties.udid = properties.id

    local actorInfo = {
        properties = properties,
        actorId = heroInfo.actorId,
        level = heroInfo.level,
        equipments = heroInfo.equipments,
        skillIds = clone(heroInfo.skills),
        breakthrough = heroInfo.breakthrough,  
        grade = heroInfo.grade,   
        rankCode = heroInfo.rankCode,          
    }
    self._type = ACTOR_TYPES.HERO
    table.insert(actorInfo.skillIds, "beattacked_reduce_cd")
    QHeroModel.super.ctor(self, actorInfo, events, callbacks)
    
    self._exp = heroInfo.exp

    self._actorId = heroInfo.actorId
end

-- 增加经验值，并升级
function QHeroModel:increaseEXP(exp)
    if exp == nil or exp == 0 then return end
    assert(not self:isDead(), string.format("QHeroModel %s is dead, can't increase Exp", self:getId()))
    assert(exp > 0, "QHeroModel:increaseEXP() - invalid exp")

    self._exp = self._exp + exp
    -- 简化的升级算法，每一个级别升级的经验值都是固定的
    local needExp = self:getLevelFullExp()
    while self._exp >= needExp do
        self.level_ = self.level_ + 1
        self._exp = self._exp - needExp
        needExp = self:getLevelFullExp()
        self:setFullHp() -- 每次升级，HP 都完全恢复
        self:dispatchEvent({name = QHeroModel.LEVEL_UP_EVENT})
    end
    self:dispatchEvent({name = QHeroModel.EXP_CHANGED_EVENT})

    return self
end

function QHeroModel:getExp()
    return self._exp
end

function QHeroModel:hit(skill, target, split_number, override_damage, original_damage)
    -- 调用父类的 hit() 方法
    return QHeroModel.super.hit(self, skill, target, split_number, override_damage, original_damage)
    -- if damage > 0 then
    --     -- 每次攻击成功，增加 10 点 EXP
    --     self:increaseEXP(10)
    -- end
end

return QHeroModel
