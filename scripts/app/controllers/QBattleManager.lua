
local QModelBase = import("..models.QModelBase")
local QBattleManager = class("QBattleManager", QModelBase)

local QActor = import("..models.QActor")
local QSkill = import("..models.QSkill")
local QTeam = import("..utils.QTeam")
local QAIDirector = import("..ai.QAIDirector")
local QStaticDatabase = import(".QStaticDatabase")
local QFileCache = import("..utils.QFileCache")
local QNotificationCenter = import(".QNotificationCenter")
local QSkeletonViewController = import(".QSkeletonViewController")
local QTutorialStageEnrolling = import("..tutorial.enrolling.QTutorialStageEnrolling")
local QBattleLog = import(".QBattleLog")

QBattleManager.NPC_CREATED = "NPC_CREATED"
QBattleManager.NPC_CLEANUP = "NPC_CLEANUP"
QBattleManager.NPC_DEATH_LOGGED = "NPC_DEATH_LOGGED"
QBattleManager.HERO_CLEANUP = "HERO_CLEANUP"
QBattleManager.START = "BATTLE_START"
QBattleManager.PAUSE = "BATTLE_PAUSE"
QBattleManager.RESUME = "BATTLE_RESUME"
QBattleManager.END = "BATTLE_END"
QBattleManager.STOP = "BATTLE_STOP"
QBattleManager.WAVE_CONFIRMED = "WAVE_CONFIRMED"
QBattleManager.WAVE_STARTED = "WAVE_STARTED"
QBattleManager.WAVE_ENDED = "WAVE_ENDED"
QBattleManager.WIN = "BATTLE_WIN"
QBattleManager.LOSE = "BATTLE_LOSE"
QBattleManager.ONTIMER = "BATTLE_ONTIMER"
QBattleManager.BATTLE_TIMER_INTERVAL = 0.1 -- seconds
QBattleManager.ONFRAME = "BATTLE_ONFRAME"
QBattleManager.USE_MANUAL_SKILL = "USE_MANUAL_SKILL"
QBattleManager.CUTSCENE_START = "BATTLE_CUTSCENE_START"
QBattleManager.CUTSCENE_END = "BATTLE_CUTSCENE_END"
QBattleManager.ON_SET_TIME_GEAR = "ON_SET_TIME_GEAR"
QBattleManager.ON_CHANGE_DAMAGE_COEFFICIENT = "ON_CHANGE_DAMAGE_COEFFICIENT"

function QBattleManager:ctor(dungeonConfig)
    QBattleManager.super.ctor(self)

    self._battleTime = 0

    self._heroes = {}
    self._deadHeroes = {}
    self._enemies = {}
    self._heroGhosts = {}
    self._enemyGhosts = {}

    self._paused = false

    self._dungeonConfig = dungeonConfig

    self._monsters = self:isPVPMode() and {} or clone(QStaticDatabase:sharedDatabase():getMonstersById(self._dungeonConfig.monster_id))
    self:_assignReward()

    self._waveCount = self:_calculateWaveCount()
    self._timeLeft = self:getDungeonDuration()

    self._damageHistory = {}
    self._treatHistory = {}

    self._aiDirector = QAIDirector.new()

    self._trapDirectors = {}

    self._bullets = {}
    self._lasers = {}

    self._exceptActor = {}
    self._bulletTimeReferenceCount = 0
    self._isFirstNPCCreated = false
    self._isHaveEnemyInAppearEffectDelay = false
    self._ended = false -- 记录是否结束了，在WIN或者LOSE的消息发出的时候设置，防止消息重复发出。
    self._pauseAI = true

    self._nextSchedulerHandletId = 1
    self._delaySchedulers = {}

    self._curWave = 0
    self._curWaveStartTime = 0
    self._pauseBetweenWaves = true
    self._startCountDown = false

    self._enrollingStage = QTutorialStageEnrolling.new()
    -- self._enrollingStage:start(self) -- 12/23 wk 临时屏蔽等待张楠修改

    self._battleLog = QBattleLog.new(self._dungeonConfig.id)
    self._normalAttackRecord = {}

    self._isActiveDungeon = false
    self._activeDungeonType = 0
    self._activeDungeonInfo = remote.activityInstance:getDungeonById(self._dungeonConfig.id)
    if self._activeDungeonInfo ~= nil then
        self._isActiveDungeon = true
        self._activeDungeonType = self._activeDungeonInfo.dungeon_type
    end

    app:resetBattleNpcProbability(self._dungeonConfig.id)

    self._timeGear = 1.0

    self._damageCoefficient = 1.0
    if QBattleManager.ARENA_BEATTACK_30_COEFFICIENT == nil then
        local coefficient = 3
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.ARENA_BEATTACK_30_COEFFICIENT ~= nil and globalConfig.ARENA_BEATTACK_30_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.ARENA_BEATTACK_30_COEFFICIENT.value 
        end
        QBattleManager.ARENA_BEATTACK_30_COEFFICIENT = coefficient
    end
    if QBattleManager.ARENA_BEATTACK_60_COEFFICIENT == nil then
        local coefficient = 3
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.ARENA_BEATTACK_60_COEFFICIENT ~= nil and globalConfig.ARENA_BEATTACK_60_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.ARENA_BEATTACK_60_COEFFICIENT.value 
        end
        QBattleManager.ARENA_BEATTACK_60_COEFFICIENT = coefficient
    end
    if QBattleManager.SUNWELL_BEATTACK_30_COEFFICIENT == nil then
        local coefficient = 3
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.SUNWELL_BEATTACK_30_COEFFICIENT ~= nil and globalConfig.SUNWELL_BEATTACK_30_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.SUNWELL_BEATTACK_30_COEFFICIENT.value 
        end
        QBattleManager.SUNWELL_BEATTACK_30_COEFFICIENT = coefficient
    end
    if QBattleManager.SUNWELL_BEATTACK_60_COEFFICIENT == nil then
        local coefficient = 3
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.SUNWELL_BEATTACK_60_COEFFICIENT ~= nil and globalConfig.SUNWELL_BEATTACK_60_COEFFICIENT.value ~= nil then
            coefficient = globalConfig.SUNWELL_BEATTACK_60_COEFFICIENT.value 
        end
        QBattleManager.SUNWELL_BEATTACK_60_COEFFICIENT = coefficient
    end
end

function QBattleManager:_getBossCount()
    if self._bossCount == nil then
        self._bossCount = 0
        for _, monsterInfo in ipairs(self._monsters) do
            if monsterInfo.is_boss == true then
                self._bossCount = self._bossCount + 1
            end
        end
    end

    return self._bossCount

end

function QBattleManager:_assignReward()
    if self._dungeonConfig.awards == nil then self._dungeonConfig.awards = {} end
    if self._dungeonConfig.awards2 == nil then self._dungeonConfig.awards2 = {} end

    if #self._dungeonConfig.awards == 0 and #self._dungeonConfig.awards2 == 0 then
        return
    end

    if DEBUG > 0 then
        print("self._dungeonConfig.awards = ")
        printTable(self._dungeonConfig.awards)
        print("self._dungeonConfig.awards2 = ")
        printTable(self._dungeonConfig.awards2)
    end

    -- get monster who have rewards
    local monsters = {}
    for _, monsterInfo in ipairs(self._monsters) do
        local charactorInfo = QStaticDatabase:sharedDatabase():getCharacterByID(monsterInfo.npc_id)
        if charactorInfo ~= nil then
            if self._activeDungeonInfo == nil then
                table.insert(monsters, monsterInfo)
            else
                if charactorInfo.drop_index ~= nil then
                    table.insert(monsters, monsterInfo)
                end
            end
        end
    end

    local monsterCount = #monsters
    for _, reward in pairs(self._dungeonConfig.awards) do
        if reward.npcId ~= nil then
            if reward.index ~= nil then
                local index = reward.index
                local monsterInfo = monsters[index]
                if monsterInfo ~= nil then
                    if monsterInfo.rewards == nil then
                        monsterInfo.rewards = {}
                    end
                    monsterInfo.rewardIndex = index
                    table.insert(monsterInfo.rewards, {reward = reward, isGarbage = false})
                end
            end
        end
    end
    for _, reward in pairs(self._dungeonConfig.awards2) do
        if reward.npcId ~= nil then
            if reward.index ~= nil then
                local index = reward.index
                local monsterInfo = monsters[index]
                if monsterInfo ~= nil then
                    if monsterInfo.rewards == nil then
                        monsterInfo.rewards = {}
                    end
                    monsterInfo.rewardIndex = index
                    table.insert(monsterInfo.rewards, {reward = reward, isGarbage = true})
                end
            end
        end
    end

    -- find if have boss
    local bosses = {}
    local enemies = {}
    for _, monsterInfo in ipairs(monsters) do
        if monsterInfo.is_boss == true then
            table.insert(bosses, monsterInfo)
        else
            table.insert(enemies, monsterInfo)
        end
    end

    local bossCount = #bosses
    local enemyCount = #enemies

    if bossCount > 0 then
        local rewards = {}
        local garbage = {}
        if self._dungeonConfig.awards ~= nil then
            for _, reward in pairs(self._dungeonConfig.awards) do
                if reward.npcId == nil and (remote.items:getItemType(reward.type) == ITEM_TYPE.MONEY or remote.items:getItemType(reward.type) == ITEM_TYPE.ITEM) then
                    table.insert(rewards, {reward = reward, isGarbage = false})
                end
            end
        end
        if self._dungeonConfig.awards2 ~= nil then
            for _, reward in pairs(self._dungeonConfig.awards2) do
                if reward.npcId == nil and (remote.items:getItemType(reward.type) == ITEM_TYPE.MONEY or remote.items:getItemType(reward.type) == ITEM_TYPE.ITEM) then
                    table.insert(garbage, {reward = reward, isGarbage = true})
                end
            end
        end

        -- boss
        if bossCount == 1 then
            bosses[1].rewards = rewards
        else
            local index = math.random(1, bossCount)
            local rewardCount = #rewards
            while rewardCount > 0 do
                if rewardCount == 1 then
                    if bosses[index].rewards == nil then
                        bosses[index].rewards = {}
                    end
                    table.insert(bosses[index].rewards, rewards[1])
                    break
                else
                    local itemIndex = math.random(1, rewardCount)
                    if bosses[index].rewards == nil then
                        bosses[index].rewards = {}
                    end
                    table.insert(bosses[index].rewards, rewards[itemIndex])
                    table.remove(rewards, itemIndex)
                    rewardCount = rewardCount - 1
                    index = math.random(1, bossCount)
                end
            end
        end

        -- enemy
        if enemyCount == 1 then
            enemies[1].rewards = garbage
        elseif enemyCount > 0 then
            local index = math.random(1, enemyCount)
            local garbageCount = #garbage
            while garbageCount > 0 do
                if garbageCount == 1 then
                    if enemies[index].rewards == nil then
                        enemies[index].rewards = {}
                    end
                    table.insert(enemies[index].rewards, garbage[1])
                    break
                else
                    local itemIndex = math.random(1, garbageCount)
                    if enemies[index].rewards == nil then
                        enemies[index].rewards = {}
                    end
                    table.insert(enemies[index].rewards, garbage[itemIndex])
                    table.remove(garbage, itemIndex)
                    garbageCount = garbageCount - 1
                    index = math.random(1, enemyCount)
                end
            end
        else
            -- no enemy
            if bossCount == 1 then
                for _, item in pairs(garbage) do
                    table.insert(bosses[1].rewards, item)
                end
            else
                local index = math.random(1, bossCount)
                local rewardCount = #garbage
                while rewardCount > 0 do
                    if rewardCount == 1 then
                        if bosses[index].rewards == nil then
                            bosses[index].rewards = {}
                        end
                        table.insert(bosses[index].rewards, garbage[1])
                        break
                    else
                        local itemIndex = math.random(1, rewardCount)
                        if bosses[index].rewards == nil then
                            bosses[index].rewards = {}
                        end
                        table.insert(bosses[index].rewards, garbage[itemIndex])
                        table.remove(garbage, itemIndex)
                        rewardCount = rewardCount - 1
                        index = math.random(1, bossCount)
                    end
                end
            end
        end
    else
        local rewards = {}
        if self._dungeonConfig.awards ~= nil then
            for _, reward in pairs(self._dungeonConfig.awards) do
                if reward.npcId == nil and (remote.items:getItemType(reward.type) == ITEM_TYPE.MONEY or remote.items:getItemType(reward.type) == ITEM_TYPE.ITEM) then
                    table.insert(rewards, {reward = reward, isGarbage = false})
                end
            end
        end
        if self._dungeonConfig.awards2 ~= nil then
            for _, reward in pairs(self._dungeonConfig.awards2) do
                if reward.npcId == nil and (remote.items:getItemType(reward.type) == ITEM_TYPE.MONEY or remote.items:getItemType(reward.type) == ITEM_TYPE.ITEM) then
                    table.insert(rewards, {reward = reward, isGarbage = true})
                end
            end
        end

        if enemyCount == 1 then
            enemies[1].rewards = rewards
        elseif enemyCount > 0 then
            local index = math.random(1, enemyCount)
            local rewardCount = #rewards
            while rewardCount > 0 do
                if rewardCount == 1 then
                    if enemies[index].rewards == nil then
                        enemies[index].rewards = {}
                    end
                    table.insert(enemies[index].rewards, rewards[1])
                    break
                else
                    local itemIndex = math.random(1, rewardCount)
                    if enemies[index].rewards == nil then
                        enemies[index].rewards = {}
                    end
                    table.insert(enemies[index].rewards, rewards[itemIndex])
                    table.remove(rewards, itemIndex)
                    rewardCount = rewardCount - 1
                    index = math.random(1, enemyCount)
                end
            end
        end
    end

    if DEBUG > 0 then
        print("Assign rewards = ")
        for _, monsterInfo in ipairs(monsters) do
            if monsterInfo.rewards ~= nil then
                print("npc id = " .. monsterInfo.npc_id)
                printTable(monsterInfo.rewards)
            end
        end
    end

end

function QBattleManager:getDeadEnemyRewards(isPrint)
    local rewards = {}
    for i, item in ipairs(self._monsters) do
        if item.created == true and item.death_logged == true and item.rewards ~= nil then
            if isPrint == true and item.rewards ~= nil and #item.rewards > 0 then
                if self._isActiveDungeon == true and self._activeDungeonType == DUNGEON_TYPE.ACTIVITY_TIME and item.rewardIndex ~= nil then 
                    print(item.npc:getActorID() .. " at index " .. tostring(item.rewardIndex) .. " has reward:")
                else
                    print(item.npc:getActorID() .. " has reward:")
                end
            end
            for _, reward in ipairs(item.rewards) do
                table.insert(rewards, reward.reward)
                if isPrint == true then
                    printTable(reward)
                end
            end
        end
    end
    return rewards
end

function QBattleManager:getDungeonConfig()
    return self._dungeonConfig
end

function QBattleManager:isActiveDungeon()
    return self._isActiveDungeon
end

function QBattleManager:getActiveDungeonType()
    return self._activeDungeonType
end

function QBattleManager:isBattleEnded()
    return self._ended
end

function QBattleManager:isPVPMode()
    return self._dungeonConfig.isPVPMode or false
end

function QBattleManager:isInArena()
    return self._dungeonConfig.isArena or false
end

function QBattleManager:isInSunwell()
    return self._dungeonConfig.isSunwell or false
end

function QBattleManager:isSunwellAllowControl()
    if QBattleManager.SUNWELL_ALLOW_CONTROL == nil then
        local result = true
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.SUNWELL_ALLOW_CONTROL ~= nil and globalConfig.SUNWELL_ALLOW_CONTROL.value ~= nil then
            result = globalConfig.SUNWELL_ALLOW_CONTROL.value 
        end
        QBattleManager.SUNWELL_ALLOW_CONTROL = result
    end
    return QBattleManager.SUNWELL_ALLOW_CONTROL
end

function QBattleManager:isInTutorial()
    return self._dungeonConfig.isTutorial or false
end

function QBattleManager:isPaused()
    return self._paused
end

function QBattleManager:isPausedBetweenWave()
    return self._pauseBetweenWaves
end

function QBattleManager:isInEditor()
    return self._dungeonConfig.isEditor or false
end

function QBattleManager:getTime()
    return self._battleTime
end

function QBattleManager:getDungeonEnemyCount()
    if self._dungeonEnemyCount == nil then
        self._dungeonEnemyCount = 0
        for _, item in ipairs(self._monsters) do
            if item.probability == nil and item.npc_summoned == nil then
                self._dungeonEnemyCount = self._dungeonEnemyCount + 1
            end
        end
    end
    return self._dungeonEnemyCount
end

function QBattleManager:getDungeonDeadEnemyCount()
    local count = 0
    for _, item in ipairs(self._monsters) do
        if item.probability == nil and item.npc_summoned == nil and item.created == true and item.death_logged == true then
            count = count + 1
        end
    end
    return count
end

function QBattleManager:getHeroes()
    if #self._heroes > 0 or #self._deadHeroes > 0 then return self._heroes end

    self._heroes = {}
    if self:isInTutorial() == true or self:isInEditor() then
        if self._dungeonConfig.heroInfos ~= nil then
            for _, heroInfo in ipairs(self._dungeonConfig.heroInfos) do
                hero = app:createHeroWithoutCache(heroInfo)
                -- pvp special skills
                hero:checkCDReduce()
                table.insert(self._heroes, hero)
                self._battleLog:addHeroOnStage(hero, hero:getBattleForce())
            end
        end
    else
        if remote.teams ~= nil then

            local teamName = QTeam.INSTANCE_TEAM
            if self._dungeonConfig.teamName ~= nil then
                teamName = self._dungeonConfig.teamName
            end

            for k, heroId in ipairs(remote.teams:getTeams(teamName)) do
                local heroInfo = remote.herosUtil:getHeroByID(heroId)
                -- local hero = app:createHero(heroInfo)
                local hero = app:createHeroWithoutCache(heroInfo)
                hero:resetStateForBattle()
                if self:isInArena() then
                    hero:setForceAuto(true)
                end
                table.insert(self._heroes, hero)
            end

            if remote.teams._joinHero then
                for _, joinHeroId in pairs(remote.teams._joinHero) do
                    local already_there = false
                    for k, heroId in ipairs(remote.teams:getTeams(teamName)) do
                        if heroId == joinHeroId then
                            already_there = true
                            break
                        end
                    end
                    if not already_there then
                        local heroInfo = remote.herosUtil:getHeroByID(joinHeroId)
                        -- hero = app:createHero(hero)
                        local hero = app:createHeroWithoutCache(heroInfo)
                        hero:resetStateForBattle()
                        table.insert(self._heroes, hero)
                    end
                end
            end

        end

    end
    local currentTime = q.time()
    for _, hero in ipairs(self._heroes) do
        self._battleLog:onHeroCreated(hero:getActorID(), currentTime)
        hero:dump()
    end

    return self._heroes
end

function QBattleManager:getDeadHeroes()
    return self._deadHeroes
end

function QBattleManager:getEnemies()
    return self._enemies
end

function QBattleManager:getMyEnemies(actor)
    return self:getMyEnemiesWithType(actor:getType())
end

local function func_dead_filter(actor)
    return not actor:isDead()
end
function QBattleManager:getMyEnemiesWithType(actorType)
    local enemies = nil
    if actorType == ACTOR_TYPES.HERO or actorType == ACTOR_TYPES.HERO_NPC then
        enemies = self:getEnemies()
    else
        enemies = self:getHeroes()
    end

    local result = {}
    table.mergeForArray(result, enemies, func_dead_filter)
    return result
end

function QBattleManager:getMyTeammates(actor, includeSelf)
    local teammates = nil
    if actor:getType() == ACTOR_TYPES.HERO or actor:getType() == ACTOR_TYPES.HERO_NPC then
        teammates = self:getHeroes()
    else
        teammates = self:getEnemies()
    end

    local result = {}
    if includeSelf == true then
        table.mergeForArray(result, teammates, func_dead_filter)
    else
        table.mergeForArray(result, teammates, function(teammate) return not teammate:isDead() and teammate ~= actor end)
    end
    return result
end

function QBattleManager:getMyTeammatesWithType(actorType)
    local teammates = nil
    if actorType == ACTOR_TYPES.HERO or actorType == ACTOR_TYPES.HERO_NPC then
        teammates = self:getHeroes()
    else
        teammates = self:getEnemies()
    end

    local result = {}
    table.mergeForArray(result, teammates, func_dead_filter)
end

function QBattleManager:getWaveCount()
    return self._waveCount
end

function QBattleManager:getTimeLeft()
    return self._timeLeft
end

local function deimport(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n,v = debug.getlocal(3, 1)
                currentModuleName = v
            end

            currentModuleNameParts = string.split(currentModuleName, ".")
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end

    package.loaded[moduleFullName] = nil
end

-- 在windows下调用这个函数会清除所有在场actor的ai，并从磁盘再次加载ai。便于策划调AI。
function QBattleManager:debug_reloadAI()
    if device.platform == "windows" then

        -- QFileCache会把ai config缓存起来
        QFileCache.sharedFileCache()._aiConfigCache = {}

        for _, hero in ipairs(self._heroes) do
            if hero:isDead() == false and (self._aiDirector:hasBehaviorTree(hero.behaviorNode) or hero.behaviorNode == nil) then
                if hero.behaviorNode ~= nil then self._aiDirector:removeBehaviorTree(hero.behaviorNode) end
                hero.behaviorNode = nil
                hero:setTarget(nil)

                -- require函数会把ai config也缓存起来,
                deimport(app.packageRoot .. ".ai.config." .. hero:getAIType())
                -- 缓存都清空之后才能保证再次从磁盘读入
                hero.behaviorNode = self._aiDirector:createBehaviorTree(hero:getAIType(), hero)
                self._aiDirector:addBehaviorTree(hero.behaviorNode)
            end
        end

        for _, monster in ipairs(self._monsters) do
            if monster.created and monster.npc and monster.npc:isDead() == false and (self._aiDirector:hasBehaviorTree(monster.ai) or monster.ai == nil) then
                if monster.ai ~= nil then self._aiDirector:removeBehaviorTree(monster.ai) end
                monster.ai = nil
                monster.npc:setTarget(nil)
                
                -- require函数会把ai config也缓存起来
                deimport(app.packageRoot .. ".ai.config." .. monster.npc:getAIType())
                -- 缓存都清空之后才能保证再次从磁盘读入
                monster.ai = self._aiDirector:createBehaviorTree(monster.npc:getAIType(), monster.npc)
                self._aiDirector:addBehaviorTree(monster.ai)
            end
        end

    end
end

function QBattleManager:start()

    self._enrollingStage:start(self) -- 12/23 wk 临时修改
    -- ended with battle win or lose 
    self._frameId = scheduler.scheduleUpdateGlobal(handler(self, QBattleManager._onFrame))
    -- ended with battle win or lose 
    self._timerId = scheduler.scheduleGlobal(handler(self, QBattleManager._onTimer), QBattleManager.BATTLE_TIMER_INTERVAL)
    -- ended after exist battle scene
    self._battleTimeId = scheduler.scheduleUpdateGlobal(handler(self, QBattleManager._onBattleFrame))

    QNotificationCenter.sharedNotificationCenter():addEventListener(QNotificationCenter.EVENT_BULLET_TIME_TURN_ON, self._onBulletTimeEvent, self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QNotificationCenter.EVENT_BULLET_TIME_TURN_OFF, self._onBulletTimeEvent, self)

    if self:isInEditor() == false then
        -- hard code
        -- 第一章 第四关 kreah 出场
        -- if self._dungeonConfig.id == "wailing_caverns_4" and remote.instance:checkIsPassByDungeonId("wailing_caverns_4") == false then
        if self._dungeonConfig.id == "wailing_caverns_4" then
            self:startCutscene(global.cutscenes.KRESH_ENTRANCE)
        else
            self:_startBattle()
        end
    else
        self:_startBattle()
    end

    if self:isPVPMode() then
        for _, enemy in ipairs(self._enemies) do
            for _, skill in pairs(enemy._activeSkills) do
                if skill:getName() == "charge" then
                    skill:coolDown()
                    skill:reduceCoolDownTime(skill._cd_time - 1.0)
                end
            end
        end
    end
end

function QBattleManager:_startBattle()
    self:dispatchEvent({name = QBattleManager.START})
    self._battleLog:setStartTime(q.time())

    self._pauseBetweenWaves = false

    if self:isPVPMode() then
        self._startCountDown = true
        self:_checkStartCountDown()
    else
        self:performWithDelay(function()
            self._startCountDown = true
            self:_checkStartCountDown()
        end, global.hero_enter_time)
    end

    -- create AI for heroes
    if self:isInTutorial() == false then
        for i, hero in ipairs(self:getHeroes()) do
            local ai = self._aiDirector:createBehaviorTree(hero:getAIType(), hero)
            hero.behaviorNode = ai
            self._aiDirector:addBehaviorTree(ai)
        end
    end

    -- recharge combo points to full points
    for i, hero in ipairs(self:getHeroes()) do
        if hero:isNeedComboPoints() then
            hero:gainComboPoints(hero:getComboPointsMax())
        end
    end
    for i, hero in ipairs(self:getEnemies()) do
        if hero:isNeedComboPoints() then
            hero:gainComboPoints(hero:getComboPointsMax())
        end
    end

    if self:isInEditor() == false then
        -- 第一关 第二波 三个软泥怪出现提示释放剑刃风暴
        if self._dungeonConfig.id == "wailing_caverns_1" and remote.instance:checkIsPassByDungeonId("wailing_caverns_1") == false then
            local hero = self:getHeroes()[1]
            local skill = nil
            for _, v in pairs(hero:getManualSkills()) do
                skill = v
                break
            end
            local magic_time = 24
            local first_cd = skill:get("first_cd")
            local cd = skill:get("cd")
            skill:set("first_cd", magic_time + 8)
            skill:set("cd", magic_time + 8)
            skill:coolDown()
        end

        -- -- 第三关 第一波 三个软泥怪出现提示释放剑刃风暴
        -- if self._dungeonConfig.id == "wailing_caverns_3" and remote.instance:checkIsPassByDungeonId("wailing_caverns_3") == false then
        --     local heroes = self:getHeroes()
        --     local skill = nil
        --     local hero = nil
        --     for _, _hero in ipairs(heroes) do
        --         for _, v in pairs(_hero:getManualSkills()) do
        --             skill = v
        --             hero = _hero
        --             break
        --         end
        --     end
        --     if skill and hero then
        --         local magic_time = 7
        --         skill:set("first_cd", magic_time + global.wave_animation_time)
        --         skill:coolDown()
        --         self:performWithDelay(function()
        --             skill:forceReadyAndConditionMet(nil)
        --             if app.scene ~= nil then
        --                 skill:_stopCd()
        --                 app.scene:pauseBattleAndUseSkill(hero, skill)
        --             end
        --         end, magic_time + global.wave_animation_time)
        --     end
        -- end

        -- 第五关 第一波 第一条蛇出来后集火提示
        if self._dungeonConfig.id == "wailing_caverns_5" and remote.instance:checkIsPassByDungeonId("wailing_caverns_5") == false then
            self:performWithDelay(function()
                local enemy = nil
                local enemies = self:getEnemies()
                for _, v in ipairs(enemies) do
                    if string.match(v:getUDID(), "40012") ~= nil then
                        enemy = v
                    end
                end
                if app.scene ~= nil then
                    app.scene:pauseBattleAndAttackEnemy(enemy)
                end
            end, 6.5 + global.wave_animation_time)
        end
    end
end

function QBattleManager:ended()
    -- remove trap
    for _, trapDirector in ipairs(self._trapDirectors) do
        if trapDirector:isCompleted() == false then
            trapDirector:cancel()
        end
    end
    self._trapDirectors = {}

    -- remove bullet
    for _, bullet in ipairs(self._bullets) do
        if bullet:isFinished() == false then
            bullet:cancel()
        end
    end
    self._bullets = {}

    -- remove laser
    for _, laser in ipairs(self._lasers) do
        if laser:isFinished() == false then
            laser:cancel()
        end
    end
    self._lasers = {}

    if self._timerId ~= nil then
        scheduler.unscheduleGlobal(self._timerId)
        self._timerId = nil
    end
    if self._frameId ~= nil then
        scheduler.unscheduleGlobal(self._frameId)
        self._frameId = nil
    end
    self._aiDirector = nil

    self:dispatchEvent({name = QBattleManager.END})

    QNotificationCenter.sharedNotificationCenter():removeEventListener(QNotificationCenter.EVENT_BULLET_TIME_TURN_ON, self._onBulletTimeEvent, self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QNotificationCenter.EVENT_BULLET_TIME_TURN_OFF, self._onBulletTimeEvent, self)
end

function QBattleManager:stop()
    if self._battleTimeId ~= nil then
        scheduler.unscheduleGlobal(self._battleTimeId)
        self._battleTimeId = nil
    end

    self:dispatchEvent({name = QBattleManager.STOP})
end

function QBattleManager:pause()
    self._paused = true
    self:_checkEndCountDown()
    self:dispatchEvent({name = QBattleManager.PAUSE})
end

function QBattleManager:resume()
    self._paused = false
    self:_checkStartCountDown()
    self:dispatchEvent({name = QBattleManager.RESUME})
end

function QBattleManager:startCutscene(cutsceneName)
    self._paused = true
    self:dispatchEvent({name = QBattleManager.CUTSCENE_START, cutscene = cutsceneName})
end

function QBattleManager:endCutscene()
    self._paused = false
    self:_startBattle()
    self:dispatchEvent({name = QBattleManager.CUTSCENE_END})
end

-- 静态帮助函数，获取攻击力最大的actor
function QBattleManager.getMaxAttacker(list)
    return table.max_fun(list, QActor.getAttack)
end


function QBattleManager:_onBattleFrame(dt)
    if (self._paused == true and _G["_tutorial_allow_trap_play"] ~= true) then
        return
    end

    dt = dt * self:getTimeGear()
    
    self._battleTime = self._battleTime + dt

    self:_handleSchedulerOnFrame(dt)
end

function QBattleManager:_handleSchedulerOnFrame(dt)
    if #self._delaySchedulers > 0 then
        if self._bulletTimeReferenceCount == 0 then
            for _, schedulerInfo in ipairs(self._delaySchedulers) do
                if not schedulerInfo.pauseBetweenWave or not self:isPausedBetweenWave() then
                    schedulerInfo.delay = schedulerInfo.delay - dt
                end
                if schedulerInfo.delay < 0 then
                    schedulerInfo.func()
                end
            end
        else
            for _, schedulerInfo in ipairs(self._delaySchedulers) do
                local isInBulletTime = true
                for _, actor in ipairs(self._exceptActor) do
                    if actor == schedulerInfo.actor then
                        isInBulletTime = false
                    end
                end
                if isInBulletTime == false then
                    if not schedulerInfo.pauseBetweenWave or not self:isPausedBetweenWave() then
                        schedulerInfo.delay = schedulerInfo.delay - dt
                    end
                    if schedulerInfo.delay < 0 then
                        schedulerInfo.func()
                    end
                end
            end
        end

        while true do
            local removeIndex = 0
            for i, schedulerInfo in ipairs(self._delaySchedulers) do
                if schedulerInfo.delay < 0 then
                    removeIndex = i
                    break
                end
            end
            if removeIndex ~= 0 then
                table.remove(self._delaySchedulers, removeIndex)
            else
                break
            end
        end
    end
end

function QBattleManager:_onFrame(dt)
	dt = dt * self:getTimeGear()

    if self._paused == true or self._ended == true then 
        return 
    end

    -- if self._vm_memory_used == nil then
    --     self._vm_memory_used = collectgarbage("count")
    -- else
    --     local current_vm_memory_used = collectgarbage("count")
    --     if current_vm_memory_used - self._vm_memory_used > 5 * 1024 then
    --         collectgarbage("step", 1000)
    --         self._vm_memory_used = collectgarbage("count")
    --     end
    -- end
    collectgarbage("step", 10)

    if self._bulletTimeReferenceCount == 0 then
        for _, trapDirector in ipairs(self._trapDirectors) do
            trapDirector:visit(dt)
        end
        for i, trapDirector in ipairs(self._trapDirectors) do
            if trapDirector:isCompleted() == true then
                table.remove(self._trapDirectors, i)
                break
            end
        end
    end

    if self._bulletTimeReferenceCount == 0 then
        for _, bullet in ipairs(self._bullets) do
            bullet:visit(dt)
        end
        for i, bullet in ipairs(self._bullets) do
            if bullet:isFinished() == true then
                table.remove(self._bullets, i)
                break
            end
        end
    end

    if self._bulletTimeReferenceCount == 0 then
        for _, laser in ipairs(self._lasers) do
            laser:visit(dt)
        end
        for i, laser in ipairs(self._lasers) do
            if laser:isFinished() == true then
                table.remove(self._lasers, i)
                break
            end
        end
    end

    for _, monster in ipairs(self._monsters) do
        if monster.life_span then
            if monster.npc and not monster.npc:isDead() then
                if self:getTime() - monster.born_time > monster.life_span then
                    monster.npc:suicide()
                end
            elseif monster.npc_summoned then
                for _, summoned in pairs(monster.npc_summoned) do
                    if not summoned.npc:isDead() and self:getTime() - summoned.born_time > monster.life_span then
                        summoned.npc:suicide()
                    end
                end
            end
        end
    end

    for _, ghost in ipairs(self._heroGhosts) do
        local actor = ghost.actor
        local ai = ghost.ai
        if not actor:isDead() and ghost.life_span > 0 then
            ghost.life_countdown = ghost.life_countdown - dt
            if ghost.life_countdown <= 0 then
                actor:suicide()
                self:dispatchEvent({name = QBattleManager.NPC_DEATH_LOGGED, npc = actor, is_hero = true})
                self:dispatchEvent({name = QBattleManager.NPC_CLEANUP, npc = actor, is_hero = true})
                self._aiDirector:removeBehaviorTree(ai)
                app.grid:removeActor(actor)
            end
        end
    end

    for _, ghost in ipairs(self._enemyGhosts) do
        local actor = ghost.actor
        local ai = ghost.ai
        if not actor:isDead() and ghost.life_span > 0 then
            ghost.life_countdown = ghost.life_countdown - dt
            if ghost.life_countdown <= 0 then
                actor:suicide()
                self:dispatchEvent({name = QBattleManager.NPC_DEATH_LOGGED, npc = actor, is_hero = false})
                self:dispatchEvent({name = QBattleManager.NPC_CLEANUP, npc = actor, is_hero = false})
                self._aiDirector:removeBehaviorTree(ai)
                app.grid:removeActor(actor)
            end
        end
    end

    if self._enrollingStage then
        if self._enrollingStage:isStageFinished() == true then
            self._enrollingStage:ended()
        end
        self._enrollingStage:visit()
    end

    if self:isPVPMode() then
        local time = self:getDungeonDuration() - self:getTimeLeft()
        local old_coefficient = self._damageCoefficient
        if time >= 60 then
            if self:isInArena() then
                self._damageCoefficient = QBattleManager.ARENA_BEATTACK_60_COEFFICIENT + 1
            elseif self:isInSunwell() then
                self._damageCoefficient = QBattleManager.SUNWELL_BEATTACK_60_COEFFICIENT + 1
            end
        elseif time >= 30 then
            if self:isInArena() then
                self._damageCoefficient = QBattleManager.ARENA_BEATTACK_30_COEFFICIENT + 1
            elseif self:isInSunwell() then
                self._damageCoefficient = QBattleManager.SUNWELL_BEATTACK_30_COEFFICIENT + 1
            end
        end

        if old_coefficient ~= self._damageCoefficient then
            self:dispatchEvent({name = QBattleManager.ON_CHANGE_DAMAGE_COEFFICIENT, damage_coefficient = self._damageCoefficient})
        end
    end

    self:dispatchEvent({name = QBattleManager.ONFRAME, deltaTime = dt})
end

function QBattleManager:_onTimer(dt)
	dt = dt * self:getTimeGear()

    if self._paused == true or self._ended == true or self._pauseBetweenWaves == true then 
        return 
    end

    -- check time left
    if self._startCountDown == true then
        self._timeLeft = self._timeLeft - dt
    end

    self:dispatchEvent({name = QBattleManager.ONTIMER})

    local allDead, nextWave = self:_checkWave()

    local isAllEnemyDead = false
    if allDead == true and nextWave == nil then
        isAllEnemyDead = true
    end

    -- check enemy heroes
    if self:isPVPMode() then
        self:_checkEnemyHeroes()
    end

    if self:_checkWinOrLose(isAllEnemyDead) == true then 
        return 
    end

    if allDead == true then
        if nextWave ~= nil then
            if nextWave == 1 then
                self._curWave = nextWave
                self._curWaveStartTime = self:getTime() + global.hero_enter_time * 0.15

                local isBossComing = false
                for _, item in ipairs(self._monsters) do
                    if item.wave == self._curWave and item.created ~= true and item.is_boss == true then
                        if item.appear < global.wave_animation_time then
                            isBossComing = true 
                            break
                        end
                    end
                end

                self:performWithDelay(function()
                    self:dispatchEvent({name = QBattleManager.WAVE_STARTED, wave = self._curWave, isBossComing = isBossComing})
                end, global.wave_animation_time - global.wave_animation_time + 0.5)

                self:performWithDelay(function()
                    self._pauseAI = false
                end, global.hero_enter_time * 0.15)
            else
                self._nextWave = nextWave
                self._pauseBetweenWaves = true
                self:_checkEndCountDown()

                if self._dungeonConfig.mode == BATTLE_MODE.CONTINUOUS then
                    self:onStartNewWave()
                else
                	self:setTimeGear(1.0)

                    self:performWithDelay(function()
                        self:dispatchEvent({name = QBattleManager.WAVE_ENDED, wave = self._curWave})
                        self._pauseAI = true
                    end, global.npc_view_dead_blink_time + 0.5)
                end
            end

            self._isFirstNPCCreated = false
        end
    end

    -- check heroes
    if self:_checkHeroes() == false then 
        return 
    end

    -- run AI loop
    if _debug_aiDirector_ == nil then 
        _debug_aiDirector_ = false 
    end
    if _debug_aiDirector_ ~= true and self._pauseAI == false then
        self._aiDirector:visit()
    end
end

function QBattleManager:_checkWinOrLose(isAllEnemyDead)

    -- check if win
    if isAllEnemyDead == true then
        self:_onWin({isAllEnemyDead = true})
        return true
    end

    -- check lose
    local heroCountExceptHealth = 0
    for i, hero in ipairs(self._heroes) do
        if hero:getTalentFunc() ~= "health" then
            heroCountExceptHealth = heroCountExceptHealth + 1
        end
    end

    if self._isActiveDungeon == true and self._activeDungeonType == DUNGEON_TYPE.ACTIVITY_TIME then 
        if self._timeLeft <= 0 or heroCountExceptHealth <= 0 then
            local rewards = self:getDeadEnemyRewards()
            local rewardCount = #rewards
            if rewardCount > 0 then
                self:_onWin({isAllEnemyDead = false})
            else
                self:_onLose()
            end
            return true
        end
    else
        if self:isPVPMode() == true then
            if self._timeLeft <= 0 then
                if self:isInSunwell() then
                    local enemies = self:getEnemies()
                    for _, enemy in ipairs(enemies) do
                        if enemy:isDead() == false then
                            enemy:decreaseHp(enemy:getHp())
                        end
                    end

                    local heroes = self:getHeroes()
                    for _, hero in ipairs(heroes) do
                        if hero:isDead() == false then
                            hero:decreaseHp(hero:getHp())
                        end
                    end
                    self:_onWin({isTimeOver = true})
                    return true
                elseif self:isInArena() then
                    self:_onLose({isTimeOver = true})
                    return true
                end
            elseif heroCountExceptHealth <= 0 then
                self:_onLose()
                return true
            end
        else
            if self._timeLeft <= 0 or heroCountExceptHealth <= 0 then
                self:_onLose()
                return true
            end
        end
    end

    if self:isPVPMode() then
        local all_dead = true
        for _, enemy in ipairs(self._enemies) do
            if not enemy:isHealth() and not enemy:isDead() then
                all_dead = false
                break
            end
        end
        if all_dead then
            self:_onWin({isAllEnemyDead = true})
            return false
        end
    end

    return false

end

function QBattleManager:_onWin(options)
    if options == nil then
        options = {}
    end

    app:resetBattleNpcProbability(self._dungeonConfig.id)
    app:resetBattleRandomNumber(self._dungeonConfig.id)

    self._battleLog:setIsWin(true)
    self._battleLog:setDuration(self:getDungeonDuration() - self:getTimeLeft())

    local event = {name = QBattleManager.WIN}
    table.merge(event, options)
    self:dispatchEvent(event)

    self._ended = true
    self:_checkEndCountDown()
    self._battleLog:setEndTime(q.time())
end

function QBattleManager:_onLose(options)
    if options == nil then
        options = {}
    end

    app:resetBattleNpcProbability(self._dungeonConfig.id)

    local event = {name = QBattleManager.LOSE}
    table.merge(event, options)
    self:dispatchEvent(event)

    self._ended = true
    self:_checkEndCountDown()
    self._battleLog:setEndTime(q.time())
    app:resetBattleNpcProbability(self._dungeonConfig.id)
end

function QBattleManager:onConfirmNewWave()
    self:dispatchEvent({name = QBattleManager.WAVE_CONFIRMED, wave = self._curWave})
end

function QBattleManager:onStartNewWave()
    if self._nextWave == nil or self._pauseBetweenWaves == false then
        return
    end

    if self._nextWave <= self._curWave then
        assert(false, "QBattleManager:onStartNewWave next wave is equal to or small then current wave!")
        return
    end

    -- remove trap
    for _, trapDirector in ipairs(self._trapDirectors) do
        if trapDirector:isCompleted() == false then
            trapDirector:cancel()
        end
    end
    self._trapDirectors = {}

    self._pauseBetweenWaves = false
    self:_checkStartCountDown()

    self._pauseAI = false
    self._curWave = self._nextWave
    self._curWaveStartTime = self:getTime() + global.wave_animation_time

    local isBossComing = false
    for _, item in ipairs(self._monsters) do
        if item.wave == self._curWave and item.created ~= true and item.is_boss == true then
            if item.appear < global.wave_animation_time then
                isBossComing = true 
                break
            end
        end
    end

    self:performWithDelay(function()
        self:dispatchEvent({name = QBattleManager.WAVE_STARTED, wave = self._nextWave, isBossComing = isBossComing})
    end, 0)

    if self:isInEditor() == false then

        -- 第一关 第二波
        if self._dungeonConfig.id == "wailing_caverns_1" and self._curWave == 2 and remote.instance:checkIsPassByDungeonId("wailing_caverns_1") == false then
            local hero = self:getHeroes()[1]
            local skill = nil
            for _, v in pairs(hero:getManualSkills()) do
                skill = v
                break
            end
            local left_time = skill._cd_time * (1 - skill._cd_progress) - 5.5
            if left_time > 0 then
                skill:reduceCoolDownTime(left_time)
            end
            self:performWithDelay(function()
                skill:forceReadyAndConditionMet(nil)
                if app.scene ~= nil then
                    skill:_stopCd()
                    app.scene:pauseBattleAndUseSkill(hero, skill)
                end
            end, 5.5, nil, true)
        end

        -- 第二关 第二波 第二条蛇出来后集火提示
        if self._dungeonConfig.id == "wailing_caverns_2" and self._curWave == 2 and remote.instance:checkIsPassByDungeonId("wailing_caverns_2") == false then
            self:performWithDelay(function()
                local enemy = nil
                local enemies = self:getEnemies()
                for _, v in ipairs(enemies) do
                    if string.match(v:getUDID(), "40003") ~= nil then
                        enemy = v
                    end
                end
                if app.scene ~= nil then
                    app.scene:pauseBattleAndAttackEnemy(enemy)
                end
            end, 6 + global.wave_animation_time)
        end
    end

    for _, hero in ipairs(self._heroes) do
        hero:setManualMode(QActor.AUTO)
        hero:clearLastAttackee()
    end
end

function QBattleManager:createEnemiesInPVPMode()
    if self:isPVPMode() == false then
        return
    end

    for _, hero in ipairs(self._dungeonConfig.pvp_rivals) do
        local actor = app:createHeroWithoutCache(hero)
        actor:resetStateForBattle()
        
        if hero.hp ~= nil and hero.hp > 0 then
            actor:setHp(hero.hp)
        end
        if hero.skillCD ~= nil and hero.skillCD > 0 then
            for _, skill in pairs(actor:getManualSkills()) do
                skill:coolDown()
                local realcdt = skill:getCdTime() * hero.skillCD * 0.001
                skill:reduceCoolDownTime(realcdt)
            end
        end

        actor:setType(ACTOR_TYPES.NPC)
        actor.ai = self._aiDirector:createBehaviorTree(actor:getAIType(), actor)
        self._aiDirector:addBehaviorTree(actor.ai)

        actor:setForceAuto(true)

        table.insert(self._enemies, actor)
        self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = actor, pos = {x = 0, y = 0}, isBoss = false})

        actor:dump()
    end
end

function QBattleManager:createEnemiesInTutorial()
    if self:isInTutorial() == false then
        return
    end

    local wave = 1

    for i, item in ipairs(self._monsters) do
        if item.wave == wave then
            if item.created ~= true then
                -- create NPC
                item.created = true
                item.npc = app:createNpc(item.npc_id)
                table.insert(self._enemies, item.npc)
                self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = item.npc, pos = {x = item.x, y = item.y}, isBoss = false})
            end
        end
    end
end

-- ignore appear skill and appear effect
function QBattleManager:createEnemyManually(id, wave, x, y, skeletonView)
    if id == nil or wave <= 0 then
        return
    end

    for i, item in ipairs(self._monsters) do
        if item.npc_id == id and item.created ~= true then
            if x == nil then
                x = item.x
            end
            if y == nil then
                y = item.y
            end
            item.created = true
            item.npc = app:createNpc(app:getBattleRandomNpc(self._dungeonConfig.monster_id, i, item.npc_id), {item.appear_skill, item.dead_skill}, item.dead_skill)
            item.born_time = self:getTime()
            item.ai = self._aiDirector:createBehaviorTree(item.npc:getAIType(), item.npc)
            self._aiDirector:addBehaviorTree(item.ai)
            table.insert(self._enemies, item.npc)
            self._isHaveEnemyInAppearEffectDelay = false
           
            item.npc.rewards = item.rewards
            if x == nil or y == nil then
                self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = item.npc, pos = {x = item.x, y = item.y}, isBoss = item.is_boss, isManually = true, skeletonView = skeletonView})
            else
                self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = item.npc, screen_pos = {x = x, y = y}, isBoss = item.is_boss, isManually = true, skeletonView = skeletonView})
            end
            if self._isActiveDungeon == true and self._activeDungeonType == DUNGEON_TYPE.ACTIVITY_TIME and item.rewardIndex ~= nil then 
                self._battleLog:onMonsterCreated(item.npc:getId(), item.npc:getActorID(), item.rewardIndex, q.time())
            else
                self._battleLog:onMonsterCreated(item.npc:getId(), item.npc:getActorID(), nil, q.time())
            end
        end
    end
end

--[[
check 3 things:
1. if there is npc in this wave need to be created, create it when appropriate in this function
2. all NPC in current wave have been dead
3. if there is next wave if all NPC dead
--]]
function QBattleManager:_checkWave()
    if self._ended then return nil, nil end

    if self._curWave == 0 then
        return true, 1
    end

    -- check if all of npc in this wave have been dead
    local allDead = true

    local interval = self:getTime() - self._curWaveStartTime

    -- check if all enemy is dead and disapper
    for i, monster in ipairs(self._monsters) do
        if monster.created and monster.npc:isDead() == false then
            if not monster.can_be_ignored then
                allDead = false
                break
            end
        end
    end
    if self._isHaveEnemyInAppearEffectDelay == false and allDead == true and self._isFirstNPCCreated == true then
        local isChangeStartTime = true
        local deltaTime = 0xffff
        for i, item in ipairs(self._monsters) do
            if item.wave == self._curWave and item.created ~= true then
                if interval >= item.appear then
                    isChangeStartTime = false
                    break
                else
                    if item.appear - interval < deltaTime then
                        deltaTime = item.appear - interval
                    end
                end
            end
        end
        if deltaTime > global.npc_view_dead_blink_time then
            deltaTime = deltaTime - global.npc_view_dead_blink_time
        end
        if isChangeStartTime == true then
            self._curWaveStartTime = self._curWaveStartTime - deltaTime 
        end
    end 

    -- summoned enemy is not assigned in self._monsters, remove dead sommoned enemies
    for i, enemy in ipairs(self._enemies) do
        if enemy:isDead() == false then
            local can_be_ignored = nil
            for i, item in ipairs(self._monsters) do
                if item.npc and item.npc == enemy then
                    can_be_ignored = item.can_be_ignored
                    break
                elseif item.npc_summoned and item.npc_summoned[enemy:getId()] and item.npc_summoned[enemy:getId()].npc == enemy then
                    can_be_ignored = item.can_be_ignored
                    break
                end
            end
            if not can_be_ignored then
                allDead = false
            end
        else
            local summoned_item = nil
            local summoned = nil
            local isSummoned = false
            for _, item in ipairs(self._monsters) do
                if item.npc_summoned then
                    summoned = item.npc_summoned[enemy:getId()]
                    if summoned and summoned.npc == enemy then
                        isSummoned = true
                        summoned_item = item
                        break
                    end
                end
            end
            if isSummoned then
                if self:isInTutorial() == false and app.grid:hasActor(enemy) == true then
                    self:dispatchEvent({name = QBattleManager.NPC_DEATH_LOGGED, npc = enemy, isBoss = false})
                    self:dispatchEvent({name = QBattleManager.NPC_CLEANUP, npc = enemy, isBoss = false})

                    self:performWithDelay(function()
                        table.removebyvalue(self._enemies, enemy)
                    end, global.remove_npc_delay_time)

                    for _, ai in ipairs(self._aiDirector:getChildren()) do
                        if ai:getActor() == enemy then
                            self._aiDirector:removeBehaviorTree(ai)
                            break
                        end
                    end

                    app.grid:removeActor(enemy)
                    self._battleLog:addMonsterLifeSpan(enemy, self:getTime() - summoned.born_time)
                end
            end
        end
    end

    -- get current time interval since the battle created
    for i, item in ipairs(self._monsters) do
        if item.wave == self._curWave then
            local probability = item.probability
            if probability ~= nil and app:getBattleNpcProbability(self._dungeonConfig.monster_id, i) > probability * 100 then
                -- npc不生成
            elseif interval >= item.appear then
                if item.created ~= true then
                    allDead = false

                    -- create NPC
                    item.created = true
                    item.npc = app:createNpc(app:getBattleRandomNpc(self._dungeonConfig.monster_id, i, item.npc_id), {item.appear_skill, item.dead_skill}, item.dead_skill)
                    item.born_time = self:getTime()

                    if self._isFirstNPCCreated == false then
                        self._isFirstNPCCreated = true
                    end

                    if self:isInTutorial() == false then
                        local delay = 0
                        if item.appear_effect ~= nil then
                            delay = item.appear_delay or 0.3
                        end
                        -- delay to create ai if npc have appear effect 
                        self._isHaveEnemyInAppearEffectDelay = true
                        if delay == 0 then
                            item.ai = self._aiDirector:createBehaviorTree(item.npc:getAIType(), item.npc)
                            self._aiDirector:addBehaviorTree(item.ai)
                            table.insert(self._enemies, item.npc)
                            self._isHaveEnemyInAppearEffectDelay = false
                        else
                            self:performWithDelay(function()
                                if not self._ended then
                                    item.ai = self._aiDirector:createBehaviorTree(item.npc:getAIType(), item.npc)
                                    self._aiDirector:addBehaviorTree(item.ai)
                                    table.insert(self._enemies, item.npc)
                                    self._isHaveEnemyInAppearEffectDelay = false
                                end
                            end, delay)
                        end
                        item.npc.rewards = item.rewards
                        self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = item.npc, pos = {x = item.x, y = item.y}, effectId = item.appear_effect, isBoss = item.is_boss})

                        if item.appear_skill ~= nil then
                            item.npc:attack(item.npc:getSkillWithId(item.appear_skill))
                        end
                    else
                        table.insert(self._enemies, item.npc)
                        self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = item.npc, pos = {x = item.x, y = item.y}, isBoss = item.is_boss})
                    end
                    if self._isActiveDungeon == true and self._activeDungeonType == DUNGEON_TYPE.ACTIVITY_TIME and item.rewardIndex ~= nil then 
                        self._battleLog:onMonsterCreated(item.npc:getId(), item.npc:getActorID(), item.rewardIndex, q.time())
                    else
                        self._battleLog:onMonsterCreated(item.npc:getId(), item.npc:getActorID(), nil, q.time())
                    end

                else
                    if not item.npc:isDead() then
                        if not item.can_be_ignored then
                            allDead = false
                        end
                    elseif item.cleanup ~= true then
                        -- 张南：hard coding, 莫格莱尼的尸体在其生成的那波不消失，剧情需要
                        if self:isInTutorial() == false and (item.npc:getDisplayID() ~= 140302 or item.npc:getReviveCount() > 0) and not item.npc:isDoingDeadSkill() then

                            item.cleanup = true

                            self:dispatchEvent({name = QBattleManager.NPC_CLEANUP, npc = item.npc, isBoss = item.is_boss})

                            self:performWithDelay(function()
                                table.removebyvalue(self._enemies, item.npc)
                            end, global.remove_npc_delay_time)
                            self._aiDirector:removeBehaviorTree(item.ai)

                            app.grid:removeActor(item.npc)
                        end

                        if item.death_logged ~= true and self:isInTutorial() == false and (item.npc:getDisplayID() ~= 140302 or item.npc:getReviveCount() > 0) then

                            item.death_logged = true

                            self:dispatchEvent({name = QBattleManager.NPC_DEATH_LOGGED, npc = item.npc, isBoss = item.is_boss})

                            if self._isActiveDungeon == true and self._activeDungeonType == DUNGEON_TYPE.ACTIVITY_TIME and item.rewardIndex ~= nil then 
                                self._battleLog:onMonsterDead(item.npc:getId(), item.npc:getActorID(), q.time())
                            else
                                self._battleLog:onMonsterDead(item.npc:getId(), item.npc:getActorID(), q.time())
                            end
                            self._battleLog:addMonsterLifeSpan(item.npc, self:getTime() - item.born_time)
                        end
                    end
                end
            else
                allDead = false
            end
        elseif item.wave > self._curWave then
            return allDead, item.wave
        else
            -- 张南：hard coding, 莫格莱尼的尸体在下一波中消失
            if item.npc and item.npc:getDisplayID() == 140302 and item.npc:getReviveCount() > 0 then
                -- 被复活的怪物
                if not item.npc:isDead() then
                    allDead = false
                elseif item.cleanup ~= true then
                    if self:isInTutorial() == false then
                        item.cleanup = true
                    
                        self:dispatchEvent({name = QBattleManager.NPC_CLEANUP, npc = item.npc, isBoss = item.is_boss})

                        self:performWithDelay(function()
                            table.removebyvalue(self._enemies, item.npc)
                        end, global.remove_npc_delay_time)
                        self._aiDirector:removeBehaviorTree(item.ai)

                        app.grid:removeActor(item.npc)
                    end
                end
            end
        end
    end

    return allDead, nil
end

function QBattleManager:_checkHeroes()
    if self._ended then return false end

    if self:isInTutorial() == false then
        for i, hero in ipairs(self._heroes) do
            if hero:isDead() then
                table.insert(self._deadHeroes, hero)
                table.removebyvalue(self._heroes, hero)
                app.grid:removeActor(hero)
                self._aiDirector:removeBehaviorTree(hero.behaviorNode)
                self._battleLog:addHeroDeath(hero)
                self._battleLog:onHeroDead(hero:getActorID(), q.time())
                self:dispatchEvent({name = QBattleManager.HERO_CLEANUP, hero = hero})
            end
        end
    end

    return true
end

function QBattleManager:_checkEnemyHeroes()
    if self._ended or not self:isPVPMode() or self:isInTutorial() then
        return false
    end

    for i, enemy in ipairs(self._enemies) do
        if enemy:isDead() and app.grid:hasActor(enemy) == true then
            self:dispatchEvent({name = QBattleManager.NPC_DEATH_LOGGED, npc = enemy, isBoss = false})
            self:dispatchEvent({name = QBattleManager.NPC_CLEANUP, npc = enemy, isBoss = false})

            self:performWithDelay(function()
                table.removebyvalue(self._enemies, enemy)
            end, global.remove_npc_delay_time)

            for _, ai in ipairs(self._aiDirector:getChildren()) do
                if ai:getActor() == enemy then
                    self._aiDirector:removeBehaviorTree(ai)
                    break
                end
            end

            app.grid:removeActor(enemy)
        end
    end

    return true
end

function QBattleManager:_calculateWaveCount()
    if self:isPVPMode() == true then
        return 1
    end
    
    local wave = 0
    for i, item in ipairs(self._monsters) do
        if item.wave > wave then
            wave = item.wave
        end
    end
    return wave
end

function QBattleManager:getDungeonDuration()
    if self:isPVPMode() then
        if self:isInArena() then
            local config = QStaticDatabase:sharedDatabase():getConfiguration()
            local duration = config.ARENA_DURATION and config.ARENA_DURATION.value or 90
            return duration or 90
        elseif self:isInSunwell() then
            local config = QStaticDatabase:sharedDatabase():getConfiguration()
            local duration = config.SUNWELL_BATTLE_TIME and config.SUNWELL_BATTLE_TIME.value or 90
            return duration or 90
        end
    end

    if self._dungeonConfig.duration == nil then
        return 600
    else
        return self._dungeonConfig.duration
    end
end

function QBattleManager:addDamageHistory(actorUDID, damageValue, skillIdOrBuffId)
    if actorUDID == nil or damageValue == nil then
        return
    end

    table.insert(self._damageHistory, {udid = actorUDID, value = damageValue, from = skillIdOrBuffId})  

    for _, hero in ipairs(self._heroes) do
        if hero:getUDID() == actorUDID then
            local skill = hero:getSkills()[skillIdOrBuffId]
            if skill then
                self._battleLog:setLastHeroAttack(hero, skill)
            end
            break
        end
    end

end

function QBattleManager:addTreatHistory(actorUDID, treatValue, skillIdOrBuffId)
    if actorUDID == nil or treatValue == nil then
        return
    end

    table.insert(self._treatHistory, {udid = actorUDID, value = treatValue, from = skillIdOrBuffId})
end

function QBattleManager:onUseSkill(actor, skill)
    if actor == nil or skill == nil then
        return
    end

    for _, hero in ipairs(self._heroes) do
        if actor == hero then
            self._battleLog:addHeroSkillCast(actor, skill)
            break
        end
    end
end

function QBattleManager:getDamageValueForEachActor()
    local damageValues = {}
    for _, historyItem in ipairs(self._damageHistory) do
        if damageValues[historyItem.udid] == nil then
            damageValues[historyItem.udid] = historyItem.value
        else
            damageValues[historyItem.udid] = damageValues[historyItem.udid] + historyItem.value
        end
    end
    return damageValues
end

function QBattleManager:getTreatValueForEachActor()
    local treatValues = {}
    for _, historyItem in ipairs(self._treatHistory) do
        if treatValues[historyItem.udid] == nil then
            treatValues[historyItem.udid] = historyItem.value
        else
            treatValues[historyItem.udid] = treatValues[historyItem.udid] + historyItem.value
        end
    end
    return treatValues
end

function QBattleManager:onActorUseManualSkill(actor, skill, auto)
    if actor == nil or skill == nil then
        return
    end

    self:dispatchEvent({name = QBattleManager.USE_MANUAL_SKILL, actor = actor, skill = skill, auto = auto})
end

function QBattleManager:addTrapDirector(director)
    if director == nil then
        return
    end

    for _, trapDirector in ipairs(self._trapDirectors) do
        if trapDirector == director then
            return
        end
    end

    table.insert(self._trapDirectors, director)
end

function QBattleManager:getTrapDirectors()
    return self._trapDirectors
end

function QBattleManager:addBullet(bullet)
    table.insert(self._bullets, bullet)
end

function QBattleManager:addLaser(laser)
    table.insert(self._lasers, laser)
end

function QBattleManager:_onBulletTimeEvent(event)
    if event.name == QNotificationCenter.EVENT_BULLET_TIME_TURN_ON then

        self._bulletTimeReferenceCount = self._bulletTimeReferenceCount + 1

        local heroes = self:getHeroes()
        local enemies = self:getEnemies()

        for _, hero in ipairs(heroes) do
            hero:inBulletTime(true)
            local view = app.scene:getActorViewFromModel(hero)
            if view and view.setAnimationScale then
                view:setAnimationScale(0, "bullet_time")
            end
        end
        for _, enemy in ipairs(enemies) do
            enemy:inBulletTime(true)
            local view = app.scene:getActorViewFromModel(enemy)
            if view and view.setAnimationScale then
                view:setAnimationScale(0, "bullet_time")
            end
        end

        -- hero will not stop animation when it is playing manual skill
        self._exceptActor = {}
        local exceptActor = {}
        for _, hero in ipairs(heroes) do
            if hero:isDead() == false then
                for _, skill in ipairs(hero:getExecutingSkills()) do
                    if skill ~= nil and skill:getSkillType() == QSkill.MANUAL then
                        hero:inBulletTime(false)
                        local actorView = app.scene:getActorViewFromModel(hero)
                        table.insert(exceptActor, actorView)
                        table.insert(self._exceptActor, hero)
                        break
                    end
                end
            end
        end
        if self:isPVPMode() then
            for _, hero in ipairs(enemies) do
                if hero:isDead() == false then
                    for _, skill in ipairs(hero:getExecutingSkills()) do
                        if skill ~= nil and skill:getSkillType() == QSkill.MANUAL then
                            hero:inBulletTime(false)
                            local actorView = app.scene:getActorViewFromModel(hero)
                            table.insert(exceptActor, actorView)
                            table.insert(self._exceptActor, hero)
                            break
                        end
                    end
                end
            end
        end

        for _, view in ipairs(exceptActor) do
            if view.setAnimationScale then
                view:setAnimationScale(1, "bullet_time")
            end
        end
        QSkeletonViewController.sharedSkeletonViewController():setAllEffectsAnimationScale(0)

        if self._bulletTimeReferenceCount == 1 then
            QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QNotificationCenter.EVENT_BULLET_TIME_TURN_START})
        end
        
    elseif event.name == QNotificationCenter.EVENT_BULLET_TIME_TURN_OFF then

        self._bulletTimeReferenceCount = self._bulletTimeReferenceCount - 1

        if self._bulletTimeReferenceCount == 0 then

            local heroes = self:getHeroes()
            local enemies = self:getEnemies()

            for _, hero in ipairs(heroes) do
                hero:inBulletTime(false)
                local view = app.scene:getActorViewFromModel(hero)
                if view and view.setAnimationScale then
                    view:setAnimationScale(1.0, "bullet_time")
                end
            end
            for _, enemy in ipairs(enemies) do
                enemy:inBulletTime(false)
                local view = app.scene:getActorViewFromModel(enemy)
                if view and view.setAnimationScale then
                    view:setAnimationScale(1.0, "bullet_time")
                end
            end

            self._exceptActor = {}

            QSkeletonViewController.sharedSkeletonViewController():resetAllEffectsAnimationScale()
            QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QNotificationCenter.EVENT_BULLET_TIME_TURN_FINISH})
        end
    end
end

function QBattleManager:isInBulletTime()
    if self._bulletTimeReferenceCount > 0 then
        return true
    else
        return false
    end
end

function QBattleManager:reloadActorAi(actor)
    if actor == nil or self._aiDirector == nil then
        return
    end

    if actor:isDead() == true then
        return
    end

    local children = self._aiDirector:getChildren()
    for _, aiTree in ipairs(children) do
        if aiTree:getActor() == actor then
            self._aiDirector:removeBehaviorTree(aiTree)
            break
        end
    end

    local ai = self._aiDirector:createBehaviorTree(actor:getAIType(), actor)
    self._aiDirector:addBehaviorTree(ai)
    if actor:getType() == ACTOR_TYPES.HERO then
        actor.behaviorNode = ai
    else
        for _, monster in ipairs(self._monsters) do
            if monster.created == true and monster.npc == actor then
                monster.ai = ai
                break
            end
        end
    end
    
end

function QBattleManager:replaceActorAI(actor, aitype)
    if actor == nil or self._aiDirector == nil then
        return
    end

    if actor:isDead() == true then
        return
    end

    actor:unlockTarget()

    local children = self._aiDirector:getChildren()
    for _, aiTree in ipairs(children) do
        if aiTree:getActor() == actor then
            self._aiDirector:removeBehaviorTree(aiTree)
            break
        end
    end

    if aitype == nil then aitype = actor:getAIType() end
    local ai = self._aiDirector:createBehaviorTree(aitype, actor)
    self._aiDirector:addBehaviorTree(ai)
    if actor:getType() == ACTOR_TYPES.HERO then
        actor.behaviorNode = ai
    else
        for _, monster in ipairs(self._monsters) do
            if monster.created == true and monster.npc == actor then
                monster.ai = ai
                break
            end
        end
    end
end

function QBattleManager:isWaitingForStart()
    if self._curWave == 0 or self._curWaveStartTime == 0 then
        return true
    end

    if self._curWave == 1 and self._curWaveStartTime > self:getTime() then
        return true
    end

    return false
end

function QBattleManager:getCurrentWave()
    return self._curWave
end

function QBattleManager:getNextWave()
    return self._nextWave
end

function QBattleManager:summonGhosts(ghost_id, summoner, life_span, screen_pos)
    if ghost_id == nil or summoner == nil then
        return
    end

    local heroes = self:getHeroes()
    for _, hero in ipairs(heroes) do
        if hero == summoner then
            local ghost = app:createNpc(ghost_id)
            ghost:setType(ACTOR_TYPES.HERO_NPC)
            ghost:resetStateForBattle()
            local ai = self._aiDirector:createBehaviorTree(ghost:getAIType(), ghost)
            self._aiDirector:addBehaviorTree(ai)
            table.insert(self._heroGhosts, {actor = ghost, ai = ai, life_span = life_span, life_countdown = life_span})

            self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = ghost, screen_pos = screen_pos, is_hero = true})
            return ghost
        end
    end

    local enemies = self:getEnemies()
    for _, enemy in ipairs(enemies) do
        if enemy == summoner then
            local ghost = app:createNpc(ghost_id)
            ai = self._aiDirector:createBehaviorTree(ghost:getAIType(), ghost)
            self._aiDirector:addBehaviorTree(ai)
            table.insert(self._enemyGhosts, {actor = ghost, ai = ai, life_span = life_span, life_countdown = life_span})

            self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = ghost, screen_pos = screen_pos})
            return ghost
        end
    end
end

function QBattleManager:isGhost(actor)
    for _, ghost in ipairs(self._heroGhosts) do 
        if actor == ghost.actor then
            return true
        end
    end
    for _, ghost in ipairs(self._enemyGhosts) do 
        if actor == ghost.actor then
            return true
        end
    end
    return false
end

function QBattleManager:summonMonsters(wave, summoner)
    -- normal wave monsters can not be summoned
    if type(wave) ~= number and wave >= 0 then
        return 
    end

    local monsters = {}
    for _, item in ipairs(self._monsters) do
        if item.wave == wave then
            table.insert(monsters, item)

            -- create NPC
            local npc = app:createNpc(app:getBattleRandomNpc(self._dungeonConfig.monster_id, i, item.npc_id), {item.appear_skill, item.dead_skill}, item.dead_skill)
            if item.npc_summoned == nil then
                item.npc_summoned = {}
            end
            item.npc_summoned[npc:getId()] = {npc = npc, born_time = self:getTime()}

            if self._isFirstNPCCreated == false then
                self._isFirstNPCCreated = true
            end

            local screen_pos = {}
            if item.relative then
                local offset_x = 0
                if item.offset_x then offset_x = item.offset_x end
                local offset_y = 0
                if item.offset_y then offset_y = item.offset_y end
                screen_pos = {x = summoner:getPosition().x + offset_x, y = summoner:getPosition().y + offset_y}
            else
                screen_pos = nil
            end 
            if self:isInTutorial() == false then
                local delay = 0
                if item.appear_effect ~= nil then
                    delay = item.appear_delay or 0.3
                end
                -- delay to create ai if npc have appear effect 
                self:performWithDelay(function()
                    ai = self._aiDirector:createBehaviorTree(npc:getAIType(), npc)
                    self._aiDirector:addBehaviorTree(ai)
                    table.insert(self._enemies, npc)
                end, delay)

                self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = npc, screen_pos = screen_pos, pos = {x = item.x, y = item.y}, effectId = item.appear_effect, isBoss = item.is_boss})

                if item.appear_skill ~= nil then
                    npc:attack(npc:getSkillWithId(item.appear_skill))
                end
            else
                table.insert(self._enemies, npc)
                self:dispatchEvent({name = QBattleManager.NPC_CREATED, npc = npc, screen_pos = screen_pos, pos = {x = item.x, y = item.y}, isBoss = item.is_boss})
            end
        end
    end
end

function QBattleManager:isBoss(npc)
    if npc == nil or npc:getType() ~= ACTOR_TYPES.NPC then
        return false
    end

    for _, item in ipairs(self._monsters) do
        if item.npc == npc then
            if item.is_boss == true then
                return true
            else
                return false
            end
            break
        end
    end
    return false
end

function QBattleManager:performWithDelay(func, delay, actor, pauseBetweenWave)
    if func == nil or delay < 0 then
        assert(false, "invalid args to call QBattleManager:performWithDelay")
        return nil
    end

    local handlerId = self._nextSchedulerHandletId
    table.insert(self._delaySchedulers, {handlerId = handlerId, delay = delay, func = func, actor = actor, pauseBetweenWave = pauseBetweenWave})
    self._nextSchedulerHandletId = handlerId + 1
    return handlerId
end

function QBattleManager:removePerformWithHandler(handlerId)
    if handlerId <= 0 then
        return
    end

    local index = 0
    for i, schedulerInfo in ipairs(self._delaySchedulers) do
        if schedulerInfo.handlerId == handlerId then
            index = i
            break
        end
    end

    if index > 0 then
        table.remove(self._delaySchedulers, index)
    end
end

function QBattleManager:getBattleLog()
    return self._battleLog:getBattleLog()
end

function QBattleManager:isAutoNextWave()
    for _, hero in ipairs(self._heroes) do
        if hero:isForceAuto() then
            return true
        end
    end

    return false
end

function QBattleManager:checkNormalAttack(display_id, skill_name)
    local id = display_id .. skill_name
    local record = self._normalAttackRecord[id]

    if record == nil then
        return true
    elseif record.allow_time <= self:getTime() then
        return true
    end

    return false
end

function QBattleManager:registerNormalAttack(display_id, skill_name)
    local id = display_id .. skill_name
    self._normalAttackRecord[id] = {allow_time = self:getTime() + math.random(7, 10) / 100}
end

function QBattleManager:_checkStartCountDown()
    if self._paused == false and self._ended == false and self._pauseBetweenWaves == false and self._startCountDown == true then 
        self._battleLog:setStartCountDown(q.time())
    end

    
end

function QBattleManager:_checkEndCountDown()
    if self._paused == true or self._ended == true or self._pauseBetweenWaves == true or self._startCountDown == false then 
        self._battleLog:setEndCountDown(q.time())
    end
end

function QBattleManager:setTimeGear(time_gear)
	self._timeGear = time_gear

    self:dispatchEvent({name = QBattleManager.ON_SET_TIME_GEAR, time_gear = time_gear})
end

function QBattleManager:getTimeGear()
	return self._timeGear
end

function QBattleManager:getDamageCoefficient()
    return self._damageCoefficient
end

return QBattleManager
