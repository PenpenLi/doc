--
-- Author: wkwang
-- Date: 2014-09-15 14:21:35
-- 用于CCBI文件的缓存
--
local QWidgetCacheUtils = class("QWidgetCacheUtils")

function QWidgetCacheUtils:ctor()
	self._widgetCaches = {}
	self:_prepareCacheList()
end

function QWidgetCacheUtils:_prepareCacheList()
	self._widgetList = {}

    --添加预先加载好的CCB
    -- self:addWidgetCache("QUIWidgetInstanceNormalBoss",5)
    -- self:addWidgetCache("QUIWidgetInstanceEliteBoss",5)
    -- self:addWidgetCache("QUIWidgetInstanceNormalMonster",10)
    -- self:addWidgetCache("QUIWidgetInstanceEliteMonster",10)
    --cache英雄
    -- self:addWidgetCache("QUIWidgetHeroFrame",20)
    -- self:addWidgetCache("QUIWidgetHeroSmallFrame",12)
    --cache装备格子
    -- self:addWidgetCache("QUIWidgetEquipmentBox",6)
    --cache物品格子
    -- self:addWidgetCache("QUIWidgetItemsBox",16)
    -- self:addWidgetCache("QUIWidgetDailySignInBox",31)
    -- self:addWidgetCache("QUIWidgetRewardRulesReward",10)
end

--[[
	加载之前先push进list
]]
function QWidgetCacheUtils:addWidgetCache(name, num, options)
	if num == nil then
		num = 1
	end
	table.insert(self._widgetList,{name = name, options = options, num = num})
end

--[[
	开始加载list中的对象
]]
function QWidgetCacheUtils:cacheWidgetForList(progressFun)
	self._progressFun = progressFun
	self._totalCount = 0
	for _,value in pairs(self._widgetList) do
		self._totalCount = self._totalCount + value.num
	end
	self._currentCount = 0
	if self._totalCount == 0 then
		self._progressFun(1)
		self._progressFun = nil
	else
		self._progressFun(0)
		self:_loadWidgetForList()
	end
end

function QWidgetCacheUtils:_loadWidgetForList()
	if #self._widgetList > 0 then
		self:cacheWidget(self._widgetList[1])
		self._currentCount = self._currentCount + 1
		self._progressFun(self._currentCount/self._totalCount)
		if self._widgetList[1].num < 2 then
			table.remove(self._widgetList,1)
		else
			self._widgetList[1].num = self._widgetList[1].num - 1
		end
	end
	-- if #self._widgetList > 0 then
	-- 	self:cacheWidget(self._widgetList[1])
	-- 	self._currentCount = self._currentCount + 1
	-- 	self._progressFun(self._currentCount/self._totalCount)
	-- 	if self._widgetList[1].num < 2 then
	-- 		table.remove(self._widgetList,1)
	-- 	else
	-- 		self._widgetList[1].num = self._widgetList[1].num - 1
	-- 	end
	-- end
	if self._currentCount < self._totalCount then
		scheduler.performWithDelayGlobal(handler(self, self._loadWidgetForList),0)
	else
		self._progressFun = nil
	end
end

function QWidgetCacheUtils:cacheWidget(data)
	local name = data.name
	local options = data.options
    local widget = self:initWidgetForName(name, options)
    self:setWidgetForName(widget,name)
end

function QWidgetCacheUtils:initWidgetForName(name, options)
	local controllerClass = import(app.packageRoot .. ".ui.widgets." .. name)
	local widget = controllerClass.new(options)
	return widget
end

function QWidgetCacheUtils:getWidgetForName(name,parent)
	local widget 
	if self._widgetCaches[name] == nil or #self._widgetCaches[name] == 0 then
    	widget = self:initWidgetForName(name, options)
		widget:retain()
	else
		widget = self._widgetCaches[name][1]
		table.remove(self._widgetCaches[name],1)
	end
	parent:addChild(widget)
	widget:release()
	return widget
end

function QWidgetCacheUtils:setWidgetForName(widget,name)
	widget:retain()
	widget:removeFromParentAndCleanup(false)
	if self._widgetCaches[name] == nil then
		self._widgetCaches[name] = {}
	end
	table.insert(self._widgetCaches[name],widget)
end

function QWidgetCacheUtils:purgeWidgetCache()
	for _, widgets in pairs(self._widgetCaches) do
		for _, widget in ipairs(widgets) do
			widget:release()
		end
	end
	self._widgetCaches = {}
end

function QWidgetCacheUtils:reloadCache(progressFun)
	self:_prepareCacheList()
	self:cacheWidgetForList(progressFun)
end

return QWidgetCacheUtils