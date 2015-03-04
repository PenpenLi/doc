--
-- Author: Your Name
-- Date: 2015-01-23 09:57:47
--
local QArena = class("QArena")
local QUIViewController = import("..ui.QUIViewController")
local QStaticDatabase = import("..controllers.QStaticDatabase")
local QTutorialDirector = import("..tutorial.QTutorialDirector")

QArena.EVENT_UPDATE = "QARENA_EVENT_UPDATE"
QArena.EVENT_UPDATE_SELF = "QARENA_EVENT_UPDATE_SELF"
QArena.EVENT_UPDATE_TEAM = "QARENA_EVENT_UPDATE_TEAM"

function QArena:ctor(options)
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self.info = {}
	self.myInfo = {}
	self:clearFighter()
end

function QArena:openArena()
  --浮动提示条
  	local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  	if remote.user.level < unlockVlaue["UNLOCK_ARENA"].value then
      	app.tip:floatTip("战队等级"..unlockVlaue["UNLOCK_ARENA"].value.."级解锁")
  	else
	    if false and remote.user.nickname == nil or remote.user.nickname == "" then
	      	app.tutorial:startTutorial(QTutorialDirector.Stage_10_ArenaAddName)
	    end
	    self:requestArenaInfo(function(data)
			app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogArena", options = {arenaResponse = data.arenaResponse}})
		end)
		return true
  	end
  	return false
end

function QArena:requestSetDefenseHero(team)
	app:getClient():setDefenseHero(team, function(data)
		self.myInfo.heros = {}
		for _,actorId in pairs(team) do
			table.insert(self.myInfo.heros, remote.herosUtil:getHeroByID(actorId))
		end
		self.myInfo.force = remote.teams:getBattleForceForKey(remote.teams.ARENA_DEFEND_TEAM)
		self:dispatchEvent({name = QArena.EVENT_UPDATE_TEAM, data = self:madeReciveData("self")})
	end)
end

function QArena:requestBuyFighterCount()
	app:getClient():buyFightCountRequest(function (data)
		self:updateSelf(data)
		self:dispatchEvent({name = QArena.EVENT_UPDATE_SELF, data = self:madeReciveData("self")})
	end)
end

function QArena:requestArenaInfo(callBack)
	if self.fighter ~= nil and #self.fighter > 0 and #self.fighter[1] > 3 and self.myInfo ~= nil and self.refreshCount <= self.refreshMaxCount then
		local data = self:madeReciveData()
		if callBack ~= nil then callBack(data) end
		self.refreshCount = self.refreshCount + 1
		self:dispatchEvent({name = QArena.EVENT_UPDATE, data = data})
	else
		local team = remote.teams:getTeams(remote.teams.INSTANCE_TEAM)
		if team == nil or #team == 0 then
			team = {}
			local haveHeros = remote.herosUtil:getHaveHeroKey()
			local maxCount = #haveHeros > remote.teams:getHerosMaxCount() and remote.teams:getHerosMaxCount() or #haveHeros
			for i=1,maxCount,1 do
				table.insert(team, haveHeros[i])
			end
		end
		app:getClient():arenaRefresh(team, function (data)
			self:updateFighter(data)
			self:updateSelf(data)
			local data = self:madeReciveData()
			self:dispatchEvent({name = QArena.EVENT_UPDATE, data = data})
			if callBack ~= nil then callBack(data) end
		end)
		if self.refreshCount > 0 then
			self.refreshMaxCount = self.refreshCount + 1
			self.refreshCount = 0
		end
	end
end

function QArena:clearFighter()
	self.fighter = {}
	self.refreshCount = 0
	self.refreshMaxCount = 3
end

function QArena:updateFighter(data)
	if data.arenaResponse ~= nil and data.arenaResponse.rivals then
		for index,value in pairs(data.arenaResponse.rivals) do
			remote.teams:sortTeam(value.heros)
			if index <= 4 then
				if #self.fighter < index then
					self.fighter[index] = {}
				end
				if self:checkFighter(value.userId) == true then
					table.insert(self.fighter[index], value)
				end
			end
		end
	end
end

function QArena:checkFighter(fighterId)
	for _,fighter in pairs(self.fighter) do
		for _,value in pairs(fighter) do
			if fighterId == value.userId then
				return false
			end
		end
	end
	return true
end

function QArena:removeFighter(fighterId)
	for _,fighter in pairs(self.fighter) do
		for index,value in pairs(fighter) do
			if fighterId == value.userId then
				table.remove(fighter,index)
			end
		end
	end
	return true
end

function QArena:updateSelf(data)
	if data.arenaResponse ~= nil and data.arenaResponse.self ~= nil then
		for key,value in pairs(data.arenaResponse.self) do
			self.myInfo[key] = value
		end
	end
	remote.teams:sortTeam(self.myInfo.heros)
end

function QArena:updateArenaMoney(count)
	if self.myInfo ~= nil then
		self.myInfo.arenaMoney = count
	end
end

function QArena:madeReciveData(type)
	local data = {}
	data.arenaResponse = {}
	if type == nil or type == "self" then
		data.arenaResponse.self = self.myInfo
	end
	if type == nil or type == "rivals" then
		data.arenaResponse.rivals = {}
		for i=1,4,1 do
			if self.fighter[i] ~= nil and #self.fighter[i] > 0 then
				local randomNum = math.random(#self.fighter[i])
				table.insert(data.arenaResponse.rivals, self.fighter[i][randomNum])
				table.remove(self.fighter[i], randomNum)
			end
		end

		--保存上一轮抽取的对手在本轮中
		if self._oldRivals ~= nil then
			for index,value in pairs(self._oldRivals) do
				if index <= 4 then
					if #self.fighter < index then
						self.fighter[index] = {}
					end
					if self:checkFighter(value.userId) == true then
						table.insert(self.fighter[index], value)
					end
				end
			end
		end
		self._oldRivals = clone(data.arenaResponse.rivals)
	end
	return data
end

return QArena