
local QEArenaViewer = class("QEArenaViewer", function()
    return display.newScene("QEArenaViewer")
end)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QBattleScene = import("...scenes.QBattleScene")

function QEArenaViewer:ctor()
	-- background
	self:addChild(CCLayerColor:create(ccc4(128, 128, 128, 255), display.width, display.height))

    local menu = CCMenu:create()
    self:addChild(menu, 1)
    local button = CCMenuItemFont:create("暂停")
    button:setPosition(0 - 500, 300)
    button:setEnabled(true)
    button:registerScriptTapHandler(function()
    	self:disableSlowMotion()
    	app.battle:pause()
    end)
    menu:addChild(button)
    local button = CCMenuItemFont:create("步进")
    button:setPosition(0 - 425, 300)
    button:setEnabled(true)
    button:registerScriptTapHandler(function()
    	self:disableSlowMotion()
		app.battle:resume()
		scheduler.performWithDelayGlobal(function()
			app.battle:pause()
		end, 0)
    end)
    menu:addChild(button)
    local button = CCMenuItemFont:create("继续")
    button:setPosition(0 - 350, 300)
    button:setEnabled(true)
    button:registerScriptTapHandler(function()
    	self:disableSlowMotion()
    	app.battle:resume()
    end)
    menu:addChild(button)
    local button = CCMenuItemFont:create("慢速")
    button:setPosition(0 - 275, 300)
    button:setEnabled(true)
    button:registerScriptTapHandler(function()
    	self:toggleSlowMotion()
    end)
    menu:addChild(button)
end

function QEArenaViewer:disableSlowMotion()
	if self._slowIndex ~= nil and self._slowIndex > 0 and self._slowHandler then
		self._slowIndex = 0
		self._slowHandler.destroy()
		self._slowHandler = nil
	end
end

function QEArenaViewer:toggleSlowMotion()
	if self._slowMax == nil then
		self._slowMax = 2
	end
	if self._slowIndex == nil then
		self._slowIndex = 0
	end

	self._slowIndex = (self._slowIndex + 1) % self._slowMax
	if self._slowIndex > 0 and self._slowHandler == nil then
	    local obj = {}
    	local function pause()	
			if obj._ended then
				return
			end	

    		scheduler.performWithDelayGlobal(function()
    			if obj._ended then
    				return
    			end
    			app.battle:pause()
    			obj.resume()
    		end, 0)
    	end
    	local function resume()		
			if obj._ended then
				return
			end
			
			local sharedScheduler = CCDirector:sharedDirector():getScheduler()
			local count = math.pow(2, self._slowIndex - 1)
		    local handle 
		    handle = sharedScheduler:scheduleScriptFunc(function()
		    	count = count - 1
		    	if count == 0 then
		        	sharedScheduler:unscheduleScriptEntry(handle)
	    			if obj._ended then
	    				return
	    			end
	    			app.battle:resume()
	    			obj.pause()
		    	end
		    end, 0, false)
    	end
    	obj = {pause = pause, resume = resume}
    	obj.pause()
	    obj.destroy = function()
	    	obj._ended = true
	    	app.battle:resume()
	   	end
	    self._slowHandler = obj
	elseif self._slowIndex == 0 and self._slowHandler ~= nil then
		self._slowHandler.destroy()
		self._slowHandler = nil
	end
end

function QEArenaViewer:cleanup()
	self:endBattle()
end

function QEArenaViewer:onReceiveData(message)
	if message == nil then
		return
	end

	self._message = message
	self:onResetBattle()
end

function QEArenaViewer:endBattle(isWin)
	if app.grid then
    	app.grid:pauseMoving()
    end
    if app.scene then
    	app.scene:setBattleEnded(true)
	    app.scene:removeFromParentAndCleanup(true)
	    app.scene = nil
    end
    if app.editor.databaser ~= nil then
    	app.editor.databaser:onBattleEnd(isWin)
    end
end

function QEArenaViewer:onResetBattle()
	if self._message == nil or self._message.team1 == nil or self._message.team2 == nil then
		return
	end

	printTable(self._message)

	local config = {}
	config.id = "arena"
	config.name = "竞技场关卡"
	config.description = "这是一个竞技场关卡"
	config.monster_id = "arena_"
	config.isPVPMode = true
	config.isArena = true
	config.duration = 90
	config.team_exp = 0
	config.energy = 0
	config.hero_exp = 0
	config.money = 0
	config.sweep_id = -1
	config.sweep_num = -1
	config.mode = 3 -- BATTLE_MODE
	config.scene = "ccb/Battle_Scene.ccbi"
	config.bg = "map/arena.jpg"
	config.bg_2 = "map/arena.jpg"
	config.bg_3 = "map/arena.jpg"
	config.bgm = "not_exist.mp3"

	local compareFunc = function(member1, member2)
			local character1 = QStaticDatabase:sharedDatabase():getCharacterByID(member1.id)
			local character2 = QStaticDatabase:sharedDatabase():getCharacterByID(member2.id)
			local talent1 = QStaticDatabase:sharedDatabase():getTalentByID(character1.talent)
			local talent2 = QStaticDatabase:sharedDatabase():getTalentByID(character2.talent)
			if talent1.hatred < talent2.hatred then
				return true
			elseif talent1.hatred > talent2.hatred then
				return false
			else
				if member1.id >= member2.id then
					return false
				else
					return true
				end
			end
		end
		
	if #self._message.team1 > 1 then
		table.sort(self._message.team1, compareFunc)
	end
	if #self._message.team2 > 1 then
		table.sort(self._message.team2, compareFunc)
	end

	local heroInfo = {}
	for _, member in ipairs(self._message.team1) do
		local info = {}
		info.actorId = member.id
		info.level = member.level
		info.breakthrough = member["break"]
		info.grade = member.grade
		info.rankCode = "R0"
		if member.equipment == "all" then
			info.itmes = app.editor.helper:getHeroItems(info.actorId, info.breakthrough)
		else
			info.items = {}
		end
		local isMaxLevel = true
		if member.skill ~= "max" then
			isMaxLevel = false
		end
		info.skills = app.editor.helper:getHeroSkills(info.actorId, info.level, info.breakthrough, isMaxLevel)
		if info.actorId == "garona" then
			for _, skill in ipairs(info.skills) do
				if skill == "bladestorm_orc_warlord_1" then
					info.skills[_] = "killing_spree_test"
					break
				end
			end
		end
		table.insert(heroInfo, info)
	end
	config.heroInfos = heroInfo

	local rivalInfo = {}
	for _, member in ipairs(self._message.team2) do
		local info = {}
		info.actorId = member.id
		info.level = member.level
		info.breakthrough = member["break"]
		info.grade = member.grade
		info.rankCode = "R0"
		if member.equipment == "all" then
			info.itmes = app.editor.helper:getHeroItems(info.actorId, info.breakthrough)
		else
			info.items = {}
		end
		local isMaxLevel = true
		if member.skill ~= "max" then
			isMaxLevel = false
		end
		info.skills = app.editor.helper:getHeroSkills(info.actorId, info.level, info.breakthrough, isMaxLevel)
		table.insert(rivalInfo, info)
	end
	config.pvp_rivals = rivalInfo
	config.isEditor = true

	print("battle config:")
	printTable(config)

	local scene = QBattleScene.new(config)
    self:addChild(scene)

end

return QEArenaViewer