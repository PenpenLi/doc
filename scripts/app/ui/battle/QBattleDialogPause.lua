
local QBattleDialog = import(".QBattleDialog")
local QBattleDialogPause = class("QBattleDialogPause", QBattleDialog)

function QBattleDialogPause:ctor(owner, options)
	local ccbFile = "Battle_Dialog_Pause.ccbi"
	if owner == nil then
		owner = {}
	end

	QBattleDialogPause.super.ctor(self, ccbFile, owner)
end

return QBattleDialogPause