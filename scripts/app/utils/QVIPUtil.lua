-- Author: qinyuanji
-- 2015/03/04
-- This class is for VIP wrapping configurations

local QVIPUtil = class("QVIPUtil")
local QStaticDatabase = import("...controllers.QStaticDatabase")


function QVIPUtil:VIPLevel( ... )
	return 10
end

function QVIPUtil:getMaxLevel( ... )
	if self.maxLevel == nil then
		self.maxLevel = table.nums(QStaticDatabase:sharedDatabase():getVIP()) - 1
	end
	return self.maxLevel
end

--需要充值符石数
function QVIPUtil:cash(level)
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve cash exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].cash
end

--赠送扫荡劵数
function QVIPUtil:getFreeSweepCount(level)
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve sweep coupon exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].sweep_coupon
end

--购买体力/金钱次数上限
-- vType: ITEM_TYPE.ENERY - enery ITEM_TYPE.MONEY - money
function QVIPUtil:getBuyVirtualCount(vType, level)
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve buy energy count exceed maximum VIP level")
	end
	if vType  == ITEM_TYPE.ENERGY  then
		return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].energy_limit
	else
		return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].money_limit
	end
end

--可重置精英关卡次数
function QVIPUtil:getResetEliteDungeonCount( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve elite dungeon count exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].dungeon_elite_limit
end

--技能点上限
function QVIPUtil:getSkillPointCount( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve maximum skill point exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].skill_points_limit
end

--可购买竞技场门票次数
function QVIPUtil:getArenaResetCount( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve arena reset count exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].arena_times_limit
end

--太阳井重置次数
function QVIPUtil:getSunwellResetCount( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve sunwell reset count exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].sunwell_times
end


--开启扫荡关卡功能(使用符石扫荡关卡)
function QVIPUtil:canUseTokenSweep( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve canUseTokenSweep exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_token_sweep
end

function QVIPUtil:getUseTokenSweepUnlockLevel(  )
	local tokenSweep = {}
	for k, v in pairs(QStaticDatabase:sharedDatabase():getVIP()) do
		table.insert(tokenSweep, k)
	end
	table.sort(tokenSweep, function (x, y)
		return tonumber(x) < tonumber(y)
	end)
	for _, v in ipairs(tokenSweep) do
		if QStaticDatabase:sharedDatabase():getVIP()[tostring(v)].switch_token_sweep == true then
			return v
		end
	end
	return #tokenSweep
end

--可购买技能强化点数
function QVIPUtil:canBuySkillPoint( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve canBuySkillPoint exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_skill_points
end

function QVIPUtil:getBuySkillPointUnlockLevel(  )
	local skillPointLevel = {}
	for k, v in pairs(QStaticDatabase:sharedDatabase():getVIP()) do
		table.insert(skillPointLevel, k)
	end
	table.sort(skillPointLevel, function (x, y)
		return tonumber(x) < tonumber(y)
	end)
	for _, v in ipairs(skillPointLevel) do
		if QStaticDatabase:sharedDatabase():getVIP()[tostring(v)].switch_skill_points == true then
			return v
		end
	end
	return #skillPointLevel
end

--重置竞技场CD开关
function QVIPUtil:canResetArenaCD( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve canResetArenaCD exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_arena_cd
end

function QVIPUtil:getcanResetArenaCDUnlockLevel(  )
	local arenaCD = {}
	for k, v in pairs(QStaticDatabase:sharedDatabase():getVIP()) do
		table.insert(arenaCD, k)
	end
	table.sort(arenaCD, function (x, y)
		return tonumber(x) < tonumber(y)
	end)
	for _, v in ipairs(arenaCD) do
		if QStaticDatabase:sharedDatabase():getVIP()[tostring(v)].switch_arena_cd == true then
			return v
		end
	end
	return #arenaCD
end
--一键扫荡10次关卡
function QVIPUtil:canSweepTenTimes( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve canSweepTenTimes exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_sweep_ten_times
end

--永久召唤地精商人
function QVIPUtil:enableGoblinPermanent( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve enableGoblinPermanent exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_shop_1_permanent
end

--永久召唤黑市商人
function QVIPUtil:enableBlackMarketPermanent( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve enableBlackMarketPermanent exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_shop_2_permanent
end

--太阳井宝箱金钱增加50%开关
function QVIPUtil:sunwellMoneyBonus( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve sunwellMoneyBonus exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_sunwell_money
end

--装备一键强化开关
function QVIPUtil:oneClickEnhance( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve oneClickEnhance exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_enhance_one
end

--装备全部强化开关
function QVIPUtil:allEnhance( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve allEnhance exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_enhance_all
end

--装备一键附魔开关
function QVIPUtil:oneClickEnchant( level )
	local lv = level or self:VIPLevel()
	if lv > self:getMaxLevel() then
		lv = self:getMaxLevel()
		print("retrieve oneClickEnchant exceed maximum VIP level")
	end
	return QStaticDatabase:sharedDatabase():getVIP()[tostring(lv)].switch_enchant_immediate
end



return QVIPUtil