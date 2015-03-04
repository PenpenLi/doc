local QUIWidget = import("QUIWidget")
local QUIWidgetMonsterPrompt = class("QUIWidgetMonsterPrompt", QUIWidget)

local QFullCircleUiMask = import("..battle.QFullCircleUiMask")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetMonsterPrompt:ctor(options)
  local ccbFile = "ccb/Widget_MonstarPrompt.ccbi"
  local callBacks = {}
  QUIWidgetMonsterPrompt.super.ctor(self, ccbFile, callBacks, options)
  
  if options ~= nil then
    self.info = options.info
    self._size = options.size
    self._scale = options.scale
    self.config = options.config
  end
  self:getOldSize()
  self.chineseSize = 21
  
  self._ccbOwner.boss:setVisible(false)
  self._ccbOwner.monster_name:setString("")
  self._ccbOwner.monster_level:setString("")
  self._ccbOwner.monster_skill1:setString("")
  self._ccbOwner.monster_skill2:setString("")
  self._ccbOwner.monster_skill3:setString("")
  self._ccbOwner.monster_content:setString("")
  
  --设置头像
  self._headContent = CCNode:create()
  local ccclippingNode = QFullCircleUiMask.new()
  ccclippingNode:setRadius(self._scale * (self._size.width/2 - 5))
  ccclippingNode:addChild(self._headContent)
  self._ccbOwner.node_head:addChild(ccclippingNode)
  
  self.displayConfig = QStaticDatabase:sharedDatabase():getCharacterByID(self.config.npc_id)
  self.skillConfig = QStaticDatabase:sharedDatabase():getSkillsInfoByName(self.displayConfig.npc_skill)
  local headImageTexture = CCTextureCache:sharedTextureCache():addImage(self.info.icon)
  self._imgSp = CCSprite:createWithTexture(headImageTexture)
  local imgSize = self._imgSp:getContentSize()
  self._imgSp:setScale(self._scale * self._size.width/imgSize.width)
  self._headContent:addChild(self._imgSp)
  
  self:setAll()
  
  self.size = self._ccbOwner.monster_bg:getContentSize()
end

function QUIWidgetMonsterPrompt:setAll()

  self._ccbOwner.monster_name:setString(self.info.name)
  self._ccbOwner.monster_level:setString("LV."..self.displayConfig.npc_level)
  self._ccbOwner.monster_content:setString(q.autoWrap(self.info.desc or "", self.chineseSize, 40/3 , self.oldSkillSize.width))

  if self.config.is_boss ~= nil and self.config.is_boss == true then
    self._ccbOwner.boss:setVisible(true)
    self:getBossSkill()
  else
    self._ccbOwner.monster_skill1:setString(q.autoWrap(self.info.brief or "", self.chineseSize, 40/3 , self.oldSkillSize.width))
  end
  self:setContentBg()
  self:setPromptBg()
end
--设置整个悬浮提示框的大小
function QUIWidgetMonsterPrompt:setPromptBg()
  local promptWidth = self._ccbOwner.monster_bg:getContentSize().width
  local headSize = self._size.height
--  local frameSize = self._ccbOwner.kuang_bg:getContentSize().height 
--  local frameChang = frameSize - self.oldFrameSize.height
  self._ccbOwner.monster_bg:setScaleY((self.oldBgSize.height + self.skillChange)/self.oldBgSize.height)
end

function QUIWidgetMonsterPrompt:setContentBg()
  self.skillSize1 = self._ccbOwner.monster_skill1:getContentSize().height
  self.skillSize2 = self._ccbOwner.monster_skill2:getContentSize().height
  self.skillSize3 = self._ccbOwner.monster_skill3:getContentSize().height
  self.skillChange1 = self.skillSize1 - self.oldSkillSize.height
  if self._ccbOwner.monster_skill2:getString() == "" then
    self.skillChange2 = -24
  else
    self.skillChange2 = self.skillSize2 - self.oldSkillSize.height
  end
  if self._ccbOwner.monster_skill3:getString() == "" then
    self.skillChange3 = -24
  else
    self.skillChange3 = self.skillSize3 - self.oldSkillSize.height
  end
  self.skillChange = self.skillChange1 + self.skillChange2 + self.skillChange3
  self._ccbOwner.monster_skill2:setPosition(self.oldSkillPosition2.x, self.oldSkillPosition2.y - self.skillChange1)
  self._ccbOwner.monster_skill3:setPosition(self.oldSkillPosition3.x, self.oldSkillPosition3.y - self.skillChange1 - self.skillChange2)
  self._ccbOwner.frame_node:setPosition(0, -self.skillChange)
end
--获取各项初始值
function QUIWidgetMonsterPrompt:getOldSize()
  self.oldBgSize = self._ccbOwner.monster_bg:getContentSize()
  self.oldSkillSize = self._ccbOwner.monster_skill1:getContentSize()
  self.oldFrameSize = self._ccbOwner.kuang_bg:getContentSize()
  self.oldSkillPosition1 = ccp(self._ccbOwner.monster_skill1:getPosition())
  self.oldSkillPosition2 = ccp(self._ccbOwner.monster_skill2:getPosition())
  self.oldSkillPosition3 = ccp(self._ccbOwner.monster_skill3:getPosition())
end
--获取boss技能
function QUIWidgetMonsterPrompt:getBossSkill()
  if self.info.skill_desc_1 ~= nil then
    self._ccbOwner.monster_skill1:setString(q.autoWrap(self.info.skill_name_1.."："..self.info.skill_desc_1, self.chineseSize, 40/3 , self.oldSkillSize.width))
  end
  if self.info.skill_desc_2 ~= nil then
    self._ccbOwner.monster_skill2:setString(q.autoWrap(self.info.skill_name_2.."："..self.info.skill_desc_2, self.chineseSize, 40/3 , self.oldSkillSize.width))
  end
  if self.info.skill_desc_3 ~= nil then
    self._ccbOwner.monster_skill3:setString(q.autoWrap(self.info.skill_name_3.."："..self.info.skill_desc_3, self.chineseSize, 40/3 , self.oldSkillSize.width))
  end
end

return QUIWidgetMonsterPrompt