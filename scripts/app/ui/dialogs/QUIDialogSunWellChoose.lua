--
-- Author: Your Name
-- Date: 2015-01-29 17:03:40
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogSunWellChoose = class("QUIDialogSunWellChoose", QUIDialog)
local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetSunWellChoose = import("..widgets.QUIWidgetSunWellChoose")
local QUIViewController = import("..QUIViewController")

function QUIDialogSunWellChoose:ctor(options)
	local ccbFile = "ccb/Dialog_SunWell_Choose.ccbi"
	local callBacks = {}
	QUIDialogSunWellChoose.super.ctor(self,ccbFile,callBacks,options)
	app:getNavigationController():getTopPage():setManyUIVisible()
end

function QUIDialogSunWellChoose:viewDidAppear()
    QUIDialogSunWellChoose.super.viewDidAppear(self)
  	self:addBackEvent()
    self:initContent()
end

function QUIDialogSunWellChoose:viewWillDisappear()
    QUIDialogSunWellChoose.super.viewWillDisappear(self)
	self:removeBackEvent()

	for _,widget in pairs(self._chooseTable) do
		widget:removeAllEventListeners()
	end
end

function QUIDialogSunWellChoose:initContent()
	self._index = self:getOptions().index
	self._ccbOwner.tf_title:setString("决战太阳之井·第"..self._index.."关防守敌人")
	self._sunWell = remote.sunWell:getInstanceInfoByIndex(self._index)
	if self._sunWell ~= nil then
		self._chooseTable = {}
		for i=1,3,1 do
			local chooseWidget = QUIWidgetSunWellChoose.new()
			chooseWidget:addEventListener(QUIWidgetSunWellChoose.EVENT_CLICK, handler(self, self.chooseHandler))
			chooseWidget:setInfo(self._sunWell["fighter"..i], self._index, i)
			self._chooseTable[i] = chooseWidget
			self._ccbOwner["node"..i]:addChild(chooseWidget)
		end
	end
end

function QUIDialogSunWellChoose:chooseHandler(event)
	local info = event.target:getInfo()
	local heros = clone(remote.teams:getTeams(remote.teams.SUNWELL_ATTACK_TEAM))
	for _,actorId in pairs(heros) do
		local heroInfo = remote.sunWell:getSunwellHeroInfo(actorId)
		if heroInfo ~= nil and heroInfo.hp <= 0 then
			remote.teams:delHero(actorId, remote.teams.SUNWELL_ATTACK_TEAM)
		end
	end
	remote.teams:saveTeam(remote.teams.SUNWELL_ATTACK_TEAM)
	app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogTeamArrangement",
		options = {info = info, battleButtonVisible = true, teamKey = remote.teams.SUNWELL_ATTACK_TEAM, teamCls = "QUIWidgetHeroSmallFrameHasState"}})
end

function QUIDialogSunWellChoose:onTriggerBackHandler(tag)
	self:_onTriggerBack()
end

function QUIDialogSunWellChoose:onTriggerHomeHandler(tag)
	self:_onTriggerHome()
end

function QUIDialogSunWellChoose:_onTriggerBack()
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogSunWellChoose:_onTriggerHome()
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

return QUIDialogSunWellChoose