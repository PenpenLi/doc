--
-- Author: wkwang
-- Date: 2014-10-13 18:02:20
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroUpgradeCell = class("QUIWidgetHeroUpgradeCell", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QUIWidgetAnimationPlayer = import("..widgets.QUIWidgetAnimationPlayer")
local QHerosUtils = import("...utils.QHerosUtils")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")

QUIWidgetHeroUpgradeCell.CLICK_NONE = "CLICK_NONE"
QUIWidgetHeroUpgradeCell.CLICK_DOWN = "CLICK_DOWN"

function QUIWidgetHeroUpgradeCell:ctor(options)
	local ccbFile = "ccb/Widget_HeroUpgrade_client.ccbi"
	local callBacks = {
        {ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetHeroUpgradeCell._onTriggerClick)},
    }
	QUIWidgetHeroUpgradeCell.super.ctor(self, ccbFile, callBacks, options)    
	self._isMove = false -- 是否移动 在开始连续吃卡前终止
	self._isEating = false -- 是否在连续吃卡
	self._eatNum = 0
	local page = app:getNavigationController():getTopPage()
	self._eatEffectLayer = CCNode:create()
	page:getView():addChild(self._eatEffectLayer)
	self._numEffectLayer = CCNode:create()
	page:getView():addChild(self._numEffectLayer)
end

function QUIWidgetHeroUpgradeCell:onEnter()
	self._isEnter = true
    self._heroProxy = cc.EventProxy.new(remote.herosUtil)
    self._heroProxy:addEventListener(QHerosUtils.EVENT_HERO_EXP_CHECK, handler(self, self._saveExp))
end

function QUIWidgetHeroUpgradeCell:onExit()
	self._isEnter = false
	self:_saveExp()
	self._eatEffectLayer:removeFromParentAndCleanup(true)
	self._numEffectLayer:removeFromParentAndCleanup(true)
	self._heroProxy:removeAllEventListeners()
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end
	self._itemEffectTexture:release()
end

function QUIWidgetHeroUpgradeCell:getContentSize()
	return self._ccbOwner.node_bg:getContentSize()
end

function QUIWidgetHeroUpgradeCell:setTargetPosition(p)
	self._targetPosition = p
end

function QUIWidgetHeroUpgradeCell:setInfo(value, actorId)
	self._item = value
	self._actorId = actorId
	self._ccbOwner.tf_exp:setString(self._item.exp)

	self._ccbOwner.node_icon:removeAllChildren()
	local itemBox = QUIWidgetItemsBox.new()
	itemBox:setGoodsInfo(self._item.id, ITEM_TYPE.ITEM, 0)
	self._ccbOwner.node_icon:addChild(itemBox)
	self:updateItemNum()

	self._itemTexture = CCTextureCache:sharedTextureCache():addImage(self._item.icon)
	self._itemEffectTexture = CCTextureCache:sharedTextureCache():addImage(ICON_URL["ITEM_ID_"..self._item.id])
	self._itemEffectTexture:retain()
end

function QUIWidgetHeroUpgradeCell:updateItemNum()
	local itemNum = remote.items:getItemsNumByID(self._item.id)
	self._ccbOwner.tf_num:setString(itemNum)
	if itemNum == 0 then
		makeNodeFromNormalToGray(self._ccbOwner.node_icon)
		self._ccbOwner.node_btn:setEnabled(false)
	end
end

function QUIWidgetHeroUpgradeCell:_onTriggerClick(event)
	printInfo(event, CCControlEventTouchDown)
	if tonumber(event) == CCControlEventTouchDown then
		self:_onDownHandler()
	else
		self:_onUpHandler()
	end
end

function QUIWidgetHeroUpgradeCell:setIsMove(b)
	self._isMove = b
end

function QUIWidgetHeroUpgradeCell:_onDownHandler()
	self._ccbOwner.node_select:setVisible(true)
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end
	-- 延时一秒 如果一秒内未up或者移动则连续吃经验
	self._timeHandler = scheduler.performWithDelayGlobal(handler(self, self._eatExpItemsForEach), 1)
end

function QUIWidgetHeroUpgradeCell:_onUpHandler()
	if self._ccbOwner.node_select:isVisible() == false then
		return 
	end
	self._ccbOwner.node_select:setVisible(false)
	self._isMove = false
	if self._timeHandler ~= nil then
		scheduler.unscheduleGlobal(self._timeHandler)
		self._timeHandler = nil
	end
	if self._isEating == false then
		self:_eatExpItem()
	else
		self._isEating = false
	end
end

function QUIWidgetHeroUpgradeCell:_eatExpItemsForEach()
	scheduler.unscheduleGlobal(self._timeHandler)
	self._timeHandler = nil
	if self._isMove == false then
		self._isEating = true
		self._timeHandler = scheduler.performWithDelayGlobal(handler(self, self._eatExpItem), 0.2)
	end
end

function QUIWidgetHeroUpgradeCell:_eatExpItem()
	if remote.items:getItemsNumByID(self._item.id) > 0 then
		if remote.herosUtil:heroCanUpgrade(self._actorId) == true then
			remote.herosUtil:heroEatExp(self._item.exp, self._actorId)
			self:addEatNum()
			self:_showEatNum()
			self:updateItemNum()
			self:_showEffect()
			if self._isEating == true then
				self._timeHandler = scheduler.performWithDelayGlobal(handler(self, self._eatExpItem), 0.2)
			end
		else
		  app.tip:floatTip("英雄等级不能超过战队等级")
--		app:alert({content = "英雄等级不能超过战队等级", title = "系统提示", callBack=nil,comfirmBack=nil}, false)
		end
	else
		--失败
	end
end

--[[
	1.5秒之内不添加新的经验道具 则保存到后台
]]
function QUIWidgetHeroUpgradeCell:addEatNum()
	if remote.items:removeItemsByID(self._item.id, 1) == false then
		return false
	end
	self._eatNum = self._eatNum + 1
	-- remote.herosUtil:setExpItemsForHero(self._actorId, self._item.id) 备用的一种方式
	-- if self._saveHandler ~= nil then
	-- 	scheduler.unscheduleGlobal(self._saveHandler)
	-- end
	-- self._saveHandler = scheduler.performWithDelayGlobal(handler(self, self._saveExp), 1.5)
	return true
end

--[[
	保存吃卡数据到后台
]]
function QUIWidgetHeroUpgradeCell:_saveExp()
	if self._eatNum > 0 then
		app:getClient():intensify(self._actorId, self._item.id, self._eatNum, function()
		end)
		self._eatNum = 0
	end
end

function QUIWidgetHeroUpgradeCell:_showEatNum()
	if self._numEffect == nil then
		self._numEffect = QUIWidgetAnimationPlayer.new()
		local p = self._ccbOwner.node_eat_num:convertToWorldSpaceAR(ccp(0,0))
		self._numEffect:setPosition(p.x, p.y)
		self._numEffectLayer:addChild(self._numEffect)
	end
	self._numEffect:playAnimation("ccb/Widget_Upgarde_tips.ccbi", function(ccbOwner)
				ccbOwner.tf_num:setString("×"..self._eatNum)
            end)
	-- if self._effectHandler ~= nil then
	-- 	self._ccbOwner.tf_eat_num:stopAction(self._effectHandler)
	-- 	self._effectHandler = nil
	-- end
	-- self._ccbOwner.tf_eat_num:setString("x "..self._eatNum)
	-- self._ccbOwner.tf_eat_num:setOpacity(255)
	-- self._ccbOwner.tf_eat_num:setScale(1)
	-- local arr = CCArray:create()
	-- arr:addObject(CCScaleTo:create(0.2, 1.2))
	-- arr:addObject(CCScaleTo:create(0.6, 1))
	-- arr:addObject(CCCallFunc:create(function()
	-- 	self._ccbOwner.tf_eat_num:setOpacity(0)
	-- 	self._effectHandler = nil
	-- 	end))
	-- local seq = CCSequence:create(arr)
	-- self._effectHandler = self._ccbOwner.tf_eat_num:runAction(seq)
end

function QUIWidgetHeroUpgradeCell:_showEffect(callBack)
	if self._targetPosition == nil then return end
	local effectFun1 = function ()
		if self._isEnter == nil or self._isEnter == false then return end
    	local effect = QUIWidgetAnimationPlayer.new()
    	effect:setPosition(self._targetPosition.x, self._targetPosition.y)
    	self._eatEffectLayer:addChild(effect)
    	effect:playAnimation("ccb/effects/UseItem2.ccbi", nil, function()
                effect:removeFromParentAndCleanup(true)
				if self._isEnter == nil or self._isEnter == false then return end
                if callBack ~= nil then callBack() end
            end)
	end
	local effectFun2 = function ()
		if self._isEnter == nil or self._isEnter == false then return end
		local icon = CCSprite:create()
		icon:setTexture(self._itemEffectTexture)
		local p = self._ccbOwner.node_icon:convertToWorldSpaceAR(ccp(0,0))
		icon:setPosition(p.x, p.y)
		self._eatEffectLayer:addChild(icon)
		local arr = CCArray:create()
		arr:addObject(CCMoveTo:create(0.2, self._targetPosition))
		arr:addObject(CCCallFunc:create(function()
				icon:removeFromParentAndCleanup(true)
				effectFun1()
			end))
		local seq = CCSequence:create(arr)
		icon:runAction(seq)
	end
	local effectFun3 = function ()
		if self._isEnter == nil or self._isEnter == false then return end
		local effect = QUIWidgetAnimationPlayer.new()
		local p = self._ccbOwner.node_icon:convertToWorldSpaceAR(ccp(0,0))
    	effect:setPosition(p.x, p.y)
    	self._eatEffectLayer:addChild(effect)
    	effect:playAnimation("ccb/effects/UseItem.ccbi", function(ccbOwner)
    			ccbOwner.node_icon:setTexture(self._itemEffectTexture)
    		end, function()
                effect:removeFromParentAndCleanup(true)
            end)
	end
	effectFun3()
	scheduler.performWithDelayGlobal(effectFun2, 0.1)
end

return QUIWidgetHeroUpgradeCell