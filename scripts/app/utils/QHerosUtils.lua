--
-- Author: Your Name
-- Date: 2014-06-16 18:08:30
-- 英雄数据处理以及缓存类 实例对象保存在remote中
--
local QHerosUtils = class("QHerosUtils")

local QStaticDatabase = import("..controllers.QStaticDatabase")
local QHeroModel = import("..models.QHeroModel")
local QTeam = import("..utils.QTeam")

QHerosUtils.EVENT_HERO_PROP_UPDATE = "EVENT_HERO_PROP_UPDATE"
QHerosUtils.EVENT_HERO_LEVEL_UPDATE = "EVENT_HERO_LEVEL_UPDATE"
QHerosUtils.EVENT_HERO_EXP_UPDATE = "EVENT_HERO_EXP_UPDATE"

QHerosUtils.EVENT_HERO_EXP_CHECK = "EVENT_HERO_EXP_CHECK"

function QHerosUtils:ctor(options)
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
	self.heros = {}
	self._keyHeros = {}
	self._keyHaveHeros = {}
end

--[[
	从配置中读取所有英雄
]]
function QHerosUtils:initHero()
	if #self._keyHeros == 0 then
		local herosConfig = QStaticDatabase:sharedDatabase():getCharacter() or {}
		for _,value in pairs(herosConfig) do
			if value.npc_level == nil then
				table.insert(self._keyHeros, value.id)
			end
		end
	end
	-- part 3: sort not be summoned heros
	table.sort(self._keyHeros, function(actorId1, actorId2)
		local characher1 = QStaticDatabase:sharedDatabase():getCharacterByID(actorId1)
		local grade_info1 = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(actorId1, characher1.grade or 0)
		local soulGemId1 = grade_info1.soul_gem
		local currentGemCount1 = remote.items:getItemsNumByID(soulGemId1)
		local needGemCount1 = QStaticDatabase:sharedDatabase():getNeedSoulByHeroActorLevel(actorId1, characher1.grade or 0)

		local characher2 = QStaticDatabase:sharedDatabase():getCharacterByID(actorId2)
		local grade_info2 = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(actorId2, characher2.grade or 0)
		local soulGemId2 = grade_info2.soul_gem
		local currentGemCount2 = remote.items:getItemsNumByID(soulGemId2)
		local needGemCount2 = QStaticDatabase:sharedDatabase():getNeedSoulByHeroActorLevel(actorId2, characher2.grade or 0)

		if currentGemCount1 > 0 and currentGemCount2 == 0 then
			return true
		elseif currentGemCount1 == 0 and currentGemCount2 > 0 then
			return false
		else
			if needGemCount1 < needGemCount2 then
				return true
			elseif needGemCount1 > needGemCount2 then
				return false
			else
				if currentGemCount1 > currentGemCount2 then
					return true
				elseif currentGemCount1 < currentGemCount2 then
					return false
				else
					if soulGemId1 < soulGemId2 then
						return true
					elseif soulGemId1 > soulGemId2 then
						return false
					else
						if actorId1 < actorId2 then
							return true
						else
							return false
						end
					end
				end
			end
		end
    end )
end

function QHerosUtils:updateHeros(heros)
	self:_mergeTableToTable(self.heros, heros)
	for _,value in pairs(heros) do
		if app:hasObject(value.actorId) == true then
			app:setObject(value.actorId,QHeroModel.new(value))
		end
	end
	self._keyHaveHeros = {}
	for _,value in pairs(self.heros) do
		table.insert(self._keyHaveHeros, value.actorId)
	end
	self:sortHero()
end

function QHerosUtils:getHeroByID(actorId)
	return self.heros[tonumber(actorId)]
end

function QHerosUtils:getHeroPropByHeroInfo(heroInfo)
	local database = QStaticDatabase:sharedDatabase()
	local prop = clone(heroInfo)
    local grade = database:getGradeByHeroActorLevel(prop.actorId,prop.grade)
    grade = grade or {}
    local breakthrough = database:getBreakthroughByHeroActorLevel(prop.actorId,prop.breakthrough)
    breakthrough = breakthrough or {}

    for key,value in pairs(grade) do
    	if prop[key] == nil or type(value) ~= "number" then
    		prop[key] = value
    	else
    		prop[key] = prop[key] + value
    	end
    end
    for key,value in pairs(breakthrough) do
    	if prop[key] == nil or type(value) ~= "number" then
    		prop[key] = value
    	else
    		prop[key] = prop[key] + value
    	end
    end

    return prop
end

--获取所有的英雄ID
function QHerosUtils:getHerosKey()
	return self._keyHeros
end

--获取已经拥有的英雄ID
function QHerosUtils:getHaveHeroKey(key)
	local heroKeys = {}
	if key == QTeam.SUNWELL_ATTACK_TEAM then
		heroKeys = {}
		for _,actorId in pairs(self._keyHaveHeros) do
			local heroInfo = self:getHeroByID(actorId)
			if heroInfo ~= nil and heroInfo.level >= 20 then
				heroKeys[#heroKeys + 1] = actorId
			end
		end
	else
		heroKeys = clone(self._keyHaveHeros)
	end
	return heroKeys
end

--根据英雄获取英雄属性
function QHerosUtils:getHeroProperty(heroInfo)
	return QStaticDatabase:sharedDatabase():getCharacterByID(heroInfo.actorId)
end


--传入英雄和经验增值计算最终英雄数据
--function QHerosUtils:addHerosExp(heroInfo, addExp)
--  while true do
--    local maxExp = QStaticDatabase:sharedDatabase():getExperienceByLevel(heroInfo.level)
--    if maxExp <= (heroInfo.exp + addExp) then
--      addExp = addExp - (maxExp - heroInfo.exp)
--      heroInfo.exp = 0
--      heroInfo.level = heroInfo.level + 1
--      else
--        heroInfo.exp = heroInfo.exp + addExp
--        break
--    end
--  end
--  return heroInfo
--end

--传入英雄和经验减值计算最终英雄数据
function QHerosUtils:subHerosExp(heroInfo, subExp)
  while true do
    if heroInfo.exp >= subExp then
      heroInfo.exp = heroInfo.exp - subExp
      break
    elseif heroInfo.level > 0 then
      subExp = subExp - heroInfo.exp - 1
      heroInfo.level = heroInfo.level - 1
      heroInfo.exp = QStaticDatabase:sharedDatabase():getExperienceByLevel(heroInfo.level) - 1
    else
      heroInfo.level = 0
      heroInfo.exp = 0
      break
    end
  end
    return heroInfo
end

--传入英雄数组 计算总的经验值
function QHerosUtils:countHerosExp(herosTable)
	if herosTable == nil then return 0 end
	local expNum = 0
	local hero
	for _,id in pairs(herosTable) do
		hero = remote.herosUtil:getHeroByID(id)
		if hero ~= nil then
			expNum = expNum + hero.exp + QStaticDatabase:sharedDatabase():getTotalExperienceByLevel(hero.level) + (QStaticDatabase:sharedDatabase():getCharacterByID(hero.actorId).basic_exp or 0)
		end
	end
	return expNum
end

--传入英雄ID 获取颜色值
function QHerosUtils:getHeroColorForId(actorId)
	local heroInfo = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
	return EQUIPMENT_COLOR[heroInfo.colour]
end

--检查所有英雄是否需要显示小红点
function QHerosUtils:checkAllHerosIsTip()
	if self:checkAllHerosBreakthrough() == true then
		return true
	elseif self:checkAllHerosEquipment() == true then
		return true
	elseif self:checkAllHerosGrade() == true then
		return true
	elseif self:checkAllHerosComposite() == true then
		return true
	else
		return false
	end
end

--检查指定英雄是否需要显示小红点
function QHerosUtils:checkHerosIsTipByID(actorId)
	if self:checkHerosBreakthroughByID(actorId) == true then
		return true
	elseif #self:checkHerosEquipmentByID(actorId) > 0 then
		return true
	elseif self:checkHerosGradeByID(actorId) == true then
		return true
	else
		return false
	end
end

--检查所有英雄当前是否有可穿戴的装备
function QHerosUtils:checkAllHerosEquipment()
    local herosKey = table.keys(self.heros)
    local equipTable = {}
	for _,key in pairs(herosKey) do
		equipTable = self:checkHerosEquipmentByID(key)
		if #equipTable > 0 then
			return true
		end
	end
	return false
end

--检查所有英雄当前是否有英雄拥有突破所需的装备
function QHerosUtils:checkAllHerosBreakthroughNeedEqu()
  local herosKey = table.keys(self.heros)
  local equipTable = {}
  local heroInfo = nil  
  local heroHasWear = {}
  local actorId = nil
  for _,key in pairs(herosKey) do
    equipTable = self:checkHerosEquipmentByID(key)
    heroInfo = self.heros[key]
  	heroHasWear = heroInfo.equipments or {}
    if #equipTable + #heroHasWear == 6 then
      if actorId == nil then
        actorId = key
      end
    end
  end
  return actorId
end

--检查英雄当前是否有可穿戴的装备
function QHerosUtils:checkHerosEquipmentByID(actorId)
	local wearEquip = {}
	local heroInfo = self.heros[actorId]
	if heroInfo == nil then return wearEquip end
	if heroInfo.breakthrough == 0 then
		local actorInfo = QStaticDatabase:sharedDatabase():getCharacterByID(heroInfo.actorId)
		if actorInfo == nil then return wearEquip end
		local breakthroughInfo = QStaticDatabase:sharedDatabase():getBreakthroughByTalentLevel(actorInfo.talent,heroInfo.breakthrough+1)
		if breakthroughInfo == nil then return wearEquip end

		local equipments = heroInfo.equipments or {}
		local itemID = ""
		local isHave = false
		local isWear = false

		for _,name in pairs(EQUIPMENT_TYPE) do
			itemID = breakthroughInfo[name]
			if itemID ~= nil then
				isHave = false
				isWear = false
				local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(itemID)
				if itemConfig.level <= heroInfo.level then
					--检查装备是否穿在身上
					isWear = self:checkIsWear(heroInfo.actorId, itemID)
					if isWear == false then
					    --检查装备是否在包里
					    isHave = remote.items:getItemIsHaveNumByID(itemID,1)
					    if isHave == true then
					    	table.insert(wearEquip, {name = name , itemID = itemID})
					    end
					end
				end
			end
		end
	end
	return wearEquip		
end

--检查所有英雄是否可以突破
function QHerosUtils:checkAllHerosBreakthrough()
	local herosKey = table.keys(self.heros)
	for _,key in pairs(herosKey) do
		if self:checkHerosBreakthroughByID(key) == true then
			return true
		end
	end
	return false
end

--检查英雄是否可以突破
function QHerosUtils:checkHerosBreakthroughByID(actorId)
	local heroInfo = self.heros[actorId]
	local equipments = heroInfo.equipments or {}
	if #equipments < 6 then
		return false
	end
	local charactInfo = QStaticDatabase:sharedDatabase():getCharacterByID(heroInfo.actorId)
	local breakthroughInfo = QStaticDatabase:sharedDatabase():getBreakthroughByTalentLevel(charactInfo.talent, heroInfo.breakthrough+1)
	if breakthroughInfo ~= nil then
		local tbl = {}
		table.insert(tbl, breakthroughInfo.weapon)
		table.insert(tbl, breakthroughInfo.hat)
		table.insert(tbl, breakthroughInfo.clothes)
		table.insert(tbl, breakthroughInfo.bracelet)
		table.insert(tbl, breakthroughInfo.shoes)
		table.insert(tbl, breakthroughInfo.jewelry)
		for _,equipment in pairs(equipments) do
			local isFind = false
			for _,itemId in pairs(tbl) do
				if equipment.itemId == itemId then
					isFind = true
					break
				end
			end
			if isFind == false then
				return false
			end
		end
	end
	return true
end

--检查所有英雄是否可以进阶
function QHerosUtils:checkAllHerosGrade()
	local herosKey = table.keys(self.heros)
	for _,key in pairs(herosKey) do
		if self:checkHerosGradeByID(key) == true then
			return true
		end
	end
	return false
end

--检查当前英雄是否可以进阶
function QHerosUtils:checkHerosGradeByID(actorId)
	local heroInfo = self.heros[actorId]
	if heroInfo.grade >= GRAD_MAX then return false end
	local gradeConfig = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(heroInfo.actorId, heroInfo.grade+1)
	if gradeConfig == nil then return end
	local soulNum = remote.items:getItemsNumByID(gradeConfig.soul_gem) -- 灵魂碎片的数量
	if gradeConfig.soul_gem ~= nil and gradeConfig.soul_gem ~= 0 then
		if soulNum >= gradeConfig.soul_gem_count then
			return true
		else
			return false
		end
	end
	return false
end

--检查所有未召唤英雄是否可召唤
function QHerosUtils:checkAllHerosComposite()
	for _,key in pairs(self._keyHeros) do
		if self:checkHerosCompositeByID(key) == true then
			return true
		end
	end
	return false
end

--检查当前英雄是否可以合成
function QHerosUtils:checkHerosCompositeByID(actorId)
	local heroInfo = self:getHeroByID(actorId)
	if heroInfo ~= nil then return false end --已经存在无需召唤
	local gradeConfig = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(actorId, 1)
	if gradeConfig == nil then return false end
	local soulNum = remote.items:getItemsNumByID(gradeConfig.soul_gem) -- 灵魂碎片的数量
	local characher = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
	local needGemCount = QStaticDatabase:sharedDatabase():getNeedSoulByHeroActorLevel(actorId, characher.grade or 0)
	if soulNum >= needGemCount then
		return true
	end
	return false
end

--获取英雄最大等级
function QHerosUtils:getHeroMaxLevel()
	return QStaticDatabase:sharedDatabase():getTeamConfigByTeamLevel(remote.user.level).hero_limit or 1
end

--英雄是否能升级
function QHerosUtils:heroCanUpgrade(actorId)
	local hero = self:getHeroByID(actorId)
	local exp = QStaticDatabase:sharedDatabase():getExperienceByLevel(hero.level)	
	local maxLevel = self:getHeroMaxLevel()
	if hero.level < maxLevel or (hero.level == maxLevel and hero.exp < (exp-1)) then
		return true
	else
		return false
	end
end

--检查某个英雄是否穿了某个装备
function QHerosUtils:checkIsWear(actorId, itemId)
	return self:getWearByItem(actorId, itemId) ~= nil
end

--获取某个英雄穿戴的装备
function QHerosUtils:getWearByItem(actorId, itemId)
	local heroInfo = self:getHeroByID(actorId)
	local equipments = heroInfo.equipments or {}
	for _,equipment in pairs(equipments) do
		if equipment.itemId == itemId then
			return equipment
		end
	end
	return nil
end

--英雄当前装备跟突破相关
function QHerosUtils:getHeroEquipmentForBreakthrough(actorId)
	local hero = self:getHeroByID(actorId)
	local characterInfo = QStaticDatabase:sharedDatabase():getCharacterByID(hero.actorId)
	local currentBreakthroughInfo = QStaticDatabase:sharedDatabase():getBreakthroughByTalentLevel(characterInfo.talent, hero.breakthrough)
	local breakthroughInfo = QStaticDatabase:sharedDatabase():getBreakthroughByTalentLevel(characterInfo.talent, hero.breakthrough+1)
	local items = {}
	local equipments = hero.equipments or {}
	for _,typeName in pairs(EQUIPMENT_TYPE) do
		if currentBreakthroughInfo ~= nil then
			local itemID = currentBreakthroughInfo[typeName]
			local isWear = false
			for _,equipment in pairs(equipments) do
				if equipment.itemId == itemID then
					isWear = true
					break
				end
			end
			if isWear == false then
				items[typeName] = breakthroughInfo[typeName]
			else
				items[typeName] = currentBreakthroughInfo[typeName]
			end
		else
			items[typeName] = breakthroughInfo[typeName]
		end
	end
	return items
end

--英雄吃经验
function QHerosUtils:heroEatExp(expNum,actorId)
	local hero = self:getHeroByID(actorId)
	if hero == nil then
		return false
	end
	local exp = QStaticDatabase:sharedDatabase():getExperienceByLevel(hero.level)	

	local addLevel = 0
	local addExp = 0
	local maxLevel = self:getHeroMaxLevel()
	if hero.level < maxLevel or (hero.level == maxLevel and hero.exp < (exp-1)) then --英雄未满级 或者满级经验未满时则可以升级
		while true do
			exp = QStaticDatabase:sharedDatabase():getExperienceByLevel(hero.level)
			if exp <= (hero.exp + expNum) then --需要升级
				if hero.level < maxLevel then --未满级
					hero.level  = hero.level + 1
					addLevel = addLevel + 1
					addExp = addExp + (exp - hero.exp)
					expNum = expNum - (exp - hero.exp)
					hero.exp = 0
				elseif hero.level == maxLevel then --满级
					addExp = addExp + (exp - 1 - hero.exp)
					hero.exp = exp - 1
					break
				end
			else
				addExp = addExp + expNum
				hero.exp = hero.exp + expNum
				break
			end
		end
	else
		return false
	end 
	self:dispacthHeroPropUpdate(actorId, "经验：+ "..addExp)
	self:dispatchEvent({name = QHerosUtils.EVENT_HERO_EXP_UPDATE, actorId = actorId, exp = addExp})
	if addLevel > 0 then
		self:dispacthHeroPropUpdate(actorId, "等级：+ "..addLevel)
		self:dispatchEvent({name = QHerosUtils.EVENT_HERO_LEVEL_UPDATE, actorId = actorId})
		local oldHero = clone(hero)
		oldHero.level = oldHero.level - addLevel
		self:heroUpdate(oldHero, hero)
	end
    return true
end

function QHerosUtils:heroUpdate(oldHero, newHero)
	local oldHeroModel = QHeroModel.new(oldHero)
	local newHeroModel = QHeroModel.new(newHero)
    self:_changePropIsDispacth(oldHero.actorId, "生命：", newHeroModel:getMaxHp() - oldHeroModel:getMaxHp())
    self:_changePropIsDispacth(oldHero.actorId, "攻击：", newHeroModel:getMaxAttack() - oldHeroModel:getMaxAttack())
    self:_changePropIsDispacth(oldHero.actorId, "命中：", newHeroModel:getMaxHitLevel() - oldHeroModel:getMaxHitLevel())
    self:_changePropIsDispacth(oldHero.actorId, "闪避：", newHeroModel:getMaxDodgeLevel() - oldHeroModel:getMaxDodgeLevel())
    self:_changePropIsDispacth(oldHero.actorId, "暴击：", newHeroModel:getMaxCritLevel() - oldHeroModel:getMaxCritLevel())
    self:_changePropIsDispacth(oldHero.actorId, "格挡：", newHeroModel:getMaxBlockLevel() - oldHeroModel:getMaxBlockLevel())
    self:_changePropIsDispacth(oldHero.actorId, "急速：", newHeroModel:getMaxHasteLevel() - oldHeroModel:getMaxHasteLevel())
    self:_changePropIsDispacth(oldHero.actorId, "物抗：", newHeroModel:getMaxPhysicalArmor() - oldHeroModel:getMaxPhysicalArmor())
    self:_changePropIsDispacth(oldHero.actorId, "魔抗：", newHeroModel:getMaxMagicArmor() - oldHeroModel:getMaxMagicArmor())

end

function QHerosUtils:_changePropIsDispacth(actorId, name, value)
    if value ~= nil and value > 0 then
		self:dispacthHeroPropUpdate(actorId, name.."+ "..string.format("%.1f",value))		
    end
end

--英雄数据排序
function QHerosUtils:sortHero()
    table.sort(self._keyHeros, handler(self,self._sortHero))
    table.sort(self._keyHaveHeros, function (a,b)
    	local heroInfoA = self:getHeroByID(a)
    	local heroInfoB = self:getHeroByID(b)
    	local modelA = app:createHero(heroInfoA)
    	local modelB = app:createHero(heroInfoB)
    	if modelA:getBattleForce() ~= modelB:getBattleForce() then
    		return modelA:getBattleForce() > modelB:getBattleForce()
    	else
    		return self:_sortHero(a, b)
    	end
    end)
end

--出战优先 > 等级 > 经验 > 职业（ T > 治疗 > DPS）> 创建时间
function QHerosUtils:_sortHero(a,b)
	-- local isInTeamA = self:_checkHeroInTeam(a)
	-- local isInTeamB = self:_checkHeroInTeam(b)
	-- if isInTeamA ~= isInTeamB then
	-- 	return isInTeamA
	-- end
	local heroA = self:getHeroByID(a)
	local heroB = self:getHeroByID(b)
	if heroA ~= nil and heroB == nil then
		return true
	elseif heroA == nil and heroB ~= nil then
		return false
	elseif heroA ~= nil and heroB ~= nil then
		if heroA.level ~= heroB.level then
			return heroA.level > heroB.level
		elseif heroA.exp ~= heroB.exp then
			return heroA.exp > heroB.exp
		end
	end
	local characherA = QStaticDatabase:sharedDatabase():getCharacterByID(a)
	local talentA = QStaticDatabase:sharedDatabase():getTalentByID(characherA.talent)
	local characherB = QStaticDatabase:sharedDatabase():getCharacterByID(b)
	local talentB = QStaticDatabase:sharedDatabase():getTalentByID(characherB.talent)
	if talentA ~= nil and talentB ~= nil then
		if talentA.func ~= talentB.func then
			if talentA.func == 't' then
				return true
			elseif talentB.func == 't' then
				return false
			elseif talentA.func == 'health' then
				return true
			elseif talentB.func == 'health' then
				return false
			end
		elseif talentA.func == 'dps' then
			if talentA.attack_type ~= talentB.attack_type then
				return talentA.attack_type > talentB.attack_type
			end
		end
	end
	return a > b
end

--检查英雄是否在战队
function QHerosUtils:_checkHeroInTeam(herosID)
	if #remote.teams == 0 then 
		return false
	end
	return remote.teams:contains(herosID, QTeam.INSTANCE_TEAM)
end

--把tableB的数据拷贝到tableA中，如果没有则添加，如果有则替换
function QHerosUtils:_mergeTableToTable(tableA,tableB)
    for key,value in pairs(tableB) do
        tableA[key] = value
    end
end

function QHerosUtils:dispacthHeroPropUpdate(actorId,value)
	scheduler.performWithDelayGlobal(function ()
		self:dispatchEvent({name = QHerosUtils.EVENT_HERO_PROP_UPDATE, actorId = actorId, value = value})
	end,0.3)
end

--[[
	获取技能点数和刷新时间 已经计算过
]]
function QHerosUtils:getSkillPointAndTime()
	local totalPoint = 10
	local stageTime = 5 * 60
	local startPoint = remote.user.skillTickets or 0
	local lastRefreshTime = remote.user.skillTicketsRefreshedAt/1000 or 0
	local currentTime = q.serverTime()
	if startPoint >= totalPoint or (currentTime - lastRefreshTime) < stageTime then
		return startPoint, (stageTime - (currentTime - lastRefreshTime))
	else
		while true do
			if startPoint >= totalPoint or (currentTime - lastRefreshTime) < stageTime then
				break
			else
				lastRefreshTime = lastRefreshTime + stageTime
				startPoint = startPoint + 1
			end
		end
	end
	return startPoint, (stageTime - (currentTime - lastRefreshTime))
end

--[[
	英雄吃卡
]]

function QHerosUtils:setExpItemsForHero(actorId, itemId)
	self._expActorId = actorId
	if self._eatExps == nil then
		self._eatExps = {}
	end
	if self._eatExps[itemId] == nil then
		self._eatExps[itemId] = 0
	end
	self._eatExps[itemId] = self._eatExps[itemId] + 1
end

--[[
	英雄吃卡上传服务器
]]
function QHerosUtils:requestHeroExp(callBack)
	if self._eatExps == nil or self._expActorId == nil or table.nums(self._eatExps) == 0 then
		if callBack ~= nil then callBack() end
		return 
	end
	for itemId,num in pairs(self._eatExps) do
		if itemId ~= nil and num > 0 then
			app:getClient():intensify(self._expActorId, itemId, num, function()
					self:requestHeroExp(callBack)
				end)
			self._eatExps[itemId] = nil
			break
		end
	end
end

--[[
	英雄突破等级变化
]]
function QHerosUtils:getBreakThrough(breakthroughLevel)
	if breakthroughLevel <= 0 then
		return 0
	end
	if breakthroughLevel < 3 then
		return breakthroughLevel - 1, "green"
	elseif breakthroughLevel < 6 then
		return breakthroughLevel - 3, "blue" -- blue
	else
		return breakthroughLevel - 6, "purple" -- purple
	end
end

return QHerosUtils