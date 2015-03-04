--
-- Author: Your Name
-- Date: 2014-06-05 11:13:26
--
local QItems = class("QItems")

local QStaticDatabase = import("..controllers.QStaticDatabase")
local QUIViewController = import("..ui.QUIViewController")

function QItems:ctor(options)
	self._items = {}
	self._rewards = {}
end

function QItems:setItems(items)
	for _,value in pairs(items) do
		if value.count == 0 then
        	self._items[value.type] = nil
		else
        	self._items[value.type] = value
    	end
    end
end

--[[
	根据item类型（配置表中的）获取物品
]]
function QItems:getItemsByType(itemType)
	local tbl = {}
	if itemType ~= nil then
		for key,value in pairs(self._items) do
			local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(value.type)
	        if itemInfo.type == itemType then
	        	table.insert(tbl, value)
	        end
	    end
	else
		tbl = clone(self._items)
	end
    return tbl
end

--获取物品数量 不检查合成材料
function QItems:getItemsNumByID(id)
	if id == nil then
		return 0
	end
	id = tonumber(id)
	for _,itemInfo in pairs(self._items) do
		if itemInfo.type == id then
			return itemInfo.count
		end
	end 
	return 0
end

function QItems:removeItemsByID(id, count)
	id = tonumber(id)
	for _,itemInfo in pairs(self._items) do
		if itemInfo.type == id then
			if (itemInfo.count - count) >= 0 then
				itemInfo.count = itemInfo.count - count
				return true
			else
				return false
			end
		end
	end 
	return false
end

--检查是否拥有指定ID和数量的物品 检查合成的材料
function QItems:getItemIsHaveNumByID(id,num)
	local isHave = false
	local isComposite = false
	if id == nil then 
		return isHave,isComposite
	end
	local haveNum = self:getItemsNumByID(id)
	if haveNum >= num then
		isHave = true
		return isHave,isComposite
	end
	local itemInfo = QStaticDatabase:sharedDatabase():getItemByID(id)
	if itemInfo == nil then
		return isHave,isComposite
	end
	local itemNeedNum = num - haveNum
	if itemInfo.smithereens_id ~= nil and itemInfo.smithereens_id ~= 0 then
		isComposite = true
		isHave = self:getItemIsHaveNumByID(itemInfo.smithereens_id,itemNeedNum * itemInfo.smithereens_num )
		return isHave,isComposite
	end
	return isHave,isComposite
end

--检查物品或者物品碎片是否可以打关卡掉落
function QItems:getItemIsCanDrop(id)
	local dropInfo = remote.instance:getDropInfoByItemId(id, DUNGEON_TYPE.ALL)
	for _,value in pairs(dropInfo) do
		if value.map.isLock == true then
			return true
		end
	end
	return false
end

-- 获取到物品或者英雄提示
function QItems:getRewardItemsTips(items,oldHeros,cost,againBack,tokenType,freeNum)
	local options = {}
	options.cost = cost
	options.againBack = againBack
	options.tokenType = tokenType
	options.freeNum = freeNum
	options.items = items
	options.oldHeros = oldHeros
	if #options.items > 1 then
		app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAchieveManyItem", 
			options=options}, {isPopCurrentDialog = false})
	else
		options.items[1].type = self:getItemType(options.items[1].type)
		if options.items[1].type == ITEM_TYPE.HERO then
			local callfunc = function ()
				local isHave = false
			    if options.oldHeros ~= nil then
			    	for _,actorId in pairs(options.oldHeros) do
			    		if actorId == options.items[1].id then
			    			isHave = true
			    			break
			    		end
			    	end
			    end
			    if isHave == true then
			    	local newOptions = clone(options)
					local config = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(newOptions.items[1].id , newOptions.items[1].grade or 0)
			    	newOptions.items[1].type = ITEM_TYPE.ITEM
			    	newOptions.items[1].id = config.soul_gem
			    	newOptions.items[1].count = config.soul_return_count
					app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAchieveItem", 
						options=newOptions}, {isPopCurrentDialog = false})
			    else
					app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAchieveHero", 
						options=options}, {isPopCurrentDialog = false})
			    end
			end
			app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAchieveCard", 
				options={actorId = options.items[1].id, isHave = isHave, data = options.items[1], callBack = callfunc}}, {isPopCurrentDialog = false})
		else
			app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogAchieveItem", 
				options=options}, {isPopCurrentDialog = false})
		end
	end
end

--将物品整理为出售的格式
function QItems:itemSort(items)
  if next(items) == nil then return end
  local sortItems = {}
  for k, value in pairs(items) do
  	table.insert(sortItems,{type = value.type, count = value.count})
  end
  return sortItems
end

--获取物品的类型
--为了统一各种配置不同为前端所用比如money，MONEY，1 均可以返回MONEY
function QItems:getItemType(type)
  	if type == "money" or type == "MONEY" then
  		return ITEM_TYPE.MONEY
  	end
  	if type == "token_money" or type == "TOKEN_MONEY" or type == "token" then
  		return ITEM_TYPE.TOKEN_MONEY
  	end
  	if type == "arena_money" or type == "ARENA_MONEY"then
      return ITEM_TYPE.ARENA_MONEY
    end
    if type == "sunwell_money" or type == "SUNWELL_MONEY"then
      return ITEM_TYPE.SUNWELL_MONEY
    end
  	if type == "energy" or type == "ENERGY" then
  		return ITEM_TYPE.ENERGY
  	end
  	if type == "item" or type == "ITEM" then
  		return ITEM_TYPE.ITEM
  	end
  	if type == "hero" or type == "HERO" then
  		return ITEM_TYPE.HERO
  	end
  	if type == "team_exp" or type == "TEAM_EXP" then
  		return ITEM_TYPE.TEAM_EXP
  	end
  	if type == "achieve_point" or type == "ACHIEVE_POINT" then
  		return ITEM_TYPE.ACHIEVE_POINT
  	end
end

--获取非物品的ICON URL
function QItems:getURLForItem(type, flag)
	type = self:getItemType(type)
	if type == ITEM_TYPE.MONEY then
		if flag ~= nil then
			return ICON_URL.ITEM_MONEY
		else
			return ICON_URL.MONEY
		end
	end
	if type == ITEM_TYPE.TOKEN_MONEY then
		if flag ~= nil then
			return ICON_URL.ITEM_TOKEN_MONEY
		else
			return ICON_URL.TOKEN_MONEY
		end
	end
	if type == ITEM_TYPE.ARENA_MONEY then
		if flag ~= nil then
			return ICON_URL.ITEM_ARENA_MONEY
		else
			return ICON_URL.ARENA_MONEY
		end
	end
	if type == ITEM_TYPE.ENERGY then
		return ICON_URL.ENERGY
	end
	if type == ITEM_TYPE.TEAM_EXP then
		return ICON_URL.TEAM_EXP
	end
	if type == ITEM_TYPE.ACHIEVE_POINT then
		return ICON_URL.ACHIEVE_POINT
	end
end

return QItems