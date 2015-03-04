--
-- Author: Your Name
-- Date: 2014-06-06 14:40:59
--
local QUIDialog = import("..widgets.QUIDialog")
local QUIDialogHeroEquipmentDetail = class("QUIDialogHeroEquipmentDetail", QUIDialog)

local QRemote = import("...models.QRemote")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")
local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QUIWidgetEquipmentBox = import("..widgets.QUIWidgetEquipmentBox")
local QUIWidgetHeroEquipment = import("..widgets.QUIWidgetHeroEquipment")
local QUIWidgetHeroEquipmentInfo = import("..widgets.QUIWidgetHeroEquipmentInfo")
local QUIWidgetHeroEquipmentStrengthen = import("..widgets.QUIWidgetHeroEquipmentStrengthen")
local QUIWidgetHeroEquipmentEvolution = import("..widgets.QUIWidgetHeroEquipmentEvolution")

QUIDialogHeroEquipmentDetail.TAB_INFO = "TAB_INFO"
QUIDialogHeroEquipmentDetail.TAB_STRONG = "TAB_STRONG"
QUIDialogHeroEquipmentDetail.TAB_EVOLUTION = "TAB_EVOLUTION"
QUIDialogHeroEquipmentDetail.TAB_MAGIC = "TAB_MAGIC"

--onTriggerCompositeHandler onTriggerWearHandler
function QUIDialogHeroEquipmentDetail:ctor(options)
	local ccbFile = "ccb/Dialog_HeroEquipment_info.ccbi"
	local callBacks = {
		{ccbCallbackName = "onTriggerTabInfo", 				callback = handler(self, QUIDialogHeroEquipmentDetail._onTriggerTabInfo)},
		{ccbCallbackName = "onTriggerTabStrong", 		callback = handler(self, QUIDialogHeroEquipmentDetail._onTriggerTabStrong)},
		{ccbCallbackName = "onTriggerTabEvolution", 		callback = handler(self, QUIDialogHeroEquipmentDetail._onTriggerTabEvolution)},
		{ccbCallbackName = "onTriggerTabMagic", 		callback = handler(self, QUIDialogHeroEquipmentDetail._onTriggerTabMagic)},
		{ccbCallbackName = "onTriggerLeft", 		callback = handler(self, QUIDialogHeroEquipmentDetail._onTriggerLeft)},
		{ccbCallbackName = "onTriggerRight", 		callback = handler(self, QUIDialogHeroEquipmentDetail._onTriggerRight)},
	}
	QUIDialogHeroEquipmentDetail.super.ctor(self, ccbFile, callBacks, options)
    app:getNavigationController():getTopPage():setManyUIVisible()

	if options ~= nil then
		self._pos = options.pos or 0
		self._heros = options.heros or {}
	end
	self:setInfo(self._heros[self._pos], options.itemId)
end

function QUIDialogHeroEquipmentDetail:viewDidAppear()
    QUIDialogHeroEquipmentDetail.super.viewDidAppear(self)
    self._equipmentUtils:addEventListener(QUIWidgetEquipmentBox.EVENT_EQUIPMENT_BOX_CLICK, handler(self, self.onEvent))
    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(remote.HERO_UPDATE_EVENT, handler(self, self.onEvent))
    self:addBackEvent()
end

function QUIDialogHeroEquipmentDetail:viewWillDisappear()
    QUIDialogHeroEquipmentDetail.super.viewWillDisappear(self)
    self._equipmentUtils:removeAllEventListeners()
    self._remoteProxy:removeAllEventListeners()
    self:removeBackEvent()
end

function QUIDialogHeroEquipmentDetail:setInfo(actorId, itemId)
	self._actorId = actorId
	self._itemId = itemId
	if self._itemId == nil then
		self._itemId = remote.herosUtil:getHeroEquipmentForBreakthrough(self._actorId)[EQUIPMENT_TYPE.HAT]
	end
	self:initHeroArea()
	self:selectTab(QUIDialogHeroEquipmentDetail.TAB_INFO, true)
end

--初始化装备这块和头像
function QUIDialogHeroEquipmentDetail:initHeroArea()
	local heroInfo = remote.herosUtil:getHeroByID(self._actorId)
	local characher = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(heroInfo.actorId)
	self._ccbOwner.tf_name:setString(characher.name)

	local breakthroughLevel,color = remote.herosUtil:getBreakThrough(heroInfo.breakthrough)
	if breakthroughLevel > 0 then
		self._ccbOwner.tf_num:setColor(BREAKTHROUGH_COLOR[color])
	end
	self._ccbOwner.tf_num:setString((breakthroughLevel == 0 and "" or (" +"..breakthroughLevel)))
	self._ccbOwner.tf_num:setPositionX(self._ccbOwner.tf_name:getPositionX() + self._ccbOwner.tf_name:getContentSize().width/2)

	if self._heroHead == nil then
		self._heroHead = QUIWidgetHeroHead.new()
		self._heroHead:setTouchEnabled(false)
		self._ccbOwner.node_hero_head:addChild(self._heroHead)
	end
	self._heroHead:setHero(heroInfo.actorId, heroInfo.level)

	-- 装备部分
	if self._equipmentUtils == nil then
		self._equipBox = {}
	    for i = 1, 6 do
	        self._equipBox[i] = QUIWidgetEquipmentBox.new()
	        self._ccbOwner["node"..i]:addChild(self._equipBox[i])
	    end
	    --头 衣服 脚 武器 护手 饰品
	    self._equipBox[1]:setType(EQUIPMENT_TYPE.HAT)
	    self._equipBox[2]:setType(EQUIPMENT_TYPE.CLOTHES)
	    self._equipBox[3]:setType(EQUIPMENT_TYPE.SHOES)
	    self._equipBox[4]:setType(EQUIPMENT_TYPE.WEAPON)
	    self._equipBox[5]:setType(EQUIPMENT_TYPE.BRACELET)
	    self._equipBox[6]:setType(EQUIPMENT_TYPE.JEWELRY)

	    --装备控制器
	    self._equipmentUtils = QUIWidgetHeroEquipment.new()
	    self:getView():addChild(self._equipmentUtils) --此处添加至节点没有显示需求
	    self._equipmentUtils:setUI(self._equipBox)
	end
	self._equipmentUtils:setHero(heroInfo.actorId) -- 装备显示
end

function QUIDialogHeroEquipmentDetail:selectTab(name, isforce)
	if self._currentTab ~= name or isforce == true then
		self._currentTab = name
		self:removeAllTabState()
		if self._infoWidget ~= nil then
			self._infoWidget:setVisible(false)
			self._infoWidget = nil
		end
		if self._currentTab == QUIDialogHeroEquipmentDetail.TAB_INFO then
			self:selectedTabInfo()
		elseif self._currentTab == QUIDialogHeroEquipmentDetail.TAB_STRONG then
			self:selectedTabStrong()
		elseif self._currentTab == QUIDialogHeroEquipmentDetail.TAB_EVOLUTION then
			self:selectedTabEvolution()
		elseif self._currentTab == QUIDialogHeroEquipmentDetail.TAB_MAGIC then
			self:selectedTabMagic()
		end
		if self._infoWidget ~= nil then
			self._infoWidget:setVisible(true)
		end
	end
end

function QUIDialogHeroEquipmentDetail:refreshItem(itemId)
	self._itemId = itemId
	if self._info ~= nil then
		self._info:setInfo(self._actorId, self._itemId)
	end
	if self._equipmentStrengthen ~= nil then
    	self._equipmentStrengthen:setHeroInfo(self.actorId, self.itemId)
	end
	if self._evolution ~= nil then
		self._evolution:setInfo(self._actorId, self._itemId)
	end
end

function QUIDialogHeroEquipmentDetail:onEvent(event)
    if event.name == QUIWidgetEquipmentBox.EVENT_EQUIPMENT_BOX_CLICK then
        app.sound:playSound("common_item")
        self:refreshItem(event.info.id)
    elseif event.name == remote.HERO_UPDATE_EVENT then
		self._equipmentUtils:setHero(self._actorId) -- 装备显示
    end
end

function QUIDialogHeroEquipmentDetail:removeAllTabState()
	self._ccbOwner.tab_info:setEnabled(true)
	self._ccbOwner.tab_info:setHighlighted(false)
	self._ccbOwner.tab_strong:setEnabled(true)
	self._ccbOwner.tab_strong:setHighlighted(false)
	self._ccbOwner.tab_evolution:setEnabled(true)
	self._ccbOwner.tab_evolution:setHighlighted(false)
	self._ccbOwner.tab_magic:setEnabled(true)
	self._ccbOwner.tab_magic:setHighlighted(false)
end

--选中信息
function QUIDialogHeroEquipmentDetail:selectedTabInfo()
	self._ccbOwner.tab_info:setEnabled(false)
	self._ccbOwner.tab_info:setHighlighted(true)
	if self._info == nil then
		self._info = QUIWidgetHeroEquipmentInfo.new()
		self._ccbOwner.node_right:addChild(self._info)
	end
	self._info:setInfo(self._actorId, self._itemId)
	self._infoWidget = self._info
end

function QUIDialogHeroEquipmentDetail:selectedTabStrong()
	self._ccbOwner.tab_strong:setEnabled(false)
	self._ccbOwner.tab_strong:setHighlighted(true)
    if self._equipmentStrengthen == nil then
	    self._equipmentStrengthen = QUIWidgetHeroEquipmentStrengthen.new()
	    self._ccbOwner.node_right:addChild(self._equipmentStrengthen)
	end
    self._equipmentStrengthen:setHeroInfo(self.actorId, self.itemId)
	self._infoWidget = self._equipmentStrengthen
end

function QUIDialogHeroEquipmentDetail:selectedTabEvolution()
	self._ccbOwner.tab_evolution:setEnabled(false)
	self._ccbOwner.tab_evolution:setHighlighted(true)
	if self._evolution == nil then
		self._evolution = QUIWidgetHeroEquipmentEvolution.new()
		self._ccbOwner.node_right:addChild(self._evolution)
	end
	self._evolution:setInfo(self._actorId, self._itemId)
	self._infoWidget = self._evolution
end

function QUIDialogHeroEquipmentDetail:selectedTabMagic()
	self._ccbOwner.tab_magic:setEnabled(false)
	self._ccbOwner.tab_magic:setHighlighted(true)
end

function QUIDialogHeroEquipmentDetail:_onTriggerTabInfo()
	self:selectTab(QUIDialogHeroEquipmentDetail.TAB_INFO)
end

function QUIDialogHeroEquipmentDetail:_onTriggerTabStrong()
	self:selectTab(QUIDialogHeroEquipmentDetail.TAB_STRONG)
end

function QUIDialogHeroEquipmentDetail:_onTriggerTabEvolution()
	self:selectTab(QUIDialogHeroEquipmentDetail.TAB_EVOLUTION)
end

function QUIDialogHeroEquipmentDetail:_onTriggerTabMagic()
	self:selectTab(QUIDialogHeroEquipmentDetail.TAB_MAGIC)
end

function QUIDialogHeroEquipmentDetail:_onTriggerRight()
    app.sound:playSound("common_change")
    local n = table.nums(self._heros)
    if nil ~= self._pos and n > 1 then
        self._pos = self._pos + 1
        if self._pos > n then
            self._pos = 1
        end
        local options = self:getOptions()
        options.pos = self._pos
        options.parentOptions.pos = options.pos
		self:setInfo(self._heros[self._pos])
    end
end

function QUIDialogHeroEquipmentDetail:_onTriggerLeft()
    app.sound:playSound("common_change")
    local n = table.nums(self._heros)
    if nil ~= self._pos and n > 1 then
        self._pos = self._pos - 1
        if self._pos < 1 then
            self._pos = n
        end
        local options = self:getOptions()
        options.pos = self._pos
        options.parentOptions.pos = options.pos
		self:setInfo(self._heros[self._pos])
    end
end

function QUIDialogHeroEquipmentDetail:onTriggerBackHandler(tag)
    self:_onTriggerBack()
end

function QUIDialogHeroEquipmentDetail:onTriggerHomeHandler(tag)
    self:_onTriggerHome()
end

-- 对话框退出
function QUIDialogHeroEquipmentDetail:_onTriggerBack(tag, menuItem)
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

-- 对话框退出
function QUIDialogHeroEquipmentDetail:_onTriggerHome(tag, menuItem)
    app:getNavigationController():popViewController(QNavigationController.POP_TO_CURRENT_PAGE)
end

return QUIDialogHeroEquipmentDetail