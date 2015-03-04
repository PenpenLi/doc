
local QUIWidget = import(".QUIWidget")
local QUIWidgetHeroSkillBox = class("QUIWidgetHeroSkillBox", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIWidgetHeroSkillBox.EVENT_CLICK = "EVENT_CLICK"

function QUIWidgetHeroSkillBox:ctor(options)
	local ccbFile = "ccb/Widget_HeroSkillBox.ccbi"
	local callBacks = {
        {ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetHeroSkillBox._onTriggerClick)},
    }
	QUIWidgetHeroSkillBox.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    self:unselected()
    self:hideArrow()
end

function QUIWidgetHeroSkillBox:hideAllColor()
	self._ccbOwner.node_green:setVisible(false)
	self._ccbOwner.node_blue:setVisible(false)
	self._ccbOwner.node_orange:setVisible(false)
	self._ccbOwner.node_purple:setVisible(false)
	self._ccbOwner.node_white:setVisible(false)
	self._ccbOwner.node_normal:setVisible(false)
end

function QUIWidgetHeroSkillBox:setColor(name)
	self:hideAllColor()
	if self._ccbOwner["node_"..name] then
		self._ccbOwner["node_"..name]:setVisible(true)
	end
end

function QUIWidgetHeroSkillBox:setSkillID(skillID)
  	self._skillID = skillID
  	local skillInfo = QStaticDatabase:sharedDatabase():getSkillByID(skillID)
  	self:setSkillIcon(skillInfo.icon)
	self._ccbOwner.node_grade:setVisible(false)
	self._ccbOwner.node_name:setVisible(false)
end 

function QUIWidgetHeroSkillBox:showArrow()
    self._ccbOwner.node_arrow:setVisible(true)
end 

function QUIWidgetHeroSkillBox:hideArrow()
    self._ccbOwner.node_arrow:setVisible(false)
end 

function QUIWidgetHeroSkillBox:selected()
	self._ccbOwner.node_select:setVisible(true)
end 

function QUIWidgetHeroSkillBox:unselected()
	self._ccbOwner.node_select:setVisible(false)
end 

function QUIWidgetHeroSkillBox:setSkillName(skillName)
	self._ccbOwner.node_name:setVisible(true)
	self._ccbOwner.tf_name:setString(skillName)
end

function QUIWidgetHeroSkillBox:setSkillLock(lockName,lockValue)
	self._ccbOwner.node_grade:setVisible(true)
	self._ccbOwner.tf_lock_name:setString(lockName)
	self._ccbOwner.tf_lock_value:setString(lockValue)
end

function QUIWidgetHeroSkillBox:setSkillLevel(level)
	self._ccbOwner.tf_level:setString(level)
end

function QUIWidgetHeroSkillBox:setLock(b)
	self._ccbOwner.node_mask:setVisible(b)
end

function QUIWidgetHeroSkillBox:setSkillIcon(respath)
	if respath then
		if self.icon == nil then
			self.icon = CCSprite:create()
			self._ccbOwner.node_icon:addChild(self.icon)
		end
		-- self.icon:setScale(1)
		self.icon:setTexture(CCTextureCache:sharedTextureCache():addImage(respath))

		local size = self.icon:getContentSize()
		local size2 = self._ccbOwner.node_mask:getContentSize()

		if size.width > size2.width then
			self.icon:setScaleX(size2.width/size.width)
		end
		if size.height > size2.height then
			self.icon:setScaleY(size2.height/size.height)
		end
	end
end

function QUIWidgetHeroSkillBox:_onTriggerClick()
	self:dispatchEvent({name = QUIWidgetHeroSkillBox.EVENT_CLICK , skillID = self._skillID, target = self})
end

return QUIWidgetHeroSkillBox