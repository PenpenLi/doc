
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroIntroduce = class("QUIWidgetHeroIntroduce", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroSkillBox = import("..widgets.QUIWidgetHeroSkillBox")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")

function QUIWidgetHeroIntroduce:ctor(options)
	local ccbFile = "ccb/Widget_HeroIntreduce.ccbi"
	local callBacks = {}
	QUIWidgetHeroIntroduce.super.ctor(self, ccbFile, callBacks, options)

	self._skillBox = QUIWidgetHeroSkillBox.new()
	self._skillBox:setLock(false)
	self._ccbOwner.node_skill:addChild(self._skillBox:getView())
	
	self._ccbOwner.tf_skill_name = setShadow(self._ccbOwner.tf_skill_name)


    self._pageWidth = self._ccbOwner.node_mask:getContentSize().width
    self._pageHeight = self._ccbOwner.node_mask:getContentSize().height
    self._pageContent = self._ccbOwner.node_info
    self._orginalPosition = ccp(self._pageContent:getPosition())

    local layerColor = CCLayerColor:create(ccc4(0,0,0,150),self._pageWidth,self._pageHeight)
    local ccclippingNode = CCClippingNode:create()
    layerColor:setPositionX(self._ccbOwner.node_mask:getPositionX())
    layerColor:setPositionY(self._ccbOwner.node_mask:getPositionY())
    ccclippingNode:setStencil(layerColor)
    self._pageContent:removeFromParent()
    ccclippingNode:addChild(self._pageContent)

    self._ccbOwner.node_mask:getParent():addChild(ccclippingNode)
    
    self._touchLayer = QUIGestureRecognizer.new()
    -- self._touchLayer:setAttachSlide(true)
    self._touchLayer:attachToNode(self._ccbOwner.node_mask:getParent(),self._pageWidth, self._pageHeight, self._pageWidth/2-50, 
    0, handler(self, self.onTouchEvent))

    self._ccbOwner.node_scroll:setVisible(false)
    self._ccbOwner.node_shadow_bottom:setVisible(true)
    self._ccbOwner.node_shadow_top:setVisible(false)

    self._totalHeight = 645
    self:scrollAutoLayout()
end

function QUIWidgetHeroIntroduce:onEnter()
    self._touchLayer:enable()
    -- self._touchLayer:setAttachSlide(true)
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self._onEvent))
end

function QUIWidgetHeroIntroduce:onExit()
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
end

-- 处理各种touch event
function QUIWidgetHeroIntroduce:onTouchEvent(event)
    if event == nil or event.name == nil then
        return
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
        -- self._page:endMove(event.distance.y)
    elseif event.name == "began" then
        self._startY = event.y
        self._pageY = self._pageContent:getPositionY()
    elseif event.name == "moved" then
        local offsetY = self._pageY + event.y - self._startY
        if offsetY < self._orginalPosition.y then
            self._ccbOwner.node_shadow_bottom:setVisible(true)
            self._ccbOwner.node_shadow_top:setVisible(false)
            offsetY = self._orginalPosition.y
        elseif offsetY > (self._totalHeight - self._pageHeight + self._orginalPosition.y) then
            offsetY = (self._totalHeight - self._pageHeight + self._orginalPosition.y)
            self._ccbOwner.node_shadow_bottom:setVisible(false)
            self._ccbOwner.node_shadow_top:setVisible(true)
        else
        self._ccbOwner.node_shadow_bottom:setVisible(true)
        self._ccbOwner.node_shadow_top:setVisible(true)
        end
        self._pageContent:setPositionY(offsetY)
        self:showScroll()
    elseif event.name == "ended" then
    end
end

function QUIWidgetHeroIntroduce:showScroll()
    if self._handler ~= nil then
        scheduler.unscheduleGlobal(self._handler)
    end
    self._handler = scheduler.performWithDelayGlobal(function()
            self._ccbOwner.node_scroll:setVisible(false)
            scheduler.unscheduleGlobal(self._handler)
            self._handler = nil
        end,0.5)
    self._ccbOwner.node_scroll:setVisible(true)
    self:scrollAutoLayout()
end

function QUIWidgetHeroIntroduce:scrollAutoLayout()
    local totalHeight = self._ccbOwner.scroll_bar:getContentSize().height
    local smHeight = self._ccbOwner.scroll_sm:getContentSize().height
    local rate = (self._pageContent:getPositionY() - self._orginalPosition.y)/(self._totalHeight - self._pageHeight)
    self._ccbOwner.scroll_sm:setPositionY(rate * (totalHeight - smHeight) + self._ccbOwner.scroll_bar:getPositionY() + smHeight/2)
end

function QUIWidgetHeroIntroduce:setHero(hero,heroModel)
    local heroInfo = QStaticDatabase:sharedDatabase():getCharacterByID(hero.actorId)
	local heroProp = remote.herosUtil:getHeroPropByHeroInfo(heroInfo)
    self:setText("tf_attack_grow", string.format("%0.2f", heroProp.attack_grow))--math.floor(heroProp.attack_grow))
    self:setText("tf_hp_grow", string.format("%0.2f", heroProp.hp_grow))--math.floor(heroProp.hp_grow))
    self:setText("tf_hp", math.floor(heroModel:getMaxHp()))
    self:setText("tf_attack", math.floor(heroModel:getMaxAttack()))
    self:setText("tf_physicalresist", string.format("%0.2f",heroModel:getMaxArmorPhysicalReduce()).."%")
    self:setText("tf_magicresist", string.format("%0.2f",heroModel:getMaxArmorMagicReduce()).."%")
    self:setText("tf_hit", string.format("%0.1f", heroModel:getMaxHitLevel()))
    self:setText("tf_crit", string.format("%0.1f", heroModel:getMaxCritLevel()))
    self:setText("tf_dodge", string.format("%0.1f", heroModel:getMaxDodgeLevel()))
    self:setText("tf_block", string.format("%0.1f", heroModel:getMaxBlockLevel()))
    self:setText("tf_haste", string.format("%0.1f", heroModel:getMaxHasteLevel()))

    local heroTalent = QStaticDatabase:sharedDatabase():getTalentByID(heroInfo.talent)
    local skill = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(heroTalent.skill_3,1)
	if skill ~= nil then
    	self._skillBox:setSkillID(skill.id)
	    self:setText("tf_skill_name", tostring(skill.local_name))
	    self:setText("tf_skill_introduce", tostring(skill.description or ""))
    end
    local heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(hero.actorId)
    if nil ~= heroDisplay then 
        self:setText("tf_hero_introduce", tostring(heroDisplay.brief or "该英雄暂时没有介绍。"))
    end
end

function QUIWidgetHeroIntroduce:setText(name, text)
	if self._ccbOwner[name] then
		self._ccbOwner[name]:setString(text)
	end
end

function QUIWidgetHeroIntroduce:setSkillIcon(respath)
	if respath then
		local texture = CCTextureCache:sharedTextureCache():addImage(respath)
		self._ccbOwner.node_skill:setTexture(texture)
	    local size = texture:getContentSize()
	    local rect = CCRectMake(0, 0, size.width, size.height)
	    self._ccbOwner.node_skill:setTextureRect(rect)
	end
end

return QUIWidgetHeroIntroduce