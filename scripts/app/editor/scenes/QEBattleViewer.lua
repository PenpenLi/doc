local QEBattleViewer = class("QEBattleViewer", function()
    return display.newScene("QEBattleViewer")
end)

local QESkeletonViewer = import(".QESkeletonViewer")
local QBattleScene = import("...scenes.QBattleScene")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("...ui.QUIViewController")
local QSkeletonViewController = import("...controllers.QSkeletonViewController")
local QFileCache = import("...utils.QFileCache")

function QEBattleViewer:ctor(options)
	-- background
	self:addChild(CCLayerColor:create(ccc4(128, 128, 128, 255), display.width, display.height))

	-- coordinate axis
	-- self._axisNode = CCNode:create()
	-- self:addChild(self._axisNode)
	-- local horizontalLine = CCDrawNode:create()
	-- horizontalLine:drawLine({-display.cx, 0}, {display.cx, 0})
	-- self._axisNode:addChild(horizontalLine)
	-- local verticalLine = CCDrawNode:create()
	-- verticalLine:drawLine({0, -display.cy}, {0, display.height})
	-- self._axisNode:addChild(verticalLine)

	-- self._skeletonRoot = CCNode:create()
	-- self:addChild(self._skeletonRoot)
	-- self._skeletonRoot:setScale(UI_DESIGN_WIDTH / BATTLE_SCREEN_WIDTH)

	-- self._infomationNode = CCNode:create()
	-- self:addChild(self._infomationNode)
	-- self._infomationNode:setPosition(0, display.height)

	-- self._menu = CCMenu:create()
	-- self:addChild(self._menu)
	-- self._menu:setPosition(0, display.height)

	app.tutorial._runingStage = nil

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

function QEBattleViewer:disableSlowMotion()
	if self._slowIndex ~= nil and self._slowIndex > 0 and self._slowHandler then
		self._slowIndex = 0
		self._slowHandler.destroy()
		self._slowHandler = nil
	end
end

function QEBattleViewer:toggleSlowMotion()
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

function QEBattleViewer:cleanup()
	self:endBattle()
end

function QEBattleViewer:onReceiveData(message)
	if message == nil then
		return
	end

	self._message = message
	self:onResetBattle()
end

function QEBattleViewer:endBattle()
	if app.grid then
    	app.grid:pauseMoving()
    end
    if app.scene then
    	app.scene:setBattleEnded(true)
	    app.scene:removeFromParentAndCleanup(true)
	    app.scene = nil
    end
end

function QEBattleViewer:onResetBattle()
	local msg = self._message
	local dungeonId = msg.dungeon
	local database = QStaticDatabase:sharedDatabase()
	local config = database:getDungeonConfigByID(dungeonId)
	assert(config, "no dungeon for " .. dungeonId .. "!")

	config.heroInfos = {}
	local override_properties = {}

	if msg.enableH1 > 0 then
		local hero = 
		{
			actorId = msg.characterH1,
			heroId = "EditorHero1",
			level = msg.levelH1,
			skills = {},
			ranCode = "R0",
			EXP = 100,
			POSITION = {X = 0, Y = 0},
		}
		local talent = database:getTalentByID(database:getCharacterByID(hero.actorId).talent)
		local skills = ""
		if msg.n1H1 > 0 then
			skills = skills .. talent.skill_1 .. "_" .. msg.n1H1 .. ";"
		end
		if talent.skill_2 ~= nil and msg.n2H1 > 0 then
			skills = skills .. talent.skill_2 .. "_" .. msg.n2H1 .. ";"
		end
		if msg.cH1 > 0  then
			skills = skills .. talent.skill_4 .. "_" .. msg.cH1 .. ";"
		end
		if msg.m1H1 > 0 then
			skills = skills .. talent.skill_5 .. "_" .. msg.m1H1 ..";"
		end
		if msg.m2H1 > 0 then
			skills = skills .. talent.skill_6 .. "_" .. msg.m2H1 ..";"
		end
		if msg.a1H1 > 0 then
			skills = skills .. talent.skill_7 .. "_" .. msg.a1H1 ..";"
		end
		if msg.a2H1 > 0 then
			skills = skills .. talent.skill_8 .. "_" .. msg.a2H1 ..";"
		end
		if msg.p1H1 > 0 then
			skills = skills .. talent.skill_9 .. "_" .. msg.p1H1 ..";"
		end
		if msg.p2H1 > 0 then
			skills = skills .. talent.skill_10 .. "_" .. msg.p2H1 ..";"
		end
		if msg.p3H1 > 0 then
			skills = skills .. talent.skill_11 .. "_" .. msg.p3H1 ..";"
		end
		if msg.p4H1 > 0 then
			skills = skills .. talent.skill_12 .. "_" .. msg.p4H1 ..";"
		end
		skills = skills .. msg.addSkillH1
		hero.skills = string.split(skills, ";")
		table.insert(config.heroInfos, hero)

		local override_property = {}
		override_property.hp = msg.hpH1
		override_property.atk = msg.atkH1
		table.insert(override_properties, override_property)
	end

	if msg.enableH2 > 0 then
		local hero = 
		{
			actorId = msg.characterH2,
			heroId = "EditorHero1",
			level = msg.levelH2,
			skills = {},
			ranCode = "R0",
			EXP = 100,
			POSITION = {X = 0, Y = 0},
		}
		local talent = database:getTalentByID(database:getCharacterByID(hero.actorId).talent)
		local skills = ""
		if msg.n1H2 > 0 then
			skills = skills .. talent.skill_1 .. "_" .. msg.n1H2 .. ";"
		end
		if talent.skill_2 ~= nil and msg.n2H2 > 0 then
			skills = skills .. talent.skill_2 .. "_" .. msg.n2H2 .. ";"
		end
		if msg.cH2 > 0  then
			skills = skills .. talent.skill_4 .. "_" .. msg.cH2 .. ";"
		end
		if msg.m1H2 > 0 then
			skills = skills .. talent.skill_5 .. "_" .. msg.m1H2 ..";"
		end
		if msg.m2H2 > 0 then
			skills = skills .. talent.skill_6 .. "_" .. msg.m2H2 ..";"
		end
		if msg.a1H2 > 0 then
			skills = skills .. talent.skill_7 .. "_" .. msg.a1H2 ..";"
		end
		if msg.a2H2 > 0 then
			skills = skills .. talent.skill_8 .. "_" .. msg.a2H2 ..";"
		end
		if msg.p1H2 > 0 then
			skills = skills .. talent.skill_9 .. "_" .. msg.p1H2 ..";"
		end
		if msg.p2H2 > 0 then
			skills = skills .. talent.skill_10 .. "_" .. msg.p2H2 ..";"
		end
		if msg.p3H2 > 0 then
			skills = skills .. talent.skill_11 .. "_" .. msg.p3H2 ..";"
		end
		if msg.p4H2 > 0 then
			skills = skills .. talent.skill_12 .. "_" .. msg.p4H2 ..";"
		end
		skills = skills .. msg.addSkillH2
		hero.skills = string.split(skills, ";")
		table.insert(config.heroInfos, hero)

		local override_property = {}
		override_property.hp = msg.hpH2
		override_property.atk = msg.atkH2
		table.insert(override_properties, override_property)
	end

	if msg.enableH3 > 0 then
		local hero = 
		{
			actorId = msg.characterH3,
			heroId = "EditorHero1",
			level = msg.levelH3,
			skills = {},
			ranCode = "R0",
			EXP = 100,
			POSITION = {X = 0, Y = 0},
		}
		local talent = database:getTalentByID(database:getCharacterByID(hero.actorId).talent)
		local skills = ""
		if msg.n1H3 > 0 then
			skills = skills .. talent.skill_1 .. "_" .. msg.n1H3 .. ";"
		end
		if talent.skill_2 ~= nil and msg.n2H3 > 0 then
			skills = skills .. talent.skill_2 .. "_" .. msg.n2H3 .. ";"
		end
		if msg.cH3 > 0  then
			skills = skills .. talent.skill_4 .. "_" .. msg.cH3 .. ";"
		end
		if msg.m1H3 > 0 then
			skills = skills .. talent.skill_5 .. "_" .. msg.m1H3 ..";"
		end
		if msg.m2H3 > 0 then
			skills = skills .. talent.skill_6 .. "_" .. msg.m2H3 ..";"
		end
		if msg.a1H3 > 0 then
			skills = skills .. talent.skill_7 .. "_" .. msg.a1H3 ..";"
		end
		if msg.a2H3 > 0 then
			skills = skills .. talent.skill_8 .. "_" .. msg.a2H3 ..";"
		end
		if msg.p1H3 > 0 then
			skills = skills .. talent.skill_9 .. "_" .. msg.p1H3 ..";"
		end
		if msg.p2H3 > 0 then
			skills = skills .. talent.skill_11 .. "_" .. msg.p2H3 ..";"
		end
		if msg.p3H3 > 0 then
			skills = skills .. talent.skill_12 .. "_" .. msg.p3H3 ..";"
		end
		if msg.p4H3 > 0 then
			skills = skills .. talent.skill_11 .. "_" .. msg.p4H3 ..";"
		end
		skills = skills .. msg.addSkillH3
		hero.skills = string.split(skills, ";")
		table.insert(config.heroInfos, hero)

		local override_property = {}
		override_property.hp = msg.hpH3
		override_property.atk = msg.atkH3
		table.insert(override_properties, override_property)
	end

	if msg.enableH4 > 0 then
		local hero = 
		{
			actorId = msg.characterH4,
			heroId = "EditorHero1",
			level = msg.levelH4,
			skills = {},
			ranCode = "R0",
			EXP = 100,
			POSITION = {X = 0, Y = 0},
		}
		local talent = database:getTalentByID(database:getCharacterByID(hero.actorId).talent)
		local skills = ""
		if msg.n1H4 > 0 then
			skills = skills .. talent.skill_1 .. "_" .. msg.n1H4 .. ";"
		end
		if talent.skill_2 ~= nil and msg.n2H4 > 0 then
			skills = skills .. talent.skill_2 .. "_" .. msg.n2H4 .. ";"
		end
		if msg.cH4 > 0  then
			skills = skills .. talent.skill_4 .. "_" .. msg.cH4 .. ";"
		end
		if msg.m1H4 > 0 then
			skills = skills .. talent.skill_5 .. "_" .. msg.m1H4 ..";"
		end
		if msg.m2H4 > 0 then
			skills = skills .. talent.skill_6 .. "_" .. msg.m2H4 ..";"
		end
		if msg.a1H4 > 0 then
			skills = skills .. talent.skill_7 .. "_" .. msg.a1H4 ..";"
		end
		if msg.a2H4 > 0 then
			skills = skills .. talent.skill_8 .. "_" .. msg.a2H4 ..";"
		end
		if msg.p1H4 > 0 then
			skills = skills .. talent.skill_9 .. "_" .. msg.p1H4 ..";"
		end
		if msg.p2H4 > 0 then
			skills = skills .. talent.skill_10 .. "_" .. msg.p2H4 ..";"
		end
		if msg.p3H4 > 0 then
			skills = skills .. talent.skill_11 .. "_" .. msg.p3H4 ..";"
		end
		if msg.p4H4 > 0 then
			skills = skills .. talent.skill_12 .. "_" .. msg.p4H4 ..";"
		end
		skills = skills .. msg.addSkillH4
		hero.skills = string.split(skills, ";")
		table.insert(config.heroInfos, hero)

		local override_property = {}
		override_property.hp = msg.hpH4
		override_property.atk = msg.atkH4
		table.insert(override_properties, override_property)
	end

	config.isEditor = true

    local scene = QBattleScene.new(config)
    self:addChild(scene)

    local sharedScheduler = CCDirector:sharedDirector():getScheduler()
    local handle
    handle = sharedScheduler:scheduleScriptFunc(
    function()
    	if app.battle then
    		sharedScheduler:unscheduleScriptEntry(handle)
    	else
    		return
    	end

	    local heroes = app.battle:getHeroes()
	    for i, hero in ipairs(heroes) do
	    	local property = override_properties[i]

	    	local hp = property.hp
	    	hp = tonumber(hp)
	    	if hp and hp ~= 0 then
	    		hero:set("basic_hp", hp)
	    		hero:set("hp_grow", 0)
	    		hero:setFullHp()
	    	end
	    	
	    	local atk = property.atk
	    	atk = tonumber(atk)
	    	if atk and atk ~= 0 then
	    		hero:set("basic_attack", atk)
	    		hero:set("attack_grow", 0)
	    	end
	    end
	end, 0, false)
end

return QEBattleViewer