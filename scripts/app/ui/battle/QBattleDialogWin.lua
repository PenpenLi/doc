--
-- Author: Your Name
-- Date: 2014-05-19 10:58:04
--
local QBattleDialog = import(".QBattleDialog")
local QBattleDialogWin = class(".QBattleDialogWin", QBattleDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
-- local QUIWidgetEliteInfoStar = import("..widgets.QUIWidgetEliteInfoStar")
local QUIWidgetBattleWinHeroHead = import("..widgets.QUIWidgetBattleWinHeroHead")
local QDialogTeamUp = import(".QDialogTeamUp")
local QRectUiMask = import(".QRectUiMask")
local QTeam = import("..utils.QTeam")
local QRectAnimationUI = import(".QRectAnimationUI")
local QTutorialDirector = import("...tutorial.QTutorialDirector")
local QUIDialogMystoryStoreAppear = import("..dialogs.QUIDialogMystoryStoreAppear")
local QShop = import("...utils.QShop")

function QBattleDialogWin:ctor(options,owner)
	local ccbFile = "ccb/Battle_Dialog_Victory.ccbi"
	local callBacks = {{ccbCallbackName = "onTriggerNext", callback = handler(self, QBattleDialogWin._onTriggerNext)}}

	if owner == nil then 
		owner = {}
	end
	--设置该节点启用enter事件
	self:setNodeEventEnabled(true)
	QBattleDialogWin.super.ctor(self,ccbFile,owner,callBacks)

	local database = QStaticDatabase:sharedDatabase()
	local config = database:getConfig()

	--保存传递数据 awards
	local data = options.config
	self._oldUser = options.oldUser
	self._oldTeamLevel = self._oldUser.level
	self._teamLevel = self._oldTeamLevel
	self._oldTeamExp = self._oldUser.exp
	self._oldTotalExp = database:getExperienceByTeamLevel(self._teamLevel)
	self._oldExpBuff = 0
	self._oldExpStartBuff = self._oldTeamExp
	self._heroOldInfo = options.heroInfo
	self._stores = options.shops

	self._ccbOwner.node_instance:setVisible(true)
	self._ccbOwner.node_arena:setVisible(false)
	self._ccbOwner.node_sunwell:setVisible(false)
	self._ccbOwner.sunwell_tips:setVisible(false)

	if remote.instance:getDungeonById(data.id) ~= nil then
		self._ccbOwner.node_title_normal:setVisible(true)
		self._ccbOwner.node_title_activity:setVisible(false)
	else
		self._ccbOwner.node_title_normal:setVisible(false)
		self._ccbOwner.node_title_activity:setVisible(true)
	end

	--计算总共经验获取
	self._expTotal = 0

	--计算总共金钱获取
	self._moneyTotal = 0

	--掉落物品显示
 	 self._itemsBox = {}
    for i=1,5,1 do 
    	self._itemsBox[i] = QUIWidgetItemsBox.new()
    	self._ccbOwner["item"..i]:addChild(self._itemsBox[i])
    	self._itemsBox[i]:setVisible(false)
    	self._itemsBox[i]:setPromptIsOpen(true)
    end

	local config = QStaticDatabase:sharedDatabase():getConfig()
	local itmes = {}

	if app.battle:isActiveDungeon() == true and app.battle:getActiveDungeonType() == DUNGEON_TYPE.ACTIVITY_TIME then
		local awards = app.battle:getDeadEnemyRewards(true)
		for k, value in pairs(awards) do 
	  		local id = value.id
	  		if id == nil then
	  			id = "type"..value.type
	  		end
	  	 	if itmes[id] == nil then
	  	 		itmes[id] = value
	  	 	else
	  	 		itmes[id].count = itmes[id].count + value.count
	  	 	end
	  	end
	  	itmes["type"..config.award_type_team_exp] = {type = config.award_type_team_exp, count = data.team_exp}
	else
		if data.awards ~= nil then
		  	for k, value in pairs(data.awards) do 
		  		local id = value.id
		  		if id == nil then
		  			id = "type"..value.type
		  		end
		  	 	if itmes[id] == nil then
		  	 		itmes[id] = value
		  	 	else
		  	 		itmes[id].count = itmes[id].count + value.count
		  	 	end
		  	end
		end

		if data.awards2 ~= nil then
		  	for k, value in pairs(data.awards2) do 
		  		local id = value.id
		  		if id == nil then
		  			id = "type"..value.type
		  		end
		  	 	if itmes[id] == nil then
		  	 		itmes[id] = value
		  	 	else
		  	 		itmes[id].count = itmes[id].count + value.count
		  	 	end
		  	end
	  	end

	end

	for _,value in pairs(itmes) do
		local item = self:_getEmptyBox()
		local typeName = remote.items:getItemType(value.type)
		if typeName == ITEM_TYPE.ITEM then
			self:_setBoxInfo(item,value.id,ITEM_TYPE.ITEM,value.count)
		elseif typeName == ITEM_TYPE.MONEY then
			self._moneyTotal = value.count
		elseif typeName == ITEM_TYPE.TEAM_EXP then
			self._expTotal = value.count
		elseif typeName == ITEM_TYPE.HERO then
			self:_setBoxInfo(item,value.id,ITEM_TYPE.HERO,value.count)
		end
	end
	
	--初始化英雄头像
	self.heroBox = {}
	self.hero_exp = data.hero_exp
	for i = 1, 4, 1 do
	 self.heroBox[i] = QUIWidgetBattleWinHeroHead.new()
	 self._ccbOwner["hero_node" .. i]:addChild(self.heroBox[i])
	 self._ccbOwner["hero_node" .. i]:setVisible(false)
	end
   self:_setHeroInfo(self.hero_exp)

	--设置动画时长
	self._animationTime = 0.5

	self._ccbOwner.moneyNode:setString("+0")
	self._ccbOwner.expNode:setString("+0")
	self._ccbOwner.lvNode:setString(self._teamLevel)

    local tip = ui.newBMFontLabel({
        text = "+"..self._expTotal,
        font = global.ui_hp_change_font_treat,
        x = display.cx,
        y = display.cy-30,
        align = display.CENTER})
        :addTo(self)

    local appearDistance = 60 -- 数字向上移动出现的距离
    local elapseDistance = 30 -- 数字向上移动消失的距离
    local appearTime = 0.4 -- 冒数字的时间
    local stayTimeScale = 0.4 -- 数字的停留时间
    local stayTimeDelay = 0.2 -- 数字的停留时间
    local elapseTime = 0.8 -- 数字的消失时间

    -- 出现动画
    local actions = CCArray:create()
    local sequence = CCArray:create()
    actions:addObject(CCFadeIn:create(appearTime))
    actions:addObject(CCScaleTo:create(appearTime, 1))
    actions:addObject(CCMoveBy:create(appearTime, ccp(0, appearDistance)))
    sequence:addObject(CCSpawn:create(actions))

    -- 停留动画
    sequence:addObject(CCScaleTo:create(stayTimeScale, 1.2))
    sequence:addObject(CCDelayTime:create(stayTimeDelay))

    -- 消失动画
    actions = CCArray:create()
    actions:addObject(CCEaseSineIn:create(CCFadeOut:create(elapseTime)))
    actions:addObject(CCEaseSineOut:create(CCMoveBy:create(elapseTime, ccp(0, elapseDistance))))
    sequence:addObject(CCSpawn:create(actions))

    -- 停止动作
    sequence:addObject(CCRemoveSelf:create(true))

    tip:runAction(CCSequence:create(sequence))

    self._lastUpdate = q:time()

    app:getUserData():setDungeonIsPass("pass")
    
--    if app.tutorial:getStage().forcedGuide < QTutorialDirector.FORCED_GUIDE_STOP then
--    	app.tutorial:setStage(app.tutorial:getStage() + 0.5)
--    	remote.flag:set(remote.flag.FLAG_TUTORIAL_STAGE, app.tutorial:getStage())
--    end

	app.battle:resume()
  	self._audioHandler = app.sound:playSound("battle_complete")
    audio.stopBackgroundMusic()
end

function QBattleDialogWin:onEnter()
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_()
    self.prompt = app:promptTips()
    self.prompt:addItemEventListener(self)
end

function QBattleDialogWin:onExit()
   self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
   	if self.prompt ~= nil then
   		self.prompt:removeItemEventListener()
   	end
end
	
function QBattleDialogWin:_setBoxInfo(box,itemID,itemType,num)
	if box ~= nil then
		box:setGoodsInfo(itemID,itemType,num)
		box:setVisible(true)
	end
end

function QBattleDialogWin:_setHeroInfo(exp)
  
  local actorIds = remote.teams:getTeams(QTeam.INSTANCE_TEAM)
  local teamCount = remote.teams:getHerosCount(QTeam.INSTANCE_TEAM)
  for i = 1, teamCount, 1 do
    self._hero = remote.herosUtil:getHeroByID(actorIds[i])
    self.heroBox[i]:setHeroHead(self._hero.actorId, self._hero.level)
    
    local database = QStaticDatabase:sharedDatabase()
    local curLevelExp = database:getExperienceByLevel(self._hero.level)
    
    local heorInfo = clone(self._hero)
    local heroOldInfo = self._heroOldInfo[i]
    local oldHeroInfo = remote.herosUtil:subHerosExp(heorInfo, exp)
    local heroMaxLevel = remote.herosUtil:getHeroMaxLevel()
    local oldCurLevelExp = database:getExperienceByLevel(oldHeroInfo.level)
    
    if heroMaxLevel == self._hero.level and self._hero.exp == (curLevelExp - 1) then
      if heroOldInfo.level == self._hero.level and heroOldInfo.exp == (curLevelExp - 1) then
        self.heroBox[i]:expOldFull()
      else
        self.heroBox[i]:expFull(oldHeroInfo.exp, curLevelExp)
      end
    elseif oldHeroInfo.level == self._hero.level then
      self.heroBox[i]:setExpBar(self._hero.exp, exp, curLevelExp)
    elseif heroOldInfo.level == self._hero.level and heroOldInfo.exp == self._hero.exp then
      self.heroBox[i]:noExpAdd(heroOldInfo.exp, curLevelExp)
    else
      self.heroBox[i]:setUpExpBar(oldHeroInfo, oldCurLevelExp,exp , self._hero, curLevelExp)
    end
    self._ccbOwner["hero_node" .. i]:setVisible(true)
  end
end

--function QBattleDialogWin:_setExpBar()
--  local parent = self._ccbOwner.spExp:getParent()
--  self._ccbOwner.spExp:removeFromParent()
--  self._expSpMask = QRectUiMask.new()
--  self._expSpMask:update(self._oldTeamExp/self._oldTotalExp)
--  self._expSpMask:addChild(self._ccbOwner.spExp)
--  self._expSpMask:setCascadeOpacityEnabled(true)
--  parent:addChild(self._expSpMask,-1) 
--end

function QBattleDialogWin:_getEmptyBox()
	for _,box in pairs(self._itemsBox) do
		if box:isVisible() == false then
			box:resetAll()
			return box
		end
	end
	return nil
end

function QBattleDialogWin:_onFrame(dt)
    if self._lastUpdate == nil then return end
    self:_updateMoney()
    self:_updateExp()
    if q:time() - self._lastUpdate > self._animationTime then
    	self._lastUpdate = nil
    	-- self:_checkTeamUp()
    end
end

function QBattleDialogWin:_updateMoney()
	local money = self._moneyTotal * (q:time() - self._lastUpdate)/self._animationTime
	money = math.ceil(money)
	if money > self._moneyTotal then
		money = self._moneyTotal
	end
	self._ccbOwner.moneyNode:setString("+"..money)
end

function QBattleDialogWin:_updateExp()
	local exp = self._expTotal * (q:time() - self._lastUpdate)/self._animationTime
	local nativeExp = exp
	exp = math.ceil(exp)
	if exp > self._expTotal then
		exp = self._expTotal
	end
	self._ccbOwner.expNode:setString("+"..exp)
	if self._oldTeamExp + exp >= self._oldTotalExp and self._teamLevel < remote.user.level then
		self._oldExpBuff = self._oldTotalExp - self._oldTeamExp
		self._oldTeamExp = 0
		self._teamLevel = self._teamLevel + 1
		self._ccbOwner.lvNode:setString(self._teamLevel)
		local database = QStaticDatabase:sharedDatabase()
		self._oldTotalExp = database:getExperienceByTeamLevel(self._teamLevel)
	end
end

function QBattleDialogWin:_backClickHandler()
  	self:_onClose()
end

function QBattleDialogWin:_onTriggerNext()
  	app.sound:playSound("common_item")
  	self:_onClose()
end

function QBattleDialogWin:_onClose()
  	if self._stores ~= nil then
	  	app.sound:playSound("common_next")
	    local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
	    for _, value in pairs(self._stores) do 
            if value.id == tonumber(QShop.GOBLIN_SHOP) and self._oldTeamLevel >= unlockVlaue["UNLOCK_SHOP_1"].value then
                app.tip:addUnlockTips(QUIDialogMystoryStoreAppear.FIND_GOBLIN_SHOP)
            elseif value.id == tonumber(QShop.BLACK_MARKET_SHOP) and self._oldTeamLevel >= unlockVlaue["UNLOCK_SHOP_2"].value then
                app.tip:addUnlockTips(QUIDialogMystoryStoreAppear.FIND_BLACK_MARKET_SHOP)
            end
      	end
  	end 
	self._ccbOwner:onChoose()
	audio.stopSound(self._audioHandler)
end

return QBattleDialogWin