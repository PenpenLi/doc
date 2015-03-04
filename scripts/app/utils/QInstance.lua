--
-- Author: wkwang
-- Date: 2014-08-14 15:26:46
-- 副本数据管理


local QInstance = class("QInstance")
local QStaticDatabase = import("..controllers.QStaticDatabase")

local QUIDialogUnlockSucceed = import("..ui.dialogs.QUIDialogUnlockSucceed")

function QInstance:ctor(options)
	self.passInfo = {}
	self.normalInfo = {}
	self.eliteInfo = {}

	self.isNewElite = nil
end

--设置副本通过信息
-- "userId": "TEST005",
-- "dungeonId": "1-1-1",
-- "dungeonType": 1,
-- "firstPass": 1399635461937,
-- "lastPass": 1399635461937,
-- "todayPass": 32,
-- "star" : 3     
function QInstance:updateInstanceInfo(info)
	self.passCountInfo = {}
	self.passCountInfo["c_todayNormalPass"] = 0
	self.passCountInfo["c_todayElitePass"] = 0
	self.passCountInfo["c_allNormalPass"] = 0
	self.passCountInfo["c_allStarNormalPass"] = 0
	self.passCountInfo["c_allStarElitePass"] = 0
	self.passCountInfo["c_allStarCount"] = 0

	self._refreshTime = q.refreshTime(global.freshTime.map_freshTime) * 1000

	self.config = QStaticDatabase:sharedDatabase():getMaps()
	
	info = info or {}
	for id,value in pairs(info) do
		self.passInfo[value.id] = value
	end
	if #self.normalInfo == 0 or #self.eliteInfo == 0 then
		self.normalInfo = {}
		self.eliteInfo = {}
		local total = table.nums(self.config)
		for i=1,total,1 do
			local config = self.config[tostring(i)]
			config.unlock_team_level = tonumber(config.unlock_team_level)
			if config.dungeon_type == DUNGEON_TYPE.ELITE then
				table.insert(self.eliteInfo, config)
			elseif config.dungeon_type == DUNGEON_TYPE.NORMAL then
				table.insert(self.normalInfo, config)
			end
		end
	end
	self:mergeDungeonInfo(self.normalInfo)
	self:mergeDungeonInfo(self.eliteInfo)

	--检查是否解锁精英关卡
--  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
--  local unlockTutorial = app.tip:getUnlockTutorial()
--	if table.nums(info) > 0 then
--		if self.isNewElite == nil then
--			self.isNewElite = self.eliteInfo[1].isLock
--		elseif self.isNewElite == false and self.eliteInfo[1].isLock == true then
--			self.isNewElite = self.eliteInfo[1].isLock
--	    app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_ELITECOPY)
--		end
--	end

	-- remote.teams:unlockTeamForInstance()
	remote.user:update(self.passCountInfo)
end

function QInstance:mergeDungeonInfo(tbl)
	local instanceId
	local instanceIndex = 0
	local dungeonIndex = 0
	local perDungeon = nil
	for _,config in pairs(tbl) do
		if self.passInfo ~= nil then
			for _,value in pairs(self.passInfo) do
				if config.dungeon_id == value.id then
					--如果新通关则标志为最新通关
					if config.info == nil then
						self:setIsNew(true)
					end
					config.info = value
					--计算通关统计
					self:countPassInfo(config)
					break
				end
			end
		end
		if instanceId == nil or instanceId ~= config.instance_id then
			instanceId = config.instance_id
			instanceIndex = instanceIndex + 1
			dungeonIndex = 1
		else
			dungeonIndex = dungeonIndex + 1
		end

		if config.unlock_dungeon_id == nil and perDungeon ~= nil and config.dungeon_type == perDungeon.dungeon_type then
			config.unlock_dungeon_id = perDungeon.dungeon_id
		end
		config.number = instanceIndex.."-"..dungeonIndex
		config.isLock = self:checkIsPassByDungeonId(config.unlock_dungeon_id)
		perDungeon = config
	end
end

--计算需要挑战的副本
function QInstance:countNeedPassForType(type)
	local infoTable
	if type == DUNGEON_TYPE.NORMAL then
		infoTable = self.normalInfo
	elseif type == DUNGEON_TYPE.ELITE then
		infoTable = self.eliteInfo
	end
	if infoTable == nil then return end

	local lastPassId = nil
	for _,value in pairs(infoTable) do
		if value.dungeon_type == type then 
			if value.info ~= nil then
				lastPassId = value.dungeon_id
			end
		end
	end

	for _,value in pairs(infoTable) do
		if value.dungeon_type == type then 
			if (value.info == nil or value.info.star == 0) and (value.unlock_team_level or 0) <= remote.user.level then
				return value.dungeon_id
			end
		end
	end
	return lastPassId
end

--根据ID获取该关卡的通关信息
function QInstance:getPassInfoForDungeonID(id)
	for _,value in pairs(self.passInfo) do
		if id == value.id then
			return value
		end
	end
end

--根据ID获取该关卡之后的关卡
function QInstance:getNextIDForDungeonID(id, type)
	local isFind = false
	local findID = nil
	local infoTable
	if type == DUNGEON_TYPE.NORMAL then
		infoTable = self.normalInfo
	elseif type == DUNGEON_TYPE.ELITE then
		infoTable = self.eliteInfo
	end
	if infoTable == nil then return id end
	for _,value in pairs(infoTable) do
    if isFind == true then
      return value.dungeon_id
    end
		if value.dungeon_id == id then 
			isFind = true
		end
	end
	return id
end

-- 获取所有已解锁副本集合
-- {
-- 	id:"instanceId",
-- 	data:
-- 	{
-- 		instance_id: "map1_1",
-- 		instance_name: "哀嚎上",
-- 		instance_icon: "icon/head/anacondra.png",
-- 		dungeon_id: "wailing_caverns_1",
-- 		dungeon_type: "1",
-- 		attack_num: 99,
-- 		dungeon_isboss: false,
-- 		dungeon_icon: "icon/head/ectoplasm.png",
-- 		file: "ccb/Widget_EliteMap.ccbi",
-- 		info:
-- 		{
-- 			"userId": "TEST005",
--             "dungeonId": "1-1-1",
--             "dungeonType": 1,
--             "firstPass": 1399635461937,
--             "dungeonDifficulty": 1,
--             "lastPass": 1399635461937,
--             "todayPass": 32
-- 		}
-- 	}
-- }
function QInstance:getInstancesWithUnlockAndType(type)
	local tbl = {}
	local instanceId
	local instanceLock
	-- local instanceIndex = 0
	-- local dungeonIndex = 0
	local tblValue = {}
	local infoTable
	if type == DUNGEON_TYPE.NORMAL then
		infoTable = self.normalInfo
	elseif type == DUNGEON_TYPE.ELITE then
		infoTable = self.eliteInfo
	end
	if infoTable == nil then return end
	for _,value in pairs(infoTable) do
		if value.dungeon_type == type then
			if instanceId == nil or instanceId ~= value.instance_id then
				tblValue = {}
				tbl[#tbl+1] = tblValue
				-- instanceIndex = instanceIndex + 1
				-- dungeonIndex = 1
				instanceId = value.instance_id
				instanceLock = value.isLock or false
				tblValue.id = instanceId
				tblValue.data = {}
			end 
			if instanceLock == true then
				-- value.number = tostring(instanceIndex).."-"..dungeonIndex
				-- dungeonIndex = dungeonIndex + 1
				table.insert(tblValue.data, value)
			else
				tbl[#tbl] = nil
				break
			end
		end
	end
	return tbl
end

--根据ID查询副本信息
function QInstance:getInstancesById(id)
	local list = {}
	for _,value in pairs(self.normalInfo) do
		if id == value.instance_id then
			table.insert(list, value)
		end
	end
	for _,value in pairs(self.eliteInfo) do
		if id == value.instance_id then
			table.insert(list, value)
		end
	end
	return list
end

--根据ID查询关卡信息
function QInstance:getDungeonById(id)
	for _,value in pairs(self.normalInfo) do
		if id == value.dungeon_id then
			return value
		end
	end
	for _,value in pairs(self.eliteInfo) do
		if id == value.dungeon_id then
			return value
		end
	end
	return nil
end

--检查关卡是否显示星星信息
function QInstance:checkDungeonIsShowStar(dungeonId)
	local dungeonInfo = self:getDungeonById(dungeonId)
	if dungeonInfo == nil then
		return false
	end
	local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
	if globalConfig.DUNGEON_STAR_SHOW ~= nil and globalConfig.DUNGEON_STAR_SHOW.value ~= nil then
		local starDungeonConfig = self:getDungeonById(globalConfig.DUNGEON_STAR_SHOW.value)
		if starDungeonConfig ~= nil and starDungeonConfig.id > dungeonInfo.id then
			return false
		end
	end
	return true
end

--[[
	更新副本宝箱信息
]]
function QInstance:updateDropBoxInfoById(mapStars)
	for id,value in pairs(mapStars) do
	    self:setDropBoxInfoById(value.mapId,value)
	end
end

--[[
	设置副本领取宝箱信息
]]
function QInstance:setDropBoxInfoById(id,data)
	if self._dropInfo == nil then 
		self._dropInfo = {}
	end
	self._dropInfo[id] = data
end

--[[
	根据副本ID查询星星宝箱掉落信息
]]
function QInstance:getDropBoxInfoById(id,callBack)
	if self._dropInfo == nil then 
		self._dropInfo = {}
	end
	callBack(self._dropInfo[id] or {})
end

--[[
	根据物品ID查询掉落信息
]]
function QInstance:getDropInfoByItemId(id, type)
	local dungeonInfo = {}
	local database = QStaticDatabase:sharedDatabase()

	if type == DUNGEON_TYPE.NORMAL or type == DUNGEON_TYPE.ALL then
		for _,value in pairs(self.normalInfo) do
			local dungeonConfig = database:getDungeonConfigByID(value.dungeon_id)
			if dungeonConfig.drop_item ~= nil and string.find(dungeonConfig.drop_item,tostring(id)) ~= nil then
				table.insert(dungeonInfo, {map = value, dungeon = dungeonConfig})
			end
		end
	end
	if type == DUNGEON_TYPE.ELITE or type == DUNGEON_TYPE.ALL then
		for _,value in pairs(self.eliteInfo) do
			local dungeonConfig = database:getDungeonConfigByID(value.dungeon_id)
			if dungeonConfig.drop_item ~= nil and string.find(dungeonConfig.drop_item,tostring(id)) ~= nil then
				table.insert(dungeonInfo, {map = value, dungeon = dungeonConfig})
			end
		end
	end
	return dungeonInfo
end

--检查一组副本ID是否通过 "id1,id2,id3"
function QInstance:checkIsPassByDungeonId(id)
	if id == nil then return true end
	local ids = string.split(id, ",")
	local isFind = false
	for _,id in pairs(ids) do 
		isFind = false
		for _,value in pairs(self.passInfo) do
			if id == value.id and value.lastPassAt > 0 then
				isFind = true
				break
			end
		end
		if isFind == false then
			return false
		end
	end
	return true
end

--设置或获取最近新通关副本
function QInstance:setIsNew(b)
	app:setObject("local_data_isFristBattle",b)
end

function QInstance:getIsNew()
	return app:getObject("local_data_isFristBattle") or false
end

--get dungeon today fight count by dungeon id
function QInstance:getFightCountBydungeonId(dungeonId)
	local todayPass = 0
	local info = self:getDungeonById(dungeonId)
	if info.info ~= nil and info.info.todayPass ~= nil then
		if info.info.lastPassAt ~= nil and q.refreshTime(global.freshTime.map_freshTime) <= (info.info.lastPassAt/1000) then
			todayPass = info.info.todayPass
		end
	end
	return info.attack_num - todayPass
end

--计算副本的通关统计
-- self._todayNormalPass 今天普通关卡通关次数
-- self._todayElitePass 今天精英关卡通关次数
-- self._allStarNormalPass 所有三星的普通关卡
-- self._allStarElitePass 所有三星的经验关卡
-- self._allStarCount 所有星星数量
function QInstance:countPassInfo(config)
	if config.info ~= nil then
		local passCount = 0
		local starCount = 0
		if config.info.lastPassAt > self._refreshTime then
			passCount = config.info.todayPass + (config.info.todayReset or 0) * config.attack_num
		end
		if config.info.star > 2 then
			starCount = 1
		end

		self.passCountInfo["c_allStarCount"] = self.passCountInfo["c_allStarCount"] + config.info.star
		if config.dungeon_type == DUNGEON_TYPE.ELITE then
			self.passCountInfo["c_todayElitePass"] = self.passCountInfo["c_todayElitePass"] + passCount
			self.passCountInfo["c_allStarElitePass"] = self.passCountInfo["c_allStarElitePass"] + starCount
		elseif config.dungeon_type == DUNGEON_TYPE.NORMAL then
			self.passCountInfo["c_todayNormalPass"] = self.passCountInfo["c_todayNormalPass"] + passCount
			self.passCountInfo["c_allStarNormalPass"] = self.passCountInfo["c_allStarNormalPass"] + starCount
		end
	end
end

-- @qinyuanji
-- get lastpass date of dungeon
function QInstance:dungeonLastPassAt(dungeon_id)
	if self.passInfo ~= nil then
		for _, v in pairs(self.passInfo) do 
			if v.id == dungeon_id and v.lastPassAt > 0 then
				return v.lastPassAt
			end
		end
	end

	return -1
end

return QInstance
