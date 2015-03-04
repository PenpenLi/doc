--
-- Author: Your Name
-- Date: 2015-01-17 11:36:24
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogArenaFigterInfo = class("QUIDialogArenaFigterInfo", QUIDialog)

local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QUIWidgetUserHead = import("..widgets.QUIWidgetUserHead")
local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogArenaFigterInfo:ctor(options)
 	local ccbFile = "ccb/Dialog_ArenaPrompt.ccbi"
    local callBacks = {}
    QUIDialogArenaFigterInfo.super.ctor(self, ccbFile, callBacks, options)
    self.isAnimation = true --是否动画显示

    self.info = options.info
    if self.info == nil then assert(false,"the dialog options info can't is nil") end

    self._ccbOwner.tf_name:setString(self.info.name or "")
    self._ccbOwner.tf_level:setString("LV."..(self.info.level or 0))
    self._ccbOwner.tf_win_count:setString(self.info.victory or 0)
    self._ccbOwner.tf_battleforce:setString(self.info.force or 0)

	self.head = QUIWidgetUserHead.new()
	self.head:setUserAvatar(self.info.avatar)
    self.head:setUserLevelVisible(false)
    self._ccbOwner.node_head:addChild(self.head)

    for index,value in pairs(self.info.heros) do
    	local heroHead = QUIWidgetHeroHead.new()
		heroHead:setHero(value.actorId)
		heroHead:setLevel(value.level)
		heroHead:setBreakthrough(value.breakthrough)
		heroHead:setStar(value.grade)
		self._ccbOwner["node_hero"..index]:addChild(heroHead)
    end
end

function QUIDialogArenaFigterInfo:_backClickHandler()
    self:_onTriggerClose()
end

-- 关闭对话框
function QUIDialogArenaFigterInfo:_onTriggerClose()
    self:playEffectOut()
end

function QUIDialogArenaFigterInfo:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogArenaFigterInfo