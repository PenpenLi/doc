--
-- Author: Your Name
-- Date: 2014-05-26 19:18:02
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetTeamField = class("QUIWidgetTeamField", QUIWidget)

local QUIWidgetHeroHead = import(".QUIWidgetHeroHead")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIWidgetTeamField.EVENT_REMOVE_HROE = "EVENT_REMOVE_HROE"

function QUIWidgetTeamField:ctor(options)
	local ccbFile = "ccb/Widget_TeamField.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerHeroButton1", 				callback = handler(self, QUIWidgetTeamField._onTriggerHeroButton1)},
		{ccbCallbackName = "onTriggerHeroButton2", 				callback = handler(self, QUIWidgetTeamField._onTriggerHeroButton2)},
		{ccbCallbackName = "onTriggerHeroButton3", 				callback = handler(self, QUIWidgetTeamField._onTriggerHeroButton3)},
		{ccbCallbackName = "onTriggerHeroButton4", 				callback = handler(self, QUIWidgetTeamField._onTriggerHeroButton4)}
	}
	QUIWidgetTeamField.super.ctor(self,ccbFile,callBacks,options)

	self._heads = {}
	self._isRunging = false
end

--设置战队信息
function QUIWidgetTeamField:setTeamInfo(teams)
 	self._teamHeros = teams
 	self:_freshTeamField()
end

function QUIWidgetTeamField:addEventProxy(eventProxy)
	self._eventProxy = eventProxy
end

function QUIWidgetTeamField:getRuning()
	return self._isRunging
end

function QUIWidgetTeamField:changeHero(hero,touchCcp)
	for i = 1,4,1 do
		if self._ccbOwner["btn"..tostring(i)] then
			local contentsize = self._ccbOwner["btn"..tostring(i)]:getContentSize()
			local endCcp = self._ccbOwner["btn"..tostring(i)]:convertToNodeSpace(ccp(touchCcp.x,touchCcp.y))
			if contentsize.width >= endCcp.x and contentsize.height >= endCcp.y then
				self:_removeHeroForTeam(i)
				self:getView():getParent():getPositionX()
				return true
			end
		end
	end
	return false
end

--刷新战队显示
function QUIWidgetTeamField:_freshTeamField()
	local index = 1
	self:_clearTeamField()
	local force = 0
	for _,teamHero in pairs(self._teamHeros) do
		self._heads[index] = QUIWidgetHeroHead.new()
		self._heads[index]:setHero(teamHero.actorId, teamHero.level)
		self._heads[index]:showBattleForce()
		self._ccbOwner["hero"..tostring(index)]:addChild(self._heads[index]:getView())
		index=index+1
		local heroModel = app:createHero(teamHero)
		if heroModel ~= nil then
			force = force + heroModel:getBattleForce()
		end
	end
	self._ccbOwner.tf_battleForce:setString(force)
end

--显示战队用动画
function QUIWidgetTeamField:freshTeamFieldForAnimation(teams, pos)
 	self._teamHeros = teams
	local index = 1
	local force = 0
	for _,teamHero in pairs(self._teamHeros) do
		local contain = self._ccbOwner["hero"..tostring(index)]
		local head = nil 
		for _,value in pairs(self._heads) do
			if value:getHeroId() == teamHero.actorId then
				head = value
				local headParent = head:getParent()
				local headPos
				if headParent ~= nil then
					headPos = head:convertToWorldSpaceAR(ccp(0,0))
					headPos = contain:convertToNodeSpaceAR(headPos)
				else
					headPos = contain:convertToNodeSpaceAR(pos)
				end
				head:setPosition(headPos.x, headPos.y)
				head:retain()
				head:removeFromParent()
				contain:addChild(head)
				head:release()
				break
			end
		end

		if head == nil then
			head = QUIWidgetHeroHead.new()
			head:setHero(teamHero.actorId, teamHero.level)
			head:showBattleForce()
			local headPos = contain:convertToNodeSpaceAR(pos)
			head:setPosition(headPos.x, headPos.y)
			contain:addChild(head)
			table.insert(self._heads, index, head)
		end

		index=index+1
		local heroModel = app:createHero(teamHero)
		if heroModel ~= nil then
			force = force + heroModel:getBattleForce()
		end
	end

	for _,head in pairs(self._heads) do
		local isHave = false
		for _,teamHero in pairs(self._teamHeros) do
			if head:getHeroId() == teamHero.actorId then
				isHave = true
				break
			end
		end
		if isHave == true then
			head:runAction(CCMoveTo:create(0.3, ccp(0,0)))
		else
			local parent = head:getParent()
			local pos = head:convertToNodeSpaceAR(ccp(display.cx,display.cy))
			local actionArrayIn = CCArray:create()
			actionArrayIn:addObject(CCMoveTo:create(0.2, pos))
			actionArrayIn:addObject(CCCallFunc:create(function ()
				head:removeFromParent()
				for index,headLocal in pairs(self._heads) do
					if headLocal == head then
						table.remove(self._heads, index)
						break
					end
				end
			end))
			local ccsequence = CCSequence:create(actionArrayIn)
			head:runAction(ccsequence)
		end
	end
	self._isRunging = true
	scheduler.performWithDelayGlobal(function()
			self._isRunging = false
		end,0.3)
	self._ccbOwner.tf_battleForce:setString(force)
end

function QUIWidgetTeamField:_clearTeamField()
	local maxCount = remote.teams:getHerosMaxCount()
	for i = 1,4,1 do
		if self._ccbOwner["hero"..tostring(i)] then
			self._ccbOwner["hero"..tostring(i)]:removeAllChildren()
		end
		if i <= maxCount then
			self._ccbOwner["lock"..tostring(i)]:setVisible(false)
		else
			self._ccbOwner["lock"..tostring(i)]:setVisible(true)
		end
	end
	self._heads = {}
end

function QUIWidgetTeamField:_removeHeroForTeam(index)
	if index <= #self._heads then
		local actorId = self._heads[index]:getHeroActorID()
		self._eventProxy:dispatchEvent({name=QUIWidgetTeamField.EVENT_REMOVE_HROE,actorId=actorId})
	end
end

function QUIWidgetTeamField:onExit()
	self._eventProxy = nil
end

------event area--------

function QUIWidgetTeamField:_onTriggerHeroButton1(tag, menuItem)
	self:_removeHeroForTeam(1)
end

function QUIWidgetTeamField:_onTriggerHeroButton2(tag, menuItem)
	if remote.teams:getHerosMaxCount() > 1 then
		self:_removeHeroForTeam(2)
	else
		local dungeonInfo = remote.instance:getDungeonById(QStaticDatabase:sharedDatabase():getDungeonHeroByIndex(1).dungeon_id)
		app.tip:floatTip("攻打关卡"..dungeonInfo.number.."解锁")
	end
end

function QUIWidgetTeamField:_onTriggerHeroButton3(tag, menuItem)
	if remote.teams:getHerosMaxCount() > 2 then
		self:_removeHeroForTeam(3)
	else
		local dungeonInfo = remote.instance:getDungeonById(QStaticDatabase:sharedDatabase():getDungeonHeroByIndex(2).dungeon_id)
		app.tip:floatTip("攻打关卡"..dungeonInfo.number.."解锁")
	end
end

function QUIWidgetTeamField:_onTriggerHeroButton4(tag, menuItem)
	if remote.teams:getHerosMaxCount() > 3 then
		self:_removeHeroForTeam(4)
	else
		local dungeonInfo = remote.instance:getDungeonById(QStaticDatabase:sharedDatabase():getDungeonHeroByIndex(3).dungeon_id)
		app.tip:floatTip("攻打关卡"..dungeonInfo.number.."解锁")
	end
end

return QUIWidgetTeamField