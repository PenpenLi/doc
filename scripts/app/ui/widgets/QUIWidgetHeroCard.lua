--
-- Author: wkwang
-- Date: 2014-08-29 14:17:59
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroCard = class("QUIWidgetHeroCard", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")
local QUIDialogHeroCard = import("..dialogs.QUIDialogHeroCard")
local QUIWidgetHeroSkillBox = import(".QUIWidgetHeroSkillBox")
local QUIWidgetHeroProfessionalIcon = import(".QUIWidgetHeroProfessionalIcon")

QUIWidgetHeroCard.EVENT_CLICK = "EVENT_CLICK"

function QUIWidgetHeroCard:ctor(options)
	local ccbFile = "ccb/Widget_HeroInfoCard.ccbi"
	local callBacks = {
        {ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetHeroCard._onTriggerClick)},}
	QUIWidgetHeroCard.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self._skillBox = QUIWidgetHeroSkillBox.new()
	self._skillBox:setLock(false)
	self._skillBox:setColor("white")
	self._ccbOwner.node_skill:addChild(self._skillBox:getView())

	self._talentIcon = QUIWidgetHeroProfessionalIcon.new({})
	self._ccbOwner.node_talent:addChild(self._talentIcon:getView())

	self._ccbOwner.node_normal:setVisible(true)
	self._isShow = false
	self._isRun = false
	self._isEffect = false
end

function QUIWidgetHeroCard:setHero(actorId)
	self._actorId = actorId
	local heroInfo = remote.herosUtil:getHeroByID(self._actorId)
    local heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self._actorId)
    self._ccbOwner.node_no:setVisible(false)
    self._ccbOwner.node_hero:setVisible(false)
    self._ccbOwner.node_title:setVisible(false)
    if heroDisplay.card == nil then
    	self._ccbOwner.node_no:setVisible(true)
    else
    	self._ccbOwner.node_title:setVisible(true)
    	self._ccbOwner.node_hero:setVisible(true)
    	self:resetHeroPart()
    	--添加技能
		local characher = QStaticDatabase:sharedDatabase():getCharacterByID(self._actorId)
        local heroTalent = QStaticDatabase:sharedDatabase():getTalentByID(characher.talent)
	    local skill = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(heroTalent.skill_3,1)
		if skill ~= nil then
	    	self._skillBox:setSkillID(skill.id)
	    end
	    --星星
	    for i=1,(characher.grade+1),1 do
			self._ccbOwner["node_star"..i]:setVisible(true)
		end
		--颜色
		local colour = characher.colour
		if colour == 1 then
			self._ccbOwner.node_white:setVisible(true)
		elseif colour == 2 then
			self._ccbOwner.node_green:setVisible(true)
		elseif colour == 3 then
			self._ccbOwner.node_blue:setVisible(true)
		elseif colour == 4 then
			self._ccbOwner.node_purple:setVisible(true)
		end
		--天赋
		self._talentIcon:setHero(self._actorId)
		--加载大图
		local cardSp = display.newSprite(heroDisplay.card)
		local cardSize = cardSp:getContentSize()
		local nodeSize = self._ccbOwner.node_normal_card:getContentSize()
		local scaleX = nodeSize.width/cardSize.width
		local scaleY = nodeSize.height/cardSize.height
		cardSp:setScaleX(scaleX)
		cardSp:setScaleY(scaleY)
		self._ccbOwner.node_card:removeAllChildren()
		self._ccbOwner.node_card:addChild(cardSp)
		--加载名称
		local nameSp = display.newSprite(heroDisplay.card_name)
		nameSp:setScaleX(scaleX)
		nameSp:setScaleY(scaleY)
		nameSp:setPositionX((nameSp:getContentSize().width * scaleX)/2)
		self._ccbOwner.node_name:removeAllChildren()
		self._ccbOwner.node_name:addChild(nameSp)
    end
end

function QUIWidgetHeroCard:setIsEffect(b)
	self._isEffect = b
end

function QUIWidgetHeroCard:resetHeroPart()
	self._ccbOwner.node_name:removeAllChildren()
	for i=1,5,1 do
		self._ccbOwner["node_star"..i]:setVisible(false)
	end
	self._ccbOwner.node_white:setVisible(false)
	self._ccbOwner.node_green:setVisible(false)
	self._ccbOwner.node_blue:setVisible(false)
	self._ccbOwner.node_purple:setVisible(false)
end

function QUIWidgetHeroCard:_onTriggerClick()
	self:dispatchEvent({name = QUIWidgetHeroCard.EVENT_CLICK})
	if self._isEffect == false then return end
  	app.sound:playSound("common_item")
	local startP = self:convertToWorldSpaceAR(ccp(0,0))
	local size = self._ccbOwner.bg_normal:getContentSize()
	self._cardDialog = app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogHeroCard", 
		options = {actorId = self._actorId, startP = startP, size = size}}, {isPopCurrentDialog = false})
	self._cardDialog:addEventListener(QUIDialogHeroCard.EVENT_CLOSED, handler(self, self._onBigCardHide))
	self:setVisible(false)
end

function QUIWidgetHeroCard:_onBigCardHide()
	self:setVisible(true)
end

return QUIWidgetHeroCard