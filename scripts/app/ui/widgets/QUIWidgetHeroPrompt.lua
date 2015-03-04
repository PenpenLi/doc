local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroPrompt = class("QUIWidgetHeroPrompt", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetHeroPrompt:ctor(options)
  local ccbFile = "ccb/Widget_HeroPrompt.ccbi"
  local callBacks = {}
  QUIWidgetHeroPrompt.super.ctor(self, ccbFile, callBacks, options)
  
  self.heroInfo = options
  
  self._hero = remote.herosUtil:getHeroByID(self.heroInfo.id)
  self.heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self.heroInfo.id)
  self.skillConfig = QStaticDatabase:sharedDatabase():getTalentByID(self.heroInfo.talent) 
  
  self.skill = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(self.skillConfig.skill_5, 1)
  
  self:setAll()
  
  self.size = self._ccbOwner.hero_bg:getContentSize()
  
end

function QUIWidgetHeroPrompt:setAll()
  self._ccbOwner.hero_name:setString(self.heroDisplay.name)
  self._ccbOwner.hero_level:setString("LV."..self._hero.level)
  self._ccbOwner.hern_content:setString(self.heroDisplay.brief)
  self._ccbOwner.skill_name:setString(self.skill.local_name)
  self._ccbOwner.skill_content:setString(self.skill.description or "")
  
  local headImageTexture =CCTextureCache:sharedTextureCache():addImage(self.heroDisplay.icon)
  self._ccbOwner.node_hero_image:setTexture(headImageTexture)
  local size = headImageTexture:getContentSize()
  local rect = CCRectMake(0, 0, size.width, size.height)
  self._ccbOwner.node_hero_image:setTextureRect(rect)
  self._ccbOwner.node_hero_image:setVisible(true)
  self._ccbOwner.node_level:setVisible(false)
end

return QUIWidgetHeroPrompt