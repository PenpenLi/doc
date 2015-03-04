--[[
	战队相关的辅助类
--]]
local QTeam = class("QTeam")

local QFlag = import("..utils.QFlag")
local QStaticDatabase = import("..controllers.QStaticDatabase")

QTeam.INSTANCE_TEAM = "INSTANCE_TEAM" --副本战队
QTeam.ARENA_DEFEND_TEAM = "ARENA_DEFEND_TEAM" --竞技场防守战队
QTeam.ARENA_ATTACK_TEAM = "ARENA_ATTACK_TEAM" --竞技场进攻战队
QTeam.SUNWELL_ATTACK_TEAM = "SUNWELL_ATTACK_TEAM" --太阳井小分队
QTeam.TIME_MACHINE_TEAM = "TIME_MACHINE_TEAM" --时光传送器小分队
QTeam.POWER_TEAM = "POWER_TEAM" --力量试练小分队
QTeam.INTELLECT_TEAM = "INTELLECT_TEAM" --智力试练小分队

function QTeam:ctor(options)
	self._teams = {} --本地英雄数据
	self._teamMaxCount = 0
end

--[[
	初始化
]]
function QTeam:init()
	self._teams[QTeam.INSTANCE_TEAM] = app:getUserData():getTeam(QTeam.INSTANCE_TEAM)
	self._teams[QTeam.ARENA_ATTACK_TEAM] = app:getUserData():getTeam(QTeam.ARENA_ATTACK_TEAM)
	self._teams[QTeam.SUNWELL_ATTACK_TEAM] = app:getUserData():getTeam(QTeam.SUNWELL_ATTACK_TEAM)
	--登录的时候清除本地防御战队
	self._teams[QTeam.ARENA_DEFEND_TEAM] = {}
	self:saveTeam(QTeam.ARENA_DEFEND_TEAM)
end

--[[
	检查战队 如果战队中的英雄不存在 则删除
]]
function QTeam:checkHeroTeam(key)
	if self._teams[key] ~= nil then
		for _,value in pairs(self._teams[key]) do
			if remote.herosUtil:getHeroByID(value) == nil then
				self:delHero(value, key)
			end
		end
	end
end

--[[
	获得这个战队的英雄列表
--]]
function QTeam:getTeams(key)
	return self._teams[key]
end

--[[
	设置这个战队的英雄列表
--]]
function QTeam:setTeams(key, teams)
	self._teams[key] = teams
	app:getUserData():setTeam(key, teams)
end

--[[
	保存这个战队的英雄列表到本地
--]]
function QTeam:saveTeam(key)
	app:getUserData():setTeam(key, self._teams[key])
end

--[[
	保存这个战队的英雄列表到本地
--]]
function QTeam:revertTeam(key)
	self._teams[key] = app:getUserData():getTeam(key)
end

--[[
	获得这个战队的英雄数量
--]]
function QTeam:getHerosCount(key)
	local heros = self._teams[key]
	return heros ~= nil and #heros or 0
end

--[[
	添加英雄到英雄列表
--]]
function QTeam:addHero(actorId,key)
	if self._teams[key] == nil then
		self._teams[key] = {}
	end
	local heros = self._teams[key]
	local maxIndex = self:getHerosMaxCount()
	if #heros >= maxIndex then
		return false
	end
	table.insert(heros, actorId)
	self:sortTeam(heros)
	return true
end

--[[
	移除英雄从英雄列表
--]]
function QTeam:delHero(actorId, key)
	if self._teams[key] == nil then
		return
	end
	local heros = self._teams[key]
	for i, id in ipairs(heros) do
		if id == actorId then
			table.remove(heros, i)
		end
	end
end

--[[
	获取该战队的总战力
--]]
function QTeam:getBattleForceForKey(key)
	local force = 0 
	local heros = self._teams[key] or {}
	for _,value in pairs(heros) do
	   	if value ~= "" then
		   	force = force + app:createHero(remote.herosUtil:getHeroByID(value)):getBattleForce()
	    end
	end
	return force
end

--[[
	查询战队是否包含英雄
	@param actorId 要查询的英雄ID
--]]
function QTeam:contains(actorId, key)
	local heros = self._teams[key] or {}
	if heros == nil then
		return false
	end

	for _, id in ipairs(heros) do
		if id == actorId then
			return true
		end
	end
	return false
end

--[[
	计算战队最大数量
--]]
function QTeam:herosMaxCount()
	--self._teamMaxCount = 4
	-- 暂时全开
	remote.flag:get({QFlag.FLAG_TEAM_LOCK}, function(data)
			if self._teamMaxCount == 0 then
				if data[QFlag.FLAG_TEAM_LOCK] ~= nil and data[QFlag.FLAG_TEAM_LOCK] ~= "" then
					self._teamMaxCount = tonumber(data[QFlag.FLAG_TEAM_LOCK])
				else
					self._teamMaxCount = 1
					remote.flag:set(QFlag.FLAG_TEAM_LOCK,self._teamMaxCount)
				end
			end
		end)
end

--[[
	获得这个战队的可加入数量
--]]
function QTeam:getHerosMaxCount()
	self:herosMaxCount()
	-- if self:unlockTeamForInstance() == true then
	-- 	return self._teamMaxCount + 1 
	-- end
	return self._teamMaxCount
end

--[[
	添加英雄到战队列表 新手引导
--]]
function QTeam:joinHero(heros)
	self._joinHero = heros
	for _,id in pairs(heros) do
		self:addHero(id, QTeam.INSTANCE_TEAM)
	end
	self:saveTeam(QTeam.INSTANCE_TEAM)
end

function QTeam:unlockTeamForDungeon(dungeonId)
	if self._teamMaxCount < 4 then
		local count = 1
		local isFind = false
		for i=1,3,1 do
			local dungeonInfo = remote.instance:getDungeonById(QStaticDatabase:sharedDatabase():getDungeonHeroByIndex(i).dungeon_id)
			if dungeonInfo ~= nil and dungeonInfo.dungeon_id == dungeonId then
				isFind = true
			end
			if dungeonInfo.info ~= nil then
				count = count + 1
			end
		end
		local dungeonInfo = remote.instance:getDungeonById(dungeonId)
		if isFind == true and count == self._teamMaxCount and dungeonInfo.info == nil then
			self._teamMaxCount = 1 + self._teamMaxCount
			remote.flag:set(QFlag.FLAG_TEAM_LOCK,self._teamMaxCount)
		end
		if count > self._teamMaxCount then
			self._teamMaxCount = count
			remote.flag:set(QFlag.FLAG_TEAM_LOCK,self._teamMaxCount)
		end

		for i=1,3,1 do
			local dungeonHero = QStaticDatabase:sharedDatabase():getDungeonHeroByIndex(i)
			local dungeonInfo = remote.instance:getDungeonById(dungeonHero.dungeon_id)
			if dungeonInfo.dungeon_id == dungeonId and dungeonInfo.info == nil then
				self:joinHero({dungeonHero.hero_actor_id})
			end
	    end
	end
end

--[[
	获取新手英雄 新手引导
	仅仅适用副本战队
--]]
function QTeam:getJoinHero()
	local heros = self._joinHero
	self._joinHero = nil
	return heros
end

--[[
	排序英雄列表
--]]
function QTeam:sortTeam(heros)
	if heros ~= nil and #heros > 1 then 
		table.sort(heros, handler(self,self._sortHero))
	end
end

--职业（ T > 治疗 > DPS）> 等级 > 经验 > 创建时间
function QTeam:_sortHero(a,b)
	local heroA
	local heroB
	if type(a) == "table" and type(b) == "table" then
		heroA = a
		heroB = b
	else
		heroA = remote.herosUtil:getHeroByID(a)
		heroB = remote.herosUtil:getHeroByID(b)
	end
	local characherA = QStaticDatabase:sharedDatabase():getCharacterByID(heroA.actorId)
	local talentA = QStaticDatabase:sharedDatabase():getTalentByID(characherA.talent)
	local characherB = QStaticDatabase:sharedDatabase():getCharacterByID(heroB.actorId)
	local talentB = QStaticDatabase:sharedDatabase():getTalentByID(characherB.talent)

	if talentA.hatred ~= talentB.hatred then
		return talentA.hatred < talentB.hatred
	end

	-- local modelA = app:createHero(heroA)
	-- local modelB = app:createHero(heroB)
	-- local attackA = modelA:getBattleForce()
	-- local attackB = modelB:getBattleForce()
	-- if attackA ~= attackB then
	-- 	return attackA > attackB
	-- end
	if talentA.func ~= talentB.func then
		if talentA.func == 'health' then
			return true
		elseif talentB.func == 'health' then
			return false
		elseif talentA.func == 't' then
			return true
		elseif talentB.func == 't' then
			return false
		end
	-- elseif  heroA.level ~= heroB.level then
	-- 	return heroA.level > heroB.level
	-- elseif heroA.exp ~= heroB.exp then
	-- 	return heroA.exp > heroB.exp
	elseif talentA.attack_type ~= talentB.attack_type then
	  return  talentA.attack_type > talentB.attack_type
  -- 	elseif heroA.createdAt ~= nil and heroB.createdAt ~= nil then
		-- return heroA.createdAt < heroB.createdAt
	end
	return heroA.actorId > heroB.actorId
end

return QTeam

