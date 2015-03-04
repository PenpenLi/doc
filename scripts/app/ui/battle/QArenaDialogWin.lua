--
-- Author: Your Name
-- Date: 2015-01-19 20:39:10
--
local QBattleDialog = import(".QBattleDialog")
local QArenaDialogWin = class("QArenaDialogWin", QBattleDialog)

local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QDialogArenaRankTop = import(".QDialogArenaRankTop")

function QArenaDialogWin:ctor(options,owner)
	local ccbFile = "ccb/Battle_Dialog_Victory.ccbi"
	local callBacks = {{ccbCallbackName = "onTriggerNext", callback = handler(self, QArenaDialogWin._onTriggerNext)}}
	if owner == nil then 
		owner = {}
	end
	QArenaDialogWin.super.ctor(self,ccbFile,owner,callBacks)
	self._ccbOwner.node_instance:setVisible(false)
	self._ccbOwner.node_arena:setVisible(true)
	self._ccbOwner.node_sunwell:setVisible(false)
	self._ccbOwner.sunwell_tips:setVisible(false)

	self._ccbOwner.node_title_normal:setVisible(true)
	self._ccbOwner.node_title_activity:setVisible(false)

	self.info = options.info

	self._ccbOwner.lvNode:setString(self.info.level)
	self._ccbOwner.tf_arena:setString("+"..self.info.arenaMoney)

	--初始化英雄头像
	self.heroBox = {}
	for index,value in pairs(self.info.heros) do
		local heroHead = QUIWidgetHeroHead.new()
		self._ccbOwner["hero_node" .. index]:addChild(heroHead)
		heroHead:setHero(value.actorId)
		heroHead:setLevel(value.level)
		heroHead:setBreakthrough(value.breakthrough)
		heroHead:setStar(value.grade)
		table.insert(self.heroBox, heroHead)
	end
	
	if options.rankInfo ~= nil then
	   self.rankInfo = options.rankInfo
	end
	
	if self.rankInfo.arenaResponse.self.lastRank > self.rankInfo.arenaResponse.self.topRank and self.rankInfo.mails ~= nil then
	   self.rankTop = QDialogArenaRankTop.new({rankInfo = self.rankInfo}, {onCloseRankTop = handler(self, QArenaDialogWin._onCloseRankTop)})
--	   printInfo(self.rankInfo.mails[1].attachment)
	end
  	self._audioHandler = app.sound:playSound("battle_complete")
    audio.stopBackgroundMusic()
end

function QArenaDialogWin:_onTriggerNext()
  	app.sound:playSound("common_item")
	self:onClose()
end

function QArenaDialogWin:_backClickHandler()
	self:onClose()
end

function QArenaDialogWin:onClose()
	self._ccbOwner:onChoose()
	audio.stopSound(self._audioHandler)
end

function QArenaDialogWin:_onCloseRankTop()
  if self.rankTop ~= nil then
     self.rankTop:close()
     self.rankTop = nil
  end
end

return QArenaDialogWin