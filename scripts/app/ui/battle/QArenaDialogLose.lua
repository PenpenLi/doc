--
-- Author: Your Name
-- Date: 2015-01-20 11:13:04
--
local QBattleDialog = import(".QBattleDialog")
local QArenaDialogLose = class(".QArenaDialogLose", QBattleDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QArenaDialogLose:ctor(data,owner)
	local ccbFile = "ccb/Battle_Dialog_Defeat.ccbi"
	local callBacks = {{ccbCallbackName = "onTriggerNext", callback = handler(self, QArenaDialogLose._onTriggerNext)}}

	if owner == nil then 
		owner = {}
	end

	QArenaDialogLose.super.ctor(self,ccbFile,owner,callBacks)

	if app.battle ~= nil then
		app.battle:resume()
	end
	self._ccbOwner.node_arena:setVisible(true)
  	self._audioHandler = app.sound:playSound("battle_failed")
    audio.stopBackgroundMusic()
end

function QArenaDialogLose:_backClickHandler()
	self:onClose()
end

function QArenaDialogLose:_onTriggerNext()
  	app.sound:playSound("common_item")
	self:onClose()
end

function QArenaDialogLose:onClose()
	self._ccbOwner:onChoose()
	audio.stopSound(self._audioHandler)
end


return QArenaDialogLose