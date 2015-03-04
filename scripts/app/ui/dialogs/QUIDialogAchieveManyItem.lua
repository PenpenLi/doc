--
-- Author: wkwang
-- Date: 2014-08-12 18:28:06
--
local QUIDialog = import(".QUIDialog")
local QUIDialogAchieveManyItem = class("QUIDialogAchieveManyItem", QUIDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QUIWidgetHeroInformation = import("..widgets.QUIWidgetHeroInformation")
local QUIDialogShowHeroAvatar = import("..dialogs.QUIDialogShowHeroAvatar")
local QNavigationController = import("...controllers.QNavigationController")
local QUIViewController = import("..QUIViewController")

function QUIDialogAchieveManyItem:ctor(options)
	local ccbFile = "ccb/Dialog_AchieveProp2.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerAgain", callback = handler(self, QUIDialogAchieveManyItem._onTriggerAgain)},
        {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogAchieveManyItem._onTriggerClose)},
    }
    QUIDialogAchieveManyItem.super.ctor(self, ccbFile, callBacks, options)

    self._isShow = false
    self.isAnimation = false

    self._ccbOwner.node_title_silver:setVisible(false)
    self._ccbOwner.node_title_normal:setVisible(false)
    self._ccbOwner.node_title_gold:setVisible(false)
    self._ccbOwner.node_buy:setVisible(false)
    self._ccbOwner.node_money:setVisible(false)
    self._ccbOwner.node_tokenMoney:setVisible(false)
    app.sound:playSound("common_award")
end

function QUIDialogAchieveManyItem:viewDidAppear()
    QUIDialogAchieveManyItem.super.viewDidAppear(self)
    self:initView()
    self.prompt = app:promptTips()
    self.prompt:addItemEventListener(self)
end
function QUIDialogAchieveManyItem:viewWillDisappear()
  QUIDialogAchieveManyItem.super.viewWillDisappear(self)
  self.prompt:removeItemEventListener()
end

function QUIDialogAchieveManyItem:initView()
    local options = self:getOptions()
    self._callBack = options.callBack
    self._againBack = options.againBack 

    self._ccbOwner.node_buy:setVisible(true)
    self._ccbOwner.tf_money:setString(options.cost)
        
    if options.tokenType == ITEM_TYPE.TOKEN_MONEY then
        self._ccbOwner.node_title_gold:setVisible(true)
        self._ccbOwner.node_tokenMoney:setVisible(true)
    elseif options.tokenType == ITEM_TYPE.MONEY then
        self._ccbOwner.node_title_silver:setVisible(true)
        self._ccbOwner.node_money:setVisible(true)
    else
        self._ccbOwner.node_title_normal:setVisible(true)
    end
    self._items = options.items
    self._index = 0
    
    self:showItems()
end

function QUIDialogAchieveManyItem:showItems()
	if #self._items > 0 then
		self._index = self._index + 1
		self._data = self._items[1]
        self._data.type = remote.items:getItemType(self._data.type)
		table.remove(self._items,1)

        --后台的坑 一次抽了两个一模一样的英雄
        local addHeros ={}

		if self._data.type == ITEM_TYPE.HERO then
            local options = self:getOptions()
            self._isHave = false
            if options.oldHeros ~= nil then
                for _,actorId in pairs(options.oldHeros) do
                    if actorId == self._data.id then
                        self._isHave = true
                        break
                    end
                end
                if self._isHave == false then
                    if addHeros[self._data.id] == nil then
                        addHeros[self._data.id] = true
                    else
                        self._isHave = true
                    end
                end
            end
			self:showHeroHandler()
		else
			self:showItemHandler()
		end
	else
		self._isShow = true
	end
end

function QUIDialogAchieveManyItem:showHeroHandler()
    app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAchieveCard", 
        options={actorId = self._data.id, isHave = self._isHave, data = self._data, callBack = handler(self, self._showCardEndHandler)}}, {isPopCurrentDialog = false})
end

function QUIDialogAchieveManyItem:_showCardEndHandler()
    if self._isHave == false then
        app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogShowHeroAvatar", 
            options= {actorId = self._data.id, tokenType = ITEM_TYPE.TOKEN_MONEY, callBack = handler(self, self._showHeroEndHandler)}}, {isPopCurrentDialog = false})
    else
        local config = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(self._data.id , self._data.grade or 0)
        self._data.type = ITEM_TYPE.ITEM
        self._data.id = config.soul_gem
        self._data.count = config.soul_return_count
        self:_showHeroEndHandler()
    end
end

function QUIDialogAchieveManyItem:_showHeroEndHandler()
	if self._data ~= nil then
		self:showItemHandler()
	end
end

function QUIDialogAchieveManyItem:showItemHandler()
	local item = QUIWidgetItemsBox.new()
	item:resetAll()
	item:setGoodsInfo(self._data.id,self._data.type,self._data.count)
    item:showEffect()
	item:setVisible(true)
	item:setPromptIsOpen(true)
	self._data = nil
	self._ccbOwner.item_contain:addChild(item)
	local posX,posY = self._ccbOwner["node"..self._index]:getPosition()
	self:_nodeRunAction(item,posX,posY)
end

-- 移动到指定位置
function QUIDialogAchieveManyItem:_nodeRunAction(node,posX,posY)
    self._isMove = true
    local actionArrayIn = CCArray:create()
    actionArrayIn:addObject(CCMoveBy:create(0.3, ccp(posX,posY)))
    actionArrayIn:addObject(CCCallFunc:create(function () 
                                                self:showItems()
                                            end))
    local ccsequence = CCSequence:create(actionArrayIn)
    self._actionHandler = node:runAction(ccsequence)
end

function QUIDialogAchieveManyItem:_backClickHandler()
	if self._isShow == false then return end
--    self:_onTriggerClose()
end

function QUIDialogAchieveManyItem:_onTriggerAgain()
	if self._isShow == false then return end
    self:_onTriggerClose()
    if self._againBack ~= nil then
    	self._againBack()
    end
end

function QUIDialogAchieveManyItem:_onTriggerClose()
  self:checkGuid()
	if self._isShow == false then return end
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    if self._callBack ~= nil then
        self._callBack()
    end
end

function QUIDialogAchieveManyItem:checkGuid()
  if app.tutorial:isTutorialFinished() == false then
    local page = app:getNavigationController():getTopPage()
    page:checkGuiad()
  end
end

return QUIDialogAchieveManyItem