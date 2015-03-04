local QUIWidget = import("QUIWidget")
local QUIWidgetItmePrompt = class("QUIWidgetItmePrompt", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")

function QUIWidgetItmePrompt:ctor(options)
  local ccbFile = "ccb/Widget_ItemPrompt.ccbi"
  local callBacks = {}
  QUIWidgetItmePrompt.super.ctor(self, ccbFile, callBacks, options)
  if options ~= nil then
    self.itemConfig = options.itmeConfig
    self.iconSize = options.boxSize
    self.scaleX = options.scaleX
    self.scaleY = options.scaleY
  end

  self:getOldInfo()

  self._ccbOwner.itme_name:setString("")
  self._ccbOwner.itme_money:setString("")
  self._ccbOwner.itme_level:setString("")
  self._ccbOwner.have_num:setString("")
--  self._ccbOwner.tf_goods_num:setVisible(false)
  for i = 1 , 4 ,1 do
    self._ccbOwner["property"..i]:setString("")
    self._ccbOwner["number"..i]:setString("")
  end

  self:setItemIcon(self.itemConfig.icon)
  
  self:setInfo()
  self.size = self._ccbOwner.itme_bg:getContentSize()

end
--设置物品信息
function QUIWidgetItmePrompt:setInfo()
  self._ccbOwner.itme_name:setString(self.itemConfig.name)
  self._ccbOwner.itme_money:setString(self.itemConfig.selling_price)
  self._ccbOwner.itme_level:setString(self.itemConfig.level)
  self._ccbOwner.have_num:setString(remote.items:getItemsNumByID(self.itemConfig.id))

  self.property = {}
  self.number = {}
  if self.itemConfig.attack ~= 0 and self.itemConfig.attack ~= nil and #self.property <= 4 then
    table.insert(self.property,"攻击")
    table.insert(self.number,"+"..self.itemConfig.attack)
  end
  if self.itemConfig.hp ~= 0 and self.itemConfig.hp ~= nil and #self.property <= 4 then
    table.insert(self.property,"生命")
    table.insert(self.number,"+"..self.itemConfig.hp)
  end
  if self.itemConfig.armor_physical ~= 0 and self.itemConfig.armor_physical ~= nil and #self.property <= 4 then
    table.insert(self.property,"物抗")
    table.insert(self.number,"+"..self.itemConfig.armor_physical)
  end
  if self.itemConfig.armor_magic ~= 0 and self.itemConfig.armor_magic ~= nil and #self.property <= 4 then
    table.insert(self.property,"魔抗")
    table.insert(self.number,"+"..self.itemConfig.armor_magic)
  end
  if self.itemConfig.hit_rating ~= 0 and self.itemConfig.hit_rating ~= nil and #self.property < 4 then
    table.insert(self.property,"命中等级")
    table.insert(self.number,"+"..self.itemConfig.hit_rating)
  end
  if self.itemConfig.dodge_rating ~= 0 and self.itemConfig.dodge_rating ~= nil and #self.property < 4 then
    table.insert(self.property,"闪避等级")
    table.insert(self.number,"+"..self.itemConfig.dodge_rating)
  end
  if self.itemConfig.critical_rating ~= 0 and self.itemConfig.critical_rating ~= nil and #self.property < 4 then
    table.insert(self.property,"暴击等级")
    table.insert(self.number,"+"..self.itemConfig.critical_rating)
  end
  if self.itemConfig.block_rating ~= 0 and self.itemConfig.block_rating ~= nil and #self.property < 4 then
    table.insert(self.property,"格挡等级")
    table.insert(self.number,"+"..self.itemConfig.block_rating)
  end
  if self.itemConfig.haste_rating ~= 0 and self.itemConfig.haste_rating ~= nil and #self.property < 4 then
    table.insert(self.property,"急速等级")
    table.insert(self.number,"+"..self.itemConfig.haste_rating)
  end

  for i = 1, #self.property, 1 do
    self._ccbOwner["property"..i]:setString(self.property[i] or "")
    self._ccbOwner["number"..i]:setString(self.number[i] or "")
  end

  self:setPromptBg()
  self:setFrameBg()
  if #self.property >0 then
    self:setProperty()
  end
end

function QUIWidgetItmePrompt:setPromptBg()
  local itmeNameSize = self._ccbOwner.itme_name:getContentSize().width
  local moneyNodePosition = self._ccbOwner.money_node:getPositionX()
  local levelNameSize = self._ccbOwner.need_level:getContentSize().width
  local levelSize = self._ccbOwner.itme_level:getContentSize().width
  self.frameChange = self.propertySize * (4 - #self.property)

  if itmeNameSize < levelNameSize+levelSize then
    self.itmeNameChange = self.oldItmeSize.width - (levelNameSize+levelSize)
  else
    self.itmeNameChange = self.oldItmeSize.width - itmeNameSize
  end
  self._ccbOwner.itme_bg:setContentSize(CCSize(self.oldPromptSize.width - self.itmeNameChange, self.oldPromptSize.height - self.frameChange))
  self._ccbOwner.money_node:setPositionX(moneyNodePosition - self.itmeNameChange)
end

function QUIWidgetItmePrompt:setFrameBg()
  local moneyIconPosition = ccp(self._ccbOwner.money_icon:getPosition())
  local moneySize = self._ccbOwner.itme_money:getContentSize()
  local positionChange = self.oldMoneySize.width - moneySize.width
  self._ccbOwner.money_icon:setPosition(moneyIconPosition.x + positionChange, moneyIconPosition.y)
  
  self._ccbOwner.kuang_bg:setScaleX((self.oldFrameSize.width - self.itmeNameChange)/self.oldFrameSize.width)
  self._ccbOwner.kuang_bg:setScaleY((self.oldFrameSize.height - self.frameChange)/self.oldFrameSize.height)
  if #self.property == 0 then
    self._ccbOwner.kuang_bg:setVisible(false)
  end
end

function QUIWidgetItmePrompt:getOldInfo()
  self.propertySize = self._ccbOwner.property1:getContentSize().height
  self.oldPromptSize = self._ccbOwner.itme_bg:getContentSize()
  self.oldFrameSize = self._ccbOwner.kuang_bg:getContentSize()
  self.oldItmeSize = self._ccbOwner.itme_name:getContentSize()
  self.oldMoneySize = self._ccbOwner.itme_money:getContentSize()
end

function QUIWidgetItmePrompt:setItemIcon(respath)
  local itmeBox = QUIWidgetItemsBox.new()
  self._ccbOwner.item_icon:addChild(itmeBox)
  itmeBox:setGoodsInfo(self.itemConfig.id, ITEM_TYPE.ITEM, 0)
--  if respath~=nil and #respath > 0 then
--    if self.icon == nil then
--      self.icon = CCSprite:create()
--      self._ccbOwner.node_icon:addChild(self.icon)
--      self._ccbOwner.node_mask:setVisible(false)
--      if self.itemConfig.type == 3 then
--        self._ccbOwner.node_scrap:setVisible(true)
--        self._ccbOwner.node_soul:setVisible(true)
--      else
--        self._ccbOwner.node_scrap:setVisible(false)
--        self._ccbOwner.node_soul:setVisible(false)
--      end
--    end
--    self.icon:setVisible(true)
--    self.icon:setScale(1)
--    self.icon:setTexture(CCTextureCache:sharedTextureCache():addImage(respath))
--  end
--  local size = self.icon:getContentSize()
--
--  if size.width > self.iconSize.width then
--    self.icon:setScaleX(self.iconSize.width * self.scaleX/size.width)
--  end
--  if size.height > self.iconSize.height then
--    self.icon:setScaleY(self.iconSize.height * self.scaleY/size.height)
--  end
end

function QUIWidgetItmePrompt:setProperty()
  if self.property[1] ~= "攻击" and self.property[1] ~= "生命" and self.property[1] ~= "物抗" and self.property[1] ~= "魔抗" then
    local position = ccp(self._ccbOwner.number1:getPosition())
    self._ccbOwner.number1:setPosition(position.x + 40, position.y)
  end
  if self.property[2] == "攻击" or self.property[2] == "生命" or self.property[2] == "物抗" or self.property[2] == "魔抗" then
    local position = ccp(self._ccbOwner.number2:getPosition())
    self._ccbOwner.number2:setPosition(position.x - 40, position.y)
  end
  if self.property[3] == "攻击" or self.property[3] == "生命" or self.property[3] == "物抗" or self.property[3] == "魔抗" then
    local position = ccp(self._ccbOwner.number3:getPosition())
    self._ccbOwner.number3:setPosition(position.x - 40, position.y)
  end
  if self.property[4] == "攻击" or self.property[4] == "生命" or self.property[4] == "物抗" or self.property[4] == "魔抗" then
    local position = ccp(self._ccbOwner.number4:getPosition())
    self._ccbOwner.number4:setPosition(position.x - 40, position.y)
  end
end

return QUIWidgetItmePrompt
