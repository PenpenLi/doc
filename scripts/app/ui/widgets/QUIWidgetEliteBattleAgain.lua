--
-- Author: wkwang
-- Date: 2014-07-14 15:41:41
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetEliteBattleAgain = class("QUIWidgetEliteBattleAgain", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetEliteBattleAgain:ctor(options)
	local ccbFile = "ccb/Widget_EliteBattleAgain.ccbi"
	local callbacks = {}
	--设置该节点启用enter事件
	self:setNodeEventEnabled(true)
	QUIWidgetEliteBattleAgain.super.ctor(self, ccbFile, callbacks, options)

	self._itemsBox = {}
	self._ccbOwner.tf_exp:setString("+0")
	self._ccbOwner.tf_money:setString("+0")
	--设置动画时长
	self._animationTime = 0.5
	self._showItemsTime = 0.5
	self._isShow = false

	self._moneyTotal = 0
	self._expTotal = 0

	self._ccbOwner.tf_tips:setVisible(false)
end

function QUIWidgetEliteBattleAgain:getHeight()
	return self._ccbOwner.node_size:getContentSize().height
end

function QUIWidgetEliteBattleAgain:getWidth()
	return self._ccbOwner.node_size:getContentSize().width
end

function QUIWidgetEliteBattleAgain:setTitle(n)
	if n == 1 then
		self._ccbOwner.tf_count:setString("第1次")
	elseif n ==2 then
		self._ccbOwner.tf_count:setString("第2次")
	elseif n ==3 then
		self._ccbOwner.tf_count:setString("第3次")
	elseif n ==4 then
		self._ccbOwner.tf_count:setString("第4次")
	elseif n ==5 then
		self._ccbOwner.tf_count:setString("第5次")
	elseif n ==6 then
		self._ccbOwner.tf_count:setString("第6次")
	elseif n ==7 then
		self._ccbOwner.tf_count:setString("第7次")
	elseif n ==8 then
		self._ccbOwner.tf_count:setString("第8次")
	elseif n ==9 then
		self._ccbOwner.tf_count:setString("第9次")
	elseif n ==10 then
		self._ccbOwner.tf_count:setString("第10次")
	end
end

function QUIWidgetEliteBattleAgain:setTitleExtra()
	self._ccbOwner.tf_count:setString("额外奖励")

	self._ccbOwner.sprite_exp:setVisible(false)
	self._ccbOwner.tf_exp:setVisible(false)
	self._ccbOwner.sprite_icon:setVisible(false)
	self._ccbOwner.tf_money:setVisible(false)

	self._ccbOwner.tf_tips:setPositionY(self._ccbOwner.tf_tips:getPositionY() + 50)
	self._ccbOwner.goods1:setPositionY(self._ccbOwner.goods1:getPositionY() + 50)
	self._ccbOwner.goods2:setPositionY(self._ccbOwner.goods2:getPositionY() + 50)
	self._ccbOwner.goods3:setPositionY(self._ccbOwner.goods3:getPositionY() + 50)
	self._ccbOwner.goods4:setPositionY(self._ccbOwner.goods4:getPositionY() + 50)
	self._ccbOwner.goods5:setPositionY(self._ccbOwner.goods5:getPositionY() + 50)
	self._ccbOwner.goods6:setPositionY(self._ccbOwner.goods6:getPositionY() + 50)
end

function QUIWidgetEliteBattleAgain:setInfo(info)
	local awards = {}
	if info ~= nil then
	  	for _, value in pairs(info) do 
	  		local id = value.id
	  		if id == nil then
	  			id = "type"..value.type
	  		end
	  	 	if awards[id] == nil then
	  	 		awards[id] = value
	  	 	else
	  	 		awards[id].count = awards[id].count + value.count
	  	 	end
	  	end
	end
	local config = QStaticDatabase:sharedDatabase():getConfig()
	for _,value in pairs(awards) do
		local typeName = remote.items:getItemType(value.type)
		if typeName == ITEM_TYPE.ITEM then
			local index = #self._itemsBox + 1
			local item = QUIWidgetItemsBox.new({ccb = "small"})
			self._itemsBox[index] = item
			item:setGoodsInfo(value.id,ITEM_TYPE.ITEM,value.count)
			self._ccbOwner["goods"..index]:addChild(item)
			item:setVisible(false)
  			local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(value.id)
		elseif typeName == ITEM_TYPE.HERO then
			local index = #self._itemsBox + 1
			local item = QUIWidgetItemsBox.new({ccb = "small"})
			self._itemsBox[index] = item
			item:setGoodsInfo(value.id,ITEM_TYPE.HERO,value.count)
			self._ccbOwner["goods"..index]:addChild(item)
			item:setVisible(false)
	    	local heroDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(value.id)
		elseif typeName == ITEM_TYPE.MONEY then
			self._moneyTotal = value.count
			self._ccbOwner.tf_money:setString("+"..tostring(self._moneyTotal))
		elseif typeName == ITEM_TYPE.TEAM_EXP then
			self._expTotal = value.count
			self._ccbOwner.tf_exp:setString("+"..tostring(self._expTotal))
		end
	end
end

function QUIWidgetEliteBattleAgain:startAnimation(callFunc)
	self._animationEndCallback = callFunc
	local animationProxy = QCCBAnimationProxy:create()
    animationProxy:retain()
    local animationManager = tolua.cast(self:getCCBView():getUserObject(), "CCBAnimationManager")
    animationManager:runAnimationsForSequenceNamed("TitleExperienceAndMoney")
    animationProxy:connectAnimationEventSignal(animationManager, function(animationName)
        animationProxy:disconnectAnimationEventSignal()
        animationProxy:release()
        self:_startPlayItemAnimation()
    end)
end

function QUIWidgetEliteBattleAgain:_startPlayItemAnimation()
	if #self._itemsBox == 0 then
		self._ccbOwner.tf_tips:setVisible(true)
		if self._animationEndCallback ~= nil then
			self._animationEndCallback()
		end
	else
		self:_playItemAnimation(1)
	end
end

function QUIWidgetEliteBattleAgain:_playItemAnimation(index)
	if #self._itemsBox < index then
		if self._animationEndCallback ~= nil then
			self._animationEndCallback()
		end
	else
		local widgetItem = self._itemsBox[index]
		widgetItem:setVisible(true)
		widgetItem:setScaleX(0)
		widgetItem:setScaleY(0)
	    local actionArrayIn = CCArray:create()
        actionArrayIn:addObject(CCEaseBackInOut:create(CCScaleTo:create(0.23, 1, 1)))
        actionArrayIn:addObject(CCCallFunc:create(function ()
	        self:_playItemAnimation(index + 1)
        end))
	    local ccsequence = CCSequence:create(actionArrayIn)
		local handler = widgetItem:runAction(ccsequence)
	end
end

return QUIWidgetEliteBattleAgain