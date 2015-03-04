--
-- Author: wkwang
-- Date: 2014-07-15 18:47:01
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetHeroFrame = class("QUIWidgetHeroFrame", QUIWidget)

local QUIWidgetHeroHead = import(".QUIWidgetHeroHead")
local QHeroModel = import("...models.QHeroModel")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroProfessionalIcon = import(".QUIWidgetHeroProfessionalIcon")
local QUIWidgetHeroEquipmentSmallBox = import(".QUIWidgetHeroEquipmentSmallBox")
local QUIWidgetHeroEquipment = import(".QUIWidgetHeroEquipment")
local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUIWidgetHeroFrame.EVENT_HERO_FRAMES_CLICK = "EVENT_HERO_FRAMES_CLICK"
QUIWidgetHeroFrame.EVENT_HERO_FRAMES_DOWN = "EVENT_HERO_FRAMES_DOWN"
QUIWidgetHeroFrame.EVENT_HERO_FRAMES_MOVE = "EVENT_HERO_FRAMES_MOVE"
QUIWidgetHeroFrame.EVENT_HERO_FRAMES_END = "EVENT_HERO_FRAMES_END"

function QUIWidgetHeroFrame:ctor(options)
	local ccbFile = "ccb/Widget_HeroOverview_sheet.ccbi"
	local callBacks = {{ccbCallbackName = "onTriggerHeroOverview", callback = handler(self, QUIWidgetHeroFrame._onTriggerHeroOverview)}}
	QUIWidgetHeroFrame.super.ctor(self,ccbFile,callBacks,options)
	
	self._forceBarScaleX = self._ccbOwner.sprite_bar:getScaleX()
	self._ccbOwner.node_hero_name = setShadow(self._ccbOwner.node_hero_name)

	self._equipBox = {}
    for i = 1, 6 do
        self._equipBox[i] = QUIWidgetHeroEquipmentSmallBox.new()
        self._ccbOwner["node_equip"..i]:addChild(self._equipBox[i]:getView())
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

	self._heroHead = QUIWidgetHeroHead.new({})
	self._heroHead:setTouchEnabled(false)
	self._ccbOwner.node_hero_head:addChild(self._heroHead:getView())

	self._talentIcon = QUIWidgetHeroProfessionalIcon.new({})
	self._ccbOwner.node_hero_professional:addChild(self._talentIcon:getView())

	self._isGrayDisplay = false
end

function QUIWidgetHeroFrame:getName()
	return "QUIWidgetHeroFrame"
end

function QUIWidgetHeroFrame:getHero()
	return self._actorId
end

function QUIWidgetHeroFrame:setHero(actorId,selectTable)
	self._actorId = actorId
	self._selectTable = selectTable
	self._hero = remote.herosUtil:getHeroByID(self._actorId)

	local database = QStaticDatabase:sharedDatabase()
	local heroInfo = database:getCharacterDisplayByActorID(self._actorId)
	-- local heroModel = app:createHero(self._hero)

	-- 设置英雄名称
	self._ccbOwner.node_hero_name:setString(heroInfo.name)

	-- 设置头像显示
	self._heroHead:setHero(actorId, level)

	local level = 0
	if self._hero ~= nil then
		level = self._hero.level
		--设置进阶
		self._ccbOwner.tf_grade:setVisible(true)
		local breakthroughLevel,color = remote.herosUtil:getBreakThrough(self._hero.breakthrough)
		if breakthroughLevel > 0 then
			self._ccbOwner.tf_grade:setColor(BREAKTHROUGH_COLOR[color])
		end
		self._ccbOwner.tf_grade:setString((breakthroughLevel == 0 and "" or ("+"..breakthroughLevel)))
		self._ccbOwner.tf_grade:setPositionX(self._ccbOwner.node_hero_name:getPositionX() + self._ccbOwner.node_hero_name:getContentSize().width)
		-- 设置经验值
		-- self._ccbOwner.node_hero_exp:setString(tostring(self._hero.exp))
		-- 是否显示小红点
	    local isTips = remote.herosUtil:checkHerosIsTipByID(self._actorId)
	    self._ccbOwner.node_tips_hero:setVisible(isTips)
		-- 设置英雄天赋	
		self._talentIcon:setHero(self._hero.actorId)
		-- 装备显示
		self._equipmentUtils:setHero(self._hero.actorId) 
		self:showEquipment()

		-- diaplay stars
		self._heroHead:setStar(self._hero.grade)
		self._heroHead:setLevel(self._hero.level)

		if self._isGrayDisplay == true then
			makeNodeOpacity(self._heroHead, 255)
			makeNodeFromGrayToNormal(self._heroHead)
			self._isGrayDisplay = false
		end

		self._ccbOwner.node_recruitAnimation:setVisible(false)
	else
		-- invisible grade label
		self._ccbOwner.tf_grade:setVisible(false)
		-- invisible tip icon
		self._ccbOwner.node_tips_hero:setVisible(false)
		-- display fragment
		self:showBattleForce()
		local characher = QStaticDatabase:sharedDatabase():getCharacterByID(self._actorId)
		local grade_info = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(self._actorId, characher.grade or 0)
		local soulGemId = grade_info.soul_gem
		local currentGemCount = remote.items:getItemsNumByID(soulGemId)
		local needGemCount = QStaticDatabase:sharedDatabase():getNeedSoulByHeroActorLevel(self._actorId, characher.grade or 0)
		-- can summon the hero
		if currentGemCount >= needGemCount then
			self._ccbOwner.sprite_bar:setScaleX(self._forceBarScaleX)
			self._ccbOwner.node_hero_force_full:setVisible(true)
			self._ccbOwner.node_hero_force:setVisible(false)
			self._ccbOwner.node_recruitAnimation:setVisible(true)
		else
			self._ccbOwner.sprite_bar:setScaleX(self._forceBarScaleX * (currentGemCount / needGemCount))
			self._ccbOwner.node_hero_force_full:setVisible(false)
			self._ccbOwner.node_hero_force:setVisible(true)
			self._ccbOwner.node_hero_force:setString(tostring(currentGemCount) .. "/" .. tostring(needGemCount))
			self._ccbOwner.node_recruitAnimation:setVisible(false)
		end

		if self._isGrayDisplay == false then
			makeNodeOpacity(self._heroHead, math.floor(255 * 0.85))
			makeNodeFromNormalToGrayLuminance(self._heroHead)
			self._isGrayDisplay = true
		end

		-- 设置英雄天赋	
		self._talentIcon:setHero(self._actorId)

		self._heroHead:setStarVisible(false)
		self._heroHead:setLevelVisible(false)
	end

	local isFind = false
	if self._selectTable ~= nil then
		for _,value in pairs(self._selectTable) do
			if value == actorId then
				isFind = true
				break
			end
		end
	end

	if isFind == true then
		self:selected()
	else
		self:unselected()
	end
	self:removeFight()
end

--刷新当前信息显示
function QUIWidgetHeroFrame:refreshInfo()
	self:setHero(self._actorId, self._selectTable)
end

function QUIWidgetHeroFrame:selected()
	self._ccbOwner.node_hero_select:setVisible(true)
end

function QUIWidgetHeroFrame:unselected()
	self._ccbOwner.node_hero_select:setVisible(false)
end

function QUIWidgetHeroFrame:setFramePos(pos)
	self._pos = pos
end

function QUIWidgetHeroFrame:getContentSize()
	return self._ccbOwner.bg:getContentSize()
end

function QUIWidgetHeroFrame:showEquipment()
	self._ccbOwner.node_hero_equipment:setVisible(true)
	self._ccbOwner.node_hero_battleForce:setVisible(false)
end

function QUIWidgetHeroFrame:showBattleForce()
	self._ccbOwner.node_hero_equipment:setVisible(false)
	self._ccbOwner.node_hero_battleForce:setVisible(true)
end

function QUIWidgetHeroFrame:showFight()
	self._isFight = true
	self._ccbOwner.node_hero_fight:setVisible(true)
end

function QUIWidgetHeroFrame:removeFight()
	self._isFight = false
	self._ccbOwner.node_hero_fight:setVisible(false)
end

function QUIWidgetHeroFrame:onExit()
	self._eventProxy = nil
end

--event callback area--
function QUIWidgetHeroFrame:_onTriggerHeroOverview(tag, menuItem)
	local position = self:convertToWorldSpaceAR(ccp(0,0))
	QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetHeroFrame.EVENT_HERO_FRAMES_CLICK, hero = self._hero, actorId = self._actorId, position = position})
end

function QUIWidgetHeroFrame:_removeDelay()
	if self._delay ~= nil then 
		scheduler.unscheduleGlobal(self._delay)
		self._delay = nil
	end
end

return QUIWidgetHeroFrame
