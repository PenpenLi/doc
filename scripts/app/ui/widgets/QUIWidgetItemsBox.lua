--
-- Author: Your Name
-- Date: 2014-07-10 18:54:20
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetItemsBox = class("QUIWidgetItemsBox", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIViewController = import("..QUIViewController")
local QUIWidgetItmePrompt = import(".QUIWidgetItmePrompt") 
local QNotificationCenter = import("...controllers.QNotificationCenter")

QUIWidgetItemsBox.EVENT_CLICK = "EVENT_CLICK"
QUIWidgetItemsBox.EVENT_BEGAIN = "ITEM_EVENT_BEGAIN"
QUIWidgetItemsBox.EVENT_END = "ITEM_EVENT_END"

function QUIWidgetItemsBox:ctor(options)
	local ccbFile = "ccb/Widget_ItemBox.ccbi"
	-- if options~=nil and options.ccb ~= nil and options.ccb == "small" then
	-- 	ccbFile = "ccb/Widget_prop.ccbi"
	-- end
	local callBacks = {
--        {ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetItemsBox._onTriggerClick)},
    }
	QUIWidgetItemsBox.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    self:setNodeVisible(self._ccbOwner.node_goods,true)
    self:setTFText(self._ccbOwner.tf_goods_num,"")
    self:setNodeVisible(self._ccbOwner.node_mask,false)
    self:resetAll()
    self:setColor("normal")
    self.promptTipIsOpen = false
end

function QUIWidgetItemsBox:setPromptIsOpen(value)
  self.promptTipIsOpen = value
end

function QUIWidgetItemsBox:getName()
	return "QUIWidgetItemsBox"
end

function QUIWidgetItemsBox:hideAllColor()
    self:setNodeVisible(self._ccbOwner.node_green,false)
    self:setNodeVisible(self._ccbOwner.node_blue,false)
    self:setNodeVisible(self._ccbOwner.node_orange,false)
    self:setNodeVisible(self._ccbOwner.node_purple,false)
    self:setNodeVisible(self._ccbOwner.node_white,false)
end

function QUIWidgetItemsBox:resetAll()
	self:hideAllColor()
    self:setNodeVisible(self._ccbOwner.icon,false)
    self:setTFText(self._ccbOwner.tf_goods_num,"")
    self._ccbOwner.node_scrap:setVisible(false)
    self._ccbOwner.node_soul:setVisible(false)
    self._ccbOwner.node_scrap_green:setVisible(false)
    self._ccbOwner.node_scrap_blue:setVisible(false)
    self._ccbOwner.node_scrap_purple:setVisible(false)
    -- self._ccbOwner.bule_light:setVisible(false)
    -- self._ccbOwner.orange_light:setVisible(false)
    -- self._ccbOwner.purple_light:setVisible(false)
end

function QUIWidgetItemsBox:getContentSize()
	return self._ccbOwner.sprite_back:getContentSize()
end

function QUIWidgetItemsBox:onEnter()
  self._ccbOwner.sprite_back:setTouchEnabled(true)
  self._ccbOwner.sprite_back:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
  self._ccbOwner.sprite_back:setTouchSwallowEnabled(false)
  self._ccbOwner.sprite_back:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIWidgetItemsBox._onTouch))
end

function QUIWidgetItemsBox:onExit()
  self._ccbOwner.sprite_back:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
  	if self._light ~= nil then
  		self._light:removeFromParentAndCleanup(true)
  		self._light = nil
  	end
    if self._signInLight ~= nil then
      self._signInLight:removeFromParentAndCleanup(true)
      self._signInLight = nil
    end
end

function QUIWidgetItemsBox:setBoxScale(scale)
  if scale == nil then return end
  self._ccbOwner.node_box:setScale(scale)
end

function QUIWidgetItemsBox:setColor(name)
	self:hideAllColor()
	if name ~= nil then
    	self:setNodeVisible(self._ccbOwner["node_"..name],true)
    else
    	printInfo("item id : "..self._itemID.." color name is nil!")
    	self:setNodeVisible(self._ccbOwner["node_normal"],true)
    end
end

function QUIWidgetItemsBox:showEffect()
	if self._itemType == ITEM_TYPE.ITEM then
		local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(self._itemID)
		if itemInfo.colour == 3 then
			self._light = CCBuilderReaderLoad("Widget_AchieveHero_light_blue.ccbi", CCBProxy:create(), {})
		elseif itemInfo.colour == 4 then
			self._light = CCBuilderReaderLoad("Widget_AchieveHero_light_purple.ccbi", CCBProxy:create(), {})
		elseif itemInfo.colour == 5 then
			self._light = CCBuilderReaderLoad("Widget_AchieveHero_light_orange.ccbi", CCBProxy:create(), {})
		end
	end
	if self._itemType == ITEM_TYPE.HERO then
		self._light = CCBuilderReaderLoad("Widget_AchieveHero_light_orange.ccbi", CCBProxy:create(), {})
	end
	if self._light ~= nil then
		self._ccbOwner.node_light:addChild(self._light)
	end
end

--显示签到光效
function QUIWidgetItemsBox:showSignInBoxEffect(state)
  if state == true then
    self._signInLight = CCBuilderReaderLoad("effects/leiji_light.ccbi", CCBProxy:create(), {})
    self._ccbOwner.node_sign_light:addChild(self._signInLight)
  elseif state == false then
    if self._signInLight ~= nil then
      self._signInLight:removeFromParent()
      self._signInLight = nil
    end
  end
end

function QUIWidgetItemsBox:setGoodsInfo(itemID, itemType, goodsNum, froceShow)
	self._itemID = itemID
	self._itemType = remote.items:getItemType(itemType)
	if self._itemType == ITEM_TYPE.MONEY then
		self:_setItemInfo(ICON_URL.ITEM_MONEY, goodsNum, froceShow)
	elseif self._itemType == ITEM_TYPE.TOKEN_MONEY then
		self:_setItemInfo(ICON_URL.ITEM_TOKEN_MONEY, goodsNum, froceShow)
	elseif self._itemType == ITEM_TYPE.ARENA_MONEY then
    self:_setItemInfo(ICON_URL.ITEM_ARENA_MONEY, goodsNum, froceShow)
  elseif self._itemType == ITEM_TYPE.SUNWELL_MONEY then
    self:_setItemInfo(ICON_URL.SUNWELL_MONEY, goodsNum, froceShow)
	elseif self._itemType == ITEM_TYPE.ITEM then
  		self:_showIsItem(itemID, goodsNum, froceShow)
	elseif self._itemType == ITEM_TYPE.HERO then
	    local heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(itemID)
	    if nil ~= heroDisplay then 
			self:_setItemInfo(heroDisplay.icon, goodsNum, froceShow)
	    end
	end
end

function QUIWidgetItemsBox:_showIsItem(itemID, goodsNum, froceShow)
	local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(itemID)
	if itemInfo.type == ITEM_CATEGORY.SCRAP or itemInfo.type == ITEM_CATEGORY.SOUL then
		self._ccbOwner.node_scrap:setVisible(true)
		if self._ccbOwner["node_scrap_"..EQUIPMENT_QUALITY[itemInfo.colour]] ~= nil then
			self._ccbOwner["node_scrap_"..EQUIPMENT_QUALITY[itemInfo.colour]]:setVisible(true)
		end
		if itemInfo.type == ITEM_CATEGORY.SOUL then
			self._ccbOwner.node_soul:setVisible(true)
		end
	end
	self:_setItemInfo(itemInfo.icon, goodsNum, froceShow)
	self:setColor(EQUIPMENT_QUALITY[itemInfo.colour])
end

function QUIWidgetItemsBox:_setItemInfo(respath, goodsNum, froceShow)
  	if respath ~= nil then
  		self:setItemIcon(respath)
  	end
  	if froceShow == nil then froceShow = false end
  	if goodsNum > 0 or froceShow == true then
    	self:setTFText(self._ccbOwner.tf_goods_num,goodsNum)
    else
    	self:setTFText(self._ccbOwner.tf_goods_num,"")
  	end
end

function QUIWidgetItemsBox:setItemIcon(respath)
	if respath~=nil and #respath > 0 then
		if self.icon == nil then
			self.icon = CCSprite:create()
			self._ccbOwner.node_icon:addChild(self.icon)
		end

		if self.clipNode == nil then
			self.clipNode = CCClippingNode:create()
			self.clipNode:setAlphaThreshold(0.5)
			local mask = self._ccbOwner.node_mask_scrap
			mask:retain()
			mask:removeFromParent()
			self.clipNode:setStencil(mask)
			mask:release()
			self._ccbOwner.node_icon:addChild(self.clipNode)
		end

		self.icon:retain()
		self.icon:removeFromParent()
		if self._ccbOwner.node_scrap:isVisible() then
			self.clipNode:addChild(self.icon)
			self.icon:release()
			self._ccbOwner.node_bar:setVisible(false)
			self._ccbOwner.node_bj:setVisible(false)
			self._ccbOwner.node_scrap_bj:setVisible(true)
		else
			self._ccbOwner.node_icon:addChild(self.icon)
			self.icon:release()
			self._ccbOwner.node_bar:setVisible(true)
			self._ccbOwner.node_bj:setVisible(true)
			self._ccbOwner.node_scrap_bj:setVisible(false)
		end

		self.icon:setVisible(true)
		self.icon:setScale(1)
		self.icon:setTexture(CCTextureCache:sharedTextureCache():addImage(respath))

		local size = self.icon:getContentSize()
		local size2 = self._ccbOwner.node_mask:getContentSize()
		local scaleX = self._ccbOwner.node_mask:getScaleX()
		local scaleY = self._ccbOwner.node_mask:getScaleY()

		if size.width > size2.width then
			self.icon:setScaleX(size2.width * scaleX/size.width)
		end
		if size.height > size2.height then
			self.icon:setScaleY(size2.height * scaleY/size.height)
		end
	end
end

function QUIWidgetItemsBox:setNodeVisible(node,b)
	if node ~= nil then
		node:setVisible(b)
	end
end

function QUIWidgetItemsBox:setTFText(node,str)
	if node ~= nil then
		node:setString(str)
	end
end

function QUIWidgetItemsBox:_onTouch(event)
  if event.name == "began" then 
    if self.promptTipIsOpen ~= false then
      QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetItemsBox.EVENT_BEGAIN , eventTarget = self, itemID=self._itemID, itmeType = self._itemType})
    end
    return true
  elseif event.name == "ended" or event.name == "cancelled" then 
  if self.promptTipIsOpen ~= false then
   QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetItemsBox.EVENT_END , eventTarget = self})
  end
    self:_onTriggerClick()
    return true
  end
end

function QUIWidgetItemsBox:_onTriggerClick()
	QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetItemsBox.EVENT_CLICK , itemID = self._itemID})
end

return QUIWidgetItemsBox