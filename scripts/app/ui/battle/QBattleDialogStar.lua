local QBattleDialog = import(".QBattleDialog")
local QBattleDialogStar = class(".QBattleDialogStar", QBattleDialog)
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QBattleDialogStar:ctor(options,owner)
	local ccbFile = "ccb/Battle_Dialog_Victory_3star.ccbi"
	local callBacks = {}

	if owner == nil then 
		owner = {}
	end
	--设置该节点启用enter事件
	self:setNodeEventEnabled(true)

	local database = QStaticDatabase:sharedDatabase()

	local data = {}
	local dungeonId = options.dungeonId
	local dungeonTargetConfig = database:getDungeonTargetByID(dungeonId)
	QBattleDialogStar.super.ctor(self,ccbFile,owner,callBacks)

	local starNum = 0
	for i=1,3,1 do
		local str = ""
		for _,value in pairs(dungeonTargetConfig) do
			if value.target == i then
				table.insert(data, app.missionTracer:isMissionComplete(i))
				str = value.target_text or ""
				break
			end
		end
		self._ccbOwner["tf_done"..i]:setString(str)
		self._ccbOwner["tf_miss"..i]:setString(str)
		if data ~= nil and data[i] ~= nil and data[i] == true then
			starNum = starNum + 1
			self._ccbOwner["tf_done"..i]:setVisible(true)
			self._ccbOwner["tf_miss"..i]:setVisible(false)
			self._ccbOwner["star_done"..i]:setVisible(true)
			self._ccbOwner["star_miss"..i]:setVisible(false)
		else
			self._ccbOwner["tf_done"..i]:setVisible(false)
			self._ccbOwner["tf_miss"..i]:setVisible(true)
			self._ccbOwner["star_done"..i]:setVisible(false)
			self._ccbOwner["star_miss"..i]:setVisible(true)
		end
	end
	for i=1,3,1 do
		if i <= starNum then
			self._ccbOwner["bstar_done"..i]:setVisible(true)
			self._ccbOwner["bstar_miss"..i]:setVisible(false)
		else
			self._ccbOwner["bstar_done"..i]:setVisible(false)
			self._ccbOwner["bstar_miss"..i]:setVisible(true)
		end
	end

	self._isPlayEnd = false
    self._rootAnimationProxy = QCCBAnimationProxy:create()
    self._rootAnimationProxy:retain()
    self._rootAnimationManager = tolua.cast(self._ccbNode:getUserObject(), "CCBAnimationManager")
    self._rootAnimationProxy:connectAnimationEventSignal(self._rootAnimationManager, handler(self, self.viewAnimationEndHandler))
    self._rootAnimationManager:runAnimationsForSequenceNamed("Default Timeline")
end

function QBattleDialogStar:onExit()
	if self._rootAnimationProxy ~= nil then
        self._rootAnimationProxy:disconnectAnimationEventSignal()
        self._rootAnimationProxy:release()
        self._rootAnimationProxy = nil
	end
end

function QBattleDialogStar:viewAnimationEndHandler()
   self._isPlayEnd = true
end

function QBattleDialogStar:_backClickHandler()
    self:_onTriggerNext()
end

function QBattleDialogStar:_onTriggerNext()
	if self._isPlayEnd == true then
		self._ccbOwner:onChoose()
	end
end

return QBattleDialogStar