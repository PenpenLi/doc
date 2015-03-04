--
-- Author: wkwang
-- Date: 2014-09-02 17:18:34
--
local QUIDialog = import(".QUIDialog")
local QUIDialogHeroCard = class("QUIDialogHeroCard", QUIDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroSkillBox = import(".QUIWidgetHeroSkillBox")
local QUIWidgetHeroProfessionalIcon = import(".QUIWidgetHeroProfessionalIcon")
local QNavigationController = import("...controllers.QNavigationController")

QUIDialogHeroCard.EVENT_CLOSED = "EVENT_CLOSED"

function QUIDialogHeroCard:ctor(options)
	local ccbFile = "ccb/Dialog_HeroInfoCard.ccbi"
	local callBacks = {}
	QUIDialogHeroCard.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self._skillBox = QUIWidgetHeroSkillBox.new()
	self._skillBox:setLock(false)
	self._skillBox:setColor("white")
	self._ccbOwner.node_skill:addChild(self._skillBox:getView())

	self._talentIcon = QUIWidgetHeroProfessionalIcon.new({})
	self._ccbOwner.node_talent:addChild(self._talentIcon:getView())
	
	for i=1,5,1 do
		self._ccbOwner["node_star"..i]:setVisible(false)
	end

	self._ccbOwner.node_normal:setVisible(true)
	self:setHero(options.actorId)
	self._isRunAnimation = false
end

function QUIDialogHeroCard:viewDidAppear()
    QUIDialogHeroCard.super.viewDidAppear(self)
    local options = self:getOptions()
	if options.size ~= nil and options.startP ~= nil then
		self._isRunAnimation = true
		self._backTouchLayer:setVisible(false)
		local size = self._ccbOwner.bg_normal:getContentSize()
		local view = self:getView()
		view:setScale(1/1.62)
		view:setPosition(options.startP.x, options.startP.y)
		view:setRotation(90)
  		local durationTime = 0.3
		local rotationAction = CCRotateTo:create(durationTime, 0)
	  	local scaleAction = CCScaleTo:create(durationTime, 1)
	  	local positionAction = CCMoveTo:create(durationTime, ccp(display.cx, display.cy))
	  	local callFun = CCCallFunc:create(function()
			self._isRunAnimation = false
			self._backTouchLayer:setVisible(true)
	  	 end)
		local actionArrayIn = CCArray:create()
	  	actionArrayIn:addObject(scaleAction)
	  	actionArrayIn:addObject(rotationAction)
	  	actionArrayIn:addObject(positionAction)
	  	local actionSpawn = CCSpawn:create(actionArrayIn)
	  	local actionArray = CCArray:create()
	  	actionArray:addObject(actionSpawn)
	  	actionArray:addObject(callFun)
	    local ccsequence = CCSequence:create(actionArray)
	  	view:runAction(ccsequence)
	end
end

function QUIDialogHeroCard:setHero(actorId)
	local heroInfo = remote.herosUtil:getHeroByID(actorId)
    local heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(actorId)
    if heroDisplay.card ~= nil then
    	--添加技能
		local characher = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
        local heroTalent = QStaticDatabase:sharedDatabase():getTalentByID(characher.talent)
	    local skill = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(heroTalent.skill_3,1)
		if skill ~= nil then
	    	self._skillBox:setSkillID(skill.id)
	    end
	    --星星
	    for i=1,(heroInfo.grade+1),1 do
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
		self._talentIcon:setHero(actorId)
		--加载大图
		local cardSp = display.newSprite(heroDisplay.card)
		self._ccbOwner.node_card:addChild(cardSp)
		--加载名称
		local nameSp = display.newSprite(heroDisplay.card_name)
		nameSp:setPositionX(nameSp:getContentSize().width/2)
		self._ccbOwner.node_name:addChild(nameSp)
    end
end

function QUIDialogHeroCard:_closeAnimation()
	local options = self:getOptions()
	if options.size ~= nil and options.startP ~= nil then
		self._isRunAnimation = true
		self._backTouchLayer:setVisible(false)
		local size = self._ccbOwner.bg_normal:getContentSize()
		local view = self:getView()
  		local durationTime = 0.3
		local rotationAction = CCRotateTo:create(durationTime, 90)
	  	local scaleAction = CCScaleTo:create(durationTime, 1/1.62)
	  	local positionAction = CCMoveTo:create(durationTime, ccp(options.startP.x, options.startP.y))
	  	local callFun = CCCallFunc:create(function()
			self:_closeHandler()
			self._isRunAnimation = false
	  	 end)
		local actionArrayIn = CCArray:create()
	  	actionArrayIn:addObject(scaleAction)
	  	actionArrayIn:addObject(rotationAction)
	  	actionArrayIn:addObject(positionAction)
	  	local actionSpawn = CCSpawn:create(actionArrayIn)
	  	local actionArray = CCArray:create()
	  	actionArray:addObject(actionSpawn)
	  	actionArray:addObject(callFun)
	    local ccsequence = CCSequence:create(actionArray)
	  	view:runAction(ccsequence)
	else
		self:_closeHandler()
	end
end

function QUIDialogHeroCard:_closeHandler()
	self:dispatchEvent({name = QUIDialogHeroCard.EVENT_CLOSED})
	app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogHeroCard:_onTriggerClose()
	if self._isRunAnimation == true or self._runClose == true then 
		return 
	end
  	app.sound:playSound("common_item")
	self._runClose = true -- add a sign resolve when double click at scale animation for remove time , may be crush, because the function trigger again
	self:_closeAnimation()
end

function QUIDialogHeroCard:_backClickHandler()
    self:_onTriggerClose()
end

return QUIDialogHeroCard