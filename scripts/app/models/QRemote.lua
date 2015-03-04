--[[
    远程数据
]]

local QModelBase = import(".QModelBase")
local QRemote = class("QRemote", QModelBase)

local QTeam = import("..utils.QTeam")
local QFlag = import("..utils.QFlag")
local QItems = import("..utils.QItems")
local QTops = import("..utils.QTops")
local QTask = import("..utils.QTask")
local QMails = import("..utils.QMails")
local QArena = import("..utils.QArena")
local QAchieveUtils = import("..utils.QAchieveUtils")
local QUserProp = import("..utils.QUserProp")
local QInstance = import("..utils.QInstance")
local QActivityInstance = import("..utils.QActivityInstance")
local QHerosUtils = import("..utils.QHerosUtils")
local QUIViewController = import("..ui.QUIViewController")
local QShop = import("..utils.QShop")
local QSunWell = import("..utils.QSunWell")
local QDailySignIn = import("..utils.QDailySignIn")

-- 定义属性
QRemote.schema = clone(cc.mvc.ModelBase.schema)
QRemote.schema["name"]           = {"string"} -- 字符串类型，没有默认值

-- 更新事件
QRemote.USER_UPDATE_EVENT = "USER_UPDATE_EVENT"
QRemote.DUNGEON_UPDATE_EVENT = "DUNGEON_UPDATE_EVENT"
QRemote.ACTIVITY_DUNGEON_UPDATE_EVENT = "ACTIVITY_DUNGEON_UPDATE_EVENT"
QRemote.HERO_UPDATE_EVENT = "HERO_UPDATE_EVENT"
QRemote.TEAMS_UPDATE_EVENT = "TEAMS_UPDATE_EVENT"
QRemote.ITEMS_UPDATE_EVENT = "ITEMS_UPDATE_EVENT"
QRemote.TOPS_UPDATE_EVENT = "TOPS_UPDATE_EVENT"
QRemote.ZONES_UPDATE_EVENT = "ZONES_UPDATE_EVENT"
QRemote.PKUSERLIST_UPDATE_EVENT = "PKUSERLIST_UPDATE_EVENT"
QRemote.TASK_UPDATE_EVENT = "TASK_UPDATE_EVENT"

function QRemote:ctor()
    QRemote.super.ctor(self)
    self.instance = QInstance.new()
    self.activityInstance = QActivityInstance.new()
    self.herosUtil = QHerosUtils.new()
    self.teams = QTeam.new({})
    self.items = QItems.new()
    self.tops = QTops.new()
    self.flag = QFlag.new()
    self.task = QTask.new()
    self.achieve = QAchieveUtils.new()
    self.user = QUserProp.new()
    self.stores = QShop.new()
    self.daily = QDailySignIn.new()
    self.mails = QMails.new()
    self.arena = QArena.new()
    self.sunWell = QSunWell.new()

    self.serverTime = nil
    self.serverResTime = nil

    self.arenaRank = nil -- Top 50 arena rank refreshes regularly
    self.allFightCapacityRank = nil
    self.teamFightCapacityRank = nil
    self.heroStarRank = nil
    self.allStarRank = nil
    self.eliteStarRank = nil
    self.normalStarRank = nil
    self.achievementPointRank = nil
end

function QRemote:updateData(data)
    --用户信息更新
    if self.user.level ~= nil and data.level ~= nil and self.user.level ~= data.level then
        self.oldUser = clone(self.user)
    end
    if self.user:update(data) == true then
        self:dispatchEvent({name = QRemote.USER_UPDATE_EVENT})
        printInfo("self:dispatchEvent({name = QRemote.USER_UPDATE_EVENT})")
    end

    if data.serverInfos then
        self.serverInfos = data.serverInfos
    end

    --副本数据更新
    if data.dungeons then
        self.instance:updateInstanceInfo(data.dungeons)
        self:dispatchEvent({name = QRemote.DUNGEON_UPDATE_EVENT})
        printInfo("self:dispatchEvent({name = QRemote.DUNGEON_UPDATE_EVENT})")

        if self.activityInstance:updateActivityInfo(data.dungeons) == true then
            self:dispatchEvent({name = QRemote.ACTIVITY_DUNGEON_UPDATE_EVENT})
            printInfo("self:dispatchEvent({name = QRemote.ACTIVITY_DUNGEON_UPDATE_EVENT})")
        end
    end

    --更新副本的星星宝箱数据
    if data.mapStars then
        self.instance:updateDropBoxInfoById(data.mapStars)
    end

    -- 英雄数据更新
    if data.heros or data.addHeros then
        if data.heros then
            local heros = {}
            for _,value in pairs(data.heros) do
                heros[value.actorId] = value
            end
            self.herosUtil:updateHeros(heros)
        end
        if data.addHeros then
            local heros = {}
            local actorIds = {}
            for _,value in pairs(data.addHeros) do
                heros[value.actorId] = value
                table.insert(actorIds, value.actorId)
            end
            self.herosUtil:updateHeros(heros)
            self.teams:joinHero(actorIds)
        end
        self:dispatchEvent({name = QRemote.HERO_UPDATE_EVENT})
        printInfo("self:dispatchEvent({name = QRemote.HERO_UPDATE_EVENT})")
    end

    --物品数据更新
    if data.items then
        self.items:setItems(data.items)
        self:dispatchEvent({name = QRemote.ITEMS_UPDATE_EVENT})
        printInfo("self:dispatchEvent({name = QRemote.ITEMS_UPDATE_EVENT})")
    end

    --军衔排行数据更新
    if data.top then
        self.tops:setTopData(data.top)
        self:dispatchEvent({name = QRemote.TOPS_UPDATE_EVENT})
        printInfo("self:dispatchEvent({name = QRemote.TOPS_UPDATE_EVENT})")
    end

    if data.zones then
        self.zones = data.zones
        self:dispatchEvent({name = QRemote.ZONES_UPDATE_EVENT})
        printInfo("self:dispatchEvent({name = QRemote.ZONES_UPDATE_EVENT})")
    end

    -- 邮件
    if data.mails then
        self.mails:updateMaliData(data)
    end

    --任务更新
    if data.dailyTaskCompleted then
        self.task:updateComplete(data.dailyTaskCompleted)
        self:dispatchEvent({name = QRemote.TASK_UPDATE_EVENT})
        printInfo("self:dispatchEvent({name = QRemote.TASK_UPDATE_EVENT})")
    end

    --成就更新
    if data.achievements then
        self.achieve:updateComplete(data.achievements)
    end
    
    --商店更新
    if data.shops then
        self.stores:updateComplete(data.shops)
        printInfo("self:dispatchEvent({name = QRemote.STORES_UPDATE_EVENT})")
    end
    
    if data.checkin then
        self.daily:updateComplete(data.checkin, data.checkinAt)
        printInfo("self:dispatchEvent({name = QRemote.DAILYSIGN_UPDATE_EVENT})")
    end
    
    if data.addupCheckinAward or data.addupCheckinCount then
        self.daily:updateAddUpSignInNum(data.addupCheckinCount, data.addupCheckinAward)
        printInfo("self:dispatchEvent({name = QRemote.ADDUP_DAILYSIGN_UPDATE_EVENT})")
    end

    --太阳井关卡信息
    if data.sunwellDungeons then
        self.sunWell:setInstanceInfo(data.sunwellDungeons)
    end

    if data.selfSunwellHeros then
        self.sunWell:updateHeroInfo(data.selfSunwellHeros)
    end

    if data.sunwellResetAt ~= nil or data.sunwellResetCount ~= nil then
        self.sunWell:updateCount(data.sunwellResetCount, data.sunwellResetAt)
    end

    if data.sunwellLastFightDungeonIndex ~= nil then
        self.sunWell:setNeedPass(data.sunwellLastFightDungeonIndex + 1)
    end

    if data.sunwellLuckydrawCompletedIndex ~= nil then
        self.sunWell:setSunwellLuckyDraw(data.sunwellLuckydrawCompletedIndex)
    end
end

return QRemote
