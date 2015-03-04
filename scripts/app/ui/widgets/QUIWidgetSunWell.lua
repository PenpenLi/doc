--
-- Author: wkwang
-- Date: 2015-01-29 15:00:10
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetSunWell = class("QUIWidgetSunWell", QUIWidget)
local QUIWidgetInstanceHead = import("..widgets.QUIWidgetInstanceHead")
local QUIWidgetInstanceNormalBoss = import("..widgets.QUIWidgetInstanceNormalBoss")
local QUIWidgetSunWellChest = import("..widgets.QUIWidgetSunWellChest")

QUIWidgetSunWell.EVENT_CLICK = "EVENT_CLICK"
QUIWidgetSunWell.EVENT_UI_RESET = "EVENT_UI_RESET"

function QUIWidgetSunWell:ctor(options)
	local ccbFile = "ccb/Widget_SunWell_client.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerBuilder", callback = handler(self, QUIWidgetSunWell._onTriggerBuilder)},
    }
	QUIWidgetSunWell.super.ctor(self, ccbFile, callBacks, options)
	cc.GameObject.extend(self)
	self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self._pageHeight = self._ccbOwner.map1:getContentSize().height * self._ccbOwner.map1:getScaleY()
	self._nodeWidth = 0
	self._maxWidth = 0
	for i=1,3,1 do
		local map = self._ccbOwner["map"..i]
		self._maxWidth = self._maxWidth + map:getContentSize().width * map:getScaleX()
	end
	self._headTbl = {}
	self._map = remote.sunWell:getMap()
	self._maxCount = table.nums(self._map)
	self:initChest()

    self.sunwellProxy = cc.EventProxy.new(remote.sunWell)
    self.sunwellProxy:addEventListener(remote.sunWell.EVENT_INSTANCE_UPDATE, handler(self, self.updateSunWellHandler))

    self._ccbOwner.node_arrow:setVisible(false)
end

function QUIWidgetSunWell:initChest()
	self._chests = {}
	for i=1,self._maxCount,1 do
		local chestContain = self._ccbOwner["chest"..i]
		if chestContain ~= nil then
			local chest = QUIWidgetSunWellChest.new()
			chest:setIndex(i)
			self._chests[i] = chest
			chestContain:addChild(chest)
		end
	end
end

function QUIWidgetSunWell:refreshHead(isAnimation)
    self._ccbOwner.node_arrow:setVisible(false)
	self._nodeWidth = 0
	self._needPass = remote.sunWell:getNeedPass()
	self._luckyDraw = remote.sunWell:getSunwellLuckyDraw()

	local isChest = false
	for i=1,self._maxCount,1 do
		local head = self._ccbOwner["node"..i]
		if self._luckyDraw[i] == true then
			self._chests[i]:setIsDraw(true)
		else
			self._chests[i]:setIsDraw(false)
			if i < self._needPass then
				isChest = true
				local chest = self._ccbOwner["chest"..i]
				self._ccbOwner.node_arrow:setVisible(true)
				-- if chest:getPositionY() + 30 > self._pageHeight then
				-- 	self._ccbOwner.node_arrow:setRotation(180)
				-- 	self._ccbOwner.node_arrow:setPosition(chest:getPositionX(), chest:getPositionY() - 30)
				-- else
				self._ccbOwner.node_arrow:setPosition(chest:getPositionX(), chest:getPositionY() + 60)
				-- end
			end
		end
		if head ~= nil then
			if i == self._needPass and isChest == false then
				makeNodeFromGrayToNormal(head)
				head:setEnabled(true)
				self._ccbOwner.node_arrow:setVisible(true)
				-- if head:getPositionY() + head:getContentSize().height/2 > self._pageHeight then
				-- 	self._ccbOwner.node_arrow:setRotation(180)
				-- 	self._ccbOwner.node_arrow:setPosition(head:getPositionX(), head:getPositionY() - head:getContentSize().height/2)
				-- else
				self._ccbOwner.node_arrow:setPosition(head:getPositionX(), head:getPositionY() + head:getContentSize().height/2)
				-- end
			else
				if i >= self._needPass then
					makeNodeFromNormalToGray(head)
				else
					makeNodeFromGrayToNormal(head)
				end
				head:setEnabled(false)
			end
		end
	end
	if self._needPass >= self._maxCount then
		self._nodeWidth = self._maxWidth
	else
		local showNode = (math.floor(self._needPass/3) + 1) * 3
		local chest = self._ccbOwner["chest"..showNode]
		self._nodeWidth = chest:getPositionX()
		if self._nodeWidth > self._maxWidth then
			self._nodeWidth = self._maxWidth
		end
	end
	for i=1,4,1 do
		local cloud = self._ccbOwner["cloud"..i]
		if self._needPass < (i * 3) then
			cloud:setVisible(true)
		else
			if cloud:isVisible() == true then
				cloud:setVisible(false)
			end
		end
	end
	self:dispatchEvent({name = QUIWidgetSunWell.EVENT_UI_RESET, isAnimation = isAnimation})
end

function QUIWidgetSunWell:onEnter()
	self:refreshHead(false)
end

function QUIWidgetSunWell:onExit()
	for index,head in pairs(self._headTbl) do
		if index == self._needPass then
			head:removeAllEventListeners()
		end
	end
    self.sunwellProxy:removeAllEventListeners()
end

function QUIWidgetSunWell:updateSunWellHandler()
	self:refreshHead(true)
end

function QUIWidgetSunWell:getContentWidth()
	return self._nodeWidth
end

function QUIWidgetSunWell:getNeedPassNode()
	local nodeIndex = 0
	self._needPass = remote.sunWell:getNeedPass()
	if self._needPass >= self._maxCount then
		nodeIndex = self._maxCount
	else
		nodeIndex = self._needPass
	end
	return self._ccbOwner["node"..nodeIndex]:getPositionX()
end

function QUIWidgetSunWell:_onTriggerBuilder(event,target)
	local index = 0
	for i=1,self._maxCount,1 do
		if target == self._ccbOwner["node"..i] then
			index = i
		end
	end
	if index > 0 then
		self:dispatchEvent({name = QUIWidgetSunWell.EVENT_CLICK, index = index})
	end
end

return QUIWidgetSunWell