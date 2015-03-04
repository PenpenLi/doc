
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHead = class("QUIWidgetHead", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QFullCircleUiMask = import("..battle.QFullCircleUiMask")

QUIWidgetHead.EVENT_HERO_HEAD_CLICK = "EVENT_HERO_HEAD_CLICK"

function QUIWidgetHead:ctor(options)
	
	local ccbFile = "ccb/Widget_head.ccbi"
  local callBacks = {
      {ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetHead._onTriggerClick)},
    }
	QUIWidgetHead.super.ctor(self,ccbFile,callBacks,options)
  cc.GameObject.extend(self)
  self:addComponent("components.behavior.EventProtocol"):exportMethods()
  
  self._ccbOwner.CCLabelTFF_TeamName = setShadow(self._ccbOwner.CCLabelTFF_TeamName)
  self._ccbOwner.CCLabelTTF_BattleForce = setShadow(self._ccbOwner.CCLabelTTF_BattleForce)
  
  self._headContent = CCNode:create()
  local ccclippingNode = QFullCircleUiMask.new()
  -- ccclippingNode:setPosition(ccp(-size.width/2,-size.height/2))
  ccclippingNode:setRadius(50)
  ccclippingNode:addChild(self._headContent)
  self._ccbOwner.node_headPicture:addChild(ccclippingNode)
end

function QUIWidgetHead:getTitleName(code)
    local rankConfig = QStaticDatabase:sharedDatabase():getRankConfigByCode(code)
    return rankConfig.name
end

function QUIWidgetHead:setInfo(user)
    -- if nick name is empty, don't show the shadow
    if user.nickname == nil or user.nickname == "" then
      self._ccbOwner.CCLayerGradient_Shadow:setVisible(false)
      self._ccbOwner.CCLabelTFF_TeamName:setString("")
    else
      self._ccbOwner.CCLayerGradient_Shadow:setVisible(true)
      self._ccbOwner.CCLabelTFF_TeamName:setString(user.nickname)
    end
    self._ccbOwner.CCLabelTFF_CharacterLevel:setString(tostring(user.level))

    local rankCode = remote.user.rankCode or ""
    if rankCode == "R0" or  rankCode == "" then
      self._ccbOwner.CCLabelTTF_TeamRank:setString("高阶督军")
    else
      self._ccbOwner.CCLabelTTF_TeamRank:setString(rankCode ..self:getTitleName(rankCode))
    end

    local force = 0
--    if remote.teams and #remote.teams > 0 then
--      local team = remote.teams[1] 
      force = remote.user
--    end

    self._ccbOwner.CCLabelTTF_BattleForce:setString("")
    self._ccbOwner.CCLabelTTF_BattleForce:setVisible(false)

    local resPath = remote.user.avatar
    if resPath == "" or resPath == nil then
      resPath = "icon/head/orc_warlord.png"
    end
    local texture = CCTextureCache:sharedTextureCache():addImage(resPath)
    if texture ~= nil then
      local sprite = CCSprite:createWithTexture(texture)
      local size = self._ccbOwner.node_headPicture_bg:getContentSize()
      sprite:setScale(size.width/sprite:getContentSize().width)
      self._headContent:removeAllChildren()
      self._headContent:addChild(sprite)
    end
end

function QUIWidgetHead:_onTriggerClick()
  self:dispatchEvent({name = QUIWidgetHead.EVENT_HERO_HEAD_CLICK , target = self})
end

return QUIWidgetHead