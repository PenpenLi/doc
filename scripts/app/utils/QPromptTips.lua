local QPromptTips = class("QPromptTips")
local QNotificationCenter = import("..controllers.QNotificationCenter")
local QUIWidgetItmePrompt = import("..ui.widgets.QUIWidgetItmePrompt")
local QUIWidgetItemsBox = import("..ui.widgets.QUIWidgetItemsBox")
local QUIWidgetMonsterHead = import("..ui.widgets.QUIWidgetMonsterHead")
local QUIWidgetMonsterPrompt = import("..ui.widgets.QUIWidgetMonsterPrompt")
local QUIWidgetChipPrompt = import("..ui.widgets.QUIWidgetChipPrompt")
local QStaticDatabase = import("..controllers.QStaticDatabase")
local QUIWidgetHeroSkillCell = import("..ui.widgets.QUIWidgetHeroSkillCell")
local QUIWidgetSkillPrompt = import("..ui.widgets.QUIWidgetSkillPrompt")
local QUIWidgetHeroInformation = import("..ui.widgets.QUIWidgetHeroInformation")
local QUIWidgetHeroPrompt = import("..ui.widgets.QUIWidgetHeroPrompt")
local QUIWidgetEnergyPrompt = import("..ui.widgets.QUIWidgetEnergyPrompt")
local QVIPUtil = import("..utils.QVIPUtil")

function QPromptTips:ctor(options)
  self._layer = options
  self.prompt = nil
end


--[[
  怪物悬浮提示
--]]

function QPromptTips:addMonsterEventListener()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetMonsterHead.EVENT_BEGAIN , QPromptTips.startMonsterPrompt, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetMonsterHead.EVENT_END , QPromptTips.stopMonsterPrompt, self)
end

function QPromptTips:removeMonsterEventListener()
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetMonsterHead.EVENT_BEGAIN , QPromptTips.startMonsterPrompt, self)
   QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetMonsterHead.EVENT_END , QPromptTips.stopMonsterPrompt, self)
  if self.prompt ~= nil then
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end

function QPromptTips:startMonsterPrompt(data)
  if data ~= nil then
    local target = data.eventTarget
    local info = data.info
    local config = data.config
    
    local headSize = target._ccbOwner.head_cricle_di:getContentSize()
    local headScale = target._ccbOwner.head_cricle_di:getScale()
   
    local position = target._ccbOwner.cityNode:convertToWorldSpaceAR(ccp(0, 0))
    if self.prompt == nil then
       self.prompt = QUIWidgetMonsterPrompt.new({info = info, size = headSize, scale = headScale, config = config})
      self._layer:addChild(self.prompt)
    end
    local promptSize = self.prompt.size
    local positionX = position.x + self.prompt.size.width/2 - headSize.width/2
    local positionY = position.y + self.prompt.size.height/2 + headSize.width/2 + self.prompt.skillChange
    self.prompt:setPosition(positionX, positionY)
  end
end

function QPromptTips:stopMonsterPrompt(event)
  if self.prompt ~= nil then 
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end

--[[
  物品悬浮提示
--]]

function QPromptTips:addItemEventListener(data)
  self.dialog = data
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetItemsBox.EVENT_BEGAIN , QPromptTips.startItemPrompt, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetItemsBox.EVENT_END , QPromptTips.stopItemPrompt, self)
end

function QPromptTips:removeItemEventListener()
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetItemsBox.EVENT_BEGAIN , QPromptTips.startItemPrompt, self)
   QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetItemsBox.EVENT_END , QPromptTips.stopItemPrompt, self)
  if self.prompt ~= nil then
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end

function QPromptTips:startItemPrompt(data)
  if data ~= nil then
    local target = data.eventTarget
    local itemId = data.itemID
    local itmeType = data.itmeType
    
    local size = target._ccbOwner.node_mask:getContentSize()
    local scaleX = target._ccbOwner.node_mask:getScaleX()
    local scaleY = target._ccbOwner.node_mask:getScaleY()
    
    local itmeConfig = nil
    if itmeType ~= ITEM_TYPE.HERO then 
      itmeConfig = QStaticDatabase:sharedDatabase():getItemByID(itemId)
    end  
    
    local position = target._ccbOwner.sprite_back:convertToWorldSpaceAR(ccp(0, 0))
    
    if itmeType == ITEM_TYPE.HERO then 
      local heroConfig = QStaticDatabase:sharedDatabase():getCharacterByID(itemId)
      if self.prompt == nil then
        self.prompt = QUIWidgetHeroPrompt.new(heroConfig)
        self._layer:addChild(self.prompt)
      end
      local promptSize = self.prompt.size
      local boxSize = target._ccbOwner.sprite_back:getContentSize()
      local positionY = position.y + promptSize.height/2 + boxSize.height/2
      self.prompt:setPosition(position.x, positionY)
      
    elseif self.prompt == nil and itmeConfig.type == 3 then
      self.prompt = QUIWidgetChipPrompt.new({itmeConfig = itmeConfig, boxSize = size, scaleX = scaleX, scaleY = scaleY})
      self._layer:addChild(self.prompt)
      local promptSize = self.prompt.size
      local boxSize = target._ccbOwner.sprite_back:getContentSize()
       self.positionY = position.y + promptSize.height/2 + boxSize.height/4
       self.positionX = position.x + (promptSize.width/2 - boxSize.width/2)
       if self.dialog.class.__cname == "QUIDialogAchieveItem" or self.dialog.class.__cname == "QUIDialogAchieveManyItem" then
          self.prompt:setPosition(position.x , self.positionY)
       else
          self.prompt:setPosition(self.positionX - 20, self.positionY)
       end
    else
      if self.prompt == nil then
        self.prompt = QUIWidgetItmePrompt.new({itmeConfig = itmeConfig, boxSize = size, scaleX = scaleX, scaleY = scaleY})
        self._layer:addChild(self.prompt)
         local promptSize = self.prompt.size
         local boxSize = target._ccbOwner.sprite_back:getContentSize()
         self.positionX = position.x + (promptSize.width/2 - boxSize.width/2) + self.prompt.itmeNameChange/2
         self.positionY = position.y + promptSize.height/2 + boxSize.height/2 - self.prompt.frameChange/2 
         if self.dialog.class.__cname == "QUIDialogAchieveItem" or self.dialog.class.__cname == "QUIDialogAchieveManyItem" then
            self.prompt:setPosition(position.x + self.prompt.itmeNameChange/2, self.positionY)
         else
            self.prompt:setPosition(self.positionX - 20, self.positionY)
         end
       end
    end
  end
end

function QPromptTips:stopItemPrompt(event)
  if self.prompt ~= nil then 
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end

--[[
  英雄悬浮提示
--]]

function QPromptTips:addHeroEventListener(data)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroInformation.EVENT_BEGAIN , QPromptTips.startHeroPrompt, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroInformation.EVENT_END , QPromptTips.stopHeroPrompt, self)
end

function QPromptTips:removeHeroEventListener()
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroInformation.EVENT_BEGAIN , QPromptTips.startHeroPrompt, self)
   QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroInformation.EVENT_END , QPromptTips.stopHeroPrompt, self)
  if self.prompt ~= nil then
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end
--
function QPromptTips:startHeroPrompt(data)
  if data ~= nil then
    local target = data.eventTarget
    local actorId = data.actorId
--    
--    local size = self.target._ccbOwner.node_mask:getContentSize()
--    local scaleX = self.target._ccbOwner.node_mask:getScaleX()
--    local scaleY = self.target._ccbOwner.node_mask:getScaleY()
      
      local heroInfo = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)   

    local position = target._ccbOwner.sprite_back:convertToWorldSpaceAR(ccp(0, 0))
    if self.prompt == nil then
      self.prompt = QUIWidgetHeroPrompt.new(heroInfo)
      self._layer:addChild(self.prompt)
    end
    local promptSize = self.prompt.size
    local boxSize = target._ccbOwner.sprite_back:getContentSize()
    local positionX = position.x + promptSize.width/2 + boxSize.width/2
    self.prompt:setPosition(positionX, position.y)
  end
end

function QPromptTips:stopHeroPrompt(event)
  if self.prompt ~= nil then 
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end

--[[
  技能悬浮提示
--]]

function QPromptTips:addSkillEventListener()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroSkillCell.EVENT_BEGAIN , QPromptTips.startSkillPrompt, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetHeroSkillCell.EVENT_END , QPromptTips.stopSkillPrompt, self)
end

function QPromptTips:removeSkillEventListener()
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroSkillCell.EVENT_BEGAIN , QPromptTips.startSkillPrompt, self)
   QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetHeroSkillCell.EVENT_END , QPromptTips.stopSkillPrompt, self)
  if self.prompt ~= nil then
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end

function QPromptTips:startSkillPrompt(data)
  if data ~= nil then
      local skillName = data.skillName
      local target = data.eventTarget
      local skillID = data.skillID
      
    local skillConfig = nil
    local isHave = false
    if skillID ~= nil then
      skillConfig = QStaticDatabase:sharedDatabase():getSkillByID(skillID)
      isHave = true
    else
      skillConfig = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(skillName, 1) 
    end 
    
    local position = target._ccbOwner.node_layout:convertToWorldSpaceAR(ccp(0, 0))
    if self.prompt == nil then
      self.prompt = QUIWidgetSkillPrompt.new(skillConfig, isHave)
      self._layer:addChild(self.prompt)
    end
    local promptSize = self.prompt.size
    local boxSize = target._ccbOwner.node_layout:getContentSize()
    local positionX = position.x + promptSize.width/2 + boxSize.width/2
    self.prompt:setPosition(positionX, position.y)
  end
end

function QPromptTips:stopSkillPrompt(event)
  if self.prompt ~= nil then 
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end


--[[
  体力悬浮提示
--]]

function QPromptTips:addEnergyEventListener()
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetEnergyPrompt.EVENT_BEGAIN , QPromptTips.startEnergyPrompt, self)
  QNotificationCenter.sharedNotificationCenter():addEventListener(QUIWidgetEnergyPrompt.EVENT_END , QPromptTips.stopEnergyPrompt, self)
end

function QPromptTips:removeEnergyEventListener()
  QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetEnergyPrompt.EVENT_BEGAIN , QPromptTips.startEnergyPrompt, self)
   QNotificationCenter.sharedNotificationCenter():removeEventListener(QUIWidgetEnergyPrompt.EVENT_END , QPromptTips.stopEnergyPrompt, self)
  if self.prompt ~= nil then
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end

function QPromptTips:startEnergyPrompt(data)
    local maxEnergyBuyCount = QVIPUtil:getBuyVirtualCount(ITEM_TYPE.ENERGY)
    -- This is copied from system setting calculation
    local secondsToMaximum2 = (global.config.max_energy - remote.user.energy) * global.config.energy_refresh_interval
    local secondsElapsed = math.floor((q.time() * 1000 - remote.user.energyRefreshedAt)/1000)%global.config.energy_refresh_interval
    local secondsToMaximum = secondsToMaximum2 - secondsElapsed

    if self.prompt == nil then
      self.prompt = QUIWidgetEnergyPrompt.new({curEnergy=remote.user.energy, curEnergyBuyCount = remote.user.todayEnergyBuyCount, 
        maxEnergyBuyCount = maxEnergyBuyCount, timeToNextEnergyPoint = global.config.energy_refresh_interval - secondsElapsed, timeToEnergyFull = secondsToMaximum}, isHave)
      self._layer:addChild(self.prompt)
    end
end

function QPromptTips:stopEnergyPrompt(event)
  if self.prompt ~= nil then 
    self.prompt:removeFromParent()
    self.prompt = nil
  end
end

return QPromptTips