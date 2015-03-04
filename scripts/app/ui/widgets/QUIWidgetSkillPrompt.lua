local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetSkillPrompt = class("QUIWidgetSkillPrompt", QUIWidget)

function QUIWidgetSkillPrompt:ctor(options, isHave)
  local ccbFile = "ccb/Widget_SkillPrompt.ccbi"
  local callBacks = {}
  QUIWidgetSkillPrompt.super.ctor(self, ccbFile, callBacks, options)
 
  self.skillInfo = options
  self.isHave = isHave 
  
  self.contentWidth = self._ccbOwner.skill_name:getContentSize().width
  self:oldInfo()
  
  if self.isHave == false then
    self:skillNoExist()
  else
    self:skillExist()
  end
    
  self.size = self._ccbOwner.skill_bg:getContentSize() 
end

function QUIWidgetSkillPrompt:skillNoExist()
  self._ccbOwner.skill_name:setString(q.autoWrap(self.skillInfo.description or "", 21, 11, self.contentWidth))
  self._ccbOwner.skill_attack:setString("")
  self._ccbOwner.attack_content:setString("")
  self:setPromptBg()
end

function QUIWidgetSkillPrompt:skillExist()
  self._ccbOwner.skill_name:setString(q.autoWrap(self.skillInfo.description or "", 21, 11, self.contentWidth))
  self._ccbOwner.skill_attack:setString(q.autoWrap(self.skillInfo.description_1 or "", 21, 11, self.contentWidth))
  self._ccbOwner.attack_content:setString(q.autoWrap(self.skillInfo.description_2 or "", 21, 11, self.contentWidth))
end

function QUIWidgetSkillPrompt:setPromptBg()
  local skillBgSzie = self._ccbOwner.skill_bg:getContentSize() 
  self._ccbOwner.skill_bg:setScaleY((skillBgSzie.height - self.oldAttackSize.height - self.oldContentSize.height)/skillBgSzie.height)
  self._ccbOwner.skill_name:setPosition(self.oldSkillNamePosition.x, self.oldSkillNamePosition.y - self.oldAttackSize.height/2 - self.oldContentSize.height/2)
end

function QUIWidgetSkillPrompt:oldInfo()
  self.oldAttackSize = self._ccbOwner.skill_attack:getContentSize()
  self.oldContentSize = self._ccbOwner.attack_content:getContentSize()
  self.oldSkillNamePosition = ccp(self._ccbOwner.skill_name:getPosition())
end

return QUIWidgetSkillPrompt