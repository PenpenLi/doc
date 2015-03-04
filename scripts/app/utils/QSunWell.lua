--
-- Author: Your Name
-- Date: 2015-02-02 11:07:01
--
local QSunWell = class("QSunWell")
local QStaticDatabase = import("..controllers.QStaticDatabase")
local QVIPUtil = import("..utils.QVIPUtil")

QSunWell.EVENT_INSTANCE_UPDATE = "QSUNWELL_EVENT_INSTANCE_UPDATE"
QSunWell.EVENT_HERO_UPDATE = "QSUNWELL_EVENT_HERO_UPDATE"

function QSunWell:ctor()
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self:clearSunwellHeroInfo()
	self:clearInstanceInfo()
	self._maxIndex = 15
	self._luckyDraws = {}
	self._resetCount = 1
	self._resetTime = q.serverTime()
end

function QSunWell:init()
	self._sunWellMap = QStaticDatabase:sharedDatabase():getSunwellMap()
	self._maxIndex = table.nums(self._sunWellMap)
end

--[[
	request sun well instance info to last battle
--]]
function QSunWell:getMap()
	return self._sunWellMap
end

--[[
	clear table _sunwellHeroInfo
--]]
function QSunWell:clearSunwellHeroInfo()
	self._sunwellHeroInfo = {}
end

--[[
	clear table _sunwellHeroInfo
--]]
function QSunWell:clearInstanceInfo()
	self._instanceInfo = {}
end

--[[
	update heroInfo from remote data
--]]
function QSunWell:updateHeroInfo(heroInfos)
	for _,value in pairs(heroInfos) do
		self._sunwellHeroInfo[value.actorId] = value
	end

    self:dispatchEvent({name = QSunWell.EVENT_HERO_UPDATE})
end

--[[
	heroInfos = {
	{actorId = actorId, hp = hp, skillCD = skillCD},
	{actorId = actorId, hp = hp, skillCD = skillCD}
	}
	cooldownTime: 已经过去了多长时间
--]]
function QSunWell:setSunwellHeroInfoFromBattleEnd(heroInfos)
	if heroInfos == nil then
		return 
	end

	if self._sunwellHeroInfo == nil then
		self._sunwellHeroInfo = {}
	end

	for _,heroInfo in pairs(heroInfos) do
		self._sunwellHeroInfo[heroInfo.actorId] = heroInfo
	end
    
end

--[[
	获取自己太阳井英雄信息
]]
function QSunWell:getSunwellHeroInfo(actorId)
	if actorId == nil then
		return nil
	end

	return self._sunwellHeroInfo[actorId]
end

function QSunWell:getInstanceInfoByIndex(index)
	return self._instanceInfo[index]
end


function QSunWell:setNeedPass(needPass)
	if needPass ~= nil then
		self._needPass = needPass
		self:dispatchEvent({name = QSunWell.EVENT_INSTANCE_UPDATE})
	end
end

function QSunWell:getNeedPass()
	if self._needPass == nil then
		self._needPass = 1
	end
	if self._needPass <= self._maxIndex then
		if self._instanceInfo[self._needPass] == nil then
			self:requestInstanceInfo(self._needPass, true)
		end
	end
	return self._needPass
end

--检查下一个关卡
function QSunWell:checkNextPass()
	local nextPass = self._needPass + 1
	if nextPass <= self._maxIndex then
		if self._instanceInfo[nextPass] == nil then
			self:requestInstanceInfo(nextPass)
		end
	end
	self._needPass = nextPass
end

--[[
	更新太阳井关卡数据
]]
function QSunWell:setInstanceInfo(info)
	for _,value in pairs(info) do
		value.isPass = self:checkIsPass(value)
		self._instanceInfo[value.index] = value
	end
	self:dispatchEvent({name = QSunWell.EVENT_INSTANCE_UPDATE})
end

--更新宝箱领取数据
function QSunWell:setSunwellLuckyDraw(data)
	for _,index in pairs(data) do
		self._luckyDraws[index] = true
	end
	self:dispatchEvent({name = QSunWell.EVENT_INSTANCE_UPDATE})
end

function QSunWell:getSunwellLuckyDraw()
	return self._luckyDraws
end

--更新次数和刷新时间
function QSunWell:updateCount(resetCount, resetTime)
	if resetCount ~= nil then
		self._resetCount = resetCount
	else
		self._resetCount = 1
	end
	if resetTime ~= nil then
		self._resetTime = resetTime/1000
	else
		self._resetTime = q.serverTime()
	end
	self:dispatchEvent({name = QSunWell.EVENT_INSTANCE_UPDATE})
end

function QSunWell:getCount()
	if self._resetTime < q.refreshTime(global.freshTime.sunwell_freshTime) then
		self._resetCount = 0
	end
	return QVIPUtil:getSunwellResetCount() - self._resetCount
end

--[[
	检查是否通过了
]]
function QSunWell:checkIsPass(dungeonInfo)
	for i=1,3,1 do
		local fighter = dungeonInfo["fighter"..i]
		local isPass = true
		if fighter ~= nil and fighter.heros ~= nil then
			for _,heroInfo in pairs(fighter.heros) do
				if heroInfo.hp == nil or heroInfo.hp > 0 then
					isPass = false
					break
				end
			end
		end
		if isPass == true then
			return isPass
		end
	end
	return false
end

--[[
	请求拉取关卡数据
]]
function QSunWell:requestInstanceInfo(index, isShow)
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  	if remote.user.level < unlockVlaue["UNLOCK_SUNWELL"].value then
    	return
    end
	app:getClient():sunwellQueryRequest(index, index, nil, nil, nil, isShow)
end

--重置太阳井副本
function QSunWell:resetCount()
	self._resetCount = self._resetCount + 1
	self._resetTime = q.serverTime()
	self:clearSunwellHeroInfo()
	self:clearInstanceInfo()
	self._luckyDraws = {}
	self._needPass = nil
	remote.teams:setTeams(remote.teams.SUNWELL_ATTACK_TEAM, {})
	self:dispatchEvent({name = QSunWell.EVENT_INSTANCE_UPDATE})
end

return QSunWell
