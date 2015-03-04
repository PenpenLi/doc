
local QUIWidget = import(".QUIWidget")
local QUIWidgetHeroOverview = class("QUIWidgetHeroOverview", QUIWidget)

local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controlers.QStaticDatabase")
local QUIWidgetHeroFrame = import(".QUIWidgetHeroFrame")
local QUIWidgetHeroProfessionalIcon = import(".QUIWidgetHeroProfessionalIcon")

QUIWidgetHeroOverview.EVENT_HERO_SHEET_MOVE = "EVENT_HERO_SHEET_MOVE"
QUIWidgetHeroOverview.EVENT_DISABLE_SCROLL_BAR = "EVENT_DISABLE_SCROLL_BAR"

function QUIWidgetHeroOverview:ctor(options)
	local ccbFile = "ccb/Widget_HeroOverview.ccbi"
	QUIWidgetHeroOverview.super.ctor(self,ccbFile,callBacks,options)
	self._heroFrames = {}
	self._emptyFrames = {}
	self._virtualFrames = {{}, {}}
	self:_clearHeroFrames()

	self._rows = options.rows  --一行摆放几个
	self._lines = options.lines  --一行摆放几个
	self._hgap = options.hgap
	self._vgap = options.vgap
	self._offsetX = options.offsetX
	self._offsetY = options.offsetY
	self._labelHeight = 25
	self._cls = options.cls or "QUIWidgetHeroFrame"
	if self._rows == nil then
		self._rows = 2
	end
	if self._lines == nil then
		self._lines = 2
	end
	if self._hgap == nil then
		self._hgap = 0
	end
	if self._vgap == nil then
		self._vgap = 0
	end
	if self._offsetX == nil then
		self._offsetX = 0
	end
	if self._offsetY == nil then
		self._offsetY = 0
	end
	
	--事先生成显示行列数两倍的Frame
	-- num = self._rows * self._lines * 2
	num = self._rows * self._lines
	local widgetClass = import(app.packageRoot .. ".ui.widgets." .. self._cls)
	for i=1,num,1 do
		local frame = widgetClass.new()
		self:getView():addChild(frame)
		-- local frame = app.widgetCache:getWidgetForName(self._cls,self:getView())
		frame:setVisible(false)
		table.insert(self._heroFrames, frame)
	end
	table.mergeForArray(self._emptyFrames, self._heroFrames)

	--记录一个Frame的宽度和长度
	self._size = self._heroFrames[1]:getContentSize()
	self._showHeight = self._lines * (self._size.height +  self._vgap)
	self._isMove = false
end

function QUIWidgetHeroOverview:onEnter()
    self._handle = scheduler.scheduleGlobal(handler(self, self._onFrame), 0)
end

function QUIWidgetHeroOverview:onExit()
	self:_removeAction()
    scheduler.unscheduleGlobal(self._handle)
    self:_clearHeroFrames()
--    for i, value in pairs(self._heroFrames) do 
--    	app.widgetCache:setWidgetForName(value,value:getName())
--	end
	self._heroFrames = {}
end

-- 清理6个hero frames
function QUIWidgetHeroOverview:_clearHeroFrames()
	for i, value in pairs(self._heroFrames) do 
		value:setVisible(false)
		value:setPosition(ccp(0,0))
	end
	for _, virtualFramesPart in ipairs(self._virtualFrames) do
		for i,frame in pairs(virtualFramesPart) do
			if frame.icon ~= nil then
				self._emptyFrames[#self._emptyFrames+1] = frame.icon
				frame.icon = nil
			end
		end
	end
	
	self._virtualFrames = {{}, {}}
end

--获取容器里面所有HeroFrames
function QUIWidgetHeroOverview:getHeroFrames()
	return self._heroFrames
end

--获取VirtualFrames
function QUIWidgetHeroOverview:getVirtualFrames()
  return self._virtualFrames[1]
end

--获取空的Frame
function QUIWidgetHeroOverview:getEmptyFrames()
	if #self._emptyFrames> 0 then
		return table.remove(self._emptyFrames)
	end
	return nil
end


--传入英雄数据 生成虚拟的Frame
function QUIWidgetHeroOverview:displayHeros(herosID,selectTable)
	self._selectTable = selectTable
	if self._selectTable == nil then 
		self._selectTable = {} 
	end
	self:_clearHeroFrames()
	self._totalHeight = 0
	self._totalExistHeroHeight = 0
	self._totalNotExistHeroHeight = 0
	self:getView():setPositionY(0)
	if herosID ~= nil then
		-- sort heros
		local selectHeros = {}
		local unselectHeros = {}
		local canBeSummonedHeros = {}
		local canNotBeSummonedHeros = {}
		local index = 1
		for _, actorId in pairs(herosID) do
			local heroInfo = remote.herosUtil:getHeroByID(actorId)
			if heroInfo ~= nil then
				if table.indexof(self._selectTable, actorId) == false then
					table.insert(selectHeros, actorId)
				else
					table.insert(unselectHeros, actorId)
				end
			else
				local characher = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
				local grade_info = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(actorId, characher.grade or 0)
				local soulGemId = grade_info.soul_gem
				local currentGemCount = remote.items:getItemsNumByID(soulGemId)
				local needGemCount = grade_info.soul_gem_count or 0

				if (currentGemCount >= needGemCount) then
					table.insert(canBeSummonedHeros, actorId)
				else
					table.insert(canNotBeSummonedHeros, actorId)
				end
			end
		end

		local index = 1
		for _, actorId in ipairs(canBeSummonedHeros) do
			self:_showExistHeroForPostion(index, actorId)
			index = index + 1
		end

		for _, actorId in ipairs(selectHeros) do
			self:_showExistHeroForPostion(index, actorId)
			index = index + 1
		end
		for _, actorId in ipairs(unselectHeros) do
			self:_showExistHeroForPostion(index, actorId)
			index = index + 1
		end

		index = 1
		for _, actorId in ipairs(canNotBeSummonedHeros) do
			self:_showNotExistHeroForPostion(index, actorId)
			index = index + 1
		end

		if self._totalExistHeroHeight == 0 then
			self._ccbOwner.node_unsummon:setPosition(self._size.width + self._hgap + self._offsetX, -self._totalExistHeroHeight - self._labelHeight)
		else
			self._ccbOwner.node_unsummon:setPosition(self._size.width + self._hgap + self._offsetX, -self._totalExistHeroHeight - self._labelHeight + self._size.height/2)
		end
		
		if #canNotBeSummonedHeros == 0 then
			self._ccbOwner.node_unsummon:setVisible(false)
		else
			self._ccbOwner.node_unsummon:setVisible(true)
		end

	end
end

function QUIWidgetHeroOverview:_show(frame,isShow,pos)
	if frame.isShow == isShow then 
		return 
	end
	if isShow == false then
		frame.isShow = isShow
		if frame.icon ~= nil then
			self._emptyFrames[#self._emptyFrames+1] = frame.icon
			frame.icon:setVisible(false)
			frame.icon = nil
		end
	else
		if #self._emptyFrames > 0 then
			frame.isShow = isShow
			frame.icon = table.remove(self._emptyFrames)
			frame.icon:setVisible(true)
			frame.icon:setPosition(ccp(frame.posX , frame.posY))
			frame.icon:setHero(frame.actorId,self._selectTable)
			frame.icon:setFramePos(pos)
		else
			
			local widgetClass = import(app.packageRoot .. ".ui.widgets." .. self._cls)
			local icon = widgetClass.new()
			self:getView():addChild(icon)
			table.insert(self._heroFrames, icon)

			frame.icon = icon
			frame.isShow = isShow
			frame.icon:setVisible(true)
			frame.icon:setPosition(ccp(frame.posX , frame.posY))
			frame.icon:setHero(frame.actorId,self._selectTable)
			frame.icon:setFramePos(pos)
		end
	end
end

--开始移动
function QUIWidgetHeroOverview:starMove()
	self._isMove = true
end

--停止移动
function QUIWidgetHeroOverview:stopMove()
	self._isMove = false
	self:_removeAction()
end

--停止移动
function QUIWidgetHeroOverview:getIsMove()
	return self._isMove
end

--停止移动
function QUIWidgetHeroOverview:runTo(actorId)
  local contentY = self:getView():getPositionY()
	for _, virtualFramesPart in ipairs(self._virtualFrames) do
		for i, value in pairs(virtualFramesPart) do
			if value.actorId == actorId then
				offsetY = value.posY + contentY + self._size.height/2

				return self:endMove(-offsetY)
			end
		end
	end
	return false
end

--移动中调用
function QUIWidgetHeroOverview:onMove()
	local contentY = self:getView():getPositionY()
	for _, virtualFramesPart in ipairs(self._virtualFrames) do
		for i, value in pairs(virtualFramesPart) do
			offsetY = value.posY + contentY
			if offsetY >= self._size.height or offsetY <= -(self._showHeight + self._size.height * 0.5 ) then  
				self:_show(value,false)
			end
		end
	end

	for _, virtualFramesPart in ipairs(self._virtualFrames) do
		for i, value in pairs(virtualFramesPart) do
			offsetY = value.posY + contentY
			if offsetY >= self._size.height or offsetY <= -(self._showHeight + self._size.height * 0.5 ) then  

			else
				self:_show(value,true,i)
			end
		end
	end
	if self._totalHeight > self._showHeight then
		local percent = contentY / (self._totalHeight - self._showHeight - self._size.height/2)
		if percent < 0 then
			percent = 0
		end
		if percent > 1 then
			percent = 1
		end
		self._lastMoveTime = q.time()
		QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetHeroOverview.EVENT_HERO_SHEET_MOVE, percent = percent})
	end
end

--移动到位移差
function QUIWidgetHeroOverview:endMove(offsetY)
	local contentY = self:getView():getPositionY()
	if self._totalHeight <= self._showHeight then
    offsetY = 0 - contentY 
	elseif contentY + offsetY < 0 then
		offsetY = 0 - contentY
	elseif contentY + offsetY > self._totalHeight - self._showHeight - self._size.height/2 then
		offsetY = self._totalHeight - self._showHeight - contentY - self._size.height/2
	end
	self:_contentRunAction(0,offsetY)
	return offsetY
end

-- 移除动作
function QUIWidgetHeroOverview:_removeAction()
	if self._actionHandler ~= nil then
		self:getView():stopAction(self._actionHandler)
		self._actionHandler = nil
	end
end

-- 移动到指定位置
function QUIWidgetHeroOverview:_contentRunAction(posX,posY)
	self._isMove = true
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveBy:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
    											self._isMove = false
    											self:_removeAction()
    											self:onMove()
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = self:getView():runAction(ccsequence)
end

--根据序号自动排列影响头像
function QUIWidgetHeroOverview:_showExistHeroForPostion(pos, actorId)
	local posX = (pos-1)%self._rows
	local posY = math.floor((pos-1)/self._rows)

	posX = posX*(self._size.width + self._hgap)+self._size.width/2 + self._offsetX
	posY = -(posY*(self._size.height +  self._vgap)+self._size.height/2) + self._offsetY

	table.insert(self._virtualFrames[1], {posX=posX, posY=posY, actorId=actorId, isShow = false})
	self._totalExistHeroHeight = math.abs(posY) + self._size.height
	self._totalHeight = self._totalExistHeroHeight
end

function QUIWidgetHeroOverview:_showNotExistHeroForPostion(pos, actorId)
	local posX = (pos-1)%self._rows
	local posY = math.floor((pos-1)/self._rows)

	posX = posX*(self._size.width + self._hgap)+self._size.width/2 + self._offsetX
	posY = -(posY*(self._size.height +  self._vgap)+self._size.height/2) + self._offsetY - self._totalExistHeroHeight + self._size.height/2 - self._labelHeight
	if self._totalExistHeroHeight == 0 then
		posY = posY - self._size.height/2
	end

	table.insert(self._virtualFrames[2], {posX=posX, posY=posY, actorId=actorId, isShow = false})
	self._totalNotExistHeroHeight = math.abs(posY) + self._size.height
	self._totalHeight = self._totalNotExistHeroHeight
end

-- 计时器每帧调用
function QUIWidgetHeroOverview:_onFrame(dt)
	if self._isMove then
		self:onMove()
	end
	if self._lastMoveTime ~= nil then
		if q.time() - self._lastMoveTime > 0.5 then
			QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetHeroOverview.EVENT_DISABLE_SCROLL_BAR})
			self._lastMoveTime = nil
		end
	end
end
return QUIWidgetHeroOverview
