--
-- Author: Your Name
-- Date: 2014-07-23 15:25:18
--
local QBattleDialog = import(".QBattleDialog")
local QDialogTeamUp = class("QDialogTeamUp", QBattleDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QTextFiledScrollUtils = import("...utils.QTextFiledScrollUtils")
local QUIViewController = import("..QUIViewController")
local QTips = import("...utils.QTips")
local QUIDialogUnlockSucceed = import("..dialogs.QUIDialogUnlockSucceed")
local QUIDialogMystoryStoreAppear = import("..dialogs.QUIDialogMystoryStoreAppear")

function QDialogTeamUp:ctor(options,owner)
	local ccbFile = "ccb/Dialog_BattelTeamUp.ccbi";
	local callBacks = {
--		{ccbCallbackName = "onTriggerConfirm", 	callback = handler(self, QDialogTeamUp._onTriggerConfirm)},
    {ccbCallbackName = "onTriggerClose",  callback = handler(self, QDialogTeamUp._onTriggerClose)}
	}
	if owner == nil then 
		owner = {}
	end
	QDialogTeamUp.super.ctor(self,ccbFile,owner,callBacks)

	self._effectTime = 2
	self._effectTbl = {}

	self._ccbOwner.tf_level:setString("")
	self._ccbOwner.tf_level_new:setString("")
	self._ccbOwner.tf_energy:setString("")
	self._ccbOwner.tf_energy_new:setString("")
	self._ccbOwner.tf_award:setString("")
	self._ccbOwner.tf_hero_level:setString("")
	self._ccbOwner.tf_hero_level_new:setString("")
	self._ccbOwner.node_hero_level:setVisible(false)

	if options ~= nil then
		self._ccbOwner.tf_level:setString(options.level)
		self:nodeEffect(self._ccbOwner.tf_level_new, options.level, options.level_new)
		self._ccbOwner.tf_energy:setString(options.energy)
		self:nodeEffect(self._ccbOwner.tf_energy_new, options.energy, options.energy_new)
		self._ccbOwner.tf_award:setString("x "..options.award)


		local heroOldLevel = QStaticDatabase:sharedDatabase():getTeamConfigByTeamLevel(options.level).hero_limit or 1
		local heroNewLevel = QStaticDatabase:sharedDatabase():getTeamConfigByTeamLevel(options.level_new).hero_limit or 1
    self.unNewlockLevel = options.level_new
    self.unOldlockLevel = options.level
		if heroNewLevel > heroOldLevel then
			self._ccbOwner.node_hero_level:setVisible(true)
			self._ccbOwner.tf_hero_level:setString(heroOldLevel)
			self:nodeEffect(self._ccbOwner.tf_hero_level_new, heroOldLevel, heroNewLevel)
		end
	end

    app.sound:playSound("battle_level_up")
end

function QDialogTeamUp:nodeEffect(node, startNum, endNum)
	if endNum <= startNum then return end
	if node ~= nil then
		local update = QTextFiledScrollUtils.new()
		update:addUpdate(startNum, endNum, function(value)
				node:setString(math.ceil(value))
			end, self._effectTime)
		node:setScale(1)
	    local actionArrayIn = CCArray:create()
        actionArrayIn:addObject(CCScaleTo:create(0.23, 1.5))
        actionArrayIn:addObject(CCScaleTo:create(0.23, 1))
	    local ccsequence = CCSequence:create(actionArrayIn)
		local handler = node:runAction(ccsequence)
		table.insert(self._effectTbl,{update = update, handler = handler, node = node})
	end
end

function QDialogTeamUp:clearEffect()
	for _,value in pairs(self._effectTbl) do
		if value.update ~= nil then
			value.update:stopUpdate()
		end
		if value.handler ~= nil and value.node ~= nil then
			value.node:stopAction(value.handler)
		end
	end
end

function QDialogTeamUp:_onTriggerClose()
  local unlockVlaue = QStaticDatabase:sharedDatabase():getConfiguration()
  local unlockTutorial = app.tip:getUnlockTutorial()
   if self.unNewlockLevel >= unlockVlaue["UNLOCK_ELITE"].value and self.unOldlockLevel < unlockVlaue["UNLOCK_ELITE"].value then
           app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_ELITECOPY)
  end
	if self.unNewlockLevel >= unlockVlaue["UNLOCK_SHOP"].value and self.unOldlockLevel < unlockVlaue["UNLOCK_SHOP"].value then
          app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_SHOP)
          unlockTutorial.shopTutorial = 1
  end
  if self.unNewlockLevel >= unlockVlaue["SPACE_TIME_TRANSMITTER"].value and self.unOldlockLevel < unlockVlaue["SPACE_TIME_TRANSMITTER"].value then
          app.tip:addUnlockTips(QUIDialogUnlockSucceed.SPACE_TIME_TRANSMITTER)
          unlockTutorial.spaceTutorial = QTips.UNLOCK_TUTORIAL_OPEN
  end
  if self.unNewlockLevel >= unlockVlaue["GOLD_CHALLENGE"].value and self.unOldlockLevel < unlockVlaue["GOLD_CHALLENGE"].value then
          app.tip:addUnlockTips(QUIDialogUnlockSucceed.GOLD_CHALLENGE)
          unlockTutorial.goldTutorial = QTips.UNLOCK_TUTORIAL_OPEN
  end
  if self.unNewlockLevel >= unlockVlaue["UNLOCK_SHOP_1"].value and self.unOldlockLevel < unlockVlaue["UNLOCK_SHOP_1"].value then
          app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_GOBLIN_SHOP) 
          if remote.stores._goblinShop.shelves == nil then
            app:getClient():getStores("2", function(data)end)
          end
          unlockTutorial.goblinTutorial = QTips.UNLOCK_TUTORIAL_OPEN
  end
  if self.unNewlockLevel >= unlockVlaue["UNLOCK_SHOP_2"].value and self.unOldlockLevel < unlockVlaue["UNLOCK_SHOP_2"].value then
          app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_BLACK_MARKET_SHOP)
          if remote.stores._blackMarketShop.shelves == nil then
            app:getClient():getStores("3", function(data)end)
          end
          unlockTutorial.blackTutorial = QTips.UNLOCK_TUTORIAL_OPEN
  end
  if unlockVlaue["UNLOCK_ARENA"] ~= nil and self.unNewlockLevel >= unlockVlaue["UNLOCK_ARENA"].value and self.unOldlockLevel < unlockVlaue["UNLOCK_ARENA"].value then
          app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_ARENA)
          if remote.stores._arenaShop.shelves == nil then
            app:getClient():getStores("4", function(data)end)
          end
          unlockTutorial.arenaTutorial = QTips.UNLOCK_TUTORIAL_OPEN        
  end
  if unlockVlaue["UNLOCK_SUNWELL"] ~= nil and self.unNewlockLevel >= unlockVlaue["UNLOCK_SUNWELL"].value and self.unOldlockLevel < unlockVlaue["UNLOCK_SUNWELL"].value then
          app.tip:addUnlockTips(QUIDialogUnlockSucceed.UNLOCK_SUNWELL)
          if remote.stores._sunwellShop.shelves == nil then
            app:getClient():getStores("5", function(data)end)
          end
          unlockTutorial.sunwellTutorial = QTips.UNLOCK_TUTORIAL_OPEN        
  end
  app.tip:setUnlockTutorial(unlockTutorial)
  self:clearEffect()
  self._ccbOwner:onChoose()
end

function QDialogTeamUp:_backClickHandler()
    self:_onTriggerClose()
end

return QDialogTeamUp