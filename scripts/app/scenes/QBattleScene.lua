--[[
    Class name: QBattleScene
    Create by Julian
    QBattleScene is a scene inherit from QBaseScene that display and control the battle process
--]]

local QBaseScene = import(".QBaseScene")
local QBattleScene = class("QBattleScene", QBaseScene)

local QFileCache = import("..utils.QFileCache")
local QBaseActorView = import("..views.QBaseActorView")
local QTouchActorView = import("..views.QTouchActorView")
local QHeroActorView = import("..views.QHeroActorView")
local QNpcActorView = import("..views.QNpcActorView")
local QDragLineController = import("..controllers.QDragLineController")
local QTouchController = import("..controllers.QTouchController")
local QNotificationCenter = import("..controllers.QNotificationCenter")
local QBattleManager = import("..controllers.QBattleManager")
local QSkeletonViewController = import("..controllers.QSkeletonViewController")
local QStaticDatabase = import("..controllers.QStaticDatabase")
local QPositionDirector = import("..utils.QPositionDirector")
local QActor = import("..models.QActor")
local QSkill = import("..models.QSkill")
local QTeam = import("..utils.QTeam")
local QHeroStatusView = import("..ui.battle.QHeroStatusView")
local QNpcTipView = import("..ui.battle.QNpcTipView")
local QBattleDialog = import("..ui.battle.QBattleDialog")
local QBattleDialogGameRule = import("..ui.battle.QBattleDialogGameRule")
local QBattleDialogWin = import("..ui.battle.QBattleDialogWin")
local QBattleDialogStar = import("..ui.battle.QBattleDialogStar")
local QBattleDialogLose = import("..ui.battle.QBattleDialogLose")
local QBattleDialogPause = import("..ui.battle.QBattleDialogPause")
local QBattleDialogAutoSkill = import("..ui.battle.QBattleDialogAutoSkill")
local QBattleDialogMissions = import("..ui.battle.QBattleDialogMissions")
local QBossHpView = import("..ui.battle.QBossHpView")
local QBaseEffectView = import("..views.QBaseEffectView")
local QDialogTeamUp = import(".QDialogTeamUp")
local QUIWidgetTutorialHandTouch = import("..ui.widgets.QUIWidgetTutorialHandTouch")
local QUIWidgetTutorialDialogue = import("..ui.widgets.QUIWidgetTutorialDialogue")
local QUIWidgetBattleTutorialDialogue = import("..ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetItemsBox = import("..ui.widgets.QUIWidgetItemsBox")
local QBattleMissionTracer = import("..tracer.QBattleMissionTracer")
local QEntranceBase = import("..cutscenes.QEntranceBase")
local QKreshEntrance = import("..cutscenes.QKreshEntrance")
local QNavigationController = import("...controllers.QNavigationController")
local QMissionBase = import("..tracer.mission.QMissionBase")
local QFullCircleUiMask = import("..ui.battle.QFullCircleUiMask")
local QArenaDialogWin = import("..ui.battle.QArenaDialogWin")
local QArenaDialogLose = import("..ui.battle.QArenaDialogLose")
local QSunWellDialogWin = import("..ui.battle.QSunWellDialogWin")

local function createTipCache()
    local _tips_inuse = {}
    local _tips_available = {}
    local _stop_return = false
    -- local _tips_available_number = 0
    local function getTip(ccb_name)
        local _available = _tips_available[ccb_name]
        local _inuse = _tips_inuse[ccb_name]
        if not _available then
            _available = {}
            _tips_available[ccb_name] = _available
        end
        if not _inuse then
            _inuse = {}
            _tips_inuse[ccb_name] = _inuse
        end

        local it = next(_available)
        if it then
            tip = it
            _available[it] = nil
            -- _tips_available_number = _tips_available_number - 1
            -- printInfo("_tips_available_number = %d", _tips_available_number)
            _inuse[it] = tip
        else
            local ccbOwner = {}
            tip = CCBuilderReaderLoad(ccb_name, CCBProxy:create(), ccbOwner)
            tip.ccbOwner = ccbOwner
            tip.need_return = true
            tip.ccb_name = ccb_name
            tip:retain()
            _inuse[tip] = tip
        end
        return tip
    end
    local function returnTip(tip)
        local _available = _tips_available[tip.ccb_name]
        local _inuse = _tips_inuse[tip.ccb_name]

        if _inuse[tip] and (not _available or not _available[tip]) then
            _inuse[tip] = nil
            if not _stop_return and _available then
                _available[tip] = tip
            else
                tip:release()
            end
            -- _tips_available_number = _tips_available_number + 1
            -- printInfo("_tips_available_number = %d", _tips_available_number)
        end
    end
    local function stopCache()
        _stop_return = true
        for _, _available in pairs(_tips_available) do
            for _, tip in pairs(_available) do
                tip:release()
            end
        end
        _tips_available = {}
    end
    local function startCache()
        _stop_return = false
    end
    local function makeRoom(ccb_name, count)
        local arr = {}
        for i = 1, count do
            table.insert(arr, getTip(ccb_name))
        end
        for i = 1, count do
            returnTip(arr[i])
        end
        arr = nil
    end
    return {getTip = getTip, returnTip = returnTip, stopCache = stopCache, startCache = startCache, makeRoom = makeRoom}
end

--[[
    member of QBattleScene:
--]]
function QBattleScene:ctor(config)
    local owner = {}

    local database = QStaticDatabase.sharedDatabase()
    QBattleScene.super.ctor(self, {ccbi = config.scene, owner = owner})
    self._dungeonConfig = config
    if self._dungeonConfig.mode == nil then
        self._dungeonConfig.mode = BATTLE_MODE.SEVERAL_WAVES
    end
    
    self._heroPisition = config.heroPosition

    self._isHaveMissions = remote.instance:checkDungeonIsShowStar(self._dungeonConfig.id)
    self._isPassedBefore = false
    local passInfo = remote.instance:getPassInfoForDungeonID(self._dungeonConfig.id)
    if passInfo ~= nil and passInfo.star ~= nil and passInfo.star >= 3 then
        self._isPassedBefore = true
    end
    self._isActiveDungeon = false
    if remote.activityInstance:getDungeonById(self._dungeonConfig.id) ~= nil then
        self._isActiveDungeon = true
    end

    local topBar_ccbProxy = CCBProxy:create()
    local topBar_ccbOwner = {}
    if self:isPVPMode() == true then
        if self:isInArena() then
            self._topBar = CCBuilderReaderLoad("Battle_Arena_TopBar.ccbi", topBar_ccbProxy, topBar_ccbOwner)
        elseif self:isInSunwell() then
            topBar_ccbOwner.onPause = handler(self, QBattleScene._onPauseButtonClicked)
            self._topBar = CCBuilderReaderLoad("Battle_Sunwell_TopBar.ccbi", topBar_ccbProxy, topBar_ccbOwner)
        else
            assert(false, "Unknown PVP Mode!")
        end
        self._topBar:setPosition(0, display.height)
        self._labelCountDown = topBar_ccbOwner.label_Countdown
        self._labelCountDown:setVisible(false)

        if self._dungeonConfig.team1Name ~= nil then
            topBar_ccbOwner.CCLabelTFF_TeamName1:setString(self._dungeonConfig.team1Name)
        end
        if self._dungeonConfig.team1Icon ~= nil then
            local x, y = topBar_ccbOwner.node_head1:getPosition()
            local parent = topBar_ccbOwner.node_head1:getParent()
            topBar_ccbOwner.node_head1:retain()
            topBar_ccbOwner.node_head1:removeFromParentAndCleanup(false)
            local ccclippingNode = QFullCircleUiMask.new()
            ccclippingNode:setRadius(50)
            ccclippingNode:addChild(topBar_ccbOwner.node_head1)
            parent:addChild(ccclippingNode)
            ccclippingNode:setPosition(x, y)
            topBar_ccbOwner.node_head1:setPosition(0, 0)
            topBar_ccbOwner.node_head1:release()
            topBar_ccbOwner.node_head1:addChild(CCSprite:create(self._dungeonConfig.team1Icon))
        end

        if self._dungeonConfig.team2Name ~= nil then
            topBar_ccbOwner.CCLabelTFF_TeamName2:setString(self._dungeonConfig.team2Name)
        end
        if self._dungeonConfig.team2Icon ~= nil then
            local x, y = topBar_ccbOwner.node_head2:getPosition()
            local parent = topBar_ccbOwner.node_head2:getParent()
            topBar_ccbOwner.node_head2:retain()
            topBar_ccbOwner.node_head2:removeFromParentAndCleanup(false)
            local ccclippingNode = QFullCircleUiMask.new()
            ccclippingNode:setRadius(50)
            ccclippingNode:addChild(topBar_ccbOwner.node_head2)
            parent:addChild(ccclippingNode)
            ccclippingNode:setPosition(x, y)
            topBar_ccbOwner.node_head2:setPosition(0, 0)
            topBar_ccbOwner.node_head2:release()
            topBar_ccbOwner.node_head2:addChild(CCSprite:create(self._dungeonConfig.team2Icon))
        end

        -- local sprite_green = topBar_ccbOwner.sprite_flag_green
        -- local sprite_yellow = topBar_ccbOwner.sprite_flag_yellow
        -- sprite_green:retain()
        -- sprite_yellow:retain()
        -- local green_parent = sprite_green:getParent()
        -- local yellow_parent = sprite_yellow:getParent()
        -- sprite_green:removeFromParent()
        -- sprite_yellow:removeFromParent()
        -- green_parent:addChild(sprite_yellow)
        -- yellow_parent:addChild(sprite_green)
        -- local x, y = sprite_yellow:getPosition()
        -- sprite_yellow:setPosition(sprite_green:getPosition())
        -- sprite_green:setPosition(x, y)
    else
        topBar_ccbOwner.onPause = handler(self, QBattleScene._onPauseButtonClicked)
        topBar_ccbOwner.onClickMission = handler(self, QBattleScene._onMissionButtonClicked)
        self._topBar = CCBuilderReaderLoad("Battle_Widget_TopBar.ccbi", topBar_ccbProxy, topBar_ccbOwner)
        self._topBar:setPosition(0, display.height)
        self._labelCountDown = topBar_ccbOwner.label_Countdown
        self._labelCountDown:setVisible(false)
        self._labelMoney = topBar_ccbOwner.label_money
        self._currentMoney = 0
        self._labelMoney:setString("0")
        self._labelChest = topBar_ccbOwner.label_chest
        self._currentChest = 0
        self._labelChest:setString("0")
        self._sprite_money = topBar_ccbOwner.sprite_money
        self._sprite_item = topBar_ccbOwner.sprite_item
        self._labelWave = topBar_ccbOwner.label_wave
        self._labelWave:setVisible(false)
        self._waveBackground = topBar_ccbOwner.sprite_waveBackground
        self._waveBackground:setVisible(false)
        self._missionCompleteNode = topBar_ccbOwner.node_MissionComplete
        self._starRoot = topBar_ccbOwner.node_starRoot
        self._starOff1 = topBar_ccbOwner.node_starOff1
        self._starOff1:setVisible(true)
        self._starOff2 = topBar_ccbOwner.node_starOff2
        self._starOff2:setVisible(true)
        self._starOff3 = topBar_ccbOwner.node_starOff3
        self._starOff3:setVisible(true)
        self._starOn1 = topBar_ccbOwner.node_starOn1
        self._starOn1:setVisible(false)
        self._starOn2 = topBar_ccbOwner.node_starOn2
        self._starOn2:setVisible(false)
        self._starOn3 = topBar_ccbOwner.node_starOn3
        self._starOn3:setVisible(false)
        self._labelDeadEnemies = topBar_ccbOwner.label_deadEnemies

        if self._isHaveMissions == false or self._isActiveDungeon == true then
            self._starRoot:setVisible(false)
        end

        self._bossHpBar = QBossHpView.new()
        topBar_ccbOwner.node_bossHealth:addChild(self._bossHpBar)
        self._bossHpBar:setVisible(false)
    end

    self:addUI(self._topBar)

    local autoSkill_ccbProxy = CCBProxy:create()
    local autoSkill_ccbOwner = {}
    autoSkill_ccbOwner.onClickAutoSkill = handler(self, QBattleScene._onAutoSkillClicked)
    self._autoSkillBar = CCBuilderReaderLoad("Battle_But_AutoSkill.ccbi", autoSkill_ccbProxy, autoSkill_ccbOwner)
    self._autoSkillBar:setPosition(self._ccbOwner.node_autoSkillButton:getPosition())
    if self:isPVPMode() and self:isInArena() then
        autoSkill_ccbOwner.sprite_lock:setVisible(true)
    end
    self:addUI(self._autoSkillBar)

    local arrow_ccbProxy = CCBProxy:create()
    local arrow_ccbOwner = {}
    arrow_ccbOwner.onTriggerNext = handler(self, QBattleScene._onNextWaveClicked)
    self._arrow = CCBuilderReaderLoad("effects/arrow_battle.ccbi", arrow_ccbProxy, arrow_ccbOwner)
    self._arrow:setPosition(self._ccbOwner.node_arrow:getPosition())
    self:addUI(self._arrow)
    self._arrow:setVisible(false)

    local bgFileName = ""
    if self._dungeonConfig.bg ~= nil then
        local bgs = string.split(self._dungeonConfig.bg, ";")
        bgFileName = bgs[math.random(1, #bgs)]
    else
        bgFileName = "map/arena.jpg"
    end

    local pvrImage = string.sub(bgFileName, 1, string.len(bgFileName) - 3) .. "pvr.ccz"
    local pvrImageFullPath = CCFileUtils:sharedFileUtils():fullPathForFilename(pvrImage)
    if CCFileUtils:sharedFileUtils():isFileExist(pvrImageFullPath) == true then
        bgFileName = pvrImageFullPath
    end

    self._backgroundImage = CCSprite:create(bgFileName)
    owner.node_background:addChild(self._backgroundImage)

    self._npcTipView = QNpcTipView.new()
    self:addUI(self._npcTipView)
    self._npcTipView:setPosition(50, display.height - global.screen_margin_top * global.pixel_per_unit)

    self._groundEffectView = {}
    self._heroViews = {}
    self._heroStatusViews = {}
    self._enemyViews = {}
    self._effectViews = {}
    self._frontEffectView = {}

    self._showBlackLayerReferenceCount = 0

    local tip_cache = createTipCache()
    tip_cache.makeRoom("effects/Heal_number.ccbi", 8)
    tip_cache.makeRoom("effects/Attack_Ynumber.ccbi", 8)
    tip_cache.makeRoom("effects/Attack_number.ccbi", 8)
    tip_cache.makeRoom("effects/Attack_baoji.ccbi", 4)
    tip_cache.makeRoom("effects/Attack_Ybaoji.ccbi", 4)
    self._tip_cache = tip_cache

    self._startDelay = 0
    self._ended = false -- 战斗结束，比如获胜或者失败后，有些功能应该屏蔽掉，比如暂停。
end

function QBattleScene:showHeroStatusViews()
    for _, view in ipairs(self._heroStatusViews) do
        view:setVisible(true)
    end
end

function QBattleScene:hideHeroStatusViews()
    for _, view in ipairs(self._heroStatusViews) do
        view:setVisible(false)
    end
end

function QBattleScene:showHeroStatusView(i)
    self._heroStatusViews[i]:setVisible(true)
end

function QBattleScene:hideHeroStatusView(i)
    self._heroStatusViews[i]:setVisible(false)
end

function QBattleScene:_checkBattleStartDelay(startPosition, stopPosition, moveSpeed)
    if startPosition == nil or stopPosition == nil or moveSpeed == nil or moveSpeed <= 0 then
        return
    end

    local deltaX = startPosition.x - stopPosition.x
    local deltaY = startPosition.y - stopPosition.y
    local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
    local timeCost = distance / moveSpeed
    if self._startDelay < timeCost then
        self._startDelay = timeCost
    end
end

function QBattleScene:_prepareHeroes()
    -- create views for heroes
    local views = {}

    if app.battle:isInTutorial() == true then
        local w = BATTLE_AREA.width / global.screen_big_grid_width
        local h = BATTLE_AREA.height / global.screen_big_grid_height
        local heros = app.battle:getHeroes()
        local heroCount = table.nums(heros)
        for i, hero in ipairs(heros) do
            local view = QHeroActorView.new(hero)
            view:setDirection(QBaseActorView.DIRECTION_RIGHT)
            view:setAnimationScale(app.battle:getTimeGear(), "time_gear")
            table.insert(views, view)
            self:addSkeletonContainer(view)

            local x = self._dungeonConfig.heroInfos[i].position.x * w + BATTLE_AREA.left
            local y = self._dungeonConfig.heroInfos[i].position.y * h + BATTLE_AREA.bottom
            app.grid:addActor(view:getModel())
            app.grid:setActorTo(view:getModel(), ccp(x, y))

            -- manual skill button, hero hp and icon
            local heroStatusView = QHeroStatusView.new(hero)
            local nodeName = nil
            if heroCount == 1 then
                nodeName = "node_skill2_odd"
            elseif heroCount == 2 then
                nodeName = "node_skill" .. tostring(i + 1)
            elseif heroCount == 3 then
                nodeName = "node_skill" .. tostring(i) .. "_odd"
            else
                nodeName = "node_skill" .. tostring(i)
            end
            heroStatusView:setPosition(ccp(self._ccbOwner[nodeName]:getPosition()))
            self:addUI(heroStatusView)
            table.insert(self._heroStatusViews, heroStatusView)
        end

    elseif app.battle:isPVPMode() == true then
        local heros = app.battle:getHeroes()
        local heroCount = table.nums(heros)
        for i, hero in ipairs(heros) do
            -- hero:resetStateForBattle() -- 清理之前的记录    

            local view = QHeroActorView.new(hero)
            view:setAnimationScale(app.battle:getTimeGear(), "time_gear")
            table.insert(views, view)

            -- manual skill button, hero hp and icon
            local heroStatusView = QHeroStatusView.new(hero)
            local nodeName = nil
            if heroCount == 1 then
                nodeName = "node_skill2_odd"
            elseif heroCount == 2 then
                nodeName = "node_skill" .. tostring(i + 1)
            elseif heroCount == 3 then
                nodeName = "node_skill" .. tostring(i) .. "_odd"
            else
                nodeName = "node_autoskill" .. tostring(i)
            end
            heroStatusView:setPosition(ccp(self._ccbOwner[nodeName]:getPosition(12)))
            self:addUI(heroStatusView)
            table.insert(self._heroStatusViews, heroStatusView)

            -- set hero hp and skill cooldown time 
            if self:isInSunwell() == true then

                local heroInfoInSunwell = remote.sunWell:getSunwellHeroInfo(hero:getActorID())
                if heroInfoInSunwell ~= nil then

                    if heroInfoInSunwell.hp ~= nil then
                        hero:setHp(heroInfoInSunwell.hp)
                        heroStatusView:onHpChanged()
                    end

                    if heroInfoInSunwell.skillCD ~= nil and heroInfoInSunwell.skillCD > 0 then
                        for _, skill in pairs(hero:getManualSkills()) do
                            skill:coolDown()
                            local realcdt = skill:getCdTime() * heroInfoInSunwell.skillCD * 0.001
                            skill:reduceCoolDownTime(realcdt)
                            heroStatusView._cd1:update(1.0 - skill:getCDProgress())
                        end
                    end
                else
                    for _, skill in pairs(hero:getManualSkills()) do
                        skill:coolDown()
                        heroStatusView._cd1:update(0.999)
                    end
                end
            elseif self:isInArena() == true then
                for _, skill in pairs(hero._manualSkills) do
                    skill:coolDown()
                    self._heroStatusViews[i]:playCoolDownAnimation_red(skill._cd_time)
                end
            end
        end

        local left = BATTLE_AREA.left
        local bottom = BATTLE_AREA.bottom
        local w = BATTLE_AREA.width
        local h = BATTLE_AREA.height
        -- 英雄入场起始点
        local stopPosition = clone(ARENA_HERO_POS)
        for _, position in ipairs(stopPosition) do
            position[1] = position[1] + display.cx
            position[2] = position[2] + display.cy
        end

        -- local offset_x = -200 - 50
        -- local stopPosition = {{display.cx + offset_x, display.cy}, {display.cx * 0.6 + 100 + 25 + offset_x, display.cy - 100}, {display.cx * 0.6 + 100 - 25 + offset_x, display.cy + 100}, {BATTLE_AREA.left + 300 + offset_x, display.cy}}
        
        for i, view in ipairs(views) do
            local index = heroCount - i + 1
            self:addSkeletonContainer(view)
            local hero = view:getModel()
            hero._enterStartPosition = {x = stopPosition[index][1] - display.cx, y = stopPosition[index][2]}
            hero._enterStopPosition = {x = stopPosition[index][1], y = stopPosition[index][2]}
            app.grid:addActor(hero) -- 注意要在view创建后加入app.grid，否则只有model，没有view的情况下，有些状态消息会miss掉
            app.grid:setActorTo(hero, hero._enterStartPosition)
            app.grid:moveActorTo(hero, hero._enterStopPosition)

            self:_checkBattleStartDelay(startPosition, stopPosition, view:getModel():getMoveSpeed())
        end
    else
        local heros = app.battle:getHeroes()
        local heroCount = table.nums(heros)
        for i, hero in ipairs(heros) do
            -- hero:resetStateForBattle() -- 清理之前的记录

            local view = QHeroActorView.new(hero)
            view:setAnimationScale(app.battle:getTimeGear(), "time_gear")
            table.insert(views, view)

            -- manual skill button, hero hp and icon
            local index = i
            local heroStatusView = QHeroStatusView.new(hero)
            local nodeName = nil
            if heroCount == 1 then
                nodeName = "node_skill2_odd"
            elseif heroCount == 2 then
                nodeName = "node_skill" .. tostring(index + 1)
            elseif heroCount == 3 then
                nodeName = "node_skill" .. tostring(index) .. "_odd"
            else
                nodeName = "node_autoskill" .. tostring(index)
            end
            heroStatusView:setPosition(ccp(self._ccbOwner[nodeName]:getPosition(12)))
            self:addUI(heroStatusView)
            table.insert(self._heroStatusViews, heroStatusView)
        end

        local left = BATTLE_AREA.left
        local bottom = BATTLE_AREA.bottom
        local w = BATTLE_AREA.width
        local h = BATTLE_AREA.height
        -- 英雄入场起始点
        local stopPosition = clone(HERO_POS)
        for _, position in ipairs(stopPosition) do
            position[1] = position[1] + display.cx
            position[2] = position[2] + display.cy
        end
        
        for i, view in ipairs(views) do
            local index = heroCount - i + 1
            self:addSkeletonContainer(view)
            local hero = view:getModel()
            hero._enterStartPosition = {x = stopPosition[index][1] - display.cx, y = stopPosition[index][2]}
            hero._enterStopPosition = {x = stopPosition[index][1], y = stopPosition[index][2]}
            app.grid:addActor(hero) -- 注意要在view创建后加入app.grid，否则只有model，没有view的情况下，有些状态消息会miss掉
            app.grid:setActorTo(hero, hero._enterStartPosition)
            app.grid:moveActorTo(hero, hero._enterStopPosition)
        end
    end

    self._heroViews = views;
end

function QBattleScene:_prepareEnemiesInPVPMode()
    if app.battle:isPVPMode() == false then
        return
    end

    local enemies = app.battle:getEnemies()
    local heroCount = table.nums(enemies)
    local left = BATTLE_AREA.left
    local bottom = BATTLE_AREA.bottom
    local w = BATTLE_AREA.width
    local h = BATTLE_AREA.height
    -- 英雄入场起始点
    local scale = UI_DESIGN_WIDTH / BATTLE_SCREEN_WIDTH
    local stopPosition = clone(ARENA_HERO_POS)
    for _, position in ipairs(stopPosition) do
        position[1] = display.width / scale - (position[1] + display.cx)
        position[2] = position[2] + display.cy
    end

    for i, view in ipairs(self._enemyViews) do
        local index = heroCount - i + 1
        local hero = view:getModel()

        if self:isInSunwell() == true then
            for _, skill in pairs(hero._manualSkills) do
                skill:coolDown()
            end
        elseif self:isInArena() == true then
            for _, skill in pairs(hero._manualSkills) do
                skill:coolDown()
            end
        end

        hero._enterStartPosition = {x = stopPosition[index][1] + display.cx, y = stopPosition[index][2]}
        hero._enterStopPosition = {x = stopPosition[index][1], y = stopPosition[index][2]}
        app.grid:addActor(hero) -- 注意要在view创建后加入app.grid，否则只有model，没有view的情况下，有些状态消息会miss掉
        app.grid:setActorTo(hero, hero._enterStartPosition)
        app.grid:moveActorTo(hero, hero._enterStopPosition)

        -- self:_checkBattleStartDelay(startPosition, stopPosition, view:getModel():getMoveSpeed())
    end
end

function QBattleScene:onEnter()
    QBattleScene.super.onEnter(self)

    app:setIsClearSkeletonData(false)
    self:_loadSkeletonData()

    app.scene = self
    app.battle = QBattleManager.new(self._dungeonConfig)

    app.grid = QPositionDirector.new()
    self:addOverlay(app.grid)

    self._eventProxy = cc.EventProxy.new(app.battle)
    self._eventProxy:addEventListener(QBattleManager.NPC_CREATED, handler(self, self._onNpcCreated))
    self._eventProxy:addEventListener(QBattleManager.NPC_CLEANUP, handler(self, self._onNpcCleanUp))
    self._eventProxy:addEventListener(QBattleManager.NPC_DEATH_LOGGED, handler(self, self._onNpcDeathLogged))
    self._eventProxy:addEventListener(QBattleManager.PAUSE, handler(self, self._onPause))
    self._eventProxy:addEventListener(QBattleManager.RESUME, handler(self, self._onResume))
    self._eventProxy:addEventListener(QBattleManager.HERO_CLEANUP, handler(self, self._onHeroCleanup))
    self._eventProxy:addEventListener(QBattleManager.START, handler(self, self._onBattleStart))
    self._eventProxy:addEventListener(QBattleManager.CUTSCENE_START, handler(self, self._onBattleCutsceneStart))
    self._eventProxy:addEventListener(QBattleManager.WIN, handler(self, self._onWin))
    self._eventProxy:addEventListener(QBattleManager.LOSE, handler(self, self._onLose))
    self._eventProxy:addEventListener(QBattleManager.ONTIMER, handler(self, self._onBattleTimer))
    self._eventProxy:addEventListener(QBattleManager.WAVE_STARTED, handler(self, self._onWaveStarted))
    self._eventProxy:addEventListener(QBattleManager.WAVE_ENDED, handler(self, self._onWaveEnded))
    self._eventProxy:addEventListener(QBattleManager.USE_MANUAL_SKILL, handler(self, self._onUseManualSkill))
    self._eventProxy:addEventListener(QBattleManager.ON_SET_TIME_GEAR, handler(self, self._onSetTimeGear))
    self._eventProxy:addEventListener(QBattleManager.ON_CHANGE_DAMAGE_COEFFICIENT, handler(self, self._onChangeDamageCoefficient))

    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()

    if CAN_SKIP_BATTLE == true and app.battle:isInTutorial() ~= true then
        self:_onSkipBattle(self._dungeonConfig.skipBattleWithWin == true)
    else
        -- add drag controller and touch controller
        if app.battle:isInTutorial() == true then
            -- invisible some node
            self._topBar:setVisible(false)
            self._autoSkillBar:setVisible(false)
            app.battle:createEnemiesInTutorial()
            app.battle:start()

        elseif app.battle:isPVPMode() == true then
            app.battle:createEnemiesInPVPMode()
            self:_prepareEnemiesInPVPMode()
            self:_prepareHeroes()
            self._labelCountDown:setVisible(true)
            self._labelCountDown:setString(string.format("%.2d:%.2d", math.floor(app.battle:getDungeonDuration() / 60.0), math.floor(app.battle:getDungeonDuration() % 60.0)))

            app.battle:pause()

            if app.battle:isInSunwell() and app.battle:isSunwellAllowControl() then
                QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_BEGIN, self.onEvent, self)
                QNotificationCenter.sharedNotificationCenter():addEventListener(QDragLineController.EVENT_DRAG_LINE_END_FOR_MOVE, self.onEvent, self)
                QNotificationCenter.sharedNotificationCenter():addEventListener(QDragLineController.EVENT_DRAG_LINE_END_FOR_ATTACK, self.onEvent, self)
                QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchController.EVENT_TOUCH_END_FOR_SELECT, self.onEvent, self)
                QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchController.EVENT_TOUCH_END_FOR_MOVE, self.onEvent, self)
                QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchController.EVENT_TOUCH_END_FOR_ATTACK, self.onEvent, self)

                self._dragController = QDragLineController.new()
                self:addDragLine(self._dragController)
                self._touchController = QTouchController.new()
                self:addDragLine(self._touchController)
                self._touchController:enableTouchEvent()
            end

            scheduler.performWithDelayGlobal(function()
                local ccbProxy = CCBProxy:create()
                local ccbOwner = {}
                local animationNode = CCBuilderReaderLoad(global.ui_arena_start_aniamtion_ccbi, ccbProxy, ccbOwner)
                animationNode:setPosition(display.cx, display.cy)
                self:addChild(animationNode)

                local animationProxy = QCCBAnimationProxy:create()
                animationProxy:retain()
                local animationManager = tolua.cast(animationNode:getUserObject(), "CCBAnimationManager")
                animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
                    animationProxy:disconnectAnimationEventSignal()
                    animationProxy:release()
                    animationNode:removeFromParent()
                    if not self._ended then
                        app.battle:resume()
                        app.battle:start()
                    end
                end)
            end, self._startDelay)

        else
            QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_BEGIN, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QDragLineController.EVENT_DRAG_LINE_END_FOR_MOVE, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QDragLineController.EVENT_DRAG_LINE_END_FOR_ATTACK, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchController.EVENT_TOUCH_END_FOR_SELECT, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchController.EVENT_TOUCH_END_FOR_MOVE, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QTouchController.EVENT_TOUCH_END_FOR_ATTACK, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QEntranceBase.ANIMATION_FINISHED, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QMissionBase.COMPLETE_STATE_CHANGE, self.onEvent, self)

            self._dragController = QDragLineController.new()
            self:addDragLine(self._dragController)
            self._touchController = QTouchController.new()
            self:addDragLine(self._touchController)
            self._touchController:enableTouchEvent()

            if self._isPassedBefore == false and self._isHaveMissions == true then
                app.missionTracer = QBattleMissionTracer.new(self._dungeonConfig.id)
                app.missionTracer:beginTracer()
            else
                self._starOff1:setVisible(false)
                self._starOff2:setVisible(false)
                self._starOff3:setVisible(false)
                self._starOn1:setVisible(true)
                self._starOn2:setVisible(true)
                self._starOn3:setVisible(true)
            end

            if app.battle:isInEditor() == true then
                self._autoSkillBar:setVisible(false)
                self._labelCountDown:setVisible(true)
                app.battle:start()
            else
                if app.battle:isActiveDungeon() == true and app.battle:getActiveDungeonType() == DUNGEON_TYPE.ACTIVITY_TIME then
                    QBattleDialogGameRule.new("Battle_Widget_TimeMachine_RulePrompt.ccbi", function()
                        self._labelDeadEnemies:setString(tostring(app.battle:getDungeonDeadEnemyCount()) .. "/" .. tostring(app.battle:getDungeonEnemyCount()))
                        self._labelCountDown:setVisible(true)
                        local animationManager = tolua.cast(self._topBar:getUserObject(), "CCBAnimationManager")
                        animationManager:runAnimationsForSequenceNamed("EnterDungeon")
                        app.battle:start()
                    end)
                else
                    self._labelCountDown:setVisible(true)
                    app.battle:start()
                end
            end

        end

        -- play BGM
        audio.playBackgroundMusic(self._dungeonConfig.bgm)
    end
end

function QBattleScene:onExit()
    -- stop BGM
    -- audio.stopBackgroundMusic()

    self:_removeSkeletonData()
    app:setIsClearSkeletonData(true)

    if app.battle:isInTutorial() == true then

    elseif app.battle:isPVPMode() == true then
        if app.battle:isInSunwell() and app.battle:isSunwellAllowControl() then
            if self._touchController ~= nil then
                self._touchController:disableTouchEvent()
            end

            QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_BEGIN, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():removeEventListener(QDragLineController.EVENT_DRAG_LINE_END_FOR_MOVE, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():removeEventListener(QDragLineController.EVENT_DRAG_LINE_END_FOR_ATTACK, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchController.EVENT_TOUCH_END_FOR_SELECT, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchController.EVENT_TOUCH_END_FOR_MOVE, self.onEvent, self)
            QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchController.EVENT_TOUCH_END_FOR_ATTACK, self.onEvent, self)
        end
    else
        if self._touchController ~= nil then
            self._touchController:disableTouchEvent()
        end

        QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchActorView.EVENT_ACTOR_TOUCHED_BEGIN, self.onEvent, self)
        QNotificationCenter.sharedNotificationCenter():removeEventListener(QDragLineController.EVENT_DRAG_LINE_END_FOR_MOVE, self.onEvent, self)
        QNotificationCenter.sharedNotificationCenter():removeEventListener(QDragLineController.EVENT_DRAG_LINE_END_FOR_ATTACK, self.onEvent, self)
        QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchController.EVENT_TOUCH_END_FOR_SELECT, self.onEvent, self)
        QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchController.EVENT_TOUCH_END_FOR_MOVE, self.onEvent, self)
        QNotificationCenter.sharedNotificationCenter():removeEventListener(QTouchController.EVENT_TOUCH_END_FOR_ATTACK, self.onEvent, self)
        QNotificationCenter.sharedNotificationCenter():removeEventListener(QEntranceBase.ANIMATION_FINISHED, self.onEvent, self)
        QNotificationCenter.sharedNotificationCenter():removeEventListener(QMissionBase.COMPLETE_STATE_CHANGE, self.onEvent, self)

        if app.missionTracer ~= nil then
            app.missionTracer:endTracer()
            app.missionTracer = nil
        end

    end

    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)

    self._eventProxy:removeAllEventListeners()

    -- 将actor从grid上清除
    for i, view in ipairs(self._heroViews) do
        if view:getModel():isDead() == false then
            app.grid:removeActor(view:getModel())
        end
    end

    for i, view in ipairs(self._heroViews) do
       view:removeFromParent()
    end
    self._heroViews = {}

    for i, view in ipairs(self._enemyViews) do
       view:removeFromParent()
    end
    self._enemyViews = {}

    for i, view in ipairs(self._groundEffectView) do
       view:removeFromParent()
    end
    self._groundEffectView = {}

    for i, view in ipairs(self._effectViews) do
       view:removeFromParent()
    end
    self._effectViews = {}

    for i, view in ipairs(self._frontEffectView) do
       view:removeFromParent()
    end
    self._frontEffectView = {}

    app.grid:removeSelf()
    app.grid = nil

    app.battle:stop()
    app.battle = nil

    app.scene = nil

    QSkeletonViewController.sharedSkeletonViewController():resetAllAnimationScale()
    QBattleScene.super.onExit(self)
end

function QBattleScene:onCleanup()
    QSkeletonDataCache:sharedSkeletonDataCache():removeUnusedData()
end

function QBattleScene:_onNpcCreated(event)

    local targetPos
    if app.battle:isPVPMode() == false then
        if event.isBoss == true and self._bossHpBar:getActor() == nil then
            self._bossHpBar:setActor(event.npc)
            self._bossHpBar:setVisible(true)
            self._labelWave:setVisible(false)
            self._waveBackground:setVisible(false)
            self._starRoot:setVisible(false)
        end

        local view = QNpcActorView.new(event.npc, event.skeletonView)
        view:setAnimationScale(app.battle:getTimeGear(), "time_gear")
        local w = BATTLE_AREA.width / global.screen_big_grid_width
        local h = BATTLE_AREA.height / global.screen_big_grid_height
        if event.screen_pos ~= nil then
            targetPos = clone(event.screen_pos)
        else
            targetPos = {x = BATTLE_AREA.left + w * event.pos.x - w / 2, y = BATTLE_AREA.bottom + h * event.pos.y - h / 2}
        end
        self:addSkeletonContainer(view)
        if not event.is_hero then
            table.insert(self._enemyViews, view)
        else
            table.insert(self._heroViews, view)
        end

    else
        local view = QHeroActorView.new(event.npc)
        view:setAnimationScale(app.battle:getTimeGear(), "time_gear")
        if event.screen_pos ~= nil then
            targetPos = clone(event.screen_pos)
        else
            targetPos = {x = BATTLE_AREA.left + event.pos.x, y = BATTLE_AREA.bottom + event.pos.y}
        end
        self:addSkeletonContainer(view)
        if not event.is_hero then
            table.insert(self._enemyViews, view)
        else
            table.insert(self._heroViews, view)
        end
    end

    app.grid:addActor(event.npc) -- 注意要在view创建后加入app.grid，否则只有model，没有view的情况下，有些状态消息会miss掉
    app.grid:setActorTo(event.npc, targetPos, false, event.screen_pos ~= nil)

    if app.battle:isInTutorial() == false and app.battle:isPVPMode() == false then
        -- play create effect
        if event.effectId ~= nil then
            local frontEffect, backEffect = QBaseEffectView.createEffectByID(event.effectId)
            local dummy = QStaticDatabase.sharedDatabase():getEffectDummyByID(event.effectId)
            local position = app.grid:_toScreenPos(event.npc.gridPos) 
            frontEffect:setPosition(position.x, position.y - 1)
            self:addEffectViews(frontEffect)
            
            -- play animation and sound
            frontEffect:playAnimation(EFFECT_ANIMATION, false)
            frontEffect:playSoundEffect(false)

            frontEffect:afterAnimationComplete(function()
                app.scene:removeEffectViews(frontEffect)
            end)
        end
        -- play boss effect
        if event.isBoss == true and event.isManually ~= true then
            app.battle:pause()

            local ccbProxy = CCBProxy:create()
            local ccbOwner = {}
            local animationNode = CCBuilderReaderLoad(global.ui_battle_boss_animation_ccbi, ccbProxy, ccbOwner)
            animationNode:setPosition(display.cx, display.cy)
            self:addUI(animationNode)

            local animationProxy = QCCBAnimationProxy:create()
            animationProxy:retain()
            local animationManager = tolua.cast(animationNode:getUserObject(), "CCBAnimationManager")
            animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
                animationProxy:disconnectAnimationEventSignal()
                animationProxy:release()
                animationNode:removeFromParent()
                app.battle:resume()
            end)
        end
    end
end

function QBattleScene:_onNpcDeathLogged(event)

    if app.battle:isActiveDungeon() == true and app.battle:getActiveDungeonType() == DUNGEON_TYPE.ACTIVITY_TIME then
        self._labelDeadEnemies:setString(tostring(app.battle:getDungeonDeadEnemyCount()) .. "/" .. tostring(app.battle:getDungeonEnemyCount()))
        local animationManager = tolua.cast(self._topBar:getUserObject(), "CCBAnimationManager")
        animationManager:runAnimationsForSequenceNamed("EnemyDead")
    end

    local views = event.is_hero and self._heroViews or self._enemyViews
    for i, view in ipairs(views) do
        if view:getModel() == event.npc then
            local direction
            if view:isFlipX() == true then
                direction = QBaseActorView.DIRECTION_RIGHT
            else
                direction = QBaseActorView.DIRECTION_LEFT
            end
            local scale = self._skeletonLayer:getScale()
            if event.npc.rewards ~= nil then
                local deltaPos = {{80, 80}, {0, 0}, {80, 0}, {80, -80}, {0, -80}, {-80, -80}, {-80, 0}, {-80, 80}, {0, 80}}
                local delayTime = 0
                for i, reward in pairs(event.npc.rewards) do
                    local index = i % 9 + 1
                    local position = ccp(view:getPosition())
                    position.x = position.x * scale + deltaPos[index][1]
                    position.y = position.y * scale + deltaPos[index][2]
                    app.battle:performWithDelay(function()
                        self:_onGetReward(reward, direction, position)
                    end, delayTime)
                    delayTime = delayTime + 0.1
                end
            end

            local array = CCArray:create()
            array:addObject(CCDelayTime:create(global.npc_view_dead_delay))          -- after 2 seconds
            array:addObject(CCBlink:create(global.npc_view_dead_blink_time, 3))           -- blink the npc 3 times in 1 second
            array:addObject(CCCallFunc:create(function()
                table.removebyvalue(views, view)
            end))
            array:addObject(CCRemoveSelf:create(true))      -- and then remove it from scene
            view:runAction(CCSequence:create(array))

            break
        end
    end
end

function QBattleScene:_onNpcCleanUp(event)

    if event.isBoss == true and self._bossHpBar:getActor() ~= nil then
        self._bossHpBar:setActor(nil)
        self._bossHpBar:setVisible(false)
        self._labelWave:setVisible(true)
        self._waveBackground:setVisible(true)
        if self._isHaveMissions == true and self._isActiveDungeon == false then
            self._starRoot:setVisible(true)
        end
    end

end

function QBattleScene:_onGetReward(rewardInfo, actorDirection, position)
    if rewardInfo == nil or position == nil then
        return 
    end

    local itemNode
    local drapSound = ""
    local isTreasure = false
    if remote.items:getItemType(rewardInfo.reward.type) == ITEM_TYPE.ITEM then
        
        local itemInfo = QStaticDatabase.sharedDatabase():getItemByID(rewardInfo.reward.id)
        if itemInfo == nil then
            return
        else
            if itemInfo.type == ITEM_CATEGORY.SOUL then
                drapSound = "gem_drop.mp3"
            end
        end
        if itemInfo.colour ~= nil and itemInfo.colour >= ITEM_QUALITY_INDEX.PURPLE then
            isTreasure = true
        end
        itemNode = QUIWidgetItemsBox.new({ccb = "small"})
        itemNode:setGoodsInfo(rewardInfo.reward.id,ITEM_TYPE.ITEM,rewardInfo.reward.count)

    elseif remote.items:getItemType(rewardInfo.reward.type) == ITEM_TYPE.MONEY then
        itemNode = CCSprite:create("icon/item/Gold_one.png")
    else
        return
    end

    actorDirection = actorDirection or QBaseActorView.DIRECTION_LEFT
    local ccbiFile = "effects/Box.ccbi"
    if rewardInfo.isGarbage == true or isTreasure == false then
        ccbiFile = "effects/Box2.ccbi"
    end

    local ccbProxy = CCBProxy:create()
    local ccbOwner = {}
    local rewardNode = CCBuilderReaderLoad(ccbiFile, ccbProxy, ccbOwner)
    rewardNode:setPosition(position.x, position.y)
    local node = ccbOwner.node_item:getParent()
    ccbOwner.node_item:removeFromParent()
    ccbOwner.node_item = nil
    node:addChild(itemNode)
    self:addUI(rewardNode)

    -- animation
    local animationProxy = QCCBAnimationProxy:create()
    animationProxy:retain()
    local animationManager = tolua.cast(rewardNode:getUserObject(), "CCBAnimationManager")
    animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
        animationProxy:disconnectAnimationEventSignal()
        animationProxy:release()
        local targetPositionX, targetPositionY = self._topBar:getPosition()
        if remote.items:getItemType(rewardInfo.reward.type) == ITEM_TYPE.ITEM then
            targetPositionX = targetPositionX + self._sprite_item:getPositionX() + self._sprite_item:getParent():getPositionX()
            targetPositionY = targetPositionY + self._sprite_item:getPositionY() + self._sprite_item:getParent():getPositionY()
        elseif remote.items:getItemType(rewardInfo.reward.type) == ITEM_TYPE.MONEY then
            targetPositionX = targetPositionX + self._sprite_money:getPositionX() + self._sprite_money:getParent():getPositionX()
            targetPositionY = targetPositionY + self._sprite_money:getPositionY() + self._sprite_money:getParent():getPositionY()
        end

        targetPositionX = targetPositionX - itemNode:getPositionX() - itemNode:getParent():getPositionX()
        targetPositionY = targetPositionY - itemNode:getPositionY() - itemNode:getParent():getPositionY()

        local actionArray = CCArray:create()
        actionArray:addObject(CCDelayTime:create(1))
        local bezierConfig = ccBezierConfig:new()
        bezierConfig.endPosition = ccp(targetPositionX, targetPositionY)
        local currentPositionX, currentPositionY = rewardNode:getPosition()
        if math.abs(currentPositionX - targetPositionX) < 200 then
            bezierConfig.controlPoint_1 = ccp(currentPositionX + (targetPositionX - currentPositionX) * 1.5, currentPositionY + (targetPositionY - currentPositionY) * 0.3)
            bezierConfig.controlPoint_2 = ccp(currentPositionX + (targetPositionX - currentPositionX) * 1.3, currentPositionY + (targetPositionY - currentPositionY) * 0.6)
        else
            bezierConfig.controlPoint_1 = ccp(currentPositionX + (targetPositionX - currentPositionX) * 0.8, currentPositionY + (targetPositionY - currentPositionY) * 0.3)
            bezierConfig.controlPoint_2 = ccp(currentPositionX + (targetPositionX - currentPositionX) * 0.9, currentPositionY + (targetPositionY - currentPositionY) * 0.6)
        end
        local bezierTo = CCBezierTo:create(0.5, bezierConfig)
        actionArray:addObject(CCEaseIn:create(bezierTo, 5))
        actionArray:addObject(CCRemoveSelf:create(true))
        actionArray:addObject(CCCallFunc:create(function()
            local ccbProxy = CCBProxy:create()
            local ccbOwner = {}
            local endEffect = CCBuilderReaderLoad("effects/ItemFall_end.ccbi", ccbProxy, ccbOwner)
            if remote.items:getItemType(rewardInfo.reward.type) == ITEM_TYPE.ITEM then
                self._sprite_item:addChild(endEffect)
                endEffect:setPosition(self._sprite_item:getContentSize().width * 0.5, self._sprite_item:getContentSize().height * 0.5)
            elseif remote.items:getItemType(rewardInfo.reward.type) == ITEM_TYPE.MONEY then
                self._sprite_money:addChild(endEffect)
                endEffect:setPosition(self._sprite_money:getContentSize().width * 0.5, self._sprite_money:getContentSize().height * 0.5)
            end
            local animationProxy = QCCBAnimationProxy:create()
            animationProxy:retain()
            local animationManager = tolua.cast(endEffect:getUserObject(), "CCBAnimationManager")
            animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
                animationProxy:disconnectAnimationEventSignal()
                animationProxy:release()
                endEffect:removeFromParent()
                if remote.items:getItemType(rewardInfo.reward.type) == ITEM_TYPE.ITEM then
                    self._currentChest = self._currentChest + rewardInfo.reward.count
                    self._labelChest:setString(tostring(self._currentChest))
                elseif remote.items:getItemType(rewardInfo.reward.type) == ITEM_TYPE.MONEY then
                    self._currentMoney = self._currentMoney + rewardInfo.reward.count
                    self._labelMoney:setString(tostring(self._currentMoney))
                end
            end)
        end))
        local ccsequence = CCSequence:create(actionArray)
        rewardNode:runAction(ccsequence)
    end)

    if drapSound ~= nil and string.len(drapSound) > 0 then
        audio.playSound(drapSound, false)
    end

end

function QBattleScene:_onHeroCleanup(event)
    for i, view in ipairs(self._heroViews) do
        if view:getModel() == event.hero then
            local array = CCArray:create()

            array:addObject(CCDelayTime:create(1))          -- after 5 seconds
            array:addObject(CCBlink:create(1, 3))           -- blink the npc 3 times in 1 second
            array:addObject(CCRemoveSelf:create(true))      -- and then remove it from scene
            view:runAction(CCSequence:create(array))

            table.removebyvalue(self._heroViews, view)
            break
        end
    end
end

function QBattleScene:_onPause(event)
    self:_pauseNode(self._backgroundLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_pauseNode(self._trackLineLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_pauseNode(self._skeletonLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_pauseNode(self._dragLineLayer,CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_pauseNode(self._overSkeletonLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    -- self:_pauseNode(self._uiLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_pauseNode(self._overlayLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_pauseSoundEffect()

    if self._dragController then
        self._dragController:disableDragLine()
    end
end

function QBattleScene:_pauseSoundEffect()
    for i, view in ipairs(self._effectViews) do
        if view.pauseSoundEffect then view:pauseSoundEffect() end
    end
    for i, view in ipairs(self._frontEffectView) do
        if view.pauseSoundEffect then view:pauseSoundEffect() end
    end
    for i, view in ipairs(self._groundEffectView) do
        if view.pauseSoundEffect then view:pauseSoundEffect() end
    end
    for i, view in ipairs(self._heroViews) do
        if view.pauseSoundEffect then view:pauseSoundEffect() end
    end
    for i, view in ipairs(self._enemyViews) do
        if view.pauseSoundEffect then view:pauseSoundEffect() end
    end
end

function QBattleScene:_pauseNode(node, actionManager, scheduler)
    actionManager:pauseTarget(node)
    scheduler:pauseTarget(node)
    local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
        local child = tolua.cast(children:objectAtIndex(i), "CCNode")
        self:_pauseNode(child, actionManager, scheduler)
    end
end

function QBattleScene:_onResume(event)
    self:_resumeNode(self._backgroundLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_resumeNode(self._trackLineLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_resumeNode(self._skeletonLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_resumeNode(self._dragLineLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_resumeNode(self._overSkeletonLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    -- self:_resumeNode(self._uiLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_resumeNode(self._overlayLayer, CCDirector:sharedDirector():getActionManager(), CCDirector:sharedDirector():getScheduler())
    self:_resumeSoundEffect()
end

function QBattleScene:_resumeNode(node, actionManager, scheduler)
    actionManager:resumeTarget(node)
    scheduler:resumeTarget(node)
    local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
        local child = tolua.cast(children:objectAtIndex(i), "CCNode")
        self:_resumeNode(child, actionManager, scheduler)
    end
end

function QBattleScene:_resumeSoundEffect()
    for i, view in ipairs(self._effectViews) do
        if view.resumeSoundEffect then view:resumeSoundEffect() end
    end
    for i, view in ipairs(self._frontEffectView) do
        if view.resumeSoundEffect then view:resumeSoundEffect() end
    end
    for i, view in ipairs(self._groundEffectView) do
        if view.resumeSoundEffect then view:resumeSoundEffect() end
    end
    for i, view in ipairs(self._heroViews) do
        if view.resumeSoundEffect then view:resumeSoundEffect() end
    end
    for i, view in ipairs(self._enemyViews) do
        if view.resumeSoundEffect then view:resumeSoundEffect() end
    end
end

function QBattleScene:onEvent(event)
    if event == nil or event.name == nil then
        return
    end

    local eventName = event.name
    if eventName == QEntranceBase.ANIMATION_FINISHED then
        self._topBar:setVisible(true)
        self._autoSkillBar:setVisible(true)
        if self._cutscene:getName() == global.cutscenes.KRESH_ENTRANCE then
            local x, y = self._cutscene:getKreshPosition()
            local kreshView = self._cutscene:getKreshSkeletonView()
            kreshView:retain()
            kreshView:removeFromParentAndCleanup(false)
            app.battle:createEnemyManually("normal_kresh_1", 1, x, y, kreshView)
        end
        self._cutscene:exit()
        self._cutscene = nil
        app.battle:endCutscene()

    elseif eventName == QMissionBase.COMPLETE_STATE_CHANGE then
        if self._dungeonTargetInfo == nil then
            self._dungeonTargetInfo = QStaticDatabase.sharedDatabase():getDungeonTargetByID(self._dungeonConfig.id)
            if self._dungeonTargetInfo == nil then
                return 
            end
        end

        local mission = event.mission
        local index = app.missionTracer:getMissionIndex(mission)
        if index == nil or index == 0 then
            return
        end

        local onNode = self["_starOn" .. tostring(index)]
        local offNode = self["_starOff" .. tostring(index)]
        if onNode == nil or offNode == nil then
            return
        end

        if mission:isCompleted() == true then
            local deltaY = -65
            local ccbProxy = CCBProxy:create()
            local ccbOwner = {}
            local starInfoAnimation = CCBuilderReaderLoad("effects/star_info.ccbi", ccbProxy, ccbOwner)
            ccbOwner.label_describe:setString(mission:getDescription())
            starInfoAnimation:setPositionY(deltaY * self._missionCompleteNode:getChildrenCount())
            self._missionCompleteNode:addChild(starInfoAnimation)
            local animationProxy = QCCBAnimationProxy:create()
            animationProxy:retain()
            local animationManager = tolua.cast(starInfoAnimation:getUserObject(), "CCBAnimationManager")
            animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
                animationProxy:disconnectAnimationEventSignal()
                animationProxy:release()

                local ccbProxy1 = CCBProxy:create()
                local ccbOwner1 = {}
                local starAnimation = CCBuilderReaderLoad("effects/star_touch.ccbi", ccbProxy1, ccbOwner1)
                self._missionCompleteNode:getParent():addChild(starAnimation)
                starAnimation:setPositionX(self._missionCompleteNode:getPositionX() + starInfoAnimation:getPositionX() + ccbOwner.star_done1:getPositionX())
                starAnimation:setPositionY(self._missionCompleteNode:getPositionY() + starInfoAnimation:getPositionY() + ccbOwner.star_done1:getPositionY())
                local actionArray = CCArray:create()

                local bezierConfig = ccBezierConfig:new()
                bezierConfig.endPosition = ccp(onNode:getParent():getPosition())
                local deltaY = onNode:getParent():getPositionY() - starAnimation:getPositionY()
                bezierConfig.controlPoint_1 = ccp(onNode:getParent():getPositionX() - deltaY, starAnimation:getPositionY())
                bezierConfig.controlPoint_2 = ccp(onNode:getParent():getPositionX() - deltaY * 0.5, starAnimation:getPositionY() + deltaY * 0.5)
                local bezierTo = CCBezierTo:create(0.5, bezierConfig)
                actionArray:addObject(CCEaseIn:create(bezierTo, 5))
                actionArray:addObject(CCCallFunc:create(function()
                    onNode:setVisible(true)
                    offNode:setVisible(false)
                    local animationProxy = QCCBAnimationProxy:create()
                    animationProxy:retain()
                    local animationManager = tolua.cast(starAnimation:getUserObject(), "CCBAnimationManager")
                    animationManager:runAnimationsForSequenceNamed("shining")
                    animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
                        animationProxy:disconnectAnimationEventSignal()
                        animationProxy:release()
                        starAnimation:removeFromParent()
                    end)
                end))
                local sequence = CCSequence:create(actionArray)
                starAnimation:runAction(sequence)

                starInfoAnimation:removeFromParent()
            end)
        else
            onNode:setVisible(false)
            offNode:setVisible(true)
        end
        

    elseif eventName == QTouchActorView.EVENT_ACTOR_TOUCHED_BEGIN then
        if self._ended == true then
            return
        end

        local heroViews = {}
        for i, view in ipairs(self._heroViews) do
            table.insert(heroViews, view)
        end

        local sortedActorView = q.sortNodeZOrder(heroViews, true)
        local actorView = QBattle.getTouchingActor(sortedActorView, event.positionX, event.positionY)
        if actorView == nil then
            local actorView = event.actorView
        end
        if actorView and actorView:getModel():isDead() == false then
            self._dragController:enableDragLine(actorView, {x = event.positionX, y = event.positionY})
        end

    elseif eventName == QDragLineController.EVENT_DRAG_LINE_END_FOR_MOVE then
        local heroView = event.heroView
        if heroView:getModel():isDead() == false and not self._dragController:isSameWithTouchStartPosition({x = event.positionX, y = event.positionY}) then
            heroView:getModel():onDragMove(ccp(event.positionX, event.positionY))
            self._touchController:setSelectActorView(heroView)
        end

    elseif eventName == QDragLineController.EVENT_DRAG_LINE_END_FOR_ATTACK then
        local heroView = event.heroView
        if heroView:getModel():isDead() == false then
            local targetView = event.targetView
            heroView:getModel():onDragAttack(targetView:getModel())
            self._touchController:setSelectActorView(heroView)
        end

    elseif eventName == QTouchController.EVENT_TOUCH_END_FOR_MOVE then
        local heroView = event.heroView
        if heroView:getModel():isDead() == false and not self._dragController:isSameWithTouchStartPosition({x = event.positionX, y = event.positionY}) then
            heroView:getModel():onDragMove(ccp(event.positionX, event.positionY))
        end

    elseif eventName == QTouchController.EVENT_TOUCH_END_FOR_ATTACK then
        local heroView = event.heroView
        if heroView:getModel():isDead() == false then
            local targetView = event.targetView
            local targetModel = targetView:getModel()
            heroView:getModel():onDragAttack(targetModel)
            if app.battle:isBoss(targetModel) == true then
                self._bossHpBar:setActor(targetModel)
                self._bossHpBar:setVisible(true)
            end
        end

    elseif eventName == QTouchController.EVENT_TOUCH_END_FOR_SELECT then
        local oldSelectView = event.oldSelectView
        local newSelectView = event.newSelectView
        if oldSelectView ~= nil and oldSelectView.visibleSelectCircle then
            oldSelectView:visibleSelectCircle(QBaseActorView.HIDE_CIRCLE)
        end
        if newSelectView ~= nil then
            newSelectView:visibleSelectCircle(QBaseActorView.SOURCE_CIRCLE)
            newSelectView:displayHpView()

            for _, heroStatusView in ipairs(self._heroStatusViews) do
                heroStatusView:onSelectHero(newSelectView:getModel())
            end
        else
            for _, heroStatusView in ipairs(self._heroStatusViews) do
                heroStatusView:onSelectHero(nil)
            end
        end
    end

end

function QBattleScene:_onFrame(dt)
    local zOrder = self:_updateActorZOrder()

    if self._touchController and self._touchController:isTouchEnded() then
        self._dragController:disableDragLine(true)
    end
end

function QBattleScene:_checkMissionComplete()
    if app.missionTracer == nil then
        return 
    end

    local count = app.missionTracer:getCompleteMissionCount()
    if count == 0 then
        self._starOff1:setVisible(true)
        self._starOff2:setVisible(true)
        self._starOff3:setVisible(true)
        self._starOn1:setVisible(false)
        self._starOn2:setVisible(false)
        self._starOn3:setVisible(false)
    elseif count == 1 then
        self._starOff1:setVisible(false)
        self._starOff2:setVisible(true)
        self._starOff3:setVisible(true)
        self._starOn1:setVisible(true)
        self._starOn2:setVisible(false)
        self._starOn3:setVisible(false)
    elseif count == 2 then
        self._starOff1:setVisible(false)
        self._starOff2:setVisible(false)
        self._starOff3:setVisible(true)
        self._starOn1:setVisible(true)
        self._starOn2:setVisible(true)
        self._starOn3:setVisible(false)
    else
        self._starOff1:setVisible(false)
        self._starOff2:setVisible(false)
        self._starOff3:setVisible(false)
        self._starOn1:setVisible(true)
        self._starOn2:setVisible(true)
        self._starOn3:setVisible(true)
    end

end

function QBattleScene:visibleBackgroundLayer(visible, actor, time)
    if actor == nil then
        return
    end

    local view = self:getActorViewFromModel(actor)
    if view == nil then
        return
    end

    time = time or 0.15
    local backgroundLayer = self:getBackgroundOverLayer()
    

    if visible == true then
        self._showBlackLayerReferenceCount = self._showBlackLayerReferenceCount + 1
        if self._showBlackLayerReferenceCount == 1 then
            backgroundLayer:setVisible(true)
            backgroundLayer:runAction(CCFadeTo:create(time, 200))
        end

        self._showActorView = view
    else
        self._showBlackLayerReferenceCount = self._showBlackLayerReferenceCount - 1
        if self._showBlackLayerReferenceCount == 0 then
            backgroundLayer:runAction(CCFadeTo:create(time, 0))
            app.battle:performWithDelay(function()
                backgroundLayer:setVisible(false)
            end, time)
        end

        self._showActorView = nil
    end
end

function QBattleScene:_updateActorZOrder()
    local allActorView = {}
    for i, view in ipairs(self._heroViews) do
        table.insert(allActorView, view)
    end
    for i, view in ipairs(self._enemyViews) do
        table.insert(allActorView, view)
    end
    for i, view in ipairs(self._effectViews) do
        table.insert(allActorView, view)
    end
    local sortedActorView = q.sortNodeZOrder(allActorView, false)

    local layer = self:getBackgroundOverLayer()

    -- reset the z order
    local zOrder = 1
    for _, view in ipairs(self._groundEffectView) do
        view:setZOrder(zOrder)
        zOrder = zOrder + 1
    end
    for _, view in ipairs(sortedActorView) do
        view:setZOrder(zOrder)
        zOrder = zOrder + 1
    end

    if layer:isVisible() == true then
        for i, view in ipairs(self._frontEffectView) do
            view:setZOrder(zOrder)
            zOrder = zOrder + 1
        end
        
        layer:setZOrder(zOrder)
        zOrder = zOrder + 1

        for _, view in ipairs(sortedActorView) do
            if view.__cname == "QHeroActorView" then
                local skill = view:getModel():getCurrentSkill()
                if view == self._showActorView or skill ~= nil and skill:getSkillType() == QSkill.MANUAL then
                    view:setZOrder(zOrder)
                    zOrder = zOrder + 1
                end
            end
        end
    else
        for i, view in ipairs(self._frontEffectView) do
            view:setZOrder(zOrder)
            zOrder = zOrder + 1
        end
    end

    return zOrder
end

function QBattleScene:_onPauseButtonClicked()
    if self._ended == true or self._tutorialForUseSkill == true or self._tutorialForTouchActor == true then
        return 
    end

    if app.battle:isInEditor() == true then
        if app.battle:isPVPMode() then
            if app.battle:isPaused() then
                app.battle:resume()
            else
                app.battle:pause()
            end
        end
        return
    end

    if app.battle:isPaused() == true then
        return
    end

    -- self:_onWin()
    -- if true then return end

    self.curModalDialog = QBattleDialogPause.new({
        onAbort = handler(self, QBattleScene._onAbort),
        onRestart = handler(self, QBattleScene._onRestart),
    })
end

function QBattleScene:_onMissionButtonClicked()
    if self._ended == true then
        return 
    end

    if app.battle:isInEditor() == true then
        return
    end

    if app.battle:isPaused() == true then
        return
    end

    if self._isActiveDungeon == true then
        return
    end

    -- self:_onWin()
    -- if true then return end

    self.curModalDialog = QBattleDialogMissions.new(self._isPassedBefore)
end

function QBattleScene:_onAutoSkillClicked()
    if self._ended == true then
        return 
    end

    if app.battle:isInEditor() == true then
        return
    end

    if app.battle:isPaused() == true or app.battle:isPausedBetweenWave() == true then
        return
    end

    if app.battle:isPVPMode() and app.battle:isInArena() == true then
        app.tip:floatTip("竞技场内只允许自动战斗")
    else
        -- self:_onWin()
        -- if true then return end
        local globalConfig = QStaticDatabase:sharedDatabase():getConfiguration()
        if globalConfig.UNLOCK_AUTO_SKILL.value ~= nil and remote.instance:checkIsPassByDungeonId(globalConfig.UNLOCK_AUTO_SKILL.value) == true then
            self.curModalDialog = QBattleDialogAutoSkill.new()
        else
            app.tip:floatTip(globalConfig.UNLOCK_AUTO_SKILL.description)
        end
    end
end

function QBattleScene:_onNextWaveClicked()
    app.sound:playSound("battle_switch")
    self._arrow:setVisible(false)
    
    for i, view in ipairs(self._heroViews) do
        if view:getModel():isDead() == false then
            self._heroStatusViews[i]:playCoolDownAnimation()
            app.grid:removeActor(view:getModel())
        end
    end

    -- nzhang: make sure this function is called before view:changToWalkAnimationAndRightDirection() is called
    app.battle:onConfirmNewWave()

    local speedCoefficient = 1.5
    local timeToLeave = 0
    for i, view in ipairs(self._heroViews) do
        if view:getModel():isDead() == false then
            view:getModel():set("speed", view:getModel():get("speed") * speedCoefficient)
            view:getSkeletonActor():setAnimationScaleOriginal(view:getSkeletonActor():getAnimationScaleOriginal() * speedCoefficient)

            local moveSpeed = view:getModel():getMoveSpeed()
            local position = view:getModel():getPosition()
            local targetPosition = {x = BATTLE_SCREEN_WIDTH + view:getModel():getRect().size.width, y = position.y}
            local time = (targetPosition.x - position.x) / moveSpeed
            if time > timeToLeave then
                timeToLeave = time
            end
            view:changToWalkAnimationAndRightDirection()
            view:runAction(CCMoveTo:create(time, ccp(targetPosition.x, targetPosition.y)))
        end
    end
    timeToLeave = timeToLeave + 0.5

    app.battle:performWithDelay(function()
        app.grid:resetWeight()
        for i, view in ipairs(self._heroViews) do
            if view:getModel():isDead() == false then
                app.grid:addActor(view:getModel())
                app.grid:setActorTo(view:getModel(), view:getModel()._enterStartPosition)
                app.grid:moveActorTo(view:getModel(), view:getModel()._enterStopPosition)
            end
        end
         -- change scene background
        if self._dungeonConfig.mode == BATTLE_MODE.WAVE_WITH_DIFFERENT_BACKGROUND then
            if app.battle:getNextWave() == 1 then

            elseif app.battle:getNextWave() == 2 then
                if self._dungeonConfig.bg_2 ~= nil then
                    local bgFileName = ""
                    local bgs = string.split(self._dungeonConfig.bg_2, ";")
                    bgFileName = bgs[math.random(1, #bgs)]

                    local pvrImage = string.sub(bgFileName, 1, string.len(bgFileName) - 3) .. "pvr.ccz"
                    local pvrImageFullPath = CCFileUtils:sharedFileUtils():fullPathForFilename(pvrImage)
                    if CCFileUtils:sharedFileUtils():isFileExist(pvrImageFullPath) == true then
                        bgFileName = pvrImageFullPath
                    end

                    local backImage = CCTextureCache:sharedTextureCache():addImage(bgFileName)
                    if backImage ~= nil then
                        self._backgroundImage:setTexture(backImage)
                    end
                end

            elseif app.battle:getNextWave() == 3 then
                if self._dungeonConfig.bg_3 ~= nil then
                    local bgFileName = ""
                    local bgs = string.split(self._dungeonConfig.bg_3, ";")
                    bgFileName = bgs[math.random(1, #bgs)]

                    local pvrImage = string.sub(bgFileName, 1, string.len(bgFileName) - 3) .. "pvr.ccz"
                    local pvrImageFullPath = CCFileUtils:sharedFileUtils():fullPathForFilename(pvrImage)
                    if CCFileUtils:sharedFileUtils():isFileExist(pvrImageFullPath) == true then
                        bgFileName = pvrImageFullPath
                    end

                    local backImage = CCTextureCache:sharedTextureCache():addImage(bgFileName)
                    if backImage ~= nil then
                        self._backgroundImage:setTexture(backImage)
                    end
                end

            else

            end

        elseif self._dungeonConfig.mode == BATTLE_MODE.SEVERAL_WAVES then
            self._backgroundImage:setScaleX(-1.0 * self._backgroundImage:getScaleX())
        end

        app.battle:onStartNewWave()
        
    end, timeToLeave)

    app.battle:performWithDelay(function()
        for i, view in ipairs(self._heroViews) do
            if view:getModel():isDead() == false then
                view:getModel():set("speed", view:getModel():get("speed") / speedCoefficient)
                view:getSkeletonActor():setAnimationScaleOriginal(view:getSkeletonActor():getAnimationScaleOriginal() / speedCoefficient)
            end
        end
        
        self._touchController:setSelectActorView(nil)
        self._touchController:enableTouchEvent()
        for _, view in ipairs(self._heroViews) do
            view:setEnableTouchEvent(true)
        end

        -- app.battle:onStartNewWave()

    end, timeToLeave + global.hero_enter_time / speedCoefficient - 0.3)
end

function QBattleScene:_checkTeamUp()
    if remote.oldUser ~= nil and remote.oldUser.level < remote.user.level then
        local oldUser = remote.oldUser
        remote.oldUser = nil
         if self.curModalDialog ~= nil then
            self.curModalDialog:close()
            self.curModalDialog = nil
        end
        local options = {}
        options["level"]=oldUser.level
        options["level_new"]=remote.user.level
        local database = QStaticDatabase:sharedDatabase()
        local config = database:getTeamConfigByTeamLevel(options["level_new"])
        local energy = 0
        local award = 0
        if config ~= nil then
            energy = config.energy
            award = config.token
        end
        options["energy"]=remote.user.energy - energy
        options["energy_new"]=remote.user.energy
        options["award"]=award
        self.curModalDialog = QDialogTeamUp.new(options,{
                        onChoose = handler(self, QBattleScene._onAbort)})
    else
        self:_onAbort()
    end
end

function QBattleScene:_onAbort(_, guideEvent)
    if self.curModalDialog ~= nil then
        self.curModalDialog:close()
        self.curModalDialog = nil
    end
    
    if app.tip._floatTip ~= nil then
      app.tip._floatTip = nil
      app:getNavigationThirdLayerController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
    end
    app.grid:pauseMoving()
    self:setBattleEnded(true)
    app:exitFromBattleScene(true)
    if guideEvent ~= nil then
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = guideEvent.name, options = guideEvent.options})
    end
end

function QBattleScene:_onRestart()
    if app.battle:isInEditor() then
        display.getRunningScene():endBattle()
        display.getRunningScene():onResetBattle()
        return
    end

     if self.curModalDialog ~= nil then
        self.curModalDialog:close()
        self.curModalDialog = nil
    end
    app.grid:pauseMoving()
    self:setBattleEnded(true)
    app:replaceBattleScene(self._dungeonConfig)
end

function QBattleScene:_onBattleTimer()
    local timeLeft = app.battle:getTimeLeft()
    if timeLeft < 0 then
        timeLeft = 0
    end

    if app.battle:isActiveDungeon() == true and app.battle:getActiveDungeonType() == DUNGEON_TYPE.ACTIVITY_TIME then
        if math.floor(timeLeft) <= 10 then
            self._labelCountDown:setColor(ccc3(255, 10, 0))
        end
    end

    self._labelCountDown:setString(string.format("%.2d:%.2d", math.floor(timeLeft / 60.0), math.floor(timeLeft % 60.0)))
end

function QBattleScene:_onWin(event)
    self:_removeSkeletonData()
    app:setIsClearSkeletonData(true)
    app:cleanTextureCache()

    -- is time over trigger battle end
    self._isTimeOver = event.isTimeOver
    -- end battle to finish buff and skill
    self:setBattleEnded(true)

    if not app.battle:isInEditor() then
        if app.battle:isPVPMode() == true then
            if app.battle:isInSunwell() == true then
                self:requestSunwell(true)
            else
                self:requestArenaWin()
            end
        else
            scheduler.performWithDelayGlobal(handler(self, self.requestBattleWin), 0)
        end
    end

    local heroCount = 0
    for i, view in ipairs(self._heroViews) do
        if view:getModel():isDead() == false and app.battle:isGhost(view:getModel()) == false then
            heroCount = heroCount + 1
        end
    end

    if event ~= nil and event.isAllEnemyDead == true then
        local x = BATTLE_AREA.left + BATTLE_AREA.width * 0.5
        local y = BATTLE_AREA.bottom + BATTLE_AREA.height * 0.2
        local interval = 160
        local newPositions = {}
        if heroCount == 1 then
            newPositions[1] = {x, y}
        elseif heroCount == 2 then
            newPositions[2] = {x + interval * 0.5, y}
            newPositions[1] = {x - interval * 0.5, y}
        elseif heroCount == 3 then
            newPositions[3] = {x + interval, y}
            newPositions[2] = {x, y}
            newPositions[1] = {x - interval, y}
        else
            newPositions[4] = {x + interval * 1.5, y}
            newPositions[3] = {x + interval * 0.5, y}
            newPositions[2] = {x - interval * 0.5, y}
            newPositions[1] = {x - interval * 1.5, y}
        end

        -- 将actor从grid上清除，否则会相互干扰最后的站位
        for i, view in ipairs(self._heroViews) do
            if view:getModel():isDead() == false and app.battle:isGhost(view:getModel()) == false then
                app.grid:removeActor(view:getModel())
            end
        end

        app.grid:resetWeight()
        local positionIndex = 1
        for i, view in ipairs(self._heroViews) do
            if view:getModel():isDead() == false and app.battle:isGhost(view:getModel()) == false then
                app.grid:addActor(view:getModel())
                app.grid:moveActorTo(view:getModel(), ccp(newPositions[positionIndex][1], newPositions[positionIndex][2]))
                positionIndex = positionIndex + 1
            end
        end
    else
        -- 将actor从grid上清除，否则会相互干扰最后的站位
        for i, view in ipairs(self._heroViews) do
            if view:getModel():isDead() == false and app.battle:isGhost(view:getModel()) == false then
                app.grid:removeActor(view:getModel())
            end
        end

        app.grid:resetWeight()
        for i, view in ipairs(self._heroViews) do
            if view:getModel():isDead() == false and app.battle:isGhost(view:getModel()) == false then
                app.grid:addActor(view:getModel())
            end
        end
    end

    local function onMoveCompleted()
        -- direction
        for i, view in ipairs(self._heroViews) do
            if view.getModel and view:getModel():isDead() == false and app.battle:isGhost(view:getModel()) == false then
                view:setDirection(QBaseActorView.DIRECTION_RIGHT)
            end
        end

        -- show victory
        for i, view in ipairs(self._heroViews) do
            if view.getModel and view:getModel():isDead() == false and app.battle:isGhost(view:getModel()) == false then
                view:getModel():onVictory()
            end
        end

        -- send message to server
        if app.battle:isPVPMode() == true then
            scheduler.performWithDelayGlobal(function()
                if app.battle:isInEditor() then
                    display.getRunningScene():endBattle(true)
                    display.getRunningScene():onResetBattle()
                    return
                end
                if app.battle:isInSunwell() == true then
                    self:sunwellWinHandler(nil, true)
                else
                    self:arenaWinHandler(nil, true)
                end
            end, global.victory_animation_duration)
            
        else
            scheduler.performWithDelayGlobal(function()
                if app.battle:isInEditor() then
                    display.getRunningScene():endBattle()
                    display.getRunningScene():onResetBattle()
                    return
                end
                self:battleWinHandler(nil, true)
            end, global.victory_animation_duration)
        end
    end

    local scheduler = CCDirector:sharedDirector():getScheduler()
    local handle = 0
    handle = scheduler:scheduleScriptFunc(function()
        local move_completed = true

        if event ~= nil and event.isAllEnemyDead == true then
            for i, view in ipairs(self._heroViews) do
                if view:getModel():isDead() == false and app.battle:isGhost(view:getModel()) == false then
                    if view:getModel():isWalking() then
                        move_completed = false
                    else
                        view:setDirection(QBaseActorView.DIRECTION_RIGHT)
                    end
                end
            end
        end

        if move_completed then
            onMoveCompleted()
            scheduler:unscheduleScriptEntry(handle)
        end
    end, 0, false)
    
end

--请求战斗胜利
function QBattleScene:requestBattleWin()

    local oldUser = clone(remote.user)
    local heroTotalCount = remote.teams:getHerosCount(QTeam.INSTANCE_TEAM)
    local teamHero = remote.teams:getTeams(QTeam.INSTANCE_TEAM)
   
    self._heroInfo = {}
    for i = 1, heroTotalCount, 1 do
      self._hero = remote.herosUtil:getHeroByID(teamHero[i])
      self._heroInfo[i] = self._hero 
    end
    local star = 0
    if self._isPassedBefore == true then
        star = 3
    elseif app.missionTracer ~= nil then
        star = app.missionTracer:getCompleteMissionCount()
    end
    app:getClient():dungeonFightSucceed(app.battle:getBattleLog(), star,
        function(data)
            data = {result = data, oldUser = oldUser}
            self:battleWinHandler(data)
        end,
        function(data)
            -- 全局处理器
            assert(false, "fight.dungeon.succeed filed:"..data.code)
        end
        )
end

--战斗胜利处理
function QBattleScene:battleWinHandler(data, isEnd)
    self:resultHandler(data, isEnd)
    if self.isEnd == true and self.battleResult ~= nil then
        --普通副本或者精英本需要记录当前打了新本
        local dungeonInfo = remote.instance:getDungeonById(self._dungeonConfig.id)
        if dungeonInfo ~= nil and dungeonInfo.dungeon_type == DUNGEON_TYPE.NORMAL then
            remote.user:addPropNumForKey("addupDungeonPassCount")
        elseif dungeonInfo ~= nil and dungeonInfo.dungeon_type == DUNGEON_TYPE.ELITE then
            remote.user:addPropNumForKey("addupDungeonElitePassCount")
        end
        
        local shops = nil
        if self.battleResult.result.shops ~= nil then
          shops = self.battleResult.result.shops
        end
        local alertDialog = function ()
            if self.curModalDialog ~= nil and self.curModalDialog.close ~= nil then
                self.curModalDialog:close()
                self.curModalDialog = nil
            end
            local star = 0
            if self._isPassedBefore == true then
                star = 3
            elseif app.missionTracer ~= nil then
                star = app.missionTracer:getCompleteMissionCount()
            end
            self.curModalDialog = QBattleDialogWin.new({config=self._dungeonConfig, oldUser = self.battleResult.oldUser, heroInfo = self._heroInfo, shops = shops},{
                -- onChoose = handler(self, QBattleScene._onAbort),
                onChoose = handler(self, QBattleScene._checkTeamUp),
                onRestart = handler(self, QBattleScene._onRestart),
                onNext = handler(self, QBattleScene._onNext)})
        end
        -- 全局处理器
        if self._isHaveMissions == false or self._isPassedBefore == true then
            alertDialog()
        else
            self.curModalDialog = QBattleDialogStar.new({dungeonId = self._dungeonConfig.id},{ onChoose = alertDialog})
        end
    end
end

--请求竞技场战斗胜利
function QBattleScene:requestArenaWin()

    local fighterInfo = {}
    local selfInfo = {}
    local rivalsInfo = self._dungeonConfig.rivalsInfo
    for _,value in pairs(rivalsInfo.heros) do
        local result = {actor_id = value.actorId, showed_at = 10, died_at = 50}
        table.insert(fighterInfo, result)
    end
    for _,value in pairs(self._dungeonConfig.myInfo.heros) do
        local result = {actor_id = value.actorId, showed_at = 10, died_at = nil}
        table.insert(selfInfo, result)
    end
    app:getClient():arenaFightEndRequest(self._dungeonConfig.rivalsInfo.userId, self._dungeonConfig.rivalsPos, {selfHerosStatus = selfInfo, rivalHerosStatus = fighterInfo}, function (data)
            self:arenaWinHandler(data)
        end)
end

--竞技场战斗胜利处理
function QBattleScene:arenaWinHandler(data, isEnd)
    self:resultHandler(data, isEnd)
    if self.isEnd == true and self.battleResult ~= nil then
        local info = clone(self._dungeonConfig.myInfo)
        for key,value in pairs(self.battleResult.arenaResponse.self) do
            info[key] = value
        end
        --get attack team to win dialog
        info.heros = {}
        local attackTeam = remote.teams:getTeams(remote.teams.ARENA_ATTACK_TEAM)
        for _,actorId in pairs(attackTeam) do
            table.insert(info.heros, remote.herosUtil:getHeroByID(actorId))
        end
        info.arenaMoney = self.battleResult.wallet.arenaMoney - self._dungeonConfig.myInfo.arenaMoney
        self.curModalDialog = QArenaDialogWin.new({info = info, rankInfo = self.battleResult},{
                onChoose = handler(self, QBattleScene._checkTeamUp),
                onRestart = handler(self, QBattleScene._onRestart),
                onNext = handler(self, QBattleScene._onNext)})
    end
end

--太阳井战斗胜利
function QBattleScene:requestSunwell(isWin)
    self._isWin = isWin
    --自己英雄
    local selfHeros = {}
    local liveHeroes = app.battle:getHeroes()
    local deadHeroes = app.battle:getDeadHeroes()
    for _, hero in ipairs(liveHeroes) do
        local skillCD = 1.0
        for _, skill in pairs(hero:getManualSkills()) do
            if skill:isReady() == false then
                skillCD = skill:getCDProgress()
                break
            end
        end
        table.insert(selfHeros, {actorId = hero:getActorID(), hp = hero:getHp(), skillCD = math.floor(skillCD * 1000)})
    end
    for _, hero in ipairs(deadHeroes) do
        table.insert(selfHeros, {actorId = hero:getActorID(), hp = 0, skillCD = 0})
    end
    remote.sunWell:setSunwellHeroInfoFromBattleEnd(selfHeros)
    --敌方英雄
    local enemies = {}
    local liveEnemies = app.battle:getEnemies()
    local allEnemies = self._dungeonConfig.dungeonInfo.info.heros
    for _,enemy in pairs(allEnemies) do
        local isFind = false
        for _,liveEnemy in pairs(liveEnemies) do
            if enemy.actorId == liveEnemy:getActorID() then
                isFind = true
                local skillCD = 1.0
                for _, skill in pairs(liveEnemy:getManualSkills()) do
                    if skill:isReady() == false then
                        skillCD = skill:getCDProgress()
                        break
                    end
                end
                table.insert(enemies, {actorId = liveEnemy:getActorID(), hp = liveEnemy:getHp(), skillCD = math.floor(skillCD * 1000)})
                break
            end
        end
        if isFind == false then
            table.insert(enemies, {actorId = enemy.actorId, hp = 0, skillCD = 0})
        end
    end

    local dungeonInfo = self._dungeonConfig.dungeonInfo
    --更新对手信息
    local fighter = remote.sunWell:getInstanceInfoByIndex(dungeonInfo.dungeonIndex)
    fighter  = fighter["fighter"..dungeonInfo.hardIndex]
    for _,value in pairs(fighter.heros) do
        for _,value2 in pairs(enemies) do
            if value.actorId == value2.actorId then
                value.hp = value2.hp
                value.skillCD = value2.skillCD
            end
        end
    end
    app:getClient():sunwellFightEndRequest(dungeonInfo.dungeonIndex, dungeonInfo.hardIndex, selfHeros, enemies, function (data)
            if self._isWin == true then
                self:sunwellWinHandler(data)
            else
                self:sunwellLoseHandler(data)
            end
        end)
end

--竞技场战斗胜利处理
function QBattleScene:sunwellWinHandler(data, isEnd)
    self:resultHandler(data, isEnd)
    if self.isEnd == true and self.battleResult ~= nil then
        local myTeam = clone(self._dungeonConfig.myTeam)
        self.curModalDialog = QSunWellDialogWin.new({myTeam = myTeam, isTimeOver = self._isTimeOver, sunwellMoney = self._dungeonConfig.sunwellMoney, rankInfo = self.battleResult},{
                onChoose = handler(self, QBattleScene._checkTeamUp),
                onRestart = handler(self, QBattleScene._onRestart),
                onNext = handler(self, QBattleScene._onNext)})
        remote.sunWell:checkNextPass()
    end
end

function QBattleScene:_onLose(event)
    self:_removeSkeletonData()
    app:setIsClearSkeletonData(true)
    app:cleanTextureCache()

    self:setBattleEnded(true)

    if not app.battle:isInEditor() then
        if app.battle:isPVPMode() == true then
            if app.battle:isInSunwell() == true then
                self:requestSunwell(false)
            else
                self:requestArenaLost()
            end
        end
    end

    local function playLose()
        local function showDialog() 
            scheduler.performWithDelayGlobal(function()
                if app.battle:isInEditor() then
                    display.getRunningScene():endBattle(false)
                    display.getRunningScene():onResetBattle()
                    return
                end

                if app.battle:isPVPMode() == true then
                    if app.battle:isInSunwell() == true then
                        self:sunwellLoseHandler(nil, true)
                    else
                        self:arenaLostHandler(nil, true)
                    end
                else
                    self.curModalDialog = QBattleDialogLose.new(self._dungeonConfig, {
                        onChoose = handler(self, QBattleScene._onAbort),
                        onRestart = handler(self, QBattleScene._onRestart),
                        onNext = handler(self, QBattleScene._onNext)
                    })
                end
            end, 1.5)
        end

        if app.battle:isInEditor() and not self._enemyViews then
            return
        end

        -- move to center
        local x = BATTLE_AREA.left + 840
        local y = BATTLE_AREA.bottom + BATTLE_AREA.height * 0.2
        local interval = 160
        local moveTime = 0

        -- 将actor从grid上清除，否则会相互干扰最后的站位
        for i, view in ipairs(self._enemyViews) do
            if view:getModel():isDead() == false then
                app.grid:removeActor(view:getModel())
            end
        end

        -- for i, view in ipairs(self._enemyViews) do
        --     if view:getModel():isDead() == false then
        --         local position = view:getModel():getPosition()
        --         local positionNew = ccp(x, y)
        --         local deltaX = position.x - positionNew.x
        --         local deltaY = position.y - positionNew.y
        --         local speed = view:getModel():getMoveSpeed()
        --         local time = math.sqrt(deltaX * deltaX + deltaY * deltaY) / speed
        --         if time > moveTime then
        --             moveTime = time
        --         end
        --         app.grid:addActor(view:getModel())
        --         app.grid:moveActorTo(view:getModel(), positionNew)
        --         app.battle:performWithDelay(function()
        --             view:setDirection(QBaseActorView.DIRECTION_RIGHT)
        --         end, time + 0.1)
        --         x = x - interval
        --     end
        -- end

        -- show victory
        scheduler.performWithDelayGlobal(function()
            for i, view in ipairs(self._enemyViews) do
                if view:getModel():isDead() == false then
                    view:getModel():onVictory()
                end
            end

            showDialog()
        end, moveTime)
        moveTime = moveTime + 3.0
    end

    scheduler.performWithDelayGlobal(function()
        playLose()
    end, 2.0)
end

function QBattleScene:requestArenaLost()

    local fighterInfo = {}
    local selfInfo = {}
    local rivalsInfo = self._dungeonConfig.rivalsInfo
    for _,value in pairs(rivalsInfo.heros) do
        local result = {actor_id = value.actorId, showed_at = 10, died_at = nil}
        table.insert(fighterInfo, result)
    end
    for _,value in pairs(self._dungeonConfig.myInfo.heros) do
        local result = {actor_id = value.actorId, showed_at = 10, died_at = 50}
        table.insert(selfInfo, result)
    end
    app:getClient():arenaFightEndRequest(rivalsInfo.userId, self._dungeonConfig.rivalsPos, {selfHerosStatus = selfInfo, rivalHerosStatus = fighterInfo}, function (data)
            self:arenaLostHandler(data)
        end)
end

function QBattleScene:arenaLostHandler(data, isEnd)
    self:resultHandler(data, isEnd)
    if self.isEnd == true and self.battleResult ~= nil then
        self.curModalDialog = QBattleDialogLose.new(nil,{
                onChoose = handler(self, QBattleScene._onAbort),
                onRestart = handler(self, QBattleScene._onRestart),
                onNext = handler(self, QBattleScene._onNext)})
    end
end

function QBattleScene:sunwellLoseHandler(data, isEnd)
    self:resultHandler(data, isEnd)
    if self.isEnd == true and self.battleResult ~= nil then
        self.curModalDialog = QBattleDialogLose.new(nil,{
                onChoose = handler(self, QBattleScene._onAbort),
                onRestart = handler(self, QBattleScene._onRestart),
                onNext = handler(self, QBattleScene._onNext)})
    end
end

function QBattleScene:resultHandler(data, isEnd)
    if data ~= nil then
        self.battleResult = data
        if self.isEnd == true then
            app:hideLoading()
        end
    end
    if isEnd ~= nil then
        self.isEnd = isEnd
        if self.battleResult == nil then
            app:showLoading()
        end
    end
end

function QBattleScene:_onBattleStart(event)
    if not app.battle:isPVPMode() then
        self:_prepareHeroes()
    end

    self._tip_cache:startCache()
end

function QBattleScene:_onBattleCutsceneStart(event)
    self._topBar:setVisible(false)
    self._autoSkillBar:setVisible(false)
    if event.cutscene == global.cutscenes.KRESH_ENTRANCE then
        self._cutscene = QKreshEntrance.new(event.cutscene)
        self._overSkeletonLayer:addChild(self._cutscene:getView())
        self._cutscene:startAnimation()
    else
        assert(false, "invalid cutscene name:" .. event.cutscene)
    end
end

function QBattleScene:_onWaveStarted(event)
    -- self._labelWave:setString(string.format("%d/%d", event.wave, app.battle:getWaveCount()))
    if app.battle:isPVPMode() == true or app.battle:isInTutorial() == true then
        return
    end

    if app.battle:isActiveDungeon() == true and app.battle:getActiveDungeonType() == DUNGEON_TYPE.ACTIVITY_TIME then
        return
    end

    if self._bossHpBar:isVisible() == false then
        self._waveBackground:setVisible(true)
        self._labelWave:setVisible(true)
    end

    -- change wave title
    local spriteFrame = nil
    local spriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()
    if app.battle:getWaveCount() == 1 then
        self._labelWave:setString("1/1")
    elseif app.battle:getWaveCount() == 2 then
        if event.wave == 1 then
            self._labelWave:setString("1/2")
        else
            self._labelWave:setString("2/2")
        end
    elseif app.battle:getWaveCount() == 3 then
        if event.wave == 1 then
            self._labelWave:setString("1/3")
        elseif event.wave == 2 then
            self._labelWave:setString("2/3")
        else
            self._labelWave:setString("3/3")
        end
    end
end

function QBattleScene:_onWaveEnded(event)
    if app.battle:isPVPMode() == true or app.battle:isInTutorial() == true then
        return
    end

    -- cancel all skill and disable touch and drag hero 
    self._touchController:setSelectActorView(nil)
    self._touchController:disableTouchEvent()
    self._dragController:disableDragLine(true)
    for _, view in ipairs(self._heroViews) do
        view:setEnableTouchEvent(false)
    end

    self._arrow:setVisible(true)

    if app.battle:isAutoNextWave() then
        self._arrow:setVisible(false)
        app.battle:performWithDelay(handler(self, self._onNextWaveClicked), 0)
    end
end

function QBattleScene:_onNext()

end

function QBattleScene:_onUseManualSkill(event)
    if event.actor == nil or event.skill == nil then
        return
    end

    if event.skill:isSelectActor() == true and not event.auto then
        if self._touchController ~= nil then
            local actorView = self:getActorViewFromModel(event.actor)
            if actorView ~= nil then
                self._touchController:setSelectActorView(actorView)
            end
        end
    end

    if string.find(INFO_SYSTEM_MODEL, "iPhone4") ~= nil or string.find(INFO_SYSTEM_MODEL, "iPod") ~= nil or string.find(INFO_SYSTEM_MODEL, "iPad2") ~= nil then
        app:setIsClearSkeletonData(true)
        app:cleanTextureCache()
        app:setIsClearSkeletonData(false)
    end
end

function QBattleScene:_onSetTimeGear(event)
	local time_gear = event.time_gear
    for _, view in ipairs(self._heroViews) do
        view:setAnimationScale(time_gear, "time_gear")
    end
    for _, view in ipairs(self._enemyViews) do
        view:setAnimationScale(time_gear, "time_gear")
    end
end

function QBattleScene:_onChangeDamageCoefficient(event)
    local ccbProxy = CCBProxy:create()
    local ccbOwner = {}
    local animationNode = CCBuilderReaderLoad("Battle_Buff.ccbi", ccbProxy, ccbOwner)
    animationNode:setPosition(display.cx, display.cy)
    local text = string.format("战斗疲劳，受到伤害增加%d%%", event.damage_coefficient * 100 - 100)
    ccbOwner.label_bai:setString(text)
    ccbOwner.label_huang:setString(text)
    self:addChild(animationNode)

    local animationProxy = QCCBAnimationProxy:create()
    animationProxy:retain()
    local animationManager = tolua.cast(animationNode:getUserObject(), "CCBAnimationManager")
    animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
        animationProxy:disconnectAnimationEventSignal()
        animationProxy:release()
        animationNode:removeFromParent()
    end)

    audio.playSound("audio/sound/ui/PVPFlagTaken.mp3")
end

-- return true if selece hero is changed
function QBattleScene:uiSelectHero(hero)
    if hero == nil then
        return false
    end

    local view = self:getActorViewFromModel(hero)
    if view == nil then
        return false
    end

    if self._touchController ~= nil then
        if self._dragController ~= nil then
            self._dragController:disableDragLine(true)
        end
        if self._touchController:getSelectActorView() == view then
            return true
        end
        self._touchController:setSelectActorView(view)
        return true
    end

    return false
end

function QBattleScene:setBattleEnded(isEnded)
    self._ended = isEnded
    if self._ended == true then
        -- disable drag
        if self._dragController ~= nil then
            self._dragController:disableDragLine(true)
        end
    end

    app.battle:ended()

    self._tip_cache:stopCache()
end

function QBattleScene:getHeroViews()
    return self._heroViews
end

function QBattleScene:getEnemyViews()
    return self._enemyViews
end

function QBattleScene:getActorViewFromModel(model)
    if model == nil then
        return
    end
    for i, view in ipairs(self._heroViews) do
        if view:getModel() == model then
            return view
        end
    end
    for i, view in ipairs(self._enemyViews) do
        if view:getModel() == model then
            return view
        end
    end
    return nil
end

function QBattleScene:getEffectViews()
    return self._effectViews
end

-- isInFront: display in front when black layer is visible
function QBattleScene:addEffectViews(effect, options)
    if effect == nil then
        return
    end

    options = options or {}
    if options.isFrontEffect == true then
        table.insert(self._frontEffectView, effect)
    elseif options.isGroundEffect == true then
        table.insert(self._groundEffectView, effect)
    else
        table.insert(self._effectViews, effect)
    end
    self:addSkeletonContainer(effect)
end

function QBattleScene:removeEffectViews(effect)
    if effect == nil then
        return
    end

    for i, view in ipairs(self._effectViews) do
        if effect == view then
            effect:removeFromParent()
            table.remove(self._effectViews, i)
            return
        end
    end

    for i, view in ipairs(self._frontEffectView) do
        if effect == view then
            effect:removeFromParent()
            table.remove(self._frontEffectView, i)
            return
        end
    end

    for i, view in ipairs(self._groundEffectView) do
        if effect == view then
            effect:removeFromParent()
            table.remove(self._groundEffectView, i)
            return
        end
    end
end

function QBattleScene:replaceActorViewWithCharacterId(actor, characterId)
    if actor == nil then
        return
    end

    local actorView = self:getActorViewFromModel(actor)
    if actorView == nil then
        return
    end

    if self._touchController and self._touchController:getSelectActorView() == actorView then
        self._touchController:setSelectActorView(nil)
    end

    local positionX, positionY = actorView:getPosition()

    actor:willReplaceActorView()

    actor:setReplaceCharacterId(characterId)

    local newActorView = nil
    if actor:getType() == ACTOR_TYPES.HERO then
        newActorView = QHeroActorView.new(actor)
        newActorView:setAnimationScale(app.battle:getTimeGear(), "time_gear")
        table.insert(self._heroViews, newActorView)
        table.removebyvalue(self._heroViews, actorView)
    else
        newActorView = QNpcActorView.new(actor)
        newActorView:setAnimationScale(app.battle:getTimeGear(), "time_gear")
        table.insert(self._enemyViews, newActorView)
        table.removebyvalue(self._enemyViews, actorView)
    end

    actorView:removeFromParent()
    actorView = nil
    self:addSkeletonContainer(newActorView)

    actor:didReplaceActorView()

    actor:setActorPosition(ccp(positionX, positionY))
    actor:clearLastAttackee()
    app.battle:reloadActorAi(actor)
    app.grid:setActorTo(actor, actor:getPosition())
end

function QBattleScene:replaceActorAI(actor, aitype)
    local actorView = self:getActorViewFromModel(actor)
    if actorView == nil then
        return
    end

    local positionX, positionY = actorView:getPosition()
    actor:setActorPosition(ccp(positionX, positionY))
    actor:clearLastAttackee()
    app.battle:replaceActorAI(actor, aitype)
    app.grid:setActorTo(actor, actor:getPosition())
end

-- color is a CCColor4F value
function QBattleScene:displayRect(bottomLeftPos, topRightPos, duration, color)
    if bottomLeftPos == nil or topRightPos == nil then
        return
    end

    duration = duration or 2.0
    color = color or display.COLOR_BLUE_C4F

    if bottomLeftPos.x < BATTLE_AREA.left then
        bottomLeftPos.x = BATTLE_AREA.left
    end
    if bottomLeftPos.y < BATTLE_AREA.bottom then
        bottomLeftPos.y = BATTLE_AREA.bottom
    end
    if topRightPos.x > BATTLE_AREA.right then
        topRightPos.x = BATTLE_AREA.right
    end
    if topRightPos.y > BATTLE_AREA.top then
        topRightPos.y = BATTLE_AREA.top
    end

    local vertices = {}
    table.insert(vertices, {bottomLeftPos.x, bottomLeftPos.y})
    table.insert(vertices, {bottomLeftPos.x, topRightPos.y})
    table.insert(vertices, {topRightPos.x, topRightPos.y})
    table.insert(vertices, {topRightPos.x, bottomLeftPos.y})
    local param = {
        fillColor = ccc4f(0.0, 0.0, 0.0, 0.0),
        borderWidth = 2,
        borderColor = color
    }
    local drawNode = CCDrawNode:create()
    drawNode:clear()
    drawNode:drawPolygon(vertices, param) -- red color
    self._overSkeletonLayer:addChild(drawNode)

    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(duration - 0.3))
    arr:addObject(CCFadeOut:create(0.3))
    arr:addObject(CCRemoveSelf:create(true))
    drawNode:runAction(CCSequence:create(arr))
end

-- position is counter-clockwise
-- color is a CCColor4F value
function QBattleScene:displayTriangle(position1, position2, position3, duration, color)
    if position1 == nil or position2 == nil or position3 == nil then
        return
    end

    duration = duration or 2.0
    color = color or display.COLOR_BLUE_C4F

    local vertices = {}
    table.insert(vertices, {position1.x, position1.y})
    table.insert(vertices, {position2.x, position2.y})
    table.insert(vertices, {position3.x, position3.y})

    local param = {
        fillColor = ccc4f(0.0, 0.0, 0.0, 0.0),
        borderWidth = 2,
        borderColor = color
    }
    local drawNode = CCDrawNode:create()
    drawNode:clear()
    drawNode:drawPolygon(vertices, param) -- red color
    self._overSkeletonLayer:addChild(drawNode)

    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(duration - 0.3))
    arr:addObject(CCFadeOut:create(0.3))
    arr:addObject(CCRemoveSelf:create(true))
    drawNode:runAction(CCSequence:create(arr))
end

function QBattleScene:displayWarningZone(effect_id, position, radius, duration, color, scaleX, scaleY, degree)
    if position == nil or radius == nil then
        return
    end

    duration = duration or 3.0
    color = color or cc.c4f(1.0, 1.0, 1.0, 0.2)
    scaleX = scaleX or 1.0
    scaleY = scaleY or 0.5

    if effect_id then
        local frontEffect, backEffect = QBaseEffectView.createEffectByID(effect_id)
        local effect = frontEffect or backEffect
        local effectNode = CCNode:create()
        effectNode:addChild(effect)
        effectNode:setPositionX(position.x)
        effectNode:setPositionY(position.y)
        self._backgroundLayer:addChild(effectNode)
        effect:playAnimation(EFFECT_ANIMATION, true)
        effect:playSoundEffect(false)

        local arr = CCArray:create()
        arr:addObject(CCDelayTime:create(duration - 0.3))
        arr:addObject(CCFadeOut:create(0.3))
        arr:addObject(CCCallFunc:create(function()
            effect:stopAnimation()
        end))
        arr:addObject(CCRemoveSelf:create(true))
        effectNode:runAction(CCSequence:create(arr))

        return effectNode
    end
end

-- function for tutorial

function QBattleScene:_onTouchForTutorial(event)
    if self._touchRect == nil then
        return
    end

    if event.name == "began" then
        return true
    elseif event.name == "ended" then
        if self._touchRect:containsPoint(ccp(event.x, event.y)) == true then
                        
            if self._tutorialForUseSkill == true then -- 技能点击引导
                app.battle:performWithDelay(handler(self._tutorialStatusView, self._tutorialStatusView._onClickSkillButton1), 0.2)

                self._tutorialTouchNode:setTouchEnabled(false)
                self._tutorialTouchNode:removeFromParent()
                self._tutorialTouchNode = nil
                self._touchRect = nil
                self._tutorialStatusView = nil
                self._tutorialForUseSkill = nil

                app.battle:resume()

            elseif self._tutorialForTouchActor == true then -- 角色点击引导
                local enemyView = self:getActorViewFromModel(self._tutorialEnemy)
                local heroes = app.battle:getHeroes()
                for _, hero in ipairs(heroes) do
                    if hero:isHealth() == false then
                        local heroView = self:getActorViewFromModel(hero)
                        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTouchController.EVENT_TOUCH_END_FOR_ATTACK, heroView = heroView, targetView = enemyView})
                    end
                end
                self._tutorialEnemy:onMarked()

                self._tutorialTouchNode:setTouchEnabled(false)
                self._tutorialTouchNode:removeFromParent()
                self._tutorialTouchNode = nil
                self._touchRect = nil
                self._tutorialEnemy = nil
                self._tutorialForTouchActor = nil
                
                app.battle:resume()

            else -- 角色对话
                if self.word ~= "" and self._tutorialDialogue ~= nil and self._tutorialDialogue._isSaying == true and self._tutorialDialogue:isVisible() then 
                  self._tutorialDialogue:stopSay()
                  printInfo("is say")
                  self._tutorialDialogue._ccbOwner.label_text:setString(q.autoWrap(self.word,26,13,312 * 2))
                elseif #self._tutorialSentences > 0 then
                    local sentences = self._tutorialSentences
                    local imageFiles = self._tutorialImageFiles
                    local names = self._tutorialNames

                    local dialogue = self._tutorialDialogue
                    dialogue:addWord(sentences[#sentences])
                    dialogue:setActorImage(imageFiles[#imageFiles])
                    dialogue:setName(names[#names])
                    self.word = sentences[#sentences]
                    
                    sentences[#sentences] = nil
                    imageFiles[#imageFiles] = nil
                    names[#names] = nil

                    local checkLength = #self._tutorialSentences
                    app.battle:performWithDelay(function()
                        if self._tutorialSentences and checkLength == #self._tutorialSentences then
                            self:_onTouchForTutorial({name = "ended", x = 100, y = 100})
                        end
                    end, 2.0)
                else
                    local actor = self._tutorialActor

                    if actor and not app.battle:isInEditor() then 
                        app.tip:floatTip(string.format("%s加入战斗", actor:getDisplayName())) 
                    end

                    self._tutorialTouchNode:setTouchEnabled(false)
                    self._tutorialTouchNode:removeFromParent()
                    self._tutorialTouchNode = nil
                    self._touchRect = nil
                    self._tutorialDialogue = nil
                    self._tutorialSentences = nil
                    self._tutorialImageFiles = nil
                    self._tutorialNames = nil
                    self._tutorialActor = nil
                
                    app.battle:resume()
                    app.scene:showHeroStatusViews()

                    if self._tutorialFinishCallback ~= nil then
                        local cb = self._tutorialFinishCallback
                        self._tutorialFinishCallback = nil
                        cb()
                    end
                end
            end
        end
    end
end

function QBattleScene:pauseBattleAndUseSkill(actor, skill)
    if actor == nil or skill == nil then
        return
    end

    local statusView = nil
    for _, heroStatusView in ipairs(self._heroStatusViews) do
        local hero = heroStatusView:getActor()
        if hero == actor then
            statusView = heroStatusView
            break
        end
    end

    if statusView == nil then
        return
    end

    self._tutorialStatusView = statusView

    local touchNode = CCNode:create()

    touchNode:addChild(CCLayerColor:create(ccc4(0, 0, 0, 128), display.width, display.height)) 
    touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
    touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    touchNode:setTouchSwallowEnabled(true)
    self:addChild(touchNode)
    touchNode:setTouchEnabled(true)
    touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QBattleScene._onTouchForTutorial))
    self._tutorialTouchNode = touchNode

    local skillNode = statusView._ccbOwner.node_skill1
    local positionX = statusView:getPositionX() + skillNode:getPositionX()
    local positionY = statusView:getPositionY() + skillNode:getPositionY()
    local handTouch = QUIWidgetTutorialHandTouch.new({word = "点击释放技能", direction = "up"})
    handTouch:setPosition(positionX, positionY)
--    handTouch:handRightUp()
--    handTouch:tipsLeftUp()
    touchNode:addChild(handTouch)

    self._touchRect = CCRectMake(positionX - 50, positionY - 50, 100, 100)
    self._tutorialForUseSkill = true
    
    app.battle:pause()
end

function QBattleScene:pauseBattleAndAttackEnemy(enemy, word, word2)
    if enemy == nil then
        return
    end

    self._tutorialEnemy = enemy

    local touchNode = CCNode:create()
    touchNode:addChild(CCLayerColor:create(ccc4(0, 0, 0, 128), display.width, display.height)) 
    touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
    touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    touchNode:setTouchSwallowEnabled(true)
    self:addChild(touchNode)
    touchNode:setTouchEnabled(true)
    touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QBattleScene._onTouchForTutorial))
    self._tutorialTouchNode = touchNode

    local position = enemy:getCenterPosition_Stage()
    local handTouch = QUIWidgetTutorialHandTouch.new({word = word and word or "选择集火对象", direction = "up", word2 = word2})
    handTouch:setPosition(position.x, position.y)
--    if not right then
--        handTouch:tipsLeftUp()
--        handTouch:handRightUp()
--    else
--        handTouch:tipsRightUp()
--        handTouch:handRightDown()
--    end
    touchNode:addChild(handTouch)

    local rect = enemy:getRect()
    self._touchRect = CCRectMake(position.x - rect.size.width * 0.5, position.y - rect.size.height * 0.5, rect.size.width, rect.size.height)
    self._tutorialForTouchActor = true

    app.battle:pause()
end

function QBattleScene:pauseBattleAndDisplayDislog(sentences, imageFiles, names, actor, finishCallback)
    if sentences == nil or imageFiles == nil or names == nil or #sentences == 0 or #imageFiles == 0 or #names == 0 then
        return
    end

    assert(#sentences == #imageFiles and #imageFiles == #names, "")

    self._tutorialSentences = sentences
    self._tutorialImageFiles = imageFiles
    self._tutorialNames = names
    self._tutorialActor = actor
    self._tutorialFinishCallback = finishCallback

    local touchNode = CCNode:create()
    touchNode:addChild(CCLayerColor:create(ccc4(0, 0, 0, 128), display.width, display.height)) 
    touchNode:setCascadeBoundingBox(CCRect(0.0, 0.0, display.width, display.height))
    touchNode:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    touchNode:setTouchSwallowEnabled(true)
    self:addChild(touchNode)
    touchNode:setTouchEnabled(true)
    touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QBattleScene._onTouchForTutorial))
    self._tutorialTouchNode = touchNode

    local dialogue = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, isSay = true, text = sentences[#sentences], name = names[#names]})
    dialogue:setActorImage(imageFiles[#imageFiles])
    dialogue:setName(names[#names])
    touchNode:addChild(dialogue)
    self._tutorialDialogue = dialogue
    self.word = sentences[#sentences]

    sentences[#sentences] = nil
    imageFiles[#imageFiles] = nil
    names[#names] = nil

    self._touchRect = CCRectMake(0, 0, display.width, display.height)

    local checkLength = #self._tutorialSentences
    app.battle:performWithDelay(function()
        if self._tutorialSentences and checkLength == #self._tutorialSentences then
            self:_onTouchForTutorial({name = "ended", x = 100, y = 100})
        end
    end, 2.0)

    app.battle:pause()
    app.scene:hideHeroStatusViews()
end

function QBattleScene:_getSkillIdWithAi(aiConfig, skillIds)
    if aiConfig == nil or skillIds == nil then
        return
    end
    if aiConfig.OPTIONS ~= nil and aiConfig.OPTIONS.skill_id ~= nil then
        table.insert(skillIds, aiConfig.OPTIONS.skill_id)
    end

    if aiConfig.ARGS ~= nil then
        for _, conf in pairs(aiConfig.ARGS) do
            self:_getSkillIdWithAi(conf, skillIds)
        end
    end
end

function QBattleScene:_getEffectIdWithSkill(skillConfig, effectIds)
    if skillConfig == nil or effectIds == nil then
        return
    end
    if skillConfig.OPTIONS ~= nil and skillConfig.OPTIONS.effect_id ~= nil then
        table.insert(effectIds, skillConfig.OPTIONS.effect_id)
    end

    if skillConfig.ARGS ~= nil then
        for _, conf in pairs(skillConfig.ARGS) do
            self:_getEffectIdWithSkill(conf, effectIds)
        end
    end
end

function QBattleScene:_loadSkeletonData()
    if self._dungeonConfig.isTutorial == true or self._dungeonConfig.isEditor == true then
        return
    end

    self:_removeSkeletonData()

    local dataBase = QStaticDatabase.sharedDatabase()
    local skeletonFiles = {}

    -- hero actor
    local teamName = QTeam.INSTANCE_TEAM
    if self._dungeonConfig.teamName ~= nil then
        teamName = self._dungeonConfig.teamName
    end

    local firstCount = 0
    if remote.teams ~= nil then
        for i, heroId in ipairs(remote.teams:getTeams(teamName)) do
            local hero = remote.herosUtil:getHeroByID(heroId)
            if hero~= nil then
                local character = dataBase:getCharacterByID(hero.actorId)
                if character ~= nil then
                    local characterDisplay = dataBase:getCharacterDisplayByID(character.display_id)
                    if characterDisplay ~= nil then
                        local actorFile = characterDisplay.actor_file
                        local skeletonFile = actorFile .. ".json"
                        local atlasFile = actorFile .. ".atlas"
                        table.insert(skeletonFiles, {skeletonFile, atlasFile})
                        firstCount = firstCount + 1
                        if characterDisplay.weapon_file ~= nil then
                            local weaponFile = characterDisplay.weapon_file
                            local weaponSkeletonFile = weaponFile .. ".json"
                            local weaponAtlasFile = weaponFile .. ".atlas"
                            table.insert(skeletonFiles, {weaponSkeletonFile, weaponAtlasFile})
                            firstCount = firstCount + 1
                        end
                    end
                end
            end
        end
    end

    -- enemy actor
    if self:isPVPMode() == true then
        for i, hero in ipairs(self._dungeonConfig.pvp_rivals) do
            local character = dataBase:getCharacterByID(hero.actorId)
            if character ~= nil then
                local characterDisplay = dataBase:getCharacterDisplayByID(character.display_id)
                if characterDisplay ~= nil then
                    local actorFile = characterDisplay.actor_file
                    local skeletonFile = actorFile .. ".json"
                    local atlasFile = actorFile .. ".atlas"
                    table.insert(skeletonFiles, {skeletonFile, atlasFile})
                    firstCount = firstCount + 1
                    if characterDisplay.weapon_file ~= nil then
                        local weaponFile = characterDisplay.weapon_file
                        local weaponSkeletonFile = weaponFile .. ".json"
                        local weaponAtlasFile = weaponFile .. ".atlas"
                        table.insert(skeletonFiles, {weaponSkeletonFile, weaponAtlasFile})
                        firstCount = firstCount + 1
                    end
                end
            end
        end
    else
        local dungeon = dataBase:getMonstersById(self._dungeonConfig.monster_id)
        if dungeon ~= nil then
            for i, monsterInfo in ipairs(dungeon) do
                local character = dataBase:getCharacterByID(app:getBattleRandomNpc(self._dungeonConfig.monster_id, i, monsterInfo.npc_id))
                if character ~= nil then
                    local characterDisplay = dataBase:getCharacterDisplayByID(character.display_id)
                    if characterDisplay ~= nil then
                        local actorFile = characterDisplay.actor_file
                        local skeletonFile = actorFile .. ".json"
                        local atlasFile = actorFile .. ".atlas"
                        table.insert(skeletonFiles, {skeletonFile, atlasFile})
                        firstCount = firstCount + 1
                        if characterDisplay.weapon_file ~= nil then
                            local weaponFile = characterDisplay.weapon_file
                            local weaponSkeletonFile = weaponFile .. ".json"
                            local weaponAtlasFile = weaponFile .. ".atlas"
                            table.insert(skeletonFiles, {weaponSkeletonFile, weaponAtlasFile})
                            firstCount = firstCount + 1
                        end
                    end
                end
            end
        end
    end

    -- local skillIds = {}
    -- -- hero skill
    -- if remote.teams ~= nil then
    --     for i, heroId in ipairs(remote.teams:getTeams(teamName)) do
    --         local hero = remote.herosUtil:getHeroByID(heroId)
    --         if hero~= nil then
    --             for _, skillId in ipairs(hero.skills) do
    --                 if skillId ~= nil and string.len(skillId) > 0 then
    --                     skillIds[skillId] = skillId
    --                 end
    --             end
    --         end
    --     end
    -- end

    -- -- enemy skill
    --  if dungeon ~= nil then
    --     for i, monsterInfo in ipairs(dungeon) do
    --         local character = dataBase:getCharacterByID(app:getBattleRandomNpc(self._dungeonConfig.monster_id, i, monsterInfo.npc_id))
    --         if character ~= nil then
    --             if character.innate_skill ~= nil and string.len(character.innate_skill) > 0 then
    --                 skillIds[character.innate_skill] = character.innate_skill
    --             end
    --             if character.npc_skill ~= nil and string.len(character.npc_skill) > 0 then
    --                 skillIds[character.npc_skill] = character.npc_skill
    --             end
    --             if character.npc_skill_2 ~= nil and string.len(character.npc_skill_2) > 0 then
    --                 skillIds[character.npc_skill_2] = character.npc_skill_2
    --             end
    --             if character.npc_ai ~= nil then
    --                 local config = QFileCache.sharedFileCache():getAIConfigByName(character.npc_ai)
    --                 if config ~= nil then
    --                     local skillIdsInAi = {}
    --                     self:_getSkillIdWithAi(config, skillIdsInAi)
    --                     for _, skillId in ipairs(skillIdsInAi) do
    --                         skillIds[skillId] = skillId
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end

    -- local function _warmUpSkillBehaviorNode(config)
    --     if config == nil or type(config) ~= "table" then
    --         return
    --     end

    --     QFileCache.sharedFileCache():getSkillClassByName(config.CLASS)

    --     local args = config.ARGS
    --     if args ~= nil then
    --         for k, v in pairs(args) do
    --             _warmUpSkillBehaviorNode(v)
    --         end
    --     end
    -- end
    -- for _, skillId in pairs(skillIds) do
    --     local skillData = dataBase:getSkillByID(skillId)
    --     if skillData.skill_behavior ~= nil then
    --         local config = QFileCache.sharedFileCache():getSkillConfigByName(skillData.skill_behavior)
    --         if config ~= nil then
    --             _warmUpSkillBehaviorNode(config)
    --         end
    --     end
    -- end

    -- local effectIds = {}
    -- for _, skillId in pairs(skillIds) do
    --     -- effect of skill
    --     local skillData = dataBase:getSkillByID(skillId)
    --     assert(skillData ~= nil, "can not find skill data with id:" .. skillId)
    --     if skillData ~= nil then
    --         if skillData.attack_effect ~= nil then
    --             effectIds[skillData.attack_effect] = skillData.attack_effect
    --         end
    --         if skillData.bullet_effect ~= nil then
    --             effectIds[skillData.bullet_effect] = skillData.bullet_effect
    --         end
    --         if skillData.hit_effect ~= nil then
    --             effectIds[skillData.hit_effect] = skillData.hit_effect
    --         end
    --         if skillData.second_hit_effect ~= nil then
    --             effectIds[skillData.second_hit_effect] = skillData.second_hit_effect
    --         end
    --         if skillData.skill_behavior ~= nil then
    --             local config = QFileCache.sharedFileCache():getSkillConfigByName(skillData.skill_behavior)
    --             if config ~= nil then
    --                 local effectIdInSkill = {}
    --                 self:_getEffectIdWithSkill(config, effectIdInSkill)
    --                 for _, effectId in ipairs(effectIdInSkill) do
    --                     effectIds[effectId] = effectId
    --                 end
    --             end
    --         end

    --         -- effect of buff
    --         if skillData.buff_id_1 ~= nil then
    --             local buffData = dataBase:getBuffByID(skillData.buff_id_1)
    --             if buffData.begin_effect_id ~= nil then
    --                 effectIds[buffData.begin_effect_id] = buffData.begin_effect_id
    --             end
    --             if buffData.effect_id ~= nil then
    --                 effectIds[buffData.effect_id] = buffData.effect_id
    --             end
    --             if buffData.finish_effect_id ~= nil then
    --                 effectIds[buffData.finish_effect_id] = buffData.finish_effect_id
    --             end
    --         end
    --         if skillData.buff_id_2 ~= nil then
    --             local buffData = dataBase:getBuffByID(skillData.buff_id_2)
    --             if buffData.begin_effect_id ~= nil then
    --                 effectIds[buffData.begin_effect_id] = buffData.begin_effect_id
    --             end
    --             if buffData.effect_id ~= nil then
    --                 effectIds[buffData.effect_id] = buffData.effect_id
    --             end
    --             if buffData.finish_effect_id ~= nil then
    --                 effectIds[buffData.finish_effect_id] = buffData.finish_effect_id
    --             end
    --         end

    --         -- effect of trap 
    --         if skillData.trap_id ~= nil then
    --             local trapData = dataBase:getTrapByID(skillData.trap_id)
    --             if trapData.start_effect ~= nil then
    --                 effectIds[trapData.start_effect] = trapData.start_effect
    --             end
    --             if trapData.execute_effect ~= nil then
    --                 effectIds[trapData.execute_effect] = trapData.execute_effect
    --             end
    --             if trapData.finish_effect ~= nil then
    --                 effectIds[trapData.finish_effect] = trapData.finish_effect
    --             end
    --         end
    --     end
    -- end 

    -- for _, effectId in pairs(effectIds) do
    --     local frontFile, backFile = dataBase:getEffectFileByID(effectId)
    --     if frontFile ~= nil then
    --         local skeletonFile = frontFile .. ".json"
    --         local atlasFile = frontFile .. ".atlas"
    --         table.insert(skeletonFiles, {skeletonFile, atlasFile})
    --     end
    --     if backFile ~= nil then
    --         local skeletonFile = backFile .. ".json"
    --         local atlasFile = backFile .. ".atlas"
    --         table.insert(skeletonFiles, {skeletonFile, atlasFile})
    --     end
    -- end

    for i, item in ipairs(skeletonFiles) do
        if item[1] ~= nil and item[2] ~= nil then
            local skeletonData = QSkeletonDataCache:sharedSkeletonDataCache():cacheSkeletonData(item[1], item[2])
            if skeletonData ~= nil then
                skeletonData:retain()
                table.insert(self._skeletonDatas, skeletonData)
            end
        end
        if i == firstCount then
            break
        end
    end
    
    if firstCount + 1 < #self._skeletonDatas then
        self._loadingSkeletonFiles = skeletonFiles
        self._loadingSkeletonIndex = firstCount + 1
        self._loadingSkeletonFrameId = scheduler.scheduleUpdateGlobal(handler(self, QBattleScene._onLoadingSkeletonFrame), 0.1)
    end
end

function QBattleScene:_onLoadingSkeletonFrame(dt)
    local item = self._loadingSkeletonFiles[self._loadingSkeletonIndex]
    if item[1] ~= nil and item[2] ~= nil then
        local skeletonData = QSkeletonDataCache:sharedSkeletonDataCache():cacheSkeletonData(item[1], item[2])
        if skeletonData ~= nil then
            skeletonData:retain()
            table.insert(self._skeletonDatas, skeletonData)
        end
    end

    self._loadingSkeletonIndex = self._loadingSkeletonIndex + 1
    if self._loadingSkeletonIndex > #self._loadingSkeletonFiles then
        scheduler.unscheduleGlobal(self._loadingSkeletonFrameId)
        self._loadingSkeletonFrameId = nil
    end
end

function QBattleScene:_removeSkeletonData()
    if self._loadingSkeletonFrameId ~= nil then
        scheduler.unscheduleGlobal(self._loadingSkeletonFrameId)
        self._loadingSkeletonFrameId = nil
    end

    if self._skeletonDatas == nil then
        self._skeletonDatas = {}
        return
    end

    if #self._skeletonDatas == 0 then
        return 
    end

    for _, skeletonData in ipairs(self._skeletonDatas) do
        skeletonData:release()
    end

    self._skeletonDatas = {}
end

function QBattleScene:_onSkipBattle(isWin)
    if isWin == true then
        self:_onWin()
    else
        self:_onLose()
    end
end

function QBattleScene:isInBlackLayer()
    return self._showBlackLayerReferenceCount > 0
end

function QBattleScene:isPVPMode()
    return self._dungeonConfig.isPVPMode or false
end

function QBattleScene:isInArena()
    return self._dungeonConfig.isArena or false
end

function QBattleScene:isInSunwell()
    return self._dungeonConfig.isSunwell or false
end

function QBattleScene:getTip(ccb_name)
    return self._tip_cache.getTip(ccb_name)
end

function QBattleScene:returnTip(tip)
    self._tip_cache.returnTip(tip)
end

return QBattleScene
