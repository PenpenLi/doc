
--[[--

“角色”类

level 是角色的等级，角色的攻击力、防御力、初始 Hp 都和 level 相关

]]

local QModelBase = import("..models.QModelBase")
local QActor = class("QActor", QModelBase)

local QSkill = import(".QSkill")
local QBuff = import(".QBuff")
local QHitLog = import("..utils.QHitLog")
local QStaticDatabase = import("..controllers.QStaticDatabase")
local QBattleManager = import("..controllers.QBattleManager")
local QSBDirector = import("..skill.QSBDirector")
local QTrapDirector = import("..trap.QTrapDirector")
local QFileCache = import("..utils.QFileCache")

-- 常量
QActor.ATTACK_COOLDOWN = 0.2 -- 开火冷却时间

-- 定义事件
QActor.CHANGE_STATE_EVENT       = "CHANGE_STATE_EVENT"
QActor.START_EVENT              = "START_EVENT"
QActor.READY_EVENT              = "READY_EVENT"
QActor.ATTACK_EVENT             = "ATTACK_EVENT"
QActor.MOVE_EVENT               = "MOVE_EVENT"
QActor.FREEZE_EVENT             = "FREEZE_EVENT"
QActor.THAW_EVENT               = "THAW_EVENT"
QActor.KILL_EVENT               = "KILL_EVENT"
QActor.RELIVE_EVENT             = "RELIVE_EVENT"
QActor.HP_CHANGED_EVENT         = "HP_CHANGED_EVENT"
QActor.CP_CHANGED_EVENT         = "CP_CHANGED_EVENT"
QActor.UNDER_ATTACK_EVENT       = "UNDER_ATTACK_EVENT"
QActor.SET_POSITION_EVENT       = "SET_POSITION_EVENT"
QActor.VICTORY_EVENT            = "VICTORY_EVENT"
QActor.USE_MANUAL_SKILL_EVENT   = "USE_MANUAL_SKILL_EVENT"
QActor.ONE_TRACK_START_EVENT    = "ONE_TRACK_START_EVENT"
QActor.ONE_TRACK_END_EVENT      = "ONE_TRACK_END_EVENT"
QActor.FORCE_AUTO_CHANGED_EVENT = "FORCE_AUTO_CHANGED_EVENT"

QActor.BUFF_STARTED        = "BUFF_STARTED"
QActor.BUFF_ENDED          = "BUFF_ENDED"

QActor.PLAY_SKILL_ANIMATION = "PLAY_SKILL_ANIMATION"
QActor.ANIMATION_ENDED     = "ANIMATION_ENDED"
QActor.PLAY_SKILL_EFFECT = "PLAY_SKILL_EFFECT"
QActor.STOP_SKILL_EFFECT = "STOP_SKILL_EFFECT"
QActor.CANCEL_SKILL = "CALCEL_SKILL"
QActor.SKILL_END = "SKILL_END"

-- 手动模式枚举
QActor.AUTO = "AUTO"       -- 自动模式
QActor.STAY = "STAY"       -- 手动模式：呆在某地
QActor.ATTACK = "ATTACK"   -- 手动模式：攻击敌人

-- 定义属性
QActor.schema = clone(cc.mvc.ModelBase.schema)
QActor.schema["actor_id"]       = {"number", 0}
QActor.schema["udid"]           = {"string", ""}
QActor.schema["display_id"]     = {"number"} -- 字符串类型，没有默认值
QActor.schema["talent"]         = {"string", ""}
QActor.schema["level"]          = {"number", 1} 

-- 人物属性 start
-- 生命值
QActor.schema["basic_hp"]       = {"number", 1}
QActor.schema["hp_grow"]        = {"number", 1}
-- 攻击
QActor.schema["basic_attack"]   = {"number", 0}
QActor.schema["attack_grow"]    = {"number", 1}
-- 物理防御
QActor.schema["basic_armor_physical"]   = {"number", 0}
QActor.schema["armor_physical_grow"]    = {"number", 0}
-- 魔法防御
QActor.schema["basic_armor_magic"]      = {"number", 0}
QActor.schema["armor_magic_grow"]       = {"number", 0}
-- 命中
QActor.schema["basic_hit"]      = {"number", 0}
QActor.schema["hit_grow"]       = {"number", 1}
-- 躲闪
QActor.schema["basic_dodge"]    = {"number", 0}
QActor.schema["dodge_grow"]     = {"number", 1}
-- 格挡
QActor.schema["basic_block"]    = {"number", 0}
QActor.schema["block_grow"]     = {"number", 1}
-- 暴击
QActor.schema["basic_crit"]     = {"number", 0}
QActor.schema["crit_grow"]      = {"number", 0}
-- 暴击伤害
QActor.schema["basic_critdamage_p"] = {"number", 0}
-- 攻击急速
QActor.schema["basic_haste"]     = {"number", 0}
QActor.schema["haste_grow"]      = {"number", 0}
-- 移动速度
QActor.schema["speed"]          = {"number", 120}
-- 自动释放的连击点数
QActor.schema["combo_points_auto"] = {"number", 1}
-- 人物属性 end

QActor.schema["npc_ai"]         = {"string", ""}
QActor.schema["npc_skill"]         = {"string", ""}
QActor.schema["npc_skill_2"]         = {"string", ""}

local function recalculateAtIndex(calculation_array, index)
    local last_final_value = 0
    if index > 1 then
        last_final_value = calculation_array[index - 1].final_value
    end
    local obj = calculation_array[index]
    if obj.operator == "+" then
        obj.final_value = last_final_value + obj.value
    elseif obj.operator == "*" then
        obj.final_value = last_final_value * obj.value
    elseif obj.operator == "&" then
        obj.final_value = obj.value
    else
        assert(false , string.format("Wrong operator %s", tostring(obj.operator)))
    end
end
local function createActorNumberProperty()
    local return_obj = {}
    local calculation_array = {}
    local stub_table = {}
    function return_obj:getFinalValue()
        local len = #calculation_array
        if len == 0 then
            return 0
        else
            return calculation_array[len].final_value
        end
    end
    function return_obj:getCount()
        return #calculation_array
    end
    function return_obj:insertValue(stub, operator, value)
        if stub_table[stub] then
            return
        end

        local obj = {operator = operator, value = value, stub = stub}
        table.insert(calculation_array, obj)
        recalculateAtIndex(calculation_array, #calculation_array)
        stub_table[stub] = true
    end
    function return_obj:removeValue(stub)
        local found_index = nil
        for index, obj in ipairs(calculation_array) do
            if obj.stub == stub then
                found_index = index
                stub_table[stub] = nil
                break
            end
        end
        local len = #calculation_array
        if found_index then
            for index = found_index, len do
                if index < len then
                    calculation_array[index] = calculation_array[index + 1]
                    recalculateAtIndex(calculation_array, index)
                else
                    calculation_array[index] = nil
                end
            end
        end
    end
    function return_obj:clear()
        calculation_array = {}
        stub_table = {}
    end
    return return_obj
end

function QActor:ctor(actorInfo, events, callbacks)
    if QActor.ARENA_MAX_HEALTH_COEFFICIENT == nil then
        local coefficient = 1
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.ARENA_MAX_HEALTH_COEFFICIENT ~= nil and globalConfig.ARENA_MAX_HEALTH_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.ARENA_MAX_HEALTH_COEFFICIENT.value 
        end
        QActor.ARENA_MAX_HEALTH_COEFFICIENT = coefficient
    end
    if QActor.SUNWELL_MAX_HEALTH_COEFFICIENT == nil then
        local coefficient = 1
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT ~= nil and globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.SUNWELL_MAX_HEALTH_COEFFICIENT.value 
        end
        QActor.SUNWELL_MAX_HEALTH_COEFFICIENT = coefficient
    end
    if QActor.ARENA_FINAL_DAMAGE_COEFFICIENT == nil then
        local coefficient = 1
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT ~= nil and globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.ARENA_FINAL_DAMAGE_COEFFICIENT.value 
        end
        QActor.ARENA_FINAL_DAMAGE_COEFFICIENT = coefficient
    end
    if QActor.SUNWELL_FINAL_DAMAGE_COEFFICIENT == nil then
        local coefficient = 1
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.SUNWELL_FINAL_DAMAGE_COEFFICIENT ~= nil and globalConfig.SUNWELL_FINAL_DAMAGE_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.SUNWELL_FINAL_DAMAGE_COEFFICIENT.value 
        end
        QActor.SUNWELL_FINAL_DAMAGE_COEFFICIENT = coefficient
    end
    if QActor.ARENA_TREAT_COEFFICIENT == nil then
        local coefficient = 1
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.ARENA_TREAT_COEFFICIENT ~= nil and globalConfig.ARENA_TREAT_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.ARENA_TREAT_COEFFICIENT.value 
        end
        QActor.ARENA_TREAT_COEFFICIENT = coefficient
    end
    if QActor.SUNWELL_TREAT_COEFFICIENT == nil then
        local coefficient = 1
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.SUNWELL_TREAT_COEFFICIENT ~= nil and globalConfig.SUNWELL_TREAT_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.SUNWELL_TREAT_COEFFICIENT.value 
        end
        QActor.SUNWELL_TREAT_COEFFICIENT = coefficient
    end
    if QActor.ARENA_BEATTACKED_CD_REDUCE == nil then
        local cd_reduce = 0
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.ARENA_BEATTACKED_CD_REDUCE ~= nil and globalConfig.ARENA_BEATTACKED_CD_REDUCE.value ~= nil then
            cd_reduce = globalConfig.ARENA_BEATTACKED_CD_REDUCE.value 
        end
        QActor.ARENA_BEATTACKED_CD_REDUCE = cd_reduce
    end

    QActor.super.ctor(self, actorInfo.properties)

    self:set("level",actorInfo.level)

    -- 因为角色存在不同状态，所以这里为 QActor 绑定了状态机组件
    self:addComponent("components.behavior.StateMachine")
    -- 由于状态机仅供内部使用，所以不应该调用组件的 exportMethods() 方法，改为用内部属性保存状态机组件对象
    self.fsm__ = self:getComponent("components.behavior.StateMachine")

    -- 设定状态机的默认事件
    local defaultEvents = {
        -- 初始化后，角色处于 idle 状态
        {name = "start",        from = {"none", "dead"},                to = "idle"},
        -- 攻击
        {name = "attack",       from = {"idle", "walking"},             to = "attacking"},
        -- 特殊技能
        {name = "skill",        from = {"idle", "attacking", "walking"},to = "attacking"},
        -- 移动
        {name = "move",         from = {"idle", "walking", "attacking"},to = "walking"},
        -- 开火冷却结束
        {name = "ready",        from = {"attacking", "walking", "victorious", "idle"},to = "idle"},
        -- 角色被冰冻
        {name = "freeze",       from = {"idle", "attacking", "walking"},to = "frozen"},
        -- 从冰冻状态恢复
        {name = "thaw",         form = "frozen",                        to = "idle"},
        -- 角色在正常状态和冰冻状态下都可能被杀死
        {name = "kill",         from = {"attacking", "idle", "frozen", "walking"}, to = "dead"},
        -- 复活
        {name = "relive",       from = "dead",                          to = "idle"},
        -- 胜利
        {name = "victory",      from = {"idle", "walking", "attacking", "frozen"}, to = "victorious"},
    }
    -- 如果继承类提供了其他事件，则合并
    table.insertto(defaultEvents, checktable(events))

    -- 设定状态机的默认回调
    local defaultCallbacks = {
        onchangestate = handler(self, self._onChangeState),
        onstart       = handler(self, self._onStart),
        onattack      = handler(self, self._onAttack),
        onskill       = handler(self, self._onSkill),
        onmove        = handler(self, self._onMove),
        onready       = handler(self, self._onReady),
        onfreeze      = handler(self, self._onFreeze),
        onthaw        = handler(self, self._onThaw),
        onkill        = handler(self, self._onKill),
        onrelive      = handler(self, self._onRelive),
        onvictory     = handler(self, self._onVictory),
        onbeforeready = handler(self, self._onBeforeReady),
    }
    -- 如果继承类提供了其他回调，则合并
    table.merge(defaultCallbacks, checktable(callbacks))

    self.fsm__:setupState({
        events = defaultEvents,
        callbacks = defaultCallbacks
    })
    
    -- 装备属性计算
    self._equipProp = {}
    self:_countEquipmentProperties(actorInfo.equipments)

    local database = QStaticDatabase.sharedDatabase()

    --计算突破等级
    self._breakthrough = {}
    actorInfo.breakthrough = actorInfo.breakthrough or 0
    self._breakthrough = database:getBreakthroughByHeroActorLevel(actorInfo.actorId,actorInfo.breakthrough)
    self._breakthrough = self._breakthrough or {}

    --计算进阶等级
    self._grade = {}
    actorInfo.grade = actorInfo.grade or 0
    self._grade = database:getGradeByHeroActorLevel(actorInfo.actorId,actorInfo.grade)
    self._grade = self._grade or {}

    --计算军衔属性叠加
    self._rank = {}
    self._rank = database:getRankConfigByCode(actorInfo.rankCode)

    self._skills = {}
    if actorInfo.skillIds ~= nil then
        for _, skillId in ipairs(actorInfo.skillIds) do
            if string.len(skillId) ~= 0 then
                self._skills[skillId] = QSkill.new(skillId, database:getSkillByID(skillId), self)
            end
        end 
    end

    -- 测试斩杀
    -- if self:get("talent") == "hero_warrior_arms" then
    --     self._skills["execute_test"] = QSkill.new("execute_test", database:getSkillByID("execute_test"), self)
    -- end

    self._manualSkills = {}
    self._activeSkills = {}
    self._passiveSkills = {}

    self:_classifySkillByType()

    self._sbDirectors = {}

    self._currentSkill = nil
    self._currentSBDirector = nil
    self._nextAttackSkill = nil
    
    self._revive_count = 0

    -- the "ready" event might be delayed for cooldown timeer
    self._delayedReadyHandler = nil

    self._hitlog = QHitLog.new()

    -- 是否进入人工指挥的模式，供AI进行判断
    self._manual = QActor.AUTO

    self._position = ccp(0.0, 0.0)

    self._buffs = {}
    self._buffEventListeners = {}
    self._buffAttacker = {}
    self._passiveBuffApplied = false

    -- 连击点数
    self._combo_points = 0 -- 初始连击点数
    self._combo_points_max = 5 -- 最多一次使用连击点数
    self._combo_points_total = 5 -- 最多可以存储连击点数

    -- 是否锁定当前目标，可以给冲锋使用
    self._isLockTarget = 0

    self._isInBulletTime = false
    self._isInTimeStop = 0

    self._replaceCharacterId = nil

    self:_handleBattleEvents()

    self.fsm__:doEvent("start") -- 启动状态机

    -- 创建属性堆栈 property stack
    self._number_properties = {}
    self:_createActorNumberProperty("movespeed_value")
    self:_createActorNumberProperty("movespeed_percent")
    self:_createActorNumberProperty("movespeed_replace")
    self:_createActorNumberProperty("hit_rating")
    self:_createActorNumberProperty("hit_chance")
    self:_createActorNumberProperty("dodge_rating")
    self:_createActorNumberProperty("dodge_chance")
    self:_createActorNumberProperty("block_rating")
    self:_createActorNumberProperty("block_chance")
    self:_createActorNumberProperty("critical_rating")
    self:_createActorNumberProperty("critical_chance")
    self:_createActorNumberProperty("haste_rating")
    self:_createActorNumberProperty("attackspeed_chance")
    self:_createActorNumberProperty("attack_value")
    self:_createActorNumberProperty("attack_percent")
    self:_createActorNumberProperty("critical_damage")
    self:_createActorNumberProperty("physical_damage_percent_attack")
    self:_createActorNumberProperty("magic_damage_percent_attack")
    self:_createActorNumberProperty("magic_treat_percent_attack")
    self:_createActorNumberProperty("physical_damage_percent_beattack")
    self:_createActorNumberProperty("physical_damage_percent_beattack_reduce")
    self:_createActorNumberProperty("magic_damage_percent_beattack")
    self:_createActorNumberProperty("magic_damage_percent_beattack_reduce")
    self:_createActorNumberProperty("magic_treat_percent_beattack")
end

function QActor:_createActorNumberProperty(property_name)
    self._number_properties[property_name] = createActorNumberProperty()
end

function QActor:_getActorNumberPropertyValue(property_name)
    return self._number_properties[property_name]:getFinalValue()
end

function QActor:_getActorNumberPropertyValueCount(property_name)
    return self._number_properties[property_name]:getCount()
end

function QActor:_clearActorNumberPropertyValue()
    for _, property_stack in pairs(self._number_properties) do
        property_stack:clear()
    end
end

function QActor:insertPropertyValue(property_name, stub, operator, value)
    local property_stack = self._number_properties[property_name]
    if property_stack then
        property_stack:insertValue(stub, operator, value)
    end
end

function QActor:removePropertyValue(property_name, stub)
    local property_stack = self._number_properties[property_name]
    if property_stack then
        property_stack:removeValue(stub)
    end
end

function QActor:_handleBattleEvents()
    if app.battle ~= nil then
        if  self._battleEventListener ~= nil then
            self._battleEventListener:removeAllEventListeners()
            self._battleEventListener = nil
        end
        self._battleEventListener = cc.EventProxy.new(app.battle)
        self._battleEventListener:addEventListener(QBattleManager.ONFRAME, handler(self, self._onBattleFrame))
        self._battleEventListener:addEventListener(QBattleManager.END, handler(self, self._onBattleEnded))
        self._battleEventListener:addEventListener(QBattleManager.STOP, handler(self, self._onBattleStop))
        self._battleEventListener:addEventListener(QBattleManager.PAUSE, handler(self, self._onBattlePause))
        self._battleEventListener:addEventListener(QBattleManager.RESUME, handler(self, self._onBattleResume))
        self._battleEventListener:addEventListener(QBattleManager.WAVE_ENDED, handler(self, self._onWaveEnded))
        self._battleEventListener:addEventListener(QBattleManager.WAVE_CONFIRMED, handler(self, self._onWaveConfirmed))
    end
end

function QActor:resetStateForBattle(revive)
    self._manual = QActor.AUTO
    self._position = ccp(0.0, 0.0)

    self:setTarget(nil)
    self._lastAttacker = nil
    self._lastAttackee = nil

    if revive == true then
        if self._revive_count == nil then
            self._revive_count = 0
        end
        self._revive_count = self._revive_count + 1
    else
        self._revive_count = 0
    end

    -- reset property stack
    self:_clearActorNumberPropertyValue()

    self:setFullHp()

    -- pvp special skills
    self:checkCDReduce()

    -- reset skill
    for _, skill in pairs(self._skills) do
        skill:resetState()
    end

    self:_handleBattleEvents()

    self._isInBulletTime = false
    self._grid_walking_attack_count = 0
    self._waveended = false
    self._battlepause = false
    self._isInTimeStop = 0

    if self.fsm__:isState("dead") == true then
        self.fsm__:doEvent("start") -- 启动状态机
    elseif self.fsm__:isState("idle") == false then
        self.fsm__:doEvent("ready") 
    end
end

function QActor:checkCDReduce()
    -- pvp special skills
    local skillId = "beattacked_reduce_cd"
    if app.battle:isPVPMode() and not self._skills[skillId] then
        local database = QStaticDatabase.sharedDatabase()
        local reduce_cd_skill = QSkill.new(skillId, database:getSkillByID(skillId), self)
        self._skills[skillId] = reduce_cd_skill
        self:_addSkillToArray(reduce_cd_skill, self._passiveSkills)
    elseif not app.battle:isPVPMode() and self._skills[skillId] then
        local reduce_cd_skill = self._skills[skillId]
        self._skills[skillId] = nil
        self._passiveSkills[reduce_cd_skill:getName()] = nil
    end
end

function QActor:getUDID()
    return self:get("udid")
end

function QActor:dump()
    if DEBUG > 0 then
        printInfo("=============== ACTOR ==============")
        printInfo("Id: " .. self:getId())
        printInfo("Name: " .. self:getDisplayName())
        printInfo("=======HP=======")
        printInfo("Max HP: %d", self:getMaxHp(true))
        printInfo("=====ATTACK=====")
        printInfo("Attack: %d", self:getAttack(true))
        printInfo("================")
        printInfo("Magic Armor: %d%%", self:getMagicArmor() * 100)
        printInfo("Physical Armor: %d%%", self:getPhysicalArmor() * 100)
        printInfo("Hit: %.1f%%", self:getHit())
        printInfo("Dodge: %.1f%%", self:getDodge())
        printInfo("Block: %.1f%%", self:getBlock())
        printInfo("Crit: %.1f%%", self:getCrit())
    end
end

function QActor:_countEquipmentProperties(equipments)

    if equipments ~= nil then
        local heroEquipments = equipments
        local itemInfo 
        for _,equipmentInfo in pairs(heroEquipments) do
            itemInfo = QStaticDatabase:sharedDatabase():getItemByID(tonumber(equipmentInfo.itemId))
            if itemInfo ~= nil then
                for prop,value in pairs(itemInfo) do 
                    if self._equipProp[prop] == nil then
                        if type(value) == "number" then
                            self._equipProp[prop] = value
                        end
                    else
                        self._equipProp[prop] = self._equipProp[prop] + (value or 0)
                    end
                end
            end
        end
    end
end

function QActor:_classifySkillByType()
    for _, skill in pairs(self._skills) do
        local skillType = skill:getSkillType()
        if skillType == QSkill.MANUAL then
            self:_addSkillToArray(skill, self._manualSkills)
        elseif skillType == QSkill.ACTIVE then
            self:_addSkillToArray(skill, self._activeSkills)
        elseif skillType == QSkill.PASSIVE then
            self:_addSkillToArray(skill, self._passiveSkills)
        end
    end
    table.sort( self._activeSkills, function(skill1, skill2)
        local p1 = skill1:getSkillPriority()
        local p2 = skill2:getSkillPriority()
        if p1 >= p2 then return true end
        return false
    end )

    -- 根据技能是否产生连击点数或者消耗连击点数决定是否是一个有无连击点数的英雄
    local need_combo = false
    for _, skill in pairs(self._skills) do
        if skill:isNeedComboPoints() then
            need_combo = true
            break
        end
    end
    self._is_need_combo = need_combo
end

function QActor:_addSkillToArray(skill, array)
    if skill == nil or array == nil then
        return
    end

    local skillName = skill:getName()
    if array[skillName] == nil then
        array[skillName] = skill
    elseif array[skillName]:getSkillLevel() < skill:getSkillLevel() then
        array[skillName] = skill
    end
end

function QActor:_setSkillAdditionValueToActor(skill, additionKey, schemaKey, operator)
    if skill == nil or additionKey == nil or schemaKey == nil or operator == nil then
        return
    end

    local value = skill:getAdditionValueWithKey(additionKey)
    if value ~= 0 then
        local oldValue = self:get(schemaKey)
        local newValue = oldValue
        if operator == "+" then
            newValue = oldValue + value
        elseif operator == "*" then
            newValue = oldValue * (1.0 + value)
        end
        self:set(schemaKey, newValue)
    end
end

function QActor:_applyPassiveSkillBuffs()
    for _, skill in pairs(self._passiveSkills) do
        if skill:getBuffId1() ~= "" and skill:getBuffTargetType1() == QSkill.BUFF_SELF then
            self:applyBuff(skill:getBuffId1(), self)
        end
        if skill:getBuffId2() ~= "" and skill:getBuffTargetType2() == QSkill.BUFF_SELF then
            self:applyBuff(skill:getBuffId2(), self)
        end
    end
end

function QActor:getActorID()
    return self:get("actor_id")
end

function QActor:getDisplayID()
    return self:get("display_id")
end

function QActor:getDisplayName()
    return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).name
end

function QActor:getIcon()
    return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).icon
end

function QActor:getVictoryEffect()
    return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).victory_effect
end

function QActor:getTalent()
    local talentId = self:get("talent")
    local talent = QStaticDatabase.sharedDatabase():getTalentByID(talentId)

    if talent == nil and self:getType() == ACTOR_TYPES.HERO then
        assert(talent, "talent table does not have item with key: " .. talentId)
    end

    return talent
end

function QActor:getTalentFunc()
    local talent = self:getTalent()
    if talent == nil then
        return nil
    end
    return talent.func
end

function QActor:getTalentHatred()
    local talent = self:getTalent()
    if talent == nil then
        return 0
    end
    return talent.hatred
end

function QActor:getActorScale()
    if self._replaceCharacterDisplayId ~= nil then
        return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self._replaceCharacterDisplayId).actor_scale
    end
    return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).actor_scale
end

-- actor skeleton file 
-- is a json file
function QActor:getActorFile()
    if self._replaceCharacterDisplayId ~= nil then
        return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self._replaceCharacterDisplayId).actor_file
    end
    return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).actor_file
end

function QActor:getActorWeaponFile()
    if self._replaceCharacterDisplayId ~= nil then
        return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self._replaceCharacterDisplayId).weapon_file
    end
    return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).weapon_file
end

function QActor:getSelectRectWidth()
    if self._replaceCharacterDisplayId ~= nil then
        return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self._replaceCharacterDisplayId).selected_rect_width
    end
    return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).selected_rect_width
end

function QActor:getSelectRectHeight()
    if self._replaceCharacterDisplayId ~= nil then
        return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self._replaceCharacterDisplayId).selected_rect_height
    end
    return QStaticDatabase.sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).selected_rect_height
end

function QActor:isMovable()
    return self:get("speed") ~= 0
end

function QActor:getMoveSpeed()
    if self:CanControlMove() == false then
        return 0
    end

    if not self:isMovable() then
        return 0
    end

    local speed = self:get("speed")
    speed = self:_calculateValueWithPassiveSkills(speed, "movespeed_value", "+")
    local percent1 = self:_calculateValueWithPassiveSkills(1, "movespeed_percent", "*")
    speed = speed * percent1

    speed = self:_calculateByBuffAndTrapAndAura(speed, "movespeed_value", "+")
    speed = speed + self:_getActorNumberPropertyValue("movespeed_value")
    local percent = self:_calculateByBuffAndTrapAndAura(1, "movespeed_percent", "*")
    percent = percent + self:_getActorNumberPropertyValue("movespeed_percent")
    local replace = self:_calculateByBuffAndTrapAndAura(nil, "movespeed_replace", "&")
    replace = self:_getActorNumberPropertyValueCount("movespeed_replace") > 0 and self:_getActorNumberPropertyValue("movespeed_replace") or replace
    if percent <= 0.05 then
        percent = 0.05
    end
    speed = speed * percent
    if replace then speed = replace end

    if speed < global.movement_speed_min then return global.movement_speed_min end
    return speed
end

function QActor:getType()
    assert(self._type ~= nil, "please set type in subclass, see ACTOR_TYPES")
    return self._type
end

function QActor:setType(actorType)
    assert(actorType ~= nil, "please set type in subclass, see ACTOR_TYPES")
    assert( ((actorType == ACTOR_TYPES.HERO) or (actorType == ACTOR_TYPES.NPC) or (actorType == ACTOR_TYPES.HERO_NPC)), "please set type in subclass, see ACTOR_TYPES")
    self._type = actorType
end

function QActor:getSkills()
    return self._skills
end

function QActor:getActiveSkills()
    return self._activeSkills
end

function QActor:getManualSkills()
    return self._manualSkills
end

function QActor:getPassiveSkills()
    return self._passiveSkills
end

function QActor:getSkillWithId(id)
    if id == nil then
        return nil
    end
    assert(self._skills[id] ~= nil, "skill: " .. id .. " is not exist in actor: " .. self:getId())
    return self._skills[id]
end

-- 人物等级
function QActor:getLevel()
    return self:get("level")
end

function QActor:getLevelFullExp()
    return QStaticDatabase:sharedDatabase():getExperienceByLevel(self:getLevel())
end

function QActor:getHp()
    return self._hp
end

function QActor:getHpBeforeLastChange()
    return self._hpBeforeLastChange
end

-- deprecated
function QActor:_calculateByBuffAndTrap(originValue, key, operator)
    local newValue = originValue
    if operator == "+" then
        -- buffs
        for _, buff in ipairs(self._buffs) do
            if buff.effects[key] ~= nil and not buff:isImmuned() and not buff:isAura() then
                newValue = newValue + buff.effects[key]
            end
        end
        -- traps
        if app.battle ~= nil then
            for _, trapDirector in ipairs(app.battle:getTrapDirectors()) do
                if trapDirector:isExecute() == true and trapDirector:isTragInfluenceActor(self) then
                    local trap = trapDirector:getTrap()
                    if trap.effects[key] ~= nil then
                        newValue = newValue + trap.effects[key]
                    end
                end
            end
        end

    elseif operator == "*" then
        local coefficient = 0
        -- buffs
        for _, buff in ipairs(self._buffs) do
            if buff.effects[key] ~= nil and not buff:isImmuned() and not buff:isAura() then
                coefficient = coefficient + buff.effects[key]
            end
        end
        -- traps
        if app.battle ~= nil then
            for _, trapDirector in ipairs(app.battle:getTrapDirectors()) do
                if trapDirector:isExecute() == true and trapDirector:isTragInfluenceActor(self) then
                    local trap = trapDirector:getTrap()
                    if trap.effects[key] ~= nil then
                        coefficient = coefficient + trap.effects[key]
                    end
                end
            end
        end
        newValue = originValue * (1.0 + coefficient)
    elseif operator == "&" then
        -- buffs
        for _, buff in ipairs(self._buffs) do
            if buff.effects[key] ~= nil and not buff:isImmuned() and not buff:isAura() then
                newValue = buff.effects[key]
            end
        end
        -- traps
        if app.battle ~= nil then
            for _, trapDirector in ipairs(app.battle:getTrapDirectors()) do
                if trapDirector:isExecute() == true and trapDirector:isTragInfluenceActor(self) then
                    local trap = trapDirector:getTrap()
                    if trap.effects[key] ~= nil then
                        newValue = trap.effects[key]
                    end
                end
            end
        end
    end

    return newValue
end

--[[
    QActor:_calculateByBuffAndTrapAndAura only take traps into calculation, since buff and aura is calculated via property stack
]]
function QActor:_calculateByBuffAndTrapAndAura(originValue, key, operator, includeAura)
    local newValue = originValue

    local heroes, enemies
    if app.battle then
        heroes = app.battle:getHeroes() 
        enemies = app.battle:getEnemies()
    end

    if operator == "+" then
        -- buffs
        -- for _, buff in ipairs(self._buffs) do
        --     if buff.effects[key] ~= nil and not buff:isImmuned() and not buff:isAura() and buff:isConditionMet() then
        --         newValue = newValue + buff.effects[key]
        --     end
        -- end
        -- traps
        if app.battle ~= nil then
            for _, trapDirector in ipairs(app.battle:getTrapDirectors()) do
                if trapDirector:isExecute() == true and trapDirector:isTragInfluenceActor(self) then
                    local trap = trapDirector:getTrap()
                    if trap.effects[key] ~= nil then
                        newValue = newValue + trap.effects[key]
                    end
                end
            end
        end
        -- auras
        -- if includeAura and app.battle then
        --     for _, actor in ipairs(heroes) do 
        --         if not actor:isDead() then
        --             for _, buff in ipairs(actor._buffs) do
        --                 if buff:isAura() and buff.effects[key] ~= nil and not buff:isImmuned() and buff:isAuraAffectActor(self) and buff:isConditionMet() then
        --                     newValue = newValue + buff.effects[key]
        --                 end
        --             end
        --         end
        --     end
        --     for _, actor in ipairs(enemies) do
        --         if not actor:isDead() then
        --             for _, buff in ipairs(actor._buffs) do
        --                 if buff:isAura() and buff.effects[key] ~= nil and not buff:isImmuned() and buff:isAuraAffectActor(self) and buff:isConditionMet() then
        --                     newValue = newValue + buff.effects[key]
        --                 end
        --             end
        --         end
        --     end
        -- end

    elseif operator == "*" then
        local coefficient = 0
        -- buffs
        -- for _, buff in ipairs(self._buffs) do
        --     if buff.effects[key] ~= nil and not buff:isImmuned() and not buff:isAura() and buff:isConditionMet() then
        --         coefficient = coefficient + buff.effects[key]
        --     end
        -- end
        -- traps
        if app.battle ~= nil then
            for _, trapDirector in ipairs(app.battle:getTrapDirectors()) do
                if trapDirector:isExecute() == true and trapDirector:isTragInfluenceActor(self) then
                    local trap = trapDirector:getTrap()
                    if trap.effects[key] ~= nil then
                        coefficient = coefficient + trap.effects[key]
                    end
                end
            end
        end
        -- auras
        -- if includeAura and app.battle then
        --     for _, actor in ipairs(heroes) do
        --         if not actor:isDead() then
        --             for _, buff in ipairs(actor._buffs) do
        --                 if buff:isAura() and buff.effects[key] ~= nil and not buff:isImmuned() and buff:isAuraAffectActor(self) and buff:isConditionMet() then
        --                     coefficient = coefficient + buff.effects[key]
        --                 end
        --             end
        --         end
        --     end
        --     for _, actor in ipairs(enemies) do
        --         if not actor:isDead() then
        --             for _, buff in ipairs(actor._buffs) do
        --                 if buff:isAura() and buff.effects[key] ~= nil and not buff:isImmuned() and buff:isAuraAffectActor(self) and buff:isConditionMet() then
        --                     coefficient = coefficient + buff.effects[key]
        --                 end
        --             end
        --         end
        --     end
        -- end
        newValue = originValue * (1.0 + coefficient)
    elseif operator == "&" then
        -- buffs
        -- for _, buff in ipairs(self._buffs) do
        --     if buff.effects[key] ~= nil and not buff:isImmuned() and not buff:isAura() and buff:isConditionMet() then
        --         newValue = buff.effects[key]
        --     end
        -- end
        -- traps
        if app.battle ~= nil then
            for _, trapDirector in ipairs(app.battle:getTrapDirectors()) do
                if trapDirector:isExecute() == true and trapDirector:isTragInfluenceActor(self) then
                    local trap = trapDirector:getTrap()
                    if trap.effects[key] ~= nil then
                        newValue = trap.effects[key]
                    end
                end
            end
        end
        -- auras
        -- if includeAura and app.battle then
        --     for _, actor in ipairs(heroes) do
        --         if not actor:isDead() then
        --             for _, buff in ipairs(actor._buffs) do
        --                 if buff.effects[key] ~= nil and not buff:isImmuned() and buff:isAura() and buff:isAuraAffectActor(self) and buff:isConditionMet() then
        --                     newValue = buff.effects[key]
        --                 end
        --             end
        --         end
        --     end
        --     for _, actor in ipairs(enemies) do
        --         if not actor:isDead() then
        --             for _, buff in ipairs(actor._buffs) do
        --                 if buff.effects[key] ~= nil and not buff:isImmuned() and buff:isAura() and buff:isAuraAffectActor(self) and buff:isConditionMet() then
        --                     newValue = buff.effects[key]
        --                 end
        --             end
        --         end
        --     end
        -- end
    end

    return newValue
end

--最大生命值
function QActor:getMaxHp(isPrintInfo)
    if isPrintInfo == true then
        printInfo("basic_hp: %f", self:get("basic_hp"))
        printInfo("hp_grow = (basic_hp_grow[%f] + grade_hp_grow[%f] + breakthrough_hp_grow[%f]) * (level[%d]) = %f", self:get("hp_grow"), (self._grade.hp_grow or 0), (self._breakthrough.hp_grow or 0), self:getLevel(), (self:get("hp_grow") + (self._grade.hp_grow or 0) + (self._breakthrough.hp_grow or 0)) * (self:getLevel() ))
        printInfo("equip addition: %f", (self._equipProp.hp or 0))
        printInfo("break through addition: %f", (self._breakthrough.hp or 0))
        if self._rank == nil then
            printInfo("rank coefficient: %f", 1)
        else
            printInfo("rank coefficient: %f", (self._rank.hp/100 + 1))
        end
    end

    if self._cachingProperties then
        local value = self._cachingProperties["max_hp"]
        if value then
            return value
        end
    end

    local hp = self:get("basic_hp") + (self._breakthrough.hp or 0) + (self:get("hp_grow") + (self._grade.hp_grow or 0) + (self._breakthrough.hp_grow or 0)) * (self:getLevel()) + (self._equipProp.hp or 0)
    hp = self:_calculateValueWithPassiveSkills(hp, "hp_value", "+")
    hp = self:_calculateValueWithPassiveSkills(hp, "hp_percent", "*")

    if self._rank == nil then
        hp = hp
    else
        hp = hp * (self._rank.hp/100 + 1)
    end

    -- PVP系数影响
    if app.battle ~= nil and app.battle:isPVPMode() then
        if app.battle:isInArena() then
            hp = hp * QActor.ARENA_MAX_HEALTH_COEFFICIENT
        elseif app.battle:isInSunwell() then
            hp = hp * QActor.SUNWELL_MAX_HEALTH_COEFFICIENT
        end
    end

    if self._cachingProperties then
        self._cachingProperties["max_hp"] = hp
    end

    return hp
end

--获取最大攻击
function QActor:getMaxAttack(isPrintInfo)
    if isPrintInfo == true then
        printInfo("basic_attack: %f", self:get("basic_attack"))
        printInfo("attack_grow = (basic_attack_grow[%f] + grade_attack_grow[%f] + breakthrough_attack_grow[%f]) * (level[%d]) = %f", self:get("attack_grow"), (self._grade.attack_grow or 0), (self._breakthrough.attack_grow or 0), self:getLevel(), (self:get("attack_grow") + (self._grade.attack_grow or 0) + (self._breakthrough.attack_grow or 0)) * (self:getLevel() ))
        printInfo("equip addition: %f", (self._equipProp.attack or 0))
        printInfo("break through addition: %f", (self._breakthrough.attack_grow or 0))
    end

    if self._cachingProperties then
        local value = self._cachingProperties["max_attack"]
        if value then
            return value
        end
    end

    local attack = self:get("basic_attack") + (self._breakthrough.attack or 0) + (self:get("attack_grow") + (self._grade.attack_grow or 0) + (self._breakthrough.attack_grow or 0)) * (self:getLevel() ) + (self._equipProp.attack or 0)
    attack = self:_calculateValueWithPassiveSkills(attack, "attack_value", "+")
    attack = self:_calculateValueWithPassiveSkills(attack, "attack_percent", "*")

    if self._cachingProperties then
        self._cachingProperties["max_attack"] = attack
    end

    return attack
end

-- 最大法术防御等级
function QActor:getMaxMagicArmor(isPrintInfo)
    local level = self:getLevel()
    local armor_magic = self:get("basic_armor_magic") + self:get("armor_magic_grow") * (level) + (self._equipProp.armor_magic or 0) + (self._breakthrough.armor_magic or 0)
    armor_magic = self:_calculateValueWithPassiveSkills(armor_magic, "armor_magic", "+")

    return armor_magic
end

-- deprecated
-- 最大法术抗性
function QActor:getMaxArmorMagicReduce(isPrintInfo)
    PRINT_DEPRECATED("QActor:getMaxArmorMagicReduce(isPrintInfo) is deprecated")
    if isPrintInfo == true then
        printInfo("basic_armor_magic: %f", self:get("basic_armor_magic"))
        printInfo("equip addition: %f", (self._equipProp.armor_magic or 0))
    end

    if self._cachingProperties then
        local value = self._cachingProperties["max_armor_magic_reduce"]
        if value then
            return value
        end
    end

    local level = self:getLevel()
    local armor_magic = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).armor_magic
    local armor_magic_rate = self:get("basic_armor_magic") + self:get("armor_magic_grow") * (level) + (self._equipProp.armor_magic or 0) + (self._breakthrough.armor_magic or 0)
    armor_magic_rate = self:_calculateValueWithPassiveSkills(armor_magic_rate, "armor_magic", "+")
    local armor_magic_reduce = armor_magic_rate / armor_magic

    if armor_magic_reduce > 100 then armor_magic_reduce = 100 end    

    if self._cachingProperties then
        self._cachingProperties["max_armor_magic_reduce"] = armor_magic_reduce
    end

    return armor_magic_reduce
end

-- 最大物理防御等级
function QActor:getMaxPhysicalArmor(isPrintInfo) 
    local level = self:getLevel()
    local armor_physical = self:get("basic_armor_physical") + self:get("armor_physical_grow") * (level) + (self._equipProp.armor_physical or 0) + (self._breakthrough.armor_physical or 0)
    armor_physical = self:_calculateValueWithPassiveSkills(armor_physical, "armor_physical", "+")

    return armor_physical
end

-- deprecated
-- 最大物理抗性
function QActor:getMaxArmorPhysicalReduce(isPrintInfo)
    PRINT_DEPRECATED("QActor:getMaxArmorPhysicalReduce(isPrintInfo) is deprecated")
    if isPrintInfo == true then
        printInfo("basic_armor_physical: %f", self:get("basic_armor_physical"))
        printInfo("equip addition: %f", (self._equipProp.armor_physical or 0))
    end

    if self._cachingProperties then
        local value = self._cachingProperties["max_armor_physical_reduce"]
        if value then
            return value
        end
    end

    local level = self:getLevel()
    local armor_physical = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).armor_physical
    local armor_physical_rate = self:get("basic_armor_physical") + self:get("armor_physical_grow") * (level) + (self._equipProp.armor_physical or 0) + (self._breakthrough.armor_physical or 0)
    armor_physical_rate = self:_calculateValueWithPassiveSkills(armor_physical_rate, "armor_physical", "+")
    local armor_physical_reduce = armor_physical_rate / armor_physical

    if armor_physical_reduce > 100 then armor_physical_reduce = 100 end   

    if self._cachingProperties then
        self._cachingProperties["max_armor_physical_reduce"] = armor_physical_reduce
    end

    return armor_physical_reduce
end

--根据最大命中率计算命中等级
function QActor:getMaxHitLevel()
    local hitRate = self:getMaxHit()
    local level = self:getLevel()
    local hitLevel = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).hit
    hitLevel = hitLevel * hitRate
    return hitLevel
end

--最大命中率
function QActor:getMaxHit()
    if self._cachingProperties then
        local value = self._cachingProperties["max_hit"]
        if value then
            return value
        end
    end

    local level = (app.battle and self:getTarget()) and self:getTarget():getLevel() or self:getLevel()
    local unhit = 5
    local hit = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).hit

    local hit_rate = self:get("basic_hit") + self:get("hit_grow") * (level) + (self._equipProp.hit_rating or 0) + (self._breakthrough.hit or 0)
    hit_rate = self:_calculateValueWithPassiveSkills(hit_rate, "hit_rating", "+")
    hit_rate = self:_calculateByBuffAndTrapAndAura(hit_rate, "hit_rating", "+")
    hit_rate = hit_rate + self:_getActorNumberPropertyValue("hit_rating")
    unhit = unhit - hit_rate / hit
    if unhit < 0 then unhit = 0 end
    if unhit > 100 then unhit = 100 end

    hit = 100 - unhit + self:_calculateValueWithPassiveSkills(0, "hit_chance", "+") * 100
    hit = hit + self:_calculateByBuffAndTrapAndAura(0, "hit_chance", "+") * 100
    hit = hit + self:_getActorNumberPropertyValue("hit_chance") * 100
    if hit < 0 then hit = 0 end
    if hit > 100 then hit = 100 end 

    if self._cachingProperties then
        self._cachingProperties["max_hit"] = hit
    end

    return hit
end

--根据最大闪避率计算闪避等级
function QActor:getMaxDodgeLevel()
    local dodgeRate = self:getMaxDodge()
    local level = self:getLevel()
    local dodgeLevel = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).dodge
    dodgeLevel = dodgeLevel * dodgeRate
    return dodgeLevel
end

-- 最大闪避概率（%）
function QActor:getMaxDodge()
    if self._cachingProperties then
        local value = self._cachingProperties["max_dodge"]
        if value then
            return value
        end
    end

    local level = (app.battle and self:getTarget()) and self:getTarget():getLevel() or self:getLevel()
    local dodge = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).dodge
    local dodge_rate = self:get("basic_dodge") + self:get("dodge_grow") * (level) + (self._equipProp.dodge_rating or 0) + (self._breakthrough.dodge or 0)
    dodge_rate = self:_calculateValueWithPassiveSkills(dodge_rate, "dodge_rating", "+")
    dodge_rate = self:_calculateByBuffAndTrapAndAura(dodge_rate, "dodge_rating", "+")
    dodge_rate = dodge_rate + self:_getActorNumberPropertyValue("dodge_rating")
    dodge = dodge_rate / dodge
    dodge = dodge + self:_calculateValueWithPassiveSkills(0, "dodge_chance", "+") * 100
    dodge = dodge + self:_calculateByBuffAndTrapAndAura(0, "dodge_chance", "+") * 100
    dodge = dodge + self:_getActorNumberPropertyValue("dodge_chance") * 100

    if self._cachingProperties then
        self._cachingProperties["max_dodge"] = dodge
    end

    return dodge
end

--根据最大格挡率计算格挡等级
function QActor:getMaxBlockLevel()
    local blockRate = self:getMaxBlock()
    local level = self:getLevel()
    local blockLevel = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).block
    blockLevel = blockLevel * blockRate
    return blockLevel
end

-- 最大格挡概率（%）
function QActor:getMaxBlock()
    if self._cachingProperties then
        local value = self._cachingProperties["max_block"]
        if value then
            return value
        end
    end

    local level = (app.battle and self:getTarget()) and self:getTarget():getLevel() or self:getLevel()
    local block = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).block
    local block_rate = self:get("basic_block") + self:get("block_grow") * (level) + (self._equipProp.block_rating or 0) + (self._breakthrough.block or 0)
    block_rate = self:_calculateValueWithPassiveSkills(block_rate, "block_rating", "+")
    block_rate = self:_calculateByBuffAndTrapAndAura(block_rate, "block_rating", "+")
    block_rate = block_rate + self:_getActorNumberPropertyValue("block_rating")
    block = block_rate / block
    block = block + self:_calculateValueWithPassiveSkills(0, "block_chance", "+") * 100
    block = block + self:_calculateByBuffAndTrapAndAura(0, "block_chance", "+") * 100
    block = block + self:_getActorNumberPropertyValue("block_chance") * 100

    if self._cachingProperties then
        self._cachingProperties["max_block"] = block
    end

    return block
end

--根据最大暴击率计算暴击等级
function QActor:getMaxCritLevel()
    local critRate = self:getMaxCrit()
    local level = self:getLevel()
    local critLevel = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).crit
    critLevel = critLevel * critRate
    return critLevel
end

-- 最大暴击概率（%）
function QActor:getMaxCrit()
    if self._cachingProperties then
        local value = self._cachingProperties["max_crit"]
        if value then
            return value
        end
    end

    local level = (app.battle and self:getTarget()) and self:getTarget():getLevel() or self:getLevel()
    local crit = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).crit
    local crit_rate = self:get("basic_crit") + self:get("crit_grow") * (level) + (self._equipProp.critical_rating or 0) + (self._breakthrough.critical or 0)
    crit_rate = self:_calculateValueWithPassiveSkills(crit_rate, "critical_rating", "+")
    crit_rate = self:_calculateByBuffAndTrapAndAura(crit_rate, "critical_rating", "+")
    crit_rate = crit_rate + self:_getActorNumberPropertyValue("critical_rating")
    crit = crit_rate / crit
    crit = crit + self:_calculateValueWithPassiveSkills(0, "critical_chance", "+") * 100
    crit = crit + self:_calculateByBuffAndTrapAndAura(0, "critical_chance", "+") * 100
    crit = crit + self:_getActorNumberPropertyValue("critical_chance") * 100

    if self._cachingProperties then
        self._cachingProperties["max_crit"] = crit
    end

    return crit
end

--根据最大急速率计算急速等级
function QActor:getMaxHasteLevel()
    local hasteRate = self:getMaxHaste()
    local level = self:getLevel()
    local hasteLevel = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).haste
    hasteLevel = hasteLevel * hasteRate
    return hasteLevel
end

-- 最大急速率
function QActor:getMaxHaste()
    if self._cachingProperties then
        local value = self._cachingProperties["max_haste"]
        if value then
            return value
        end
    end

    local level = self:getLevel()
    local haste = QStaticDatabase.sharedDatabase():getLevelCoefficientByLevel(tostring(level)).haste
    local haste_rate = self:get("basic_haste") + self:get("haste_grow") * (level) + (self._equipProp.haste_rating or 0) + (self._breakthrough.haste or 0)
    haste_rate = self:_calculateValueWithPassiveSkills(haste_rate, "haste_rating", "+")
    haste_rate = self:_calculateByBuffAndTrapAndAura(haste_rate, "haste_rating", "+")
    haste_rate = haste_rate + self:_getActorNumberPropertyValue("haste_rating")
    haste = haste_rate / haste / 100
    haste = haste + self:_calculateValueWithPassiveSkills(0, "attackspeed_chance", "+")
    haste = haste + self:_calculateByBuffAndTrapAndAura(0, "attackspeed_chance", "+")
    haste = haste + self:_getActorNumberPropertyValue("attackspeed_chance")

    if self._cachingProperties then
        self._cachingProperties["max_haste"] = haste
    end

    return haste
end

-- 计算战斗力
function QActor:getBattleForce()
    local config = QStaticDatabase.sharedDatabase():getForceConfigByLevel(self:getLevel())
    local force = 0
    if config ~= nil then
        local attackFroce = self:getMaxAttack() * config.attack --攻击力
        local hpFroce = self:getMaxHp() * config.hp --生命值
        local magicArmorFroce = self:getMaxMagicArmor() * config.magicArmor --法术防御
        local physicalArmorFroce = self:getMaxPhysicalArmor() * config.physicalArmor --物理防御
        local hitFroce = self:getMaxHitLevel() * config.hit --命中率
        local dodgeFroce = self:getMaxDodgeLevel() * config.dodge --闪避率
        local blockFroce = self:getMaxBlockLevel() * config.block --格挡率
        local critFroce = self:getMaxCritLevel() * config.crit --暴击率
        local hasteFroce = self:getMaxHasteLevel() * config.haste --急速率
        force = attackFroce + hpFroce + magicArmorFroce + physicalArmorFroce + hitFroce + dodgeFroce + blockFroce + critFroce + hasteFroce
        force = math.floor(force)
        printInfo("attack * rate + hp * rate + magicArmor * rate + physicalArmor * rate + hit * rate + dodge * rate + block * rate + crit * rate + haste * rate")
        printInfo("%f * %f + %f * %f + %f * %f + %f * %f + %f * %f + %f * %f + %f * %f + %f * %f + %f * %f", self:getMaxAttack(), config.attack,
         self:getMaxHp(), config.hp, self:getMaxMagicArmor(), config.magicArmor, self:getMaxPhysicalArmor(), config.physicalArmor, self:getMaxHitLevel(), config.hit,
         self:getMaxDodgeLevel(), config.dodge, self:getMaxBlockLevel(), config.block, self:getMaxCritLevel(), config.crit, self:getMaxHasteLevel(), config.haste)
        printInfo("total force: %f", force)
    end
    for _, skill in pairs(self._skills) do
        force = force + skill:getBattleForce()
    end
    return force
end

-- 攻击
function QActor:getAttack(isPrintInfo)
    if self._cachingProperties then
        local value = self._cachingProperties["attack"]
        if value then
            return value
        end
    end

    local maxAttack = self:getMaxAttack(isPrintInfo)
    local attack = self:_calculateByBuffAndTrapAndAura(maxAttack, "attack_value", "+")
    local attack_percent = 1.0
    attack_percent = attack_percent + self:_calculateByBuffAndTrapAndAura(0, "attack_percent", "+")
    attack_percent = attack_percent + self:_getActorNumberPropertyValue("attack_percent")
    attack = attack * attack_percent

    if self._cachingProperties then
        self._cachingProperties["attack"] = attack
    end

    return attack
end

-- deprecated
-- 法术抗性
function QActor:getArmorMagicReduce(isPrintInfo)
    PRINT_DEPRECATED("QActor:getArmorMagicReduce(isPrintInfo) is deprecated")
    return (self:getMaxArmorMagicReduce(isPrintInfo) / 100)
end

-- deprecated
-- 物理抗性
function QActor:getArmorPhysicalReduce(isPrintInfo)
    PRINT_DEPRECATED("QActor:getArmorPhysicalReduce(isPrintInfo) is deprecated")
    return (self:getMaxArmorPhysicalReduce(isPrintInfo) / 100)
end

-- 目標法術防禦影響系數
function QActor:getTargetMagicArmorCoefficient()
    local target = self:getTarget()
    local magic_armor = target and target:getMagicArmor() or 0
    local attack = self:getAttack()
    local coefficient = attack / (attack + 8 * magic_armor)

    return coefficient
end

-- 目標物理防禦影響系數
function QActor:getTargetPhysicalArmorCoefficient()
    local target = self:getTarget()
    local physical_armor = target and target:getPhysicalArmor() or 0
    local attack = self:getAttack()
    local coefficient = attack / (attack + 8 * physical_armor)

    return coefficient
end

-- 法术防御
function QActor:getMagicArmor(isPrintInfo)
    return self:getMaxMagicArmor(isPrintInfo)
end

-- 物理防御
function QActor:getPhysicalArmor(isPrintInfo)
    return self:getMaxPhysicalArmor(isPrintInfo)
end

-- TODO 把这个函数的计算过程与 _calculateByBuffAndTrapAndAura函数合并
function QActor:_calculateValueWithPassiveSkills(value, additionKey, operator)
    if value == nil or additionKey == nil or operator == nil then
        return nil
    end

    -- calculate with passive skill
    local newValue = value
    if operator == "+" then
        for _, skill in pairs(self._passiveSkills) do
            local additionValue = skill:getAdditionValueWithKey(additionKey)
            if additionValue and additionValue ~= 0 then
                newValue = value + additionValue
            end
        end
        if self._currentSkill and self._currentSkill:isAdditionOn() then
            local additionValue = self._currentSkill:getAdditionValueWithKey(additionKey)
            if additionValue and additionValue ~= 0 then
                newValue = value + additionValue
            end
        end

    elseif operator == "*" then
        local coefficient = 0
        for _, skill in pairs(self._passiveSkills) do
            local additionValue = skill:getAdditionValueWithKey(additionKey)
            if additionValue and additionValue ~= 0 then
                coefficient = coefficient + additionValue
            end
        end
        if self._currentSkill and self._currentSkill:isAdditionOn() then
            local additionValue = self._currentSkill:getAdditionValueWithKey(additionKey)
            if additionValue and additionValue ~= 0 then
                coefficient = coefficient + additionValue
            end
        end
        newValue = value * (1.0 + coefficient)
    end

    return newValue
end

-- 命中率（%）
function QActor:getHit()
    return self:getMaxHit()
end

-- 闪避概率（%）
function QActor:getDodge()
    return self:getMaxDodge()
end

-- 格挡概率（%）
function QActor:getBlock()
    return self:getMaxBlock()
end

-- 暴击概率（%）
function QActor:getCrit()
    return self:getMaxCrit()
end

-- 暴击伤害倍数
function QActor:getCritDamage()
    local percent1 = self:get("basic_critdamage_p")
    local percent2 = self:_calculateValueWithPassiveSkills(0, "critical_damage", "+")
    local percent3 = self:_calculateByBuffAndTrapAndAura(0, "critical_damage", "+")
    local percent4 = self:_getActorNumberPropertyValue("critical_damage")
    local critDamage = 1.00 + percent1 + percent2 + percent3 + percent4

    return (critDamage < 1 and 1) or critDamage
end

-- 物理伤害
function QActor:getPhysicalDamagePercentAttack()
    local percent1 = self:_calculateValueWithPassiveSkills(0, "physical_damage_percent_attack", "+")
    local percent2 = self:_calculateByBuffAndTrapAndAura(0, "physical_damage_percent_attack", "+")
    local percent3 = self:_getActorNumberPropertyValue("physical_damage_percent_attack")
    local percent = percent1 + percent2 + percent3

    return (percent < -1 and -1) or percent
end

-- 魔法伤害
function QActor:getMagicDamagePercentAttack()
    local percent1 = self:_calculateValueWithPassiveSkills(0, "magic_damage_percent_attack", "+")
    local percent2 = self:_calculateByBuffAndTrapAndAura(0, "magic_damage_percent_attack", "+")
    local percent3 = self:_getActorNumberPropertyValue("magic_damage_percent_attack")
    local percent = percent1 + percent2 + percent3

    return (percent < -1 and -1) or percent
end

-- 治疗效果
function QActor:getMagicTreatPercentAttack()
    local percent1 = self:_calculateValueWithPassiveSkills(0, "magic_treat_percent_attack", "+")
    local percent2 = self:_calculateByBuffAndTrapAndAura(0, "magic_treat_percent_attack", "+")
    local percent3 = self:_getActorNumberPropertyValue("magic_treat_percent_attack")
    local percent = percent1 + percent2 + percent3

    return (percent < -1 and -1) or percent
end

-- 物理易伤 + 物理伤害减免
function QActor:getPhysicalDamagePercentUnderAttack()
    local percent1 = self:_calculateValueWithPassiveSkills(0, "physical_damage_percent_beattack", "+")
    local percent2 = self:_calculateByBuffAndTrapAndAura(0, "physical_damage_percent_beattack", "+")
    local percent3 = self:_getActorNumberPropertyValue("physical_damage_percent_beattack")
    local percent4 = self:_calculateValueWithPassiveSkills(0, "physical_damage_percent_beattack_reduce", "+")
    local percent5 = self:_calculateByBuffAndTrapAndAura(0, "physical_damage_percent_beattack_reduce", "+")
    local percent6 = self:_getActorNumberPropertyValue("physical_damage_percent_beattack_reduce")
    local percent = percent1 + percent2 + percent3 + percent4 + percent5 + percent6

    return (percent < -1 and -1) or percent
end

-- 法术易伤 + 魔法伤害减免
function QActor:getMagicDamagePercentUnderAttack()
    local percent1 = self:_calculateValueWithPassiveSkills(0, "magic_damage_percent_beattack", "+")
    local percent2 = self:_calculateByBuffAndTrapAndAura(0, "magic_damage_percent_beattack", "+")
    local percent3 = self:_getActorNumberPropertyValue("magic_damage_percent_beattack")
    local percent4 = self:_calculateValueWithPassiveSkills(0, "magic_damage_percent_beattack_reduce", "+")
    local percent5 = self:_calculateByBuffAndTrapAndAura(0, "magic_damage_percent_beattack_reduce", "+")
    local percent6 = self:_getActorNumberPropertyValue("magic_damage_percent_beattack_reduce")
    local percent = percent1 + percent2 + percent3 + percent4 + percent5 + percent6

    return (percent < -1 and -1) or percent
end

-- 被治疗效果
function QActor:getMagicTreatPercentUnderAttack()
    local percent1 = self:_calculateValueWithPassiveSkills(0, "magic_treat_percent_beattack", "+")
    local percent2 = self:_calculateByBuffAndTrapAndAura(0, "magic_treat_percent_beattack", "+")
    local percent3 = self:_getActorNumberPropertyValue("magic_treat_percent_beattack")
    local percent = percent1 + percent2 + percent3

    return (percent < -1 and -1) or percent
end

-- AI类型
function QActor:getAIType()
    if self._replaceCharacterId ~= nil then
        return QStaticDatabase.sharedDatabase():getCharacterByID(self._replaceCharacterId).npc_ai
    end

    local aiType = self:get("npc_ai")
    if string.len(aiType) == 0 then
        aiType = self:getTalentFunc()

        if app.battle:isPVPMode() then
            if aiType == "t" or aiType == "dps" then
                aiType = "dps_arena"
            end
        end
    end

    return aiType
end

-- 寻找最近的actor
function QActor:getClosestActor(others, in_battle_range)
    if others == nil then return nil end

    local target = nil
    local dist = 10e20 -- the value that should be large enough

    for i, other in ipairs(others) do
        if not other:isDead() then
            if other:getPosition().x > BATTLE_AREA.left - 50 and other:getPosition().x < BATTLE_AREA.right + 50 then
                local qualified = true
                if in_battle_range then
                    local area = app.grid:getRangeArea()
                    local pos = other:getPosition()
                    if pos.x < area.left or pos.x > area.right or pos.y < area.bottom or pos.y > area.top then
                        qualified = false
                    end
                end
                if qualified then
                    local x = other:getPosition().x - self:getPosition().x
                    local y = other:getPosition().y - self:getPosition().y
                    local d = x * x + y * y
                    if d < dist then
                        target = other
                        dist = d
                    end
                end
            end
        end
    end

    return target
end

-- 返回最近的actor列表，并按照距离近-远排序
function QActor:getClosestActors(others)
    if others == nil then return nil end

    local target = nil
    local dist = 10e20 -- the value that should be large enough
    local list = {}

    for i, other in ipairs(others) do
        if not other:isDead() then
            if other:getPosition().x > BATTLE_AREA.left - 50 and other:getPosition().x < BATTLE_AREA.right + 50 then
                local x = other:getPosition().x - self:getPosition().x
                local y = other:getPosition().y - self:getPosition().y
                local d = x * x + y * y
                list[#list + 1] = {other = other, dist = d}
            end
        end
    end
    local result = {}
    for i = 1, #list do
        for j = i + 1, #list do
            if list[i].dist > list[j].dist then
                local tmp = list[i]
                list[i] = list[j]
                list[j] = tmp
            end
        end
        result[i] = list[i].other
    end

    return result
end

function QActor:getState()
    return self.fsm__:getState()
end

function QActor:setRect(rect)
    self._rect = rect
end

function QActor:getRect()
    return self._rect
end

function QActor:setCoreRect(rect)
    self._coreRect = rect
end

function QActor:getCoreRect()
    return self._coreRect
end

function QActor:getBoundingBox()
    return CCRectMake(  self._rect.origin.x + self._position.x, 
                        self._rect.origin.y + self._position.y, 
                        self._rect.size.width, self._rect.size.height)
end

function QActor:getCoreBoundingBox()
    return CCRectMake(  self._coreRect.origin.x + self._position.x, 
                        self._coreRect.origin.y + self._position.y, 
                        self._coreRect.size.width, self._coreRect.size.height)
end

function QActor:getCenterPosition()
    return ccp(self._rect.origin.x + self._position.x + self._rect.size.width * 0.5,
                self._rect.origin.y + self._position.y + self._rect.size.height * 0.5)
end

function QActor:getBoundingBox_Stage()
    local actorView = app.scene:getActorViewFromModel(self)
    local adjust = actorView:convertToWorldSpace(ccp(0, 0))
    adjust.x = adjust.x - self._position.x
    adjust.y = adjust.y - self._position.y

    return CCRectMake(  self._rect.origin.x + self._position.x + adjust.x, 
                        self._rect.origin.y + self._position.y + adjust.y, 
                        self._rect.size.width, self._rect.size.height)
end

function QActor:getCoreBoundingBox_Stage()
    local actorView = app.scene:getActorViewFromModel(self)
    local adjust = actorView:convertToWorldSpace(ccp(0, 0))
    adjust.x = adjust.x - self._position.x
    adjust.y = adjust.y - self._position.y

    return CCRectMake(  self._coreRect.origin.x + self._position.x + adjust.x, 
                        self._coreRect.origin.y + self._position.y + adjust.y, 
                        self._coreRect.size.width, self._coreRect.size.height)
end

function QActor:getCenterPosition_Stage()
    local actorView = app.scene:getActorViewFromModel(self)
    local adjust = actorView:convertToWorldSpace(ccp(0, 0))
    adjust.x = adjust.x - self._position.x
    adjust.y = adjust.y - self._position.y

    local pos = self:getCenterPosition()
    pos.x = pos.x + adjust.x
    pos.y = pos.y + adjust.y
    return pos
end

function QActor:getPosition()
    -- printInfo(self:getId() .. " getPosition: " .. self._position.x .. "," .. self._position.y)
    return self._position
end

function QActor:getPosition_Stage()
    local actorView = app.scene:getActorViewFromModel(self)
    local adjust = actorView:convertToWorldSpace(ccp(0, 0))
    adjust.x = adjust.x - self._position.x
    adjust.y = adjust.y - self._position.y

    local pos = clone(self:getPosition())
    pos.x = pos.x + adjust.x
    pos.y = pos.y + adjust.y
    return pos
end

-- 注意：这个函数应该只从QPositionDirector中调用
function QActor:setActorPosition(pos)
    local lastPositionX = self._position.x
    self._position = pos
    self:dispatchEvent({name = QActor.SET_POSITION_EVENT, position = self._position})

    -- use blink when character have it on Enter to scene
    if not app.battle:isPVPMode() and self:getType() == ACTOR_TYPES.HERO and app.battle ~= nil and app.battle:isWaitingForStart() == true then
        -- check if enter scene
        if lastPositionX < BATTLE_AREA.left + 50 and pos.x >= BATTLE_AREA.left + 50 then
            -- check if have blink skill
            local blinkSkill = nil
            for _, skill in pairs(self._skills) do
                if skill:getName() == "blink" then
                    blinkSkill = skill
                    break
                end
            end
            if blinkSkill == nil or not self:canAttack(blinkSkill) then
                return
            end

            local screenPos = app.grid:_toScreenPos(self.gridPos)
            self._dragPosition = ccp(screenPos.x + 20, screenPos.y)
            self._targetPosition = ccp(screenPos.x + 20, screenPos.y)
            self:attack(blinkSkill)
        end
    end
end

function QActor:getTargetPosition()
    return self._targetPosition
end

function QActor:getDragPosition()
    return self._dragPosition
end

function QActor:clearTargetPosition()
    self._targetPosition = nil
end

function QActor:stopDoing()
    self.fsm__:doEvent("ready")
end

function QActor:startMoving(pos)
    if pos == nil or self:CanControlMove() == false then
        return
    end

    if self._currentSkill ~= nil and self._currentSkill:isCancelWhileMove() == true then
        self:_cancelCurrentSkill()
    end

    self._targetPosition = pos

    -- 如果已经和当前位置非常接近，则忽略
    if q.is2PointsClose(self._targetPosition, self._position) then
        return
    end

    self.fsm__:doEvent("move")
end

function QActor:stopMoving()
    self.fsm__:doEvent("ready")
end

function QActor:isDead()
    return self.fsm__:getState() == "dead"
end

function QActor:isFrozen()
    return self.fsm__:getState() == "frozen"
end

function QActor:setFullHp()
    self._hp = self:getMaxHp()
    self._hpBeforeLastChange = self._hp
end

function QActor:setHp(hp)
    if hp == nil then
        return 
    end

    if hp < 0 then
        hp = 0
    end

    self._hp = hp
    self._hpBeforeLastChange = self._hp
end

function QActor:increaseHp(hp)
    assert(not self:isDead(), string.format("QActor %s:%s is dead, can't change Hp", self:getId(), self:getDisplayName()))
    assert(hp > 0, "QActor:increaseHp() - invalid hp " .. tostring(hp) .. "hp should large then 0")

    self._hpBeforeLastChange = self._hp
    
    local newhp = self._hp + hp
    if newhp > self:getMaxHp() then
        newhp = self:getMaxHp()
    end

    -- 这里不判断 self._hp = newhp，始终赋值并发出HP_CHANGED_EVENT事件
    -- 因为在满血的时候可能牧师会给英雄继续加血，这个时候如果没有HP_CHANGED_EVENT
    -- 的触发，英雄的血条会消失，看起来会很奇怪。
    self._hp = newhp
    self:dispatchEvent({name = QActor.HP_CHANGED_EVENT})

    return self
end

function QActor:decreaseHp(hp)
    assert(not self:isDead(), string.format("QActor %s:%s is dead, can't change Hp", self:getId(), self:getDisplayName()))
    assert(hp > 0, "QActor:decreaseHp() - invalid hp " .. tostring(hp) .. "hp should large then 0")

    -- 計算吸收的傷害
    local absorbTotal = 0
    for _, buff in ipairs(self._buffs) do
        if buff:isAbsorbDamage() then
            local damage = math.min(buff:getAbsorbDamageValue(), hp)
            buff:absorbDamageValue(damage)
            absorbTotal = absorbTotal + damage

            if absorbTotal >= hp then
                break
            end
        end
    end
    hp = hp - absorbTotal

    self._hpBeforeLastChange = self._hp

    local newhp = self._hp - hp
    if newhp <= 0 then
        newhp = 0
    end

    if self:getTalentFunc() ~= nil or true then
        -- newhp = self._hpBeforeLastChange
    end

    if newhp <= 0 then
        newhp = self._hpBeforeLastChange
    end

    if newhp < self._hp then
        self._hp = newhp
        app.battle:performWithDelay(function()
            self:dispatchEvent({name = QActor.HP_CHANGED_EVENT})
        end, 0.17)
        if newhp == 0 then
            self:_cancelCurrentSkill()
            self:removeAllBuff()
            for _, skill in pairs(self._activeSkills) do
                skill:resetCoolDown()
            end
            for _, skill in pairs(self._manualSkills) do
                skill:resetCoolDown()
            end
            self.fsm__:doEvent("kill")
        end
    end

    return self, hp, absorbTotal
end

function QActor:suicide()
    self:_cancelCurrentSkill()
    self:removeAllBuff()
    self.fsm__:doEvent("kill")
end

function QActor:isLockTarget()
    return self._isLockTarget > 0
end

function QActor:lockTarget()
    self._isLockTarget = self._isLockTarget + 1
end

function QActor:unlockTarget()
    self._isLockTarget = self._isLockTarget - 1
end

function QActor:setTarget(target)
    if self._isLockTarget > 0 and self._target ~= nil and self._target:isDead() == false then
        return
    end

    if target == self:getTarget() then
        return
    end

    -- target should alive
    if target ~= nil and target:isDead() == true then
        return
    end

    if self._target ~= nil then
        if self._targetSkillHandle ~= nil then
            self._target:removeEventListener(self._targetSkillHandle)
            self._targetSkillHandle = nil
        end
    end

    if target ~= nil then 
        self._targetSkillHandle = target:addEventListener(QActor.KILL_EVENT, handler(self, self._onTargetKill))
        --printInfo("set target: " .. self:getDisplayName() .. " -> " .. target:getDisplayName())
    end

    self._target = target

    -- test one track line
    -- if self:getTalentFunc() == nil or self:getTalentFunc() == "" then
    --     if target == nil then
    --         self:dispatchEvent({name = QActor.ONE_TRACK_END_EVENT})
    --     else
    --         self:dispatchEvent({name = QActor.ONE_TRACK_START_EVENT, track_target = target})
    --     end
    -- end
end

function QActor:isHealth()
    return (self:getTalent() ~= nil and self:getTalentFunc() == "health")
end

function QActor:isT()
    return (self:getTalent() ~= nil and self:getTalentFunc() == "t")
end

function QActor:isDps()
    return (self:getTalent() ~= nil and self:getTalentFunc() == "dps")
end

-- 是否是远程攻击的角色
function QActor:isRanged()
    return self:getTalentSkill():getAttackDistance() >= global.ranged_attack_distance * global.pixel_per_unit
end

function QActor:getTarget()
    return self._target
end

function QActor:isInBattleArea()
    if self._position.x >= BATTLE_AREA.left 
        and self._position.x <= BATTLE_AREA.right
        and self._position.y >= BATTLE_AREA.bottom
        and self._position.y <= BATTLE_AREA.top then
       return true
    end
    return false
end

function QActor:canMove()
    return self.fsm__:canDoEvent("move")
end

function QActor:canAttack(skill)
    if app.battle:isBattleEnded() == true then
        return
    end

    if skill == nil or self:isDead() == true then
        return false
    end

    -- check use condition
    if skill:isReadyAndConditionMet() == false then
        return false
    end

    -- get change state 
    local changeEvent = nil
    if skill == self:getTalentSkill() or skill == self:getTalentSkill2() then
        -- check normal attack is ok by battle manager
        if not app.battle:checkNormalAttack(self:getDisplayID(), skill:getName()) then
            return false
        end

        changeEvent = "attack"
    else
        changeEvent = "skill"
    end

    -- check target
    if skill:isNeedATarget() == true then
        if self._target == nil or self._target:isDead() == true or self._target:isInBattleArea() == false then 
            return false 
        end

        -- check distance
        if skill:get("auto_target") and self:getTarget() then
            if skill:isInSkillRange(self:getPosition(), self:getTarget():getPosition()) == false then
                return false
            end
        end
    end

    -- other conditions
    if self.fsm__:canDoEvent(changeEvent) == false then
        return false
    end

    -- check if current skill can cancel
    if self._currentSkill ~= nil then
        local currentSkillType = self._currentSkill:getSkillType()
        local skillType = skill:getSkillType()
        if currentSkillType == QSkill.ACTIVE then
            if (self._currentSkill ~= self:getTalentSkill() and self._currentSkill ~= self:getTalentSkill2()) and skillType ~= QSkill.MANUAL then
                return false
            end
        elseif currentSkillType == QSkill.MANUAL then
            return false
        end
    end

    if skill:getName() == "charge" and self._target and self._target._immune_charge then
        return false
    end

    return true
end

function QActor:getTalentSkill()    
    if self._talentSkill == nil then
        local name = self:get("npc_skill")
        if string.len(name) == 0 and self:getTalent() then
            name = self:getTalent().skill_1
        end
        for _, skill in pairs(self._skills) do
            if skill:getName() == name or skill:getId() == name then
                self._talentSkill = skill
                break
            end
        end
        if self._talentSkill == nil then
            assert(skill, "failed to find talent skill from actor skill list with skill name: " .. name)
        end
    end
    return self._talentSkill
end

function QActor:getTalentSkill2()    
    if self._talentSkill2 == nil then
        local name = self:get("npc_skill_2")
        if string.len(name) == 0 and self:getTalent() then
            name = self:getTalent().skill_2
        end
        for _, skill in pairs(self._skills) do
            if skill:getName() == name or skill:getId() == name then
                self._talentSkill2 = skill
                break
            end
        end
    end
    return self._talentSkill2
end

-- only use in arena
function QActor:getVaildSkillInArena()
    if self._currentSkill ~= nil then
        return nil
    end

    local skills = {}
    table.merge(skills, self._manualSkills)
    table.merge(skills, self._activeSkills)
    
    for _, skill in pairs(skills) do
        while true do
            if skill:isReady() == false then
                break
            end

            if skill:getTriggerCondition() ~= nil then
                local probability = skill:getTriggerProbability()
                if probability < math.random(1, 100) then
                    break
                end
            end

            if skill:isNeedATarget() == false then
                return skill
            else
                if self._target ~= nil and self._target:isDead() ~= true
                    and skill:isInSkillRange(self:getPosition(), self._target:getPosition(), false) == true then
                    return skill
                end
            end

            break
        end
    end

    return nil
end

function QActor:getNextAttackSkill()
    if self._nextAttackSkill == nil then
        self:resetNextAttackSkill()
    end

    return self._nextAttackSkill
end

function QActor:resetNextAttackSkill()
    local talentSkill = self:getTalentSkill()
    local talentSkill2 = self:getTalentSkill2()
    if talentSkill2 == nil then
        self._nextAttackSkill = talentSkill
    else
        self._nextAttackSkill = (math.random(1, 10000) <= 7500 and talentSkill) or talentSkill2  
    end
end

function QActor:getVaildActiveSkillForAutoLaunch()
    if self._currentSkill ~= nil then
        return nil
    end

    local validSkills = {}
    local validSkillPriority = nil
    for _, skill in pairs(self._activeSkills) do
        if validSkillPriority ~= nil and skill:getSkillPriority() < validSkillPriority then
            break
        end

        if skill:getTriggerCondition() == nil and self:canAttack(skill) then
            if (skill ~= self:getTalentSkill() and skill ~= self:getTalentSkill2()) or skill == self:getNextAttackSkill() then
                table.insert(validSkills, skill)
                validSkillPriority = skill:getSkillPriority()
            end
        end
    end

    if #validSkills == 0 then
        return nil
    else
        return validSkills[math.random(1, #validSkills)]
    end
end

-- 触发型攻击
function QActor:triggerAttack(skill, counterattack_target)
    if skill == nil then
        return
    end

    local remove_buffs = {}
    for _, buff in ipairs(self._buffs) do
        if buff.effects.can_use_skill == false and not buff:isImmuned() then
            if buff.effects.can_be_removed_with_skill == false or skill:canRemoveBuff() == false then
                -- 检查技能是否可以通过remove status移除buff
                if skill:isRemoveStatus(buff:getStatus()) then
                    table.insert(remove_buffs, buff)
                else
                    return
                end
            end
        end
    end
    for _, buff in ipairs(remove_buffs) do
        self:removeBuffByID(buff:getId())
    end

    -- 单体：检查技能的status是否会被target的任意一个buff的immune status给免疫掉，免疫的话直接返回
    -- TODO:
    local skillImmuned = false
    if skill:getRangeType() == QSkill.SINGLE then
        if counterattack_target then
            target = counterattack_target
        elseif skill:getTargetType() == QSkill.SELF then
            target = self
        else
            target = self:getTarget()
        end

        if target == nil then
            return
        end

        skillImmuned = target:isImmuneSkill(skill)
    end
    if skillImmuned then
        return
    end

    -- if skill ~= self:getTalentSkill() and skill ~= self:getTalentSkill2() then
    --     self.fsm__:doEvent("skill", {skill = skill})
    -- else
    --     self.fsm__:doEvent("attack", {skill = skill})
    -- end

    local sbDirector = QSBDirector.new(self, counterattack_target or self._target, skill)
    sbDirector._is_triggered = true
    table.insert(self._sbDirectors, sbDirector)

    skill:coolDown()

    if skill:canRemoveBuff() == true then
        local index = -1
        while index ~= 0 do
            index = 0
            for i, buff in ipairs(self._buffs) do
                if buff.effects.can_be_removed_with_skill == true then
                    index = i
                    break
                end
            end
            if index ~= 0 then
                self:removeBuffByIndex(index)
            end
        end
    end

    return sbDirector
end

function QActor:canAttackWithBuff(skill)
    for _, buff in ipairs(self._buffs) do
        if buff.effects.can_use_skill == false and not buff:isImmuned() then
            if buff.effects.can_be_removed_with_skill == false or skill:canRemoveBuff() == false then
                -- 检查技能是否可以通过remove status移除buff
                if not skill:isRemoveStatus(buff:getStatus()) then
                    return false
                end
            end
        end
    end

    -- 单体：检查技能的status是否会被target的任意一个buff的immune status给免疫掉，免疫的话直接返回
    local skillImmuned = false
    if skill:getRangeType() == QSkill.SINGLE and skill:isNeedATarget() then
        if counterattack_target then
            target = counterattack_target
        elseif skill:getTargetType() == QSkill.SELF then
            target = self
        else
            target = self:getTarget()
        end

        skillImmuned = target:isImmuneSkill(skill)
    end
    if skillImmuned then
        return false
    end

    return true
end

-- 攻击
function QActor:attack(skill, auto, counterattack_target)
    if skill == nil then
        return
    end

    local remove_buffs = {}
    for _, buff in ipairs(self._buffs) do
        if buff.effects.can_use_skill == false and not buff:isImmuned() then
            if buff.effects.can_be_removed_with_skill == false or skill:canRemoveBuff() == false then
                -- 检查技能是否可以通过remove status移除buff
                if skill:isRemoveStatus(buff:getStatus()) then
                    table.insert(remove_buffs, buff)
                else
                    return
                end
            end
        end
    end
    for _, buff in ipairs(remove_buffs) do
        self:removeBuffByID(buff:getId())
    end

    -- 单体：检查技能的status是否会被target的任意一个buff的immune status给免疫掉，免疫的话直接返回
    local skillImmuned = false
    if skill:getRangeType() == QSkill.SINGLE and skill:isNeedATarget() then
        if counterattack_target then
            target = counterattack_target
        elseif skill:getTargetType() == QSkill.SELF then
            target = self
        else
            target = self:getTarget()
        end

        skillImmuned = target:isImmuneSkill(skill)
    end
    if skillImmuned then
        return
    end

    self:_cancelCurrentSkill()

    if skill:isStopMoving() then
        self:stopMoving() -- 停止移动，站位机制里面需要对这个情况做特殊处理
    end

    if skill ~= self:getTalentSkill() and skill ~= self:getTalentSkill2() then
        self.fsm__:doEvent("skill", {skill = skill})
    else
        -- register normal attack in battle manager
        app.battle:registerNormalAttack(self:getDisplayID(), skill:getName())

        self.fsm__:doEvent("attack", {skill = skill})
    end

    self._currentSkill = skill
    self._currentSBDirector = QSBDirector.new(self, counterattack_target or self._target, skill)
    table.insert(self._sbDirectors, self._currentSBDirector)

    skill:coolDown()

    if skill == self:getNextAttackSkill() then
        self:resetNextAttackSkill()
    end

    if skill:canRemoveBuff() == true then
        local index = -1
        while index ~= 0 do
            index = 0
            for i, buff in ipairs(self._buffs) do
                if buff.effects.can_be_removed_with_skill == true then
                    index = i
                    break
                end
            end
            if index ~= 0 then
                self:removeBuffByIndex(index)
            end
        end
    end
    
    if skill:getSkillType() == QSkill.MANUAL then
        self:dispatchEvent({name = QActor.USE_MANUAL_SKILL_EVENT, skill = skill, actor = self})
        if self:getType() == ACTOR_TYPES.HERO then
            local cast_sound = QStaticDatabase:sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).cast
            audio.playSound(cast_sound, false)

            app.battle:onActorUseManualSkill(self, skill, auto)
        end
    end

    local combo_points = skill:getComboPointsGain()
    if combo_points > 0 then
        self:gainComboPoints(combo_points)
    end

    if skill:isNeedComboPoints() then
        self:consumeComboPoints()
    end
    app.battle:onUseSkill(self, skill)

    return self._currentSBDirector
end

function QActor:getMultipleTargetWithSkill(skill, target, center)
    local targets = {}
    if skill == nil then
        return targets
    end
    assert(skill:getRangeType() == QSkill.MULTIPLE, "expected ".. QSkill.MULTIPLE .. " but got " .. skill:getRangeType())
    assert(skill:getZoneType() == QSkill.ZONE_FAN or skill:getZoneType() == QSkill.ZONE_RECT, "wrong zone type: " .. skill:getZoneType())

    -- 扇形区域
    if skill:getZoneType() == QSkill.ZONE_FAN then
        -- get center position
        if skill:getSectorCenter() == QSkill.CENTER_SELF then
            -- 以自己为攻击圆的中心
            center = self:getPosition()
        else
            -- 以目标为攻击圆的中心
            assert(skill:getSectorCenter() == QSkill.CENTER_TARGET)
            if center == nil and target ~= nil then
                -- 在延迟的0.2秒内攻击对象有可能已经被打死
                center = target:getPosition()
            end
        end

        -- get radius in pixel
        local radius = skill:getSectorRadius() * global.pixel_per_unit
        assert(radius > 0, "skill: " .. skill:getId() .. " circle radius should large then 0")
        radius = radius * radius

        -- get target in circle
        if center ~= nil then
            local actors = {}
            if skill:getTargetType() == QSkill.TEAMMATE then
                actors = app.battle:getMyTeammates(self)
            elseif skill:getTargetType() == QSkill.TEAMMATE_AND_SELF then
                actors = app.battle:getMyTeammates(self, true)
            elseif skill:getTargetType() == QSkill.ENEMY then
                actors = app.battle:getMyEnemies(self)
            else
                assert(false, "skill: " .. skill:getId() .. "is range skill for teammate and enemy, but current target type is " .. skill:getTargetType())
            end

            local sectorDegree = skill:getSectorDegree()

            if sectorDegree >= 360 then
                -- it's a circle
                for _, actor in ipairs(actors) do
                    local pos = actor:getPosition()
                    local deltaX = pos.x - center.x
                    local deltaY = (pos.y - center.y) * 2
                    local distance = deltaX * deltaX + deltaY * deltaY
                    if distance < radius then
                        table.insert(targets, actor)
                    end
                end
            else
                -- it's a sector
                local actorView = nil
                if skill:getSectorCenter() == QSkill.CENTER_SELF then
                    actorView = app.scene:getActorViewFromModel(self)
                else
                    actorView = app.scene:getActorViewFromModel(target)
                end

                -- is on right side
                local isRightDirection = (actorView:isFlipX() == true)

                sectorDegree = sectorDegree * 0.5

                for _, actor in ipairs(actors) do
                    local pos = actor:getPosition()
                    local deltaX = pos.x - center.x
                    local deltaY = (pos.y - center.y) * 2
                    local distance = deltaX * deltaX + deltaY * deltaY
                    if distance < radius then
                        
                        --[[
                            For any real number (e.g., floating point) arguments x and y not both equal to zero, 
                            atan2(y, x) is the angle in radians between the positive x-axis of a plane and the point given by the coordinates (x, y) on it. 
                            The angle is positive for counter-clockwise angles (upper half-plane, y > 0), and negative for clockwise angles (lower half-plane, y < 0).
                            This produces results in the range (−π, π], which can be mapped to [0, 2π) by adding 2π to negative results.
                        --]]

                        if deltaX == 0 then
                            if sectorDegree >= 90 then
                                table.insert(targets, actor)
                            end
                            
                        elseif deltaY == 0 then
                            if isRightDirection == true and deltaX > 0 then
                                table.insert(targets, actor)
                            elseif isRightDirection == false and deltaX < 0 then
                                table.insert(targets, actor)
                            end

                        else
                            if isRightDirection == false then
                                deltaX = -deltaX
                            end

                            local radian = math.atan2(deltaY, deltaX)
                            local degree = 180 / math.pi * radian
                            if degree < 0 then
                                degree = -degree
                            end

                            if degree < sectorDegree then
                                table.insert(targets, actor)
                            end
                        end

                    end
                end
            end

            -- display range
            if DISPLAY_SKILL_RANGE == true then
                if sectorDegree >= 360 then
                    radius = math.sqrt(radius)
                    local bottomLeft = ccp(center.x - radius, center.y - radius * 0.5)
                    local topRight = ccp(center.x + radius, center.y + radius * 0.5)
                    app.scene:displayRect(bottomLeft, topRight)
                elseif sectorDegree < 90 then
                    local actorView = nil
                    if skill:getSectorCenter() == QSkill.CENTER_SELF then
                        actorView = app.scene:getActorViewFromModel(self)
                    else
                        actorView = app.scene:getActorViewFromModel(target)
                    end
                    local isRightDirection = (actorView:isFlipX() == true)
                    radius = math.sqrt(radius)
                    local radian = sectorDegree * math.pi / 180
                    local lenth = radius * math.tan(radian)
                    lenth = lenth * 0.5
                    if isRightDirection == false then
                        local pos1 = center
                        local pos2 = ccp(center.x - radius, center.y + lenth)
                        local pos3 = ccp(center.x - radius, center.y - lenth)
                        app.scene:displayTriangle(pos1, pos2, pos3)
                    else
                        local pos1 = center
                        local pos2 = ccp(center.x + radius, center.y - lenth)
                        local pos3 = ccp(center.x + radius, center.y + lenth)
                        app.scene:displayTriangle(pos1, pos2, pos3)
                    end
                    
                end
            end
        end
    -- 矩形区域
    else
        -- get target in rect
        local actors = {}
        if skill:getTargetType() == QSkill.TEAMMATE then
            actors = app.battle:getMyTeammates(self)
        elseif skill:getTargetType() == QSkill.TEAMMATE_AND_SELF then
            actors = app.battle:getMyTeammates(self, true)
        elseif skill:getTargetType() == QSkill.ENEMY then
            actors = app.battle:getMyEnemies(self)
        else
            assert(false, "skill: " .. skill:getId() .. "is range skill for teammate and enemy, but current target type is " .. skill:getTargetType())
        end

        local rectwidth = skill:getRectWidth() * global.pixel_per_unit
        local rectheight = skill:getRectHeight() * global.pixel_per_unit

        if rectwidth > 0 and rectheight > 0 then
            local actorView = app.scene:getActorViewFromModel(self)
            local isRightDirection = (actorView:isFlipX() == true)
            local center = self:getPosition()
            local left = (isRightDirection and center.x) or (center.x - rectwidth)
            local right = (not isRightDirection and center.x) or (center.x + rectwidth)
            local bottom = center.y - rectheight / 2
            local top = center.y + rectheight / 2

            for _, actor in ipairs(actors) do
                local pos = actor:getPosition()
                if pos.x >= left and pos.x <= right and pos.y >= bottom and pos.y <= top then
                    table.insert(targets, actor)
                end
            end
        end

        -- display range
        if DISPLAY_SKILL_RANGE == true then
            local rectwidth = skill:getRectWidth() * global.pixel_per_unit
            local rectheight = skill:getRectHeight() * global.pixel_per_unit

            if rectwidth > 0 and rectheight > 0 then
                local actorView = app.scene:getActorViewFromModel(self)
                local isRightDirection = (actorView:isFlipX() == true)
                local center = self:getPosition()
                local left = (isRightDirection and center.x) or (center.x - rectwidth)
                local right = (not isRightDirection and center.x) or (center.x + rectwidth)
                local bottom = center.y - rectheight / 2
                local top = center.y + rectheight / 2
                app.scene:displayRect({x = left, y = bottom}, {x = right, y = top})
            end
        end
    end

    local skill_target_id = skill:getTargetID()
    if skill_target_id ~= nil and skill_target_id ~= "" then
        local filtered_targets = {}
        for _, target in ipairs(targets) do
            if target:getActorID() == skill_target_id then
                table.insert(filtered_targets, target)
            end
        end
        targets = filtered_targets
    end

    return targets
end

function QActor:onHit( skill, target, center, delay)
    if skill == nil then
        return
    end

    if skill:isNeedATarget() == true then
        if target == nil or target:isDead() == true then
            return
        end
    end

    if skill:getRangeType() == QSkill.SINGLE then
        if skill:getTargetType() == QSkill.SELF then
            target = self
        end
        -- 单体攻击模式，直接打击目标
        if target ~= nil then
            -- 在延迟的时间内攻击对象有可能已经被打死
            self:hit(skill, target)
        end

        -- trap 
        self:triggerTrap(skill, target)
    else

        -- 开始属性cache,节省aoe计算量
        self._cachingProperties = {}
        -- 群体攻击模式
        local targets = self:getMultipleTargetWithSkill(skill, target, center)
        -- 群体攻击伤害在PVE模式下的加速
        local aoe_damage_cache = not app.battle:isPVPMode()
        local aoe_damage_original = nil
        local aoe_damage_original_id = nil
        -- 平分伤害
        local split = skill:getDamageSplit()
        local split_number = split and #targets or 0
        local delayTime = 0
        delay = delay or 0
        for _, actor in ipairs(targets) do
            if delay > 0 then
                app.battle:performWithDelay(function()
                    if actor:isDead() == false or actor:isDoingDeadSkill() then
                        self:hit(skill, actor, split_number)
                    end
                end, delayTime)
                delayTime = delayTime + delay
            else
                if aoe_damage_cache then
                    if aoe_damage_original_id == actor:getActorID() then
                        self:hit(skill, actor, split_number, nil, aoe_damage_original)
                    else
                        aoe_damage_original = self:hit(skill, actor, split_number)
                        if aoe_damage_original ~= nil then
                            aoe_damage_original_id = actor:getActorID()
                        end
                    end
                else
                    self:hit(skill, actor, split_number)
                end
            end
        end
        -- 结束属性cache
        self._cachingProperties = nil

        if skill:getZoneType() == QSkill.ZONE_RECT or (skill:getZoneType() == QSkill.ZONE_FAN and skill:getSectorCenter() == QSkill.CENTER_SELF) then
            self:triggerTrap(skill, self)
        else
            if target ~= nil and target:isDead() == false then
                self:triggerTrap(skill, target)
            end
        end
    end
end

function QActor:triggerBuff(skill, target)
    if skill:isBuffConditionMet1() then
        local buffId = skill:getBuffId1()
        local buffTargetType = skill:getBuffTargetType1()
        self:_doTriggerBuff(buffId, buffTargetType, target)
    end

    if skill:isBuffConditionMet1() then
        local buffId = skill:getBuffId2()
        buffTargetType = skill:getBuffTargetType2()
        self:_doTriggerBuff(buffId, buffTargetType, target)
    end
end

function QActor:_doTriggerBuff(buffId, buffTargetType, target)
    if buffId ~= nil and string.len(buffId) > 0 then
        if buffTargetType == QSkill.BUFF_SELF then
            self:applyBuff(buffId, self)
        elseif buffTargetType == QSkill.BUFF_TARGET and target then
            target:applyBuff(buffId, self)
        elseif buffTargetType == QSkill.BUFF_MAIN_TARGET and target and target == self:getTarget() then
            target:applyBuff(buffId, self)
        elseif buffTargetType == QSkill.BUFF_OTHER_TARGET and target and target ~= self:getTarget() then
            target:applyBuff(buffId, self)
        end
    end
end

function QActor:triggerTrap(skill, target)
    local trapId = skill:getTrapId()
    if trapId ~= nil then
        local trapDirector = QTrapDirector.new(trapId, target:getPosition(), self:getType(), self)
        app.battle:addTrapDirector(trapDirector)
    end
    
end

-- actor is attacker if isHit equal to true
-- actor is target if isHit equal to false
function QActor:triggerPassiveSkill(condition, actor)
    if condition == nil or actor == nil then
        return
    end

    for _, skill in pairs(self._passiveSkills) do
        if skill:isReady() == true and skill:getTriggerCondition() == condition then
            local probability = skill:getTriggerProbability()
            if probability >= math.random(1, 100) then
                -- apply buff
                if skill:getTriggerType() == QSkill.TRIGGER_TYPE_BUFF then
                    local buffId = skill:getTriggerBuffId()
                    local buffTargetType = skill:getTriggerBuffTargetType()
                    self:_doTriggerBuff(buffId, buffTargetType, actor)
                    
                elseif skill:getTriggerType() == QSkill.TRIGGER_TYPE_ATTACK then
                    local skillId = skill:getTriggerSkillId()
                    local triggerSkill = self._skills[skillId]
                    if triggerSkill == nil then
                        local database = QStaticDatabase.sharedDatabase()
                        triggerSkill = QSkill.new(skillId, database:getSkillByID(skillId), self)
                        self._skills[skillId] = triggerSkill
                    end
                    if triggerSkill:isReadyAndConditionMet() then
                        if condition == QSkill.TRIGGER_CONDITION_HIT and triggerSkill:isNeedATarget() then
                            local sbDirector = nil
                            if buff:getTriggerSkillAsCurrent() then
                                sbDirector = self:attack(triggerSkill, false, actor)
                            else
                                sbDirector = self:triggerAttack(triggerSkill, actor)
                            end
                            sbDirector._target = actor
                        else
                            if buff:getTriggerSkillAsCurrent() then
                                sbDirector = self:attack(triggerSkill)
                            else
                                sbDirector = self:triggerAttack(triggerSkill)
                            end
                        end
                    end
                elseif skill:getTriggerType() == QSkill.TRIGGER_TYPE_COMBO then
                    local combo_points = skill:getTriggerComboPoints()
                    self:gainComboPoints(combo_points)
                elseif skill:getTriggerType() == QSkill.TRIGGER_TYPE_CD_REDUCE then
                    local manual_skills = self:getManualSkills()
                    manual_skills[next(manual_skills)]:reduceCoolDownTime(QActor.ARENA_BEATTACKED_CD_REDUCE)
                end
                skill:coolDown()
            end
        end
    end
end

-- actor is attacker if isHit equal to true
-- actor is target if isHit equal to false
function QActor:triggerAlreadyAppliedBuff(condition, actor, trigger_target, damage)
    if condition == nil or actor == nil then
        return
    end

    for _, buff in pairs(self._buffs) do
        -- trigger target check
        local trigger_target_check = false
        local buff_trigger_target = buff:getTriggerTarget()
        if buff_trigger_target ~= QBuff.TRIGGER_TARGET_TEAMMATE_AND_SELF then
            trigger_target_check = buff_trigger_target == trigger_target
        else
            trigger_target_check = buff_trigger_target == QBuff.TRIGGER_TARGET_TEAMMATE or buff_trigger_target == QBuff.TRIGGER_TARGET_SELF
        end

        if trigger_target_check and buff:isReady() and buff:isImmuned() == false and buff:getTriggerCondition() == condition then
            local probability = buff:getTriggerProbability()
            if probability >= math.random(1, 100) then
                -- apply buff
                if buff:getTriggerType() == QBuff.TRIGGER_TYPE_BUFF then
                    local buffId = buff:getTriggerBuffId()
                    local buffTargetType = buff:getTriggerBuffTargetType()
                    self:_doTriggerBuff(buffId, buffTargetType, actor)
                    
                elseif buff:getTriggerType() == QBuff.TRIGGER_TYPE_ATTACK then
                    local skillId = buff:getTriggerSkillId()
                    local triggerSkill = self._skills[skillId]
                    if triggerSkill == nil then
                        local database = QStaticDatabase.sharedDatabase()
                        triggerSkill = QSkill.new(skillId, database:getSkillByID(skillId), self)
                        self._skills[skillId] = triggerSkill
                    end
                    if triggerSkill:isReadyAndConditionMet() then
                        local inherit_percent = buff:getTriggerSkillInheritPercent()
                        local isTriggerAttack = true
                        if inherit_percent > 0 then
                            if damage > 0 then
                                triggerSkill:setInheritedDamage(damage * inherit_percent)
                            else
                                isTriggerAttack = false
                            end
                        end

                        if isTriggerAttack == true then
                            if condition == QBuff.TRIGGER_CONDITION_HIT and triggerSkill:isNeedATarget() then
                                local sbDirector = nil
                                if buff:getTriggerSkillAsCurrent() then
                                    sbDirector = self:attack(triggerSkill, false, actor)
                                else
                                    sbDirector = self:triggerAttack(triggerSkill, actor)
                                end
                                sbDirector._target = actor
                            else
                                if buff:getTriggerSkillAsCurrent() then
                                    sbDirector = self:attack(triggerSkill)
                                else
                                    sbDirector = self:triggerAttack(triggerSkill)
                                end
                            end
                        end
                        
                    end
                elseif buff:getTriggerType() == QBuff.TRIGGER_TYPE_COMBO then
                    local combo_points = buff:getTriggerComboPoints()
                    self:gainComboPoints(combo_points)
                elseif skill:getTriggerType() == QBuff.TRIGGER_TYPE_CD_REDUCE then
                    local manual_skills = self:getManualSkills()
                    manual_skills[next(manual_skills)]:reduceCoolDownTime(QActor.ARENA_BEATTACKED_CD_REDUCE)
                end

                buff:coolDown()
            end
        end
    end
end

function QActor:isIdle()
    return self.fsm__:isState("idle")
end

function QActor:isAttacking()
    return (self._currentSkill ~= nil)

end

function QActor:isWalking()
    return self.fsm__:isState("walking")
end

function QActor:setManualMode(mode)
    self._manual = mode
end

function QActor:getManualMode()
    return self._manual
end

function QActor:isManualMode()
    return self._manual ~= QActor.AUTO
end

-- 获取上次被谁攻击了
function QActor:getLastAttacker()
    return self._lastAttacker
end

-- 获取上次攻击过的对象
function QActor:getLastAttackee()
    return self._lastAttackee
end

-- 获取被复活的次数
function QActor:getReviveCount()
    if self._revive_count == nil then
        self._revive_count = 0
    end

    return self._revive_count
end

-- 清除上次攻击过的对象，一般用于角色的ai在战斗中被替换时
function QActor:clearLastAttackee()
    self._lastAttackee = nil
end

function calcDamageWithOriginalDamage(attacker, skill, attackee, original_damage)
    if attacker == nil or attackee == nil or skill == nil then
        return 0, ""
    end

    local p = math.random() * 100 -- math.random result a real number in [0, 1)

    local blocked = false

    -- 圆桌定律计算
    if skill:getAttackType() == QSkill.ATTACK then
        if skill:getHitType() == QSkill.HIT then
            local unhit = 100 - attacker:getHit()
            if (p > 0 and p < unhit) then
                -- 未击中
                return 0, "未击中", nil ,"miss"
            end
        
            p = p - unhit
        
            local dodge = attackee:getDodge()
            if (p > 0 and p < dodge) then
                -- 被闪避
                return 0, "闪避", nil, "dodge"
            end
        
            p = p - dodge
        
            local block = attackee:getBlock()
            if (p > 0 and p < block) then
                -- 被格挡
                blocked = true
            end
        
            p = p - block

        elseif skill:getHitType() == QSkill.STRIKE or skill:getHitType() == QSkill.CRITICAL then
            -- STRIKE与CRITICAL必命中
            local unhit = 100 - attacker:getHit()
            p = p - unhit
            local dodge = attackee:getDodge()
            p = p - dodge
            local block = attackee:getBlock()
            p = p - block

        end
    elseif skill:getAttackType() == QSkill.ASSIST then
        return 0, ""
    elseif skill:getAttackType() == QSkill.TREAT then
        
    else
        assert(false, "calcDamage: unknown attack type: " .. skill:getAttackType())
    end

    local damage = original_damage

    -- 战场伤害系数
    if skill:getAttackType() == QSkill.ATTACK then
        damage = damage * app.battle:getDamageCoefficient()
    end

    -- 最终伤害 和 伤害浮动
    damage = damage * (0.8 + math.random() * 0.4)

    -- 格挡 和 暴击
    local tip = ""
    local critical = false
    if blocked then
        damage = damage * 0.5
        tip = "格挡 "
    else
        local crit = attacker:getCrit()
        if skill:getHitType() == QSkill.CRITICAL or (p > 0 and p < crit) then
            -- 暴击
            damage = damage * attacker:getCritDamage()
            tip = damage > 0 and "暴击 " or ""
            critical = true
        end
    end

    if skill:getAttackType() == QSkill.TREAT then
        -- 治疗的文字显示: 前面附加一个加号"+"
        tip = tip .. "+"
    end

    damage = math.round(damage)

    if DEBUG_DAMAGE == true then
        debugString = debugString .. "最终伤害: " .. tostring(damage) .. " \n"
        printInfo(debugString)
    end

    return damage, tip, critical, blocked and "block" or "hit"
end

function calcDamage(attacker, skill, attackee, split_number)
    if attacker == nil or attackee == nil or skill == nil then
        return 0, ""
    end

    local debugString = " \n"

    if DEBUG_DAMAGE == true then
        debugString = debugString .. attacker:getId() .. " 使用技能:" .. skill:getId() .. " \n"
        debugString = debugString .. "被攻击者:" .. attackee:getId() .. " \n"
        debugString = debugString ..  "开始计算伤害 \n"
    end

    local p = math.random() * 100 -- math.random result a real number in [0, 1)

    local blocked = false

    -- 圆桌定律计算
    if skill:getAttackType() == QSkill.ATTACK then
        if skill:getHitType() == QSkill.HIT then
            local unhit = 100 - attacker:getHit()
            if (p > 0 and p < unhit) then
                -- 未击中
                return 0, "未击中", nil ,"miss"
            end
        
            p = p - unhit
        
            local dodge = attackee:getDodge()
            if (p > 0 and p < dodge) then
                -- 被闪避
                return 0, "闪避", nil, "dodge"
            end
        
            p = p - dodge
        
            local block = attackee:getBlock()
            if (p > 0 and p < block) then
                -- 被格挡
                blocked = true
            end
        
            p = p - block

        elseif skill:getHitType() == QSkill.STRIKE or skill:getHitType() == QSkill.CRITICAL then
            -- STRIKE与CRITICAL必命中
            local unhit = 100 - attacker:getHit()
            p = p - unhit
            local dodge = attackee:getDodge()
            p = p - dodge
            local block = attackee:getBlock()
            p = p - block

        end
    elseif skill:getAttackType() == QSkill.ASSIST then
        return 0, ""
    elseif skill:getAttackType() == QSkill.TREAT then
        
    else
        assert(false, "calcDamage: unknown attack type: " .. skill:getAttackType())
    end

    -- 攻击方的伤害
    local physicalDamage = 0
    local magicDamage = 0
    local attack = attacker:getAttack()

    if skill:getDamageType() == QSkill.PHYSICAL then
        physicalDamage = attack * attack / (attack + 8 * attackee:getPhysicalArmor())
    elseif skill:getDamageType() == QSkill.MAGIC then
        magicDamage = attack * attack / (attack + 8 * attackee:getMagicArmor())
    else
        assert(false, "Unknown damage type: " .. skill:getDamageType())
    end

    -- 技能的伤害
    local isBonusDamage = skill:isBonusDamageConditionMet()
    local skill_damage_percent = (isBonusDamage and skill:getBonusDamagePercent()) or skill:getDamagePercent()
    local skill_phsical_damage = (isBonusDamage and skill:getBonusPhysicalDamage()) or skill:getPhysicalDamage()
    local skill_magic_damage = (isBonusDamage and skill:getBonusMagicDamage()) or skill:getMagicDamage()
    if DEBUG_DAMAGE == true then
        debugString = debugString .. "技能的伤害 \n"
        debugString = debugString .. "skill_damage_percent = " .. tostring(skill_damage_percent) .. " \n"
        debugString = debugString .. "skill_phsical_damage = " .. tostring(skill_phsical_damage) .. " \n"
        debugString = debugString .. "skill_magic_damage = " .. tostring(skill_magic_damage) .. " \n"
    end

    -- 攻击方的伤害加成
    local physicalDamagePercent = attacker:getPhysicalDamagePercentAttack()
    local magicDamagePercent = attacker:getMagicDamagePercentAttack()
    local magicTreatPercent = attacker:getMagicTreatPercentAttack()
    if DEBUG_DAMAGE == true then
        debugString = debugString .. "攻击方的伤害加成 \n"
        debugString = debugString .. "physicalDamagePercent = " .. tostring(physicalDamagePercent) .. " \n"
        debugString = debugString .. "magicDamagePercent = " .. tostring(magicDamagePercent) .. " \n"
        debugString = debugString .. "magicTreatPercent = " .. tostring(magicTreatPercent) .. " \n"
    end

    -- 被攻击方的伤害加成
    local physicalDamagePercentUnderAttack = attackee:getPhysicalDamagePercentUnderAttack()
    local magicDamagePercentUnderAttack = attackee:getMagicDamagePercentUnderAttack()
    local magicTreatPercentUnderAttack = attackee:getMagicTreatPercentUnderAttack()
    if DEBUG_DAMAGE == true then
        debugString = debugString .. "被攻击方的伤害加成 \n"
        debugString = debugString .. "physicalDamagePercentUnderAttack = " .. tostring(physicalDamagePercentUnderAttack) .. " \n"
        debugString = debugString .. "magicDamagePercentUnderAttack = " .. tostring(magicDamagePercentUnderAttack) .. " \n"
        debugString = debugString .. "magicTreatPercentUnderAttack = " .. tostring(magicTreatPercentUnderAttack) .. " \n"
    end

    -- 攻击方的物理伤害
    physicalDamage = (physicalDamage * (1 + skill_damage_percent) + skill_phsical_damage) * (1 + physicalDamagePercent)
    if DEBUG_DAMAGE == true then
        debugString = debugString .. "攻击方的物理伤害 \n"
        debugString = debugString .. "公式: physicalDamage = (physicalDamage * (1 + skill_damage_percent) + skill_phsical_damage) * (1 + physicalDamagePercent) \n"
        debugString = debugString .. "physicalDamage = " .. tostring(physicalDamage) .. " \n"
    end

    -- 攻击方的法术伤害
    if skill:getAttackType() == QSkill.TREAT then
        -- 攻击转换为治疗效果时 x2，效果更明显
        local coefficient = 1
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.TREAT_DAMAGE_COEFFICIENT ~= nil and globalConfig.TREAT_DAMAGE_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.TREAT_DAMAGE_COEFFICIENT.value 
        end
        magicDamage = (magicDamage * (1 + skill_damage_percent) + skill_magic_damage) * (1 + magicDamagePercent) * coefficient
        if DEBUG_DAMAGE == true then
            debugString = debugString .. "攻击方的治疗伤害 \n"
            debugString = debugString .. "公式: magicDamage = (magicDamage * (1 + skill_damage_percent) + skill_magic_damage) * 2 * (1 + magicDamagePercent) \n"
            debugString = debugString .. "magicDamage = " .. tostring(magicDamage) .. " \n"
        end
    else
        magicDamage = (magicDamage * (1 + skill_damage_percent) + skill_magic_damage) * (1 + magicTreatPercent)
        if DEBUG_DAMAGE == true then
            debugString = debugString .. "攻击方的法术伤害 \n"
            debugString = debugString .. "公式: magicDamage = (magicDamage * (1 + skill_damage_percent) + skill_magic_damage) * (1 + magicTreatPercent) \n"
            debugString = debugString .. "magicDamage = " .. tostring(magicDamage) .. " \n"
        end
    end

    -- 坚持是否有inherit damage覆盖计算，对不起上面辛辛苦苦的代码了
    local inheritDamage = skill:getInHeritedDamage()
    if inheritDamage then
        if skill:getDamageType() == QSkill.PHYSICAL then
            physicalDamage = inheritDamage
        elseif skill:getDamageType() == QSkill.MAGIC then
            magicDamage = inheritDamage
        end
    end

    -- 平分计算
    if split_number and split_number > 0 then
        physicalDamage = physicalDamage / split_number
        magicDamage = magicDamage / split_number
    end

    -- 最终物理伤害
    physicalDamage = physicalDamage * (1 + physicalDamagePercentUnderAttack)
    if DEBUG_DAMAGE == true then
        debugString = debugString .. "最终物理伤害 \n"
        debugString = debugString .. "公式: physicalDamage = physicalDamage * (1 + physicalDamagePercentUnderAttack) \n"
        debugString = debugString .. "physicalDamage = " .. tostring(physicalDamage) .. " \n"
    end

    -- 最终法术伤害
    if skill:getAttackType() == QSkill.TREAT then
        magicDamage = magicDamage * (1 + magicTreatPercentUnderAttack)
        if DEBUG_DAMAGE == true then
            debugString = debugString .. "最终治疗伤害 \n"
            debugString = debugString .. "公式: magicDamage = magicDamage * (1 + magicTreatPercentUnderAttack) \n"
            debugString = debugString .. "magicDamage = " .. tostring(magicDamage) .. " \n"
        end
    else
        magicDamage = magicDamage * (1 + magicDamagePercentUnderAttack)
        if DEBUG_DAMAGE == true then
            debugString = debugString .. "最终法术伤害 \n"
            debugString = debugString .. "公式: magicDamage = magicDamage * (1 + magicDamagePercentUnderAttack) \n"
            debugString = debugString .. "magicDamage = " .. tostring(magicDamage) .. " \n"
        end
    end

    -- 开始计算最终伤害
    local damage = (physicalDamage + magicDamage)

    -- 受到连击点数影响
    if skill:isNeedComboPoints() then
        local combo_points_coefficient = attacker:getComboPointsCoefficient()
        damage = damage * combo_points_coefficient
        if DEBUG_DAMAGE == true then
            debugString = debugString .. "连击点数 \n"
            debugString = debugString .. "公式: damage = damage * comboPointsCoefficient \n"
            debugString = debugString .. "comboPointsCoefficient = " .. tostring(combo_points_coefficient) .. " \n"
            debugString = debugString .. "damage = " .. tostring(damage) .. " \n"
        end
    end

    -- PVP系数影响
    if app.battle:isPVPMode() then
        if app.battle:isInArena() then
            if skill:getAttackType() == QSkill.TREAT then
                damage = damage * QActor.ARENA_TREAT_COEFFICIENT
            else
                damage = damage * QActor.ARENA_FINAL_DAMAGE_COEFFICIENT
            end
        elseif app.battle:isInSunwell() then
            if skill:getAttackType() == QSkill.TREAT then
                damage = damage * QActor.SUNWELL_TREAT_COEFFICIENT
            else
                damage = damage * QActor.SUNWELL_FINAL_DAMAGE_COEFFICIENT
            end
        end
    end

    -- 保存original_damage用于aoe快速计算伤害
    local original_damage = damage

    -- 战场伤害系数
    if skill:getAttackType() == QSkill.ATTACK then
        damage = damage * app.battle:getDamageCoefficient()
    end

    -- 最终伤害 和 伤害浮动
    damage = damage * (0.8 + math.random() * 0.4)
    if DEBUG_DAMAGE == true then
        debugString = debugString .. "最终伤害 和 伤害浮动 \n"
        debugString = debugString .. "公式: damage = (physicalDamage + magicDamage) * (0.8 + math.random() * 0.4) \n"
        debugString = debugString .. "damage = " .. tostring(damage) .. " \n"
    end

    -- 格挡 和 暴击
    local tip = ""
    local critical = false
    if blocked then
        damage = damage * 0.5
        tip = "格挡 "
        if DEBUG_DAMAGE == true then
            debugString = debugString .. "格挡 伤害减半 \n"
            debugString = debugString .. "公式: damage = damage * 0.5 \n"
            debugString = debugString .. "damage = " .. tostring(damage) .. " \n"
        end
    else
        local crit = attacker:getCrit()
        if skill:getHitType() == QSkill.CRITICAL or (p > 0 and p < crit) then
            -- 暴击
            damage = damage * attacker:getCritDamage()
            tip = damage > 0 and "暴击 " or ""
            critical = true
            if DEBUG_DAMAGE == true then
                debugString = debugString .. "暴击 \n"
                debugString = debugString .. "公式: damage = damage * critDamage \n"
                debugString = debugString .. "critDamage = " .. tostring(attacker:getCritDamage()) .. " \n"
                debugString = debugString .. "damage = " .. tostring(damage) .. " \n"
            end
        end
    end

    if skill:getAttackType() == QSkill.TREAT then
        -- 治疗的文字显示: 前面附加一个加号"+"
        tip = tip .. "+"
    end

    damage = math.round(damage)

    if DEBUG_DAMAGE == true then
        debugString = debugString .. "最终伤害: " .. tostring(damage) .. " \n"
        printInfo(debugString)
    end

    return damage, tip, critical, blocked and "block" or "hit", original_damage
end

-- 被击中
function QActor:hit(skill, attackee, split_number, override_damage, original_damage)
    assert(skill, "QActor:hit: skill should not be nil.")
    assert(attackee, "QActor:hit: attackee should not be nil.")
    if skill == nil or attackee == nil then
        return 
    end

    if attackee:isDead() == true or (self:isDead() == true and not self:isDoingDeadSkill()) then 
        return 
    end

    local damage, tip, critical, hit_status
    if override_damage then
        damage, tip, critical, hit_status = override_damage.damage, override_damage.tip, override_damage.critical, override_damage.hit_status
    elseif original_damage then
        damage, tip, critical, hit_status, original_damage = calcDamageWithOriginalDamage(self, skill, attackee, original_damage)
    else
        damage, tip, critical, hit_status, original_damage = calcDamage(self, skill, attackee, split_number)
    end
    local absorb = 0
    local attackType = skill:getAttackType()

    if attackType == QSkill.TREAT then
        if damage > 0 then
            attackee:increaseHp(damage)
            app.battle:addTreatHistory(self:getUDID(), damage, skill:getId())
        end

        if attackee:getMaxHp() == attackee:getHp() then
            -- 治疗任务完成后，英雄需要恢复自动模式
            if skill:getActor():isManualMode() then
                skill:getActor():setManualMode(QActor.AUTO)
            end
        end
    elseif attackType == QSkill.ATTACK then
        attackee._hitlog:addNewHit(skill:getActor(), damage, skill, skill:getActor():getTalentHatred())
        
        if damage > 0 then
            app.battle:addDamageHistory(self:getUDID(), damage, skill:getId())

            if damage > 0 then
                _, damage, absorb = attackee:decreaseHp(damage)
            end
        end

        local index = -1
        while index ~= 0 do
            index = 0
            for i, buff in ipairs(attackee._buffs) do
                if buff.effects.can_be_removed_with_hit == true then
                    index = i
                    break
                end
            end
            if index ~= 0 then
                attackee:removeBuffByIndex(index)
            end
        end

        if not app.battle:isGhost(skill:getActor()) then
            attackee._lastAttacker = skill:getActor()
        end
    end

    -- 附带伤害（毒药之类）不会触发攻击类时间
    local _is_triggered = false
    for _, sb in ipairs(self._sbDirectors) do
        if sb:getSkill() == skill and sb._is_triggered then
            _is_triggered = true
            break
        end
    end
    if _is_triggered == false then
        -- passive skill
        self:triggerPassiveSkill(QSkill.TRIGGER_CONDITION_SKILL, attackee) -- 技能
        if critical then
            self:triggerPassiveSkill(QSkill.TRIGGER_CONDITION_SKILL_CRITICAL, attackee) -- 技能暴击
        end
        if attackType == QSkill.TREAT then
            self:triggerPassiveSkill(QSkill.TRIGGER_CONDITION_SKILL_TREAT, attackee) -- 治疗技能
            if critical then
                self:triggerPassiveSkill(QSkill.TRIGGER_CONDITION_SKILL_TREAT_CRITICAL, attackee) -- 治疗技能暴击
            end
        elseif attackType == QSkill.ATTACK then
            self:triggerPassiveSkill(QSkill.TRIGGER_CONDITION_SKILL_ATTACK, attackee) -- 攻击技能
            if critical then
                self:triggerPassiveSkill(QSkill.TRIGGER_CONDITION_SKILL_ATTACK_CRITICAL, attackee) -- 攻击技能暴击
            end
        end
        if attackee:isDead() == false and hit_status == "hit" and attackType == QSkill.ATTACK then 
            attackee:triggerPassiveSkill(QSkill.TRIGGER_CONDITION_HIT, self) 
        end
        
        -- buff already applied
        -- as attacker for others
        if not app.battle:isGhost(self) then
            local teammates = app.battle:getMyTeammates(self, false)
            local enemies = app.battle:getMyEnemies(self)
            for _, mate in ipairs(teammates) do
                mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL, attackee, QBuff.TRIGGER_TARGET_TEAMMATE, damage)
                if critical then
                    mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_CRITICAL, attackee, QBuff.TRIGGER_TARGET_TEAMMATE, damage) -- 技能暴击
                end
                if attackType == QSkill.TREAT then
                    mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_TREAT, attackee, QBuff.TRIGGER_TARGET_TEAMMATE, damage) -- 治疗技能
                    if critical then
                        mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_TREAT_CRITICAL, attackee, QBuff.TRIGGER_TARGET_TEAMMATE, damage) -- 治疗技能暴击
                    end
                elseif attackType == QSkill.ATTACK then
                    mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_ATTACK, attackee, QBuff.TRIGGER_TARGET_TEAMMATE, damage) -- 攻击技能
                    if critical then
                        mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_ATTACK_CRITICAL, attackee, QBuff.TRIGGER_TARGET_TEAMMATE, damage) -- 攻击技能暴击
                    end
                end
            end
            for _, enemy in ipairs(enemies) do
                enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL, attackee, QBuff.TRIGGER_TARGET_ENEMY, damage)
                if critical then
                    enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_CRITICAL, attackee, QBuff.TRIGGER_TARGET_ENEMY, damage) -- 技能暴击
                end
                if attackType == QSkill.TREAT then
                    enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_TREAT, attackee, QBuff.TRIGGER_TARGET_ENEMY, damage) -- 治疗技能
                    if critical then
                        enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_TREAT_CRITICAL, attackee, QBuff.TRIGGER_TARGET_ENEMY, damage) -- 治疗技能暴击
                    end
                elseif attackType == QSkill.ATTACK then
                    enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_ATTACK, attackee, QBuff.TRIGGER_TARGET_ENEMY, damage) -- 攻击技能
                    if critical then
                        enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_ATTACK_CRITICAL, attackee, QBuff.TRIGGER_TARGET_ENEMY, damage) -- 攻击技能暴击
                    end
                end
            end
        end
        -- as attackee for others
        local teammates = app.battle:getMyTeammates(attackee, false)
        local enemies = app.battle:getMyEnemies(attackee)
        for _, mate in ipairs(teammates) do
            if hit_status == "hit" and attackType == QSkill.ATTACK then
                mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_HIT, self, QBuff.TRIGGER_TARGET_TEAMMATE, damage)
            elseif hit_status == "block" then
                mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_BLOCK, self, QBuff.TRIGGER_TARGET_TEAMMATE, damage)
            elseif hit_status == "dodge" then
                mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_DODGE, self, QBuff.TRIGGER_TARGET_TEAMMATE, damage)
            elseif hit_status == "miss" then
                mate:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_MISS, self, QBuff.TRIGGER_TARGET_TEAMMATE, damage)
            end
        end
        for _, enemy in ipairs(enemies) do
            if hit_status == "hit" and attackType == QSkill.ATTACK then
                enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_HIT, self, QBuff.TRIGGER_TARGET_ENEMY, damage)
            elseif hit_status == "block" then
                enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_BLOCK, self, QBuff.TRIGGER_TARGET_ENEMY, damage)
            elseif hit_status == "dodge" then
                enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_DODGE, self, QBuff.TRIGGER_TARGET_ENEMY, damage)
            elseif hit_status == "miss" then
                enemy:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_MISS, self, QBuff.TRIGGER_TARGET_ENEMY, damage)
            end
        end
        -- attacker and attackee self
        self:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL, attackee, QBuff.TRIGGER_TARGET_SELF, damage)
        if critical then
            self:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_CRITICAL, attackee, QBuff.TRIGGER_TARGET_SELF, damage) -- 技能暴击
        end
        if attackType == QSkill.TREAT then
            self:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_TREAT, attackee, QBuff.TRIGGER_TARGET_SELF, damage) -- 治疗技能
            if critical then
                self:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_TREAT_CRITICAL, attackee, QBuff.TRIGGER_TARGET_SELF, damage) -- 治疗技能暴击
            end
        elseif attackType == QSkill.ATTACK then
            self:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_ATTACK, attackee, QBuff.TRIGGER_TARGET_SELF, damage) -- 攻击技能
            if critical then
                self:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_SKILL_ATTACK_CRITICAL, attackee, QBuff.TRIGGER_TARGET_SELF, damage) -- 攻击技能暴击
            end
        end
        if not attackee:isDead() then
            if hit_status == "hit" and attackType == QSkill.ATTACK then
                attackee:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_HIT, self, QBuff.TRIGGER_TARGET_SELF, damage)
            elseif hit_status == "block" then
                attackee:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_BLOCK, self, QBuff.TRIGGER_TARGET_SELF, damage)
            elseif hit_status == "dodge" then
                attackee:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_DODGE, self, QBuff.TRIGGER_TARGET_SELF, damage)
            elseif hit_status == "miss" then
                attackee:triggerAlreadyAppliedBuff(QBuff.TRIGGER_CONDITION_MISS, self, QBuff.TRIGGER_TARGET_SELF, damage)
            end
        end
    end

    -- trigger apply buff
    self:triggerBuff(skill, attackee)

    -- 注意，这里先applyBuff，再dispatch UNDER_ATTACK_EVENT。因为在UNDER_ATTACK_EVENT的响应中
    -- 会启动Tint颜色， 这个action会使用当前的displayColor，从而将Buff设置的displayColor覆盖掉。
    -- 最终的现象是Buff的颜色看起来没有生效。
    if absorb > 0 then
        local absorb_tip = "吸收 "
        attackee:dispatchEvent({name = QActor.UNDER_ATTACK_EVENT, isTreat = false, tip = absorb_tip .. tostring(absorb)})    
    end

    if damage > 0 or string.len(tip) > 0 then
        if damage > 0 then
            tip = tip .. tostring(damage)
        end
        attackee:dispatchEvent({name = QActor.UNDER_ATTACK_EVENT, isTreat = (skill:getAttackType() == QSkill.TREAT), isCritical = critical, tip = tip})
    end

    return original_damage
end

function QActor:getCurrentSkill()
    return self._currentSkill
end

function QActor:cancelTalentSkill()
    if self._currentSkill and (self.currentSkill == self:getTalentSkill() or self.currentSkill == self:getTalentSkill2()) then
        self:_cancelCurrentSkill()
    end
end

function QActor:getExecutingSkills()
    local skills = {}
    for _, sbDirector in ipairs(self._sbDirectors) do
        table.insert(skills, sbDirector:getSkill())
    end

    return skills
end

function QActor:getCurrentSkillTarget()
    if self._currentSBDirector == nil then
        return nil
    else 
        return self._currentSBDirector:getTarget()
    end
end

function QActor:getSkillId(config, skillIds)
    if config == nil or skillIds == nil then
        return
    end
    if config.OPTIONS ~= nil and config.OPTIONS.skill_id ~= nil then
        table.insert(skillIds, config.OPTIONS.skill_id)
    end

    if config.ARGS ~= nil then
        for _, conf in pairs(config.ARGS) do
            self:getSkillId(conf, skillIds)
        end
    end
end

function QActor:getSkillIdWithAiType(aiType)
    local skillIds = {}
    if aiType ~= nil then
        local config = QFileCache.sharedFileCache():getAIConfigByName(aiType)
        if config ~= nil then
            self:getSkillId(config, skillIds)
        end
    end
    return skillIds
end

-- 对拖拽的处理，如果触发了冲锋等技能，则返回true，否则返回false
-- 
function QActor:_onDrag(position, action)
    -- if self:isForceAuto() then
    --     return
    -- end

    self:triggerPassiveSkill(action, self)

    local activeSkill = nil
    for _, skill in pairs(self._activeSkills) do
        local condition_met = false
        if skill:getTriggerCondition() == QSkill.TRIGGER_CONDITION_DRAG_OR_DRAG_ATTACK then
            condition_met = action == QSkill.TRIGGER_CONDITION_DRAG or action == QSkill.TRIGGER_CONDITION_DRAG_ATTACK
        else
            condition_met = action == skill:getTriggerCondition()
        end
        if condition_met and skill:isReady() == true then
            if skill:isInSkillRange(self:getPosition(), position, false) == true then
                local probability = skill:getTriggerProbability()
                if probability >= math.random(1, 100) then
                    activeSkill = skill
                    break
                end
            end
        end
    end

    if activeSkill ~= nil and self:canAttack(activeSkill) then
        self._dragPosition = position
        self._targetPosition = position
        self:attack(activeSkill)
        return true
    end

    return false
end

function QActor:onDragAttack(target)
    -- if self:isForceAuto() then
    --     return
    -- end

    self:setTarget(target)
    self:setManualMode(QActor.ATTACK)
    self:_onDrag(target:getPosition(), QSkill.TRIGGER_CONDITION_DRAG_ATTACK)
end

function QActor:onDragMove(position)
    -- if self:isForceAuto() then
    --     return
    -- end

    if self.fsm__:getState() == "victorious" or app.battle:isBattleEnded() then
        return
    end

    if self:_onDrag(position, QSkill.TRIGGER_CONDITION_DRAG) == false then
        -- 没有触发技能，移动到目标地点
        app.grid:moveActorTo(self, position)
    end
    
    self:setManualMode(QActor.STAY)
end

function QActor:onVictory()
    self.fsm__:doEvent("victory")
    self.fsm__:doEvent("ready", global.victory_animation_duration)
end

function QActor:getHitLog()
    return self._hitlog
end

-- state callbacks
function QActor:_onChangeState(event)
    -- printf("QActor %s:%s state change from %s to %s", self:getId(), self:getDisplayName(), event.from, event.to)

    -- clear delayed "ready" event
    if self._delayedReadyHandler ~= nil then
        -- printf("QActor ========= delayed ======== ready cancelled")

        scheduler.unscheduleGlobal(self._delayedReadyHandler)
        self._delayedReadyHandler = nil
    end

    self:dispatchEvent({name = QActor.CHANGE_STATE_EVENT, from = event.from, to = event.to, args = event.args})
end

-- 启动状态机时，设定角色默认 Hp
function QActor:_onStart(event)
    -- printf("QActor %s:%s start", self:getId(), self:getDisplayName())
    self:setFullHp()
    self:dispatchEvent({name = QActor.START_EVENT})
end

function QActor:_onReady(event)
    -- printf("QActor %s:%s ready", self:getId(), self:getDisplayName())
    self:dispatchEvent({name = QActor.READY_EVENT})
end

function QActor:_onAttack(event)
    -- printf("QActor %s:%s attack", self:getId(), self:getDisplayName())
    self:dispatchEvent({name = QActor.ATTACK_EVENT, skill = event.args[1].skill, options = event.options})
end

function QActor:_onSkill(event)
    -- printf("QActor %s:%s attack", self:getId(), self:getDisplayName())
    self:dispatchEvent({name = QActor.ATTACK_EVENT, skill = event.args[1].skill, options = event.options})
end

function QActor:_onMove(event)
    -- printf("QActor %s:%s move", self:getId(), self:getDisplayName())
    self:dispatchEvent({name = QActor.MOVE_EVENT, from = self._position, to = self._targetPosition})
end

function QActor:_onFreeze(event)
    printf("QActor %s:%s frozen", self:getId(), self:getDisplayName())
    self:dispatchEvent({name = QActor.FREEZE_EVENT})
end

function QActor:_onThaw(event)
    printf("QActor %s:%s thawing", self:getId(), self:getDisplayName())
    self:dispatchEvent({name = QActor.THAW_EVENT})
end

function QActor:_onKill(event)
    printf("QActor %s:%s dead", self:getId(), self:getDisplayName())
    self._hp = 0
    self:dispatchEvent({name = QActor.KILL_EVENT})

    local death_sound = QStaticDatabase:sharedDatabase():getCharacterDisplayByID(self:getDisplayID()).death
    if death_sound then
        audio.playSound(death_sound, false)
    end

    if self._deadSkill then
        self:attack(self:getSkillWithId(self._deadSkill))
        self._isDoingDeadSkill = true
    end
end

function QActor:_onRelive(event)
    printf("QActor %s:%s relive", self:getId(), self:getDisplayName())
    self:setFullHp()
    self:dispatchEvent({name = QActor.RELIVE_EVENT})
end

function QActor:_onVictory(event)
    self:dispatchEvent({name = QActor.VICTORY_EVENT})
end

function QActor:_onBeforeReady(event)
    local cooldown = checknumber(event.args[1])
    -- printf("QActor %s:%s _onBeforeReady, %f", self:getId(), self:getDisplayName(), cooldown)
    if cooldown > 0 then
        -- 如果开火后的冷却时间大于 0，则需要等待

        if self._delayedReadyHandler ~= nil then
            -- cancel previous delayed ready and create a new one
            scheduler.unscheduleGlobal(self._delayedReadyHandler)
        end

        self._delayedReadyHandler = app.battle:performWithDelay(function()
            -- printf("QActor ========= delayed ======== ready triggered")
            self._delayedReadyHandler = nil
            self.fsm__:doEvent("ready")
        end, cooldown)
        return false
    end

    return true
end

function QActor:_onTargetKill(event)
    printInfo(self:getId() .. " target killed")
    -- 攻击敌人任务完成后，英雄需要恢复自动模式
    if self:getManualMode() == QActor.ATTACK then
        self:setManualMode(QActor.AUTO)
    end

    self:setTarget(nil)

    if self:isWalking() then
        self:stopMoving()
    end
end

function QActor:isImmuneStatus(status)
    local statusImmuned = false
    for i, buff in ipairs(self._buffs) do
        if buff:isImmuneStatus(status) then
            statusImmuned = true
            break
        end
    end
    return statusImmuned
end

function QActor:isImmuneBuff(newBuff)
    local newBuffImmuned = false
    for i, buff in ipairs(self._buffs) do
        if buff:isImmuneBuff(newBuff) then
            newBuffImmuned = true
            break
        end
    end
    return newBuffImmuned
end

function QActor:isImmuneSkill(skill)
    local skillImmuned = false
    for i, buff in ipairs(self._buffs) do
        if buff:isImmuneSkill(skill) then
            skillImmuned = true
            break
        end
    end
    return skillImmuned
end

function QActor:isImmuneTrap(trap)
    local immuned = false
    for _, buff in ipairs(self._buffs) do
        if buff:isImmuneTrap(trap) then
            immuned = true
            break
        end
    end
    return immuned
end

function QActor:isUnderStatus(status)
    assert(status ~= nil and status ~= "", "")

    local actors = {}
    if app.battle then
        table.insertto(actors, app.battle:getMyTeammates(self, true))
        table.insertto(actors, app.battle:getMyEnemies(self))
    end

    -- buffs
    for _, buff in ipairs(self._buffs) do
        if not buff:isImmuned() and not buff:isAura() then
            if buff:getStatus() == status then
                return true
            end
        end
    end
    -- traps
    if app.battle ~= nil then
        for _, trapDirector in ipairs(app.battle:getTrapDirectors()) do
            if trapDirector:isExecute() == true and trapDirector:isTragInfluenceActor(self) then
                if trapDirector:getTrap():getStatus() == status then
                    return true
                end
            end
        end
    end
    -- auras
    for _, actor in ipairs(actors) do
        for _, buff in ipairs(actor._buffs) do
            if buff:isImmuned() and buff:isAura() and buff:isAuraAffectActor(self) then
                if buff:getStatus() == status then
                    return true
                end
            end
        end
    end

    return false
end

function QActor:applyBuff(id, attacker)
    if id == nil then
        return
    end

    if self:isDead() == true then
        return
    end

    local newBuff = QBuff.new(id, self, attacker)

    -- check if any existing buff immune the status new buff brings?
    local newBuffImmuned = false
    for i, buff in ipairs(self._buffs) do
        if buff:isImmuneBuff(newBuff) then
            newBuffImmuned = true
            break
        end
    end
    if newBuffImmuned then
        newBuff:setImmuned(true)
        if self._lastImmunedTime == nil or app.battle:getTime() - self._lastImmunedTime > 0.5 then
            self._lastImmunedTime = app.battle:getTime()
            self:dispatchEvent({name = QActor.UNDER_ATTACK_EVENT, isTreat = false, tip = "免疫"})
        end
    end

    -- check if have same exclusive group buff
    -- re-caculate damage if it is a 
    if not newBuff:isImmuned() and newBuff:hasOverrideGroup() then
        for i, buff in ipairs(self._buffs) do
            local override, replace = newBuff:canOverride(buff)
            if override then
                if replace then
                    if newBuff.effects.interval_time > 0.0 then
                        local leftPrecent = 1.0 - buff:getCurrentExecuteCount() / buff:getExecuteCount()
                        newBuff:setPhysicalDamageValue(newBuff:getPhysicalDamageValue() + buff:getPhysicalDamageValue() * leftPrecent)
                        newBuff:setPhysicalDamageValue(newBuff:getMagicDamageValue() + buff:getMagicDamageValue() * leftPrecent)
                        newBuff:setPhysicalDamageValue(newBuff:getMagicTreatValue() + buff:getMagicTreatValue() * leftPrecent)
                        newBuff:setAbsorbDamageValue(newBuff:getAbsorbDamageValue() + buff:getAbsorbDamageValue())
                    end
                    self:removeBuffByIndex(i)
                else
                    if newBuff.effects.interval_time > 0.0 then
                        buff:setPhysicalDamageValue(newBuff:getPhysicalDamageValue() + buff:getPhysicalDamageValue() * leftPrecent)
                        buff:setPhysicalDamageValue(newBuff:getMagicDamageValue() + buff:getMagicDamageValue() * leftPrecent)
                        buff:setPhysicalDamageValue(newBuff:getMagicTreatValue() + buff:getMagicTreatValue() * leftPrecent)
                        buff:setAbsorbDamageValue(newBuff:getAbsorbDamageValue() + buff:getAbsorbDamageValue())
                        buff:restart()
                    end
                    return
                end
                break
            end
        end
    end

    -- check if have same buff id
    if not newBuff:isImmuned() then
        for i, buff in ipairs(self._buffs) do
            if newBuff:getId() == buff:getId() then
                self:removeBuffByIndex(i)
                break
            end
        end
    end

    -- check if replace actor view
    if not newBuff:isImmuned() then
        if newBuff.effects.replace_character ~= -1 then
            self._target_before_replace_ai = self:getTarget()
            
            app.scene:replaceActorViewWithCharacterId(self, newBuff.effects.replace_character)
            if self:getType() == ACTOR_TYPES.NPC then
                local dataBase = QStaticDatabase.sharedDatabase()
                local characterId = newBuff.effects.replace_character
                local properties = dataBase:getCharacterByID(characterId)
                if dataBase:getSkillByID(properties.npc_skill) ~= nil then 
                    if self._skills[properties.npc_skill] == nil then
                        self._skills[properties.npc_skill] = QSkill.new(properties.npc_skill, dataBase:getSkillByID(properties.npc_skill), self)
                    end
                end
                if dataBase:getSkillByID(properties.npc_skill_2) ~= nil then 
                    if self._skills[properties.npc_skill_2] == nil then
                        self._skills[properties.npc_skill_2] = QSkill.new(properties.npc_skill_2, dataBase:getSkillByID(properties.npc_skill_2), self) 
                    end
                end
                local skillIdsForAi = self:getSkillIdWithAiType(properties.npc_ai)
                for _, skillId in ipairs(skillIdsForAi) do
                    if self._skills[skillId] == nil then
                        self._skills[skillId] = QSkill.new(skillId, dataBase:getSkillByID(skillId), self)
                    end
                end
                self._manualSkills = {}
                self._activeSkills = {}
                self._passiveSkills = {}
                self:_classifySkillByType()
            end
        elseif string.len(newBuff.effects.replace_ai) > 0 then
            self._target_before_replace_ai = self:getTarget()

            app.scene:replaceActorAI(self, newBuff.effects.replace_ai)
        end
    end

    -- check if can move
    if not newBuff:isImmuned() then
        if newBuff.effects.can_control_move == false then
            self:stopMoving()
        end
    end

    -- check if is using skill
    if not newBuff:isImmuned() then
        if newBuff.effects.can_use_skill == false then
            self:_cancelCurrentSkill()
        end
    end

    -- check if all pause
    if not newBuff:isImmuned() then
        if newBuff.effects.time_stop == true then
            self:inTimeStop(true)
        end
    end

    table.insert(self._buffs, newBuff)

    local bufferEventListener = cc.EventProxy.new(newBuff)
    bufferEventListener:addEventListener(newBuff.TRIGGER, handler(self, self._onBuffTrigger))
    table.insert(self._buffEventListeners, bufferEventListener)

    if attacker ~= nil then
        table.insert(self._buffAttacker, {buffId = id, attackerUDID = attacker:getUDID()})
    end

    self:dispatchEvent({name = QActor.BUFF_STARTED, buff = newBuff})
end

function QActor:removeBuffByIndex(index)
    if index == nil then
        return
    end

    if table.nums(self._buffs) < index then
        return
    end

    local buff = self._buffs[index]
    if buff == nil then
        return
    end

    -- check if replace actor view
    if not buff:isImmuned() then
        if buff.effects.replace_character ~= -1 then
            app.scene:replaceActorViewWithCharacterId(self, nil)

            -- 张南:太阳井要求英雄在被恐惧之后还能够攻击原来的目标，所以这里是一个hack
            if app.battle:isPVPMode() and app.battle:isInSunwell() then
                if self._target_before_replace_ai and not self._target_before_replace_ai:isDead() then
                    self:setTarget(self._target_before_replace_ai)
                    self._target_before_replace_ai = nil
                end
            end
        end
        if string.len(buff.effects.replace_ai) > 0 then
            app.scene:replaceActorAI(self, nil)

            -- 张南:太阳井要求英雄在被恐惧之后还能够攻击原来的目标，所以这里是一个hack
            if app.battle:isPVPMode() and app.battle:isInSunwell() then
                if self._target_before_replace_ai and not self._target_before_replace_ai:isDead() then
                    self:setTarget(self._target_before_replace_ai)
                    self._target_before_replace_ai = nil
                end
            end
        end
    end

    -- check if all pause
    if not buff:isImmuned() then
        if buff.effects.time_stop == true then
            self:inTimeStop(false)
        end
    end

    if not buff:isImmuned() then
        buff:onRemove()
    end

    local bufferEventListener = self._buffEventListeners[index]
    self:dispatchEvent({name = QActor.BUFF_ENDED, buff = buff})
    if bufferEventListener then
        bufferEventListener:removeAllEventListeners()
        table.remove(self._buffEventListeners, index)
    end
    table.remove(self._buffs, index)
    table.remove(self._buffAttacker, index)

    if buff:getId() == global.attack_mark_effect then
        self._isMarked = false
    end
end

function QActor:removeBuffByID(id)
    if id == nil then
        return
    end

    for i, buff in ipairs(self._buffs) do
        if buff:getId() == id then
            self:removeBuffByIndex(i)
            return
        end
    end
end

function QActor:removeAllBuff()
    while table.nums(self._buffs) > 0 do
        self:removeBuffByIndex(1)
    end
end

function QActor:_runBuff(dt)
    for i, buff in ipairs(self._buffs) do
        if not buff:isImmuned() then
            buff:visit(dt)
        end
    end

    local endedBuffIndex = 1
    while endedBuffIndex > 0 do
        endedBuffIndex = 0
        for i, buff in ipairs(self._buffs) do
            if buff:isEnded() then
                endedBuffIndex = i
                break
            end
        end
        if endedBuffIndex > 0 then
            self:removeBuffByIndex(endedBuffIndex)
        end
    end
end

function QActor:_getAttackerUDIDWithBuffId(buffId)
    if buffId == nil then
        return nil
    end
    for _, item in ipairs(self._buffAttacker) do
        if item.buffId == buffId then
            return item.attackerUDID
        end
    end
    return nil
end

function QActor:_onBuffTrigger(event)
    if app.battle:isPausedBetweenWave() == true then
        return
    end
    
    local buff = event.buff
    if buff == nil then
        return
    end

    if buff:isImmuned() then
        return
    end

    local value = 0
    local absorb = 0
    if self:isDead() == false and buff:getPhysicalDamageValue() ~= 0 then
        value = buff:getPhysicalDamageValue() / buff:getExecuteCount()
        local critical = false
        if math.random(1, 100) < buff:getCrit() then
            value = value * buff:getCritDamage()
            critical = true
        end
        -- 战场伤害系数
        value = value * app.battle:getDamageCoefficient()
        value = math.floor(value)
        -- printInfo("buff PhysicalDamageValue " .. tostring(value))
        _, value, absorb = self:decreaseHp(value)
        if absorb > 0 then
            local absorb_tip = "吸收 "
            self:dispatchEvent({name = QActor.UNDER_ATTACK_EVENT, isTreat = false, isCritical = false, tip = absorb_tip .. tostring(absorb)})
        end
        if value > 0 then
            local tip = critical and "暴击 " or ""
            self:dispatchEvent({name = QActor.UNDER_ATTACK_EVENT, isTreat = false, isCritical = critical, tip = tip .. tostring(value)})
        end
        app.battle:addDamageHistory(self:_getAttackerUDIDWithBuffId(buff:getId()), value, buff:getId())
    end

    if self:isDead() == false and buff:getMagicDamageValue() ~= 0 then
        value = buff:getMagicDamageValue() / buff:getExecuteCount()
        local critical = false
        if math.random(1, 100) < buff:getCrit() then
            value = value * buff:getCritDamage()
            critical = true
        end
        -- 战场伤害系数
        value = value * app.battle:getDamageCoefficient()
        value = math.floor(value)
        -- printInfo("buff MagicDamageValue " .. tostring(value))
        _, value, absorb = self:decreaseHp(value)
        if absorb > 0 then
            local absorb_tip = "吸收 "
            self:dispatchEvent({name = QActor.UNDER_ATTACK_EVENT, isTreat = false, isCritical = false, tip = absorb_tip .. tostring(absorb)})
        end
        if value > 0 then
            local tip = critical and "暴击 " or ""
            self:dispatchEvent({name = QActor.UNDER_ATTACK_EVENT, isTreat = false, isCritical = critical, tip = tip .. tostring(value)})
        end
        app.battle:addDamageHistory(self:_getAttackerUDIDWithBuffId(buff:getId()), value, buff:getId())
    end

    if self:isDead() == false and buff:getMagicTreatValue() ~= 0 then
        value = buff:getMagicTreatValue() / buff:getExecuteCount()
        local critical = false
        if math.random(1, 100) < buff:getCrit() then
            value = value * buff:getCritDamage()
            critical = true
        end
        value = math.floor(value)
        -- printInfo("buff MagicTreatValue " .. tostring(value))
        self:increaseHp(value)
        if value > 0 then
            local tip = critical and "暴击 " or ""
            self:dispatchEvent({name = QActor.UNDER_ATTACK_EVENT, isTreat = true, isCritical = critical, tip = tip .. "+" .. tostring(value)})
        end
        app.battle:addTreatHistory(self:_getAttackerUDIDWithBuffId(buff:getId()), value, buff:getId())
    end

    if self:isDead() == false then
        local actorView = app.scene:getActorViewFromModel(self)
        actorView:_onBuffTrigger(event)
    end
end

function QActor:playSkillAnimation(animations, loop)
    if animations == nil then
        return
    end
    self:dispatchEvent({name = QActor.PLAY_SKILL_ANIMATION, animations = animations, isLoop = loop})
end

function QActor:onAnimationEnded(eventType, trackIndex, animationName, loopCount)
    self:dispatchEvent({name = QActor.ANIMATION_ENDED, eventType = eventType, trackIndex = trackIndex, animationName = animationName, loopCount = loopCount})
end

--[[ 
    func is invoke after effect animation complete if it is not a nil value
    options: 
        isFlipX
        isLoop
        isRandomPosition
        targetPosition
        isAttackEffect
        skillId
        rotateToPosition
--]]
function QActor:playSkillEffect(effectID, func, options)
    if effectID == nil then
        return
    end
    self:dispatchEvent({name = QActor.PLAY_SKILL_EFFECT, effectID = effectID, callFunc = func, options = options})
end

function QActor:stopSkillEffect(effectID)
    if effectID == nil then
        return
    end
    self:dispatchEvent({name = QActor.STOP_SKILL_EFFECT, effectID = effectID})
end

function QActor:onAttackFinished(isCanceled)
    if self:getTarget() then
        -- 将攻击方也放入hitlog，用于保持战斗的持续性。
        self._hitlog:addNewHit(self:getTarget(), QHitLog.NO_DAMAGE, self._currentSkill, self:getTarget():getTalentHatred())
    end

    if self._currentSkill ~= nil and self._currentSkill:isNeedATarget() == true then
        self._lastAttackee = self._target
    end

    if isCanceled ~= true then
        self._currentSkill = nil
        self._currentSBDirector = nil
    end

    if self:isForceAuto() and self:getManualMode() ~= QActor.AUTO and not isCanceled then
        self:setManualMode(QActor.AUTO)
    end

    if self:isDead() == false then
        self.fsm__:doEvent("ready")
    end

    self:dispatchEvent({name = QActor.SKILL_END})
end

function QActor:_runSkill(deltaTime)    
    for i, sbDirector in ipairs(self._sbDirectors) do
        sbDirector:visit(deltaTime)
    end

    -- local size = table.nums(self._sbDirectors)
    -- if size > 0 then
    --     printInfo("self._sbDirectors size is %d, actor id: %s", size, self:getId())
    -- end
    
    local index = 1
    while index <= table.nums(self._sbDirectors) do
        local sbDirector = self._sbDirectors[index]
        if sbDirector:isSkillFinished() == true then
            table.remove(self._sbDirectors, index)
            index = index - 1
        end
        index = index + 1
    end

    if #self._sbDirectors == 0 and self._isDoingDeadSkill then
        self._isDoingDeadSkill = false
    end
end

function QActor:_cancelCurrentSkill()
    if self._currentSBDirector ~= nil then
        if self._currentSkill == self:getTalentSkill() or self._currentSkill == self:getTalentSkill2() then
            self._currentSkill:_stopCd()
        end

        self:dispatchEvent({name = QActor.CANCEL_SKILL, skillId = self._currentSkill:getId()})
        self._currentSBDirector:cancel()
        table.removebyvalue(self._sbDirectors, self._currentSBDirector)
        self._currentSBDirector = nil
        self._currentSkill = nil

        self._isDoingDeadSkill = false
    end
end

function QActor:_onBattleFrame(event)
    if self._isInBulletTime == true then
        return
    end

    if self._passiveBuffApplied == false then
        self:_applyPassiveSkillBuffs()
        self._passiveBuffApplied = true
    end

    self:_runBuff(event.deltaTime)
    
    -- 在黑屏期间，时间静止不起效
    local view = app.scene:getActorViewFromModel(self)
    if self._isInTimeStop == 0 or app.battle:isInBulletTime() or app.scene:isInBlackLayer() then
        self:_runSkill(event.deltaTime)

        if self._isInTimeStop > 0 then
            view:setAnimationScale(1, "time_stop")
        end
    else
        if self._isInTimeStop > 0 then
            view:setAnimationScale(0, "time_stop")
        end
    end
end

function QActor:_onBattleEnded(event)
    -- skill
    self:_cancelCurrentSkill()
    for _, sbDirector in ipairs(self._sbDirectors) do
        sbDirector:cancel()
    end
    self._sbDirectors = {}

    -- buff
    self:removeAllBuff()
    self._buffs = {}
    self._buffEventListeners = {}
    self._buffAttacker = {}
    self._passiveBuffApplied = false

    self._isInBulletTime = false
    self._grid_walking_attack_count = 0
    self._waveended = false
    self._battlepause = false
    self._isInTimeStop = 0

    for _, skill in pairs(self._skills) do
        skill:pauseCoolDown()
    end

    -- reset property stack
    self:_clearActorNumberPropertyValue()
end 

function QActor:_onBattleStop(event)

    if  self._battleEventListener ~= nil then
        self._battleEventListener:removeAllEventListeners()
        self._battleEventListener = nil
    end

    self._hitlog:clearAll()
    self:setTarget(nil)
    self._isMarked = false
end

function QActor:_onBattlePause(event)
    self._battlepause = true

    for _, skill in pairs(self._skills) do
        skill:pauseCoolDown()
    end
end

function QActor:_onBattleResume(event)
    self._battlepause = false

    if not self._battlepause and not self._waveended then
        for _, skill in pairs(self._skills) do
            skill:resumeCoolDown()
        end
    end
end

function QActor:_onWaveEnded(event)
    self._waveended = true

    self:_cancelCurrentSkill()

    for _, skill in pairs(self._skills) do
        skill:pauseCoolDown()
    end
end

function QActor:_onWaveConfirmed(event)
    self._waveended = false

    -- nzhang: to fix bladestorm
    self:_cancelCurrentSkill()

    if not self._battlepause and not self._waveended then
        for _, skill in pairs(self._skills) do
            skill:resumeCoolDown()
        end
    end

    -- reduce manual skill cool down time
    local manualSkills = self:getManualSkills()
    for _, skill in pairs(manualSkills) do
        skill:reduceCoolDownTime(6.0)
    end
end

function QActor:onMarked()
    if self._isMarked == true then
        return false
    end

    self:applyBuff(global.attack_mark_effect)

    self._isMarked = true
end

function QActor:onUnMarked()
    if not self._isMarked then
        return false
    end

    self:removeBuffByID(global.attack_mark_effect)

    self._isMarked = false
end

function QActor:isReverseWalk()
    if self:isWalking() ~= true then return false end

    if self.gridMidPos == nil and self.gridPos == nil then
        return false
    end

    local targetPos
    if self.gridMidPos ~= nil then
        targetPos = app.grid:_toScreenPos(self.gridMidPos)
    else
        targetPos = app.grid:_toScreenPos(self.gridPos)
    end
    local selfPos = self:getPosition()
    local directionRight = targetPos.x - selfPos.x > 0

    local actorView = app.scene:getActorViewFromModel(self)
    local facingRight = actorView:getDirection() == actorView.DIRECTION_RIGHT

    return directionRight == not facingRight
end

function QActor:isInBulletTime()
    return self._isInBulletTime
end

function QActor:inBulletTime(isIn)
    self._isInBulletTime = isIn or false
    if self._isInBulletTime == true then
        for _, skill in pairs(self._skills) do
            skill:pauseCoolDown()
        end
    else
        for _, skill in pairs(self._skills) do
            skill:resumeCoolDown()
        end
    end
end

function QActor:isInTimeStop()
    return self._isInTimeStop > 0
end

function QActor:inTimeStop(isIn)
    self._isInTimeStop = self._isInTimeStop + (isIn and 1 or -1)
    if self._isInTimeStop < 0 then self._isInTimeStop = 0 end
    local view = app.scene:getActorViewFromModel(self)
    if self._isInTimeStop > 0 then
        view:setAnimationScale(0, "time_stop")
        for _, skill in pairs(self._skills) do
            skill:pauseCoolDown()
        end
    else
        view:setAnimationScale(1, "time_stop")
        for _, skill in pairs(self._skills) do
            skill:resumeCoolDown()
        end
    end
end   

function QActor:setReplaceCharacterId(id)
    self._replaceCharacterId = id
    if self._replaceCharacterId ~= nil then
        self._replaceCharacterDisplayId = QStaticDatabase.sharedDatabase():getCharacterByID(self._replaceCharacterId).display_id
    else
        self._replaceCharacterDisplayId = nil
    end
end

function QActor:willReplaceActorView()
    self:_cancelCurrentSkill()

    for _, buff in ipairs(self._buffs) do
        self:dispatchEvent({name = QActor.BUFF_ENDED, buff = buff})
    end
end

function QActor:didReplaceActorView()
    for _, buff in ipairs(self._buffs) do
        self:dispatchEvent({name = QActor.BUFF_STARTED, buff = buff, replace = true})
    end
end

function QActor:CanControlMove()
    for _, buff in ipairs(self._buffs) do
        if not buff:isImmuned() and buff.effects.can_control_move == false then
            return false
        end
    end
    return true
end

function QActor:StartOneTrack(target, interval)
    self:dispatchEvent({name = QActor.ONE_TRACK_START_EVENT, track_target = target, interval = interval})
end

function QActor:EndOneTrack()
    self:dispatchEvent({name = QActor.ONE_TRACK_END_EVENT,})
end

function QActor:setForceAuto(force)
    self._forceAuto = force

    if force and self:getManualMode() ~= QActor.AUTO then
        if not self:isAttacking() then
            self:setManualMode(QActor.AUTO)
        end
    end

    self:dispatchEvent({name = QActor.FORCE_AUTO_CHANGED_EVENT, forceAuto = force})
end

function QActor:isForceAuto()
    return self._forceAuto
end

function QActor:getComboPoints()
    return self._combo_points
end

function QActor:getComboPointsMax()
    return self._combo_points_max
end

function QActor:getComboPointsTotal()
    return self._combo_points_total
end

function QActor:getConsumableComboPoints()
    return self._combo_points <= self._combo_points_max and self._combo_points or self._combo_points_max
end

function QActor:getComboPointsCoefficient()
    if self._coefficient_table == nil then
        local config = QStaticDatabase:sharedDatabase():getConfiguration()
        self._coefficient_table = {}
        self._coefficient_table[1] = config.ONE_COMBO_POINTS.value
        self._coefficient_table[2] = config.TWO_COMBO_POINTS.value
        self._coefficient_table[3] = config.THREE_COMBO_POINTS.value
        self._coefficient_table[4] = config.FOUR_COMBO_POINTS.value
        self._coefficient_table[5] = config.FIVE_COMBO_POINTS.value
    end
    return self._coefficient_table[self._combo_points_consumed]

    -- return self._combo_points_consumed / self._combo_points_max
end

function QActor:consumeComboPoints()
    self._combo_points_consumed = (self._combo_points > self._combo_points_max) and self._combo_points_max or self._combo_points

    self._combo_points = self._combo_points - self._combo_points_max
    if self._combo_points < 0 then
        self._combo_points = 0
    end

    self:dispatchEvent({name = QActor.CP_CHANGED_EVENT})

    local coefficient = self:getComboPointsCoefficient()
    return coefficient
end

function QActor:getComboPointsConsumed()
    return self._combo_points_consumed
end

function QActor:gainComboPoints(combo_points)
    local max = math.ceil(combo_points)
    local min = math.floor(combo_points)
    combo_points = combo_points > (math.random(min * 10000, max * 10000) / 10000) and max or min

    if combo_points == 0 then
        return
    end

    local combo_points = combo_points + self._combo_points
    if combo_points > self._combo_points_total then
        combo_points = self._combo_points_total
    end
    self._combo_points = combo_points

    self:dispatchEvent({name = QActor.CP_CHANGED_EVENT})
end

function QActor:isNeedComboPoints()
    -- do return true end

    return self._is_need_combo
end

function QActor:getComboPointsAuto()
    return self:get("combo_points_auto")
end

function QActor:isDoingDeadSkill()
    return self._isDoingDeadSkill
end

function QActor:forbidNormalAttack()
    self._forbidNormalAttack = true
end

function QActor:allowNormalAttack()
    self._forbidNormalAttack = nil
end

function QActor:isForbidNormalAttack()
    return self._forbidNormalAttack
end

return QActor
