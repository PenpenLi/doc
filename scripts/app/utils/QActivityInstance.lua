--
-- Author: wkwang
-- Date: 2014-11-28 16:03:48
-- 活动副本
--
local QActivityInstance = class("QActivityInstance")
local QStaticDatabase = import("..controllers.QStaticDatabase")

function QActivityInstance:ctor(options)
	self._activityConfig = {}
end

--初始化配置数据
function QActivityInstance:init()
	self.config = QStaticDatabase:sharedDatabase():getMaps()
	local total = table.nums(self.config)
	for i=1,total,1 do
		local config = self.config[tostring(i)]
		if config ~= nil then
			config.unlock_team_level = tonumber(config.unlock_team_level)
			if config.dungeon_type == DUNGEON_TYPE.ACTIVITY_TIME or config.dungeon_type == DUNGEON_TYPE.ACTIVITY_CHALLENGE then
				table.insert(self._activityConfig, config)
			end
		end
	end
end

--更新活动本信息
function QActivityInstance:updateActivityInfo(info)
	if self._passInfo == nil then self._passInfo = {} end
	info = info or {}
	local isUpdate = false
	for id,value in pairs(info) do
		if self:getDungeonById(value.id) ~= nil then
			self._passInfo[value.id] = value
			isUpdate = true
		end
	end
	return isUpdate
end

--获取关卡通关信息dungeonId
function QActivityInstance:getPassInfoById(dungeonId)
	if self._passInfo == nil then self._passInfo = {} end
	for _,value in pairs(self._passInfo) do
		if value.id == dungeonId then
			return value
		end
	end
	return nil
end

--获取配置通过instanceId
function QActivityInstance:getInstanceListById(id)
	local list = {}
	for _,value in pairs(self._activityConfig) do
		if value.instance_id == id then
			table.insert(list, value)
		end
	end
	return list
end

--获取配置通过dungeonId
function QActivityInstance:getDungeonById(dungeonId)
	for _,value in pairs(self._activityConfig) do
		if value.dungeon_id == dungeonId then
			return value
		end
	end
	return nil
end

--获取副本集合名称通过类型
function QActivityInstance:getInstanceGroupNameByType(type)
	local name = ""
	if type == 3 then
		name = "时空传送器"
	elseif type == 4 then
		name = "黄金挑战"		
	end
	return name
end

--获取某类型地图的关卡是否开启
function QActivityInstance:checkIsOpenForInstanceId(instanceId)
	local list = self:getInstanceListById(instanceId)
	if #list > 0 then
		return self:checkIsOpenForDungeonId(list[1].dungeon_id)
	end
	return true
end

--获取某关卡是否开启
function QActivityInstance:checkIsOpenForDungeonId(dungeonId)
	local dungeonConfig = QStaticDatabase:sharedDatabase():getDungeonConfigByID(dungeonId)
	if dungeonConfig.activity_date == nil then
		return true
	end
	local currDate = os.date("*t", (q.serverTime() - 4*60*60))
	local wday = currDate.wday + 6
	if wday > 7 then
		wday = wday - 7
	end
	if string.find(dungeonConfig.activity_date, tostring(wday)) ~= nil then
		return true
	end
	return false
end

function QActivityInstance:getAttackCountByType(instanceId)
	if instanceId == "activity1_1" then
		return remote.user.todayActivity1_1Count or 0
	elseif instanceId == "activity2_1" then
		return remote.user.todayActivity2_1Count or 0
	elseif instanceId == "activity3_1" then
		return remote.user.todayActivity3_1Count or 0
	elseif instanceId == "activity4_1" then
		return remote.user.todayActivity4_1Count or 0
	end
	return 0
end

return QActivityInstance