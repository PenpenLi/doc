--
-- Author: Your Name
-- Date: 2015-01-19 20:39:10
--
local QBattleDialog = import(".QBattleDialog")
local QSunWellDialogWin = class("QSunWellDialogWin", QBattleDialog)

local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QDialogArenaRankTop = import(".QDialogArenaRankTop")

function QSunWellDialogWin:ctor(options,owner)
	local ccbFile = "ccb/Battle_Dialog_Victory.ccbi"
	local callBacks = {{ccbCallbackName = "onTriggerNext", callback = handler(self, QSunWellDialogWin._onTriggerNext)}}
	if owner == nil then 
		owner = {}
	end
	QSunWellDialogWin.super.ctor(self,ccbFile,owner,callBacks)
	self._ccbOwner.node_instance:setVisible(false)
	self._ccbOwner.node_arena:setVisible(false)
	self._ccbOwner.node_sunwell:setVisible(true)
	self._ccbOwner.sunwell_tips:setVisible(options.isTimeOver or false)

	self._ccbOwner.node_title_normal:setVisible(true)
	self._ccbOwner.node_title_activity:setVisible(false)

	self.myTeam = options.myTeam

	self._ccbOwner.lvNode:setString(remote.user.level)
	self._ccbOwner.tf_sunwell:setString("+" .. options.sunwellMoney)

	--初始化英雄头像
	self.heroBox = {}
	for index,actorId in pairs(self.myTeam) do
		local heroHead = QUIWidgetHeroHead.new()
		self._ccbOwner["hero_node" .. index]:addChild(heroHead)
		local value = remote.herosUtil:getHeroByID(actorId)
		heroHead:setHero(value.actorId)
		heroHead:setLevel(value.level)
		heroHead:setBreakthrough(value.breakthrough)
		heroHead:setStar(value.grade)
		table.insert(self.heroBox, heroHead)
	end

  	self._audioHandler = app.sound:playSound("battle_complete")
    audio.stopBackgroundMusic()
end

function QSunWellDialogWin:_onTriggerNext()
  	app.sound:playSound("common_item")
	self:onClose()
end

function QSunWellDialogWin:_backClickHandler()
	self:onClose()
end

function QSunWellDialogWin:onClose()
	self._ccbOwner:onChoose()
	audio.stopSound(self._audioHandler)
end

function QSunWellDialogWin:_onCloseRankTop()
  if self.rankTop ~= nil then
     self.rankTop:close()
     self.rankTop = nil
  end
end

return QSunWellDialogWin