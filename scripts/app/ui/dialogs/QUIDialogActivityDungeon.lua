--
-- Author: Your Name
-- Date: 2014-12-01 15:49:22
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogActivityDungeon = class("QUIDialogActivityDungeon", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetMonsterHead = import("..widgets.QUIWidgetMonsterHead")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")

function QUIDialogActivityDungeon:ctor(options)
	local ccbFile = "ccb/Dialog_TimeMachine_info.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerTeam", 				callback = handler(self, QUIDialogActivityDungeon._onTriggerTeam)},

	}
	QUIDialogActivityDungeon.super.ctor(self,ccbFile,callBacks,options)
	app:getNavigationController():getTopPage():setManyUIVisible()

	self.info = options.info
	self.dungeonInfo = QStaticDatabase:sharedDatabase():getDungeonConfigByID(self.info.dungeon_id)
	if self.dungeonInfo ~= nil then
		self._ccbOwner.tf_name:setString(remote.activityInstance:getInstanceGroupNameByType(self.info.dungeon_type).."·"..self.info.instance_name.."    "..self.dungeonInfo.name)
		self._ccbOwner.tf_info:setString(self.dungeonInfo.description or "")
		self._ccbOwner.tf_energy:setString(self.dungeonInfo.energy)
		self:getItemConfig()
		self:getMonsterConfig()
	end
end

function QUIDialogActivityDungeon:viewDidAppear()
	QUIDialogActivityDungeon.super.viewDidAppear(self)
	self.prompt = app:promptTips()
	self.prompt:addItemEventListener(self)
	self.prompt:addMonsterEventListener()
	self:addBackEvent()
end

function QUIDialogActivityDungeon:viewWillDisappear()
  	QUIDialogActivityDungeon.super.viewWillDisappear(self)
 	self.prompt:removeItemEventListener()
    self.prompt:removeMonsterEventListener()
	self:removeBackEvent()
end

--获取关卡掉落信息
function QUIDialogActivityDungeon:getItemConfig()
	self._items = {}
	local dropItems = self.dungeonInfo.drop_item
	local dropItems = string.split(dropItems, ";")
	for _,id in pairs(dropItems) do
        self:_setBoxInfo(id,ITEM_TYPE.ITEM,0)
	end
end

function QUIDialogActivityDungeon:_setBoxInfo(itemID,itemType,num)
	local itemConfig = QStaticDatabase:sharedDatabase():getItemByID(itemID)
	if itemConfig == nil then return end
	local box = QUIWidgetItemsBox.new()
    box:setGoodsInfo(itemID,itemType,num)
    box:setPosition(100 * #self._items, 0)
    box:setScale(0.82)
    box:setPromptIsOpen(true)
    self._ccbOwner.node_items:addChild(box)
	table.insert(self._items, box)
end

--获取怪物配置生成怪物信息
function QUIDialogActivityDungeon:getMonsterConfig()
	local monsterConfig = QStaticDatabase:sharedDatabase():getMonstersById(self.dungeonInfo.monster_id)
	local monsterData = {}
	if monsterConfig ~= nil and #monsterConfig > 0 then
		for i,value in pairs(monsterConfig) do
			local value = clone(value)
			value.npc_index = i
			table.insert(monsterData, value)
		end
		table.sort(monsterData,function (a, b)
				if a.wave ~= b.wave then
					return a.wave > b.wave
				else
					return a.is_boss or false
				end
			end)
		--过滤重复的怪物
		local tempData = {}
		local tempData2 = {}
		for i,value in pairs(monsterData) do
			local npc_id = app:getBattleRandomNpc(self.dungeonInfo.monster_id, value.npc_index, value.npc_id)
			if tempData[npc_id] == nil then
				tempData[npc_id] = 1
				local clone_value = clone(value)
				clone_value.npc_id = npc_id
				table.insert(tempData2,clone_value)
			end
		end
		monsterData = tempData2
	end

	self._monster = {}
	self._monsterX = 0
	for _,value in pairs(monsterData) do
		self:generateMonster(value)
	end
end

--生成怪物头像
function QUIDialogActivityDungeon:generateMonster(value)
	local index = #self._monster+1
	self._monster[index] = QUIWidgetMonsterHead.new(value, index)
	self._ccbOwner.node_monster:addChild(self._monster[index])
	local perWidth = 0
	if index > 1 then
		perWidth = self._monster[index - 1]:getSize().width
	end
	local size = self._monster[index]:getSize()
	local gap = 2
	local offsetX = (size.width/2 + gap) * (index == 1 and 0 or 1) + perWidth/2
	self._monsterX = self._monsterX + offsetX
	self._monster[index]:setPosition(self._monsterX,0)
end

function QUIDialogActivityDungeon:_onTriggerTeam(tag)
	local teamKey = nil
	if self.info.instance_id == "activity1_1" or self.info.instance_id == "activity2_1" then
		teamKey = remote.teams.TIME_MACHINE_TEAM
	elseif self.info.instance_id == "activity3_1" then
		teamKey = remote.teams.POWER_TEAM
	elseif self.info.instance_id == "activity4_1" then
		teamKey = remote.teams.INTELLECT_TEAM
	end
	local team = remote.teams:getTeams(teamKey)
	if team == nil or #team == 0 then
		remote.teams:setTeams(teamKey, clone(remote.teams:getTeams(remote.teams.INSTANCE_TEAM)))
	end
    app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogTeamArrangement",
     options = {info = self.info, teamKey = teamKey,}})
end

-- 对话框退出
function QUIDialogActivityDungeon:onTriggerBackHandler(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- 对话框退出
function QUIDialogActivityDungeon:onTriggerHomeHandler(tag, menuItem)
	app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

return QUIDialogActivityDungeon