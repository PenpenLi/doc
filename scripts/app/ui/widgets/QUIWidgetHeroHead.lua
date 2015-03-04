
local QUIWidget = import(".QUIWidget")
local QUIWidgetHeroHead = class("QUIWidgetHeroHead", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroHeadStar = import(".QUIWidgetHeroHeadStar")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QCircleUiMask = import("..battle.QCircleUiMask")

QUIWidgetHeroHead.EVENT_HERO_HEAD_CLICK = "EVENT_HERO_HEAD_CLICK"

function QUIWidgetHeroHead:ctor(options)
	local ccbFile = "ccb/Widget_HeroHeadBox.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerTouch", callback = handler(self, QUIWidgetHeroHead._onTriggerTouch)},
		}
	QUIWidgetHeroHead.super.ctor(self,ccbFile,callBacks,options)
	
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    self:resetAll()
end

function QUIWidgetHeroHead:setHeadScale(v)
	self:getView():setScale(v)
end

function QUIWidgetHeroHead:getHeroId()
	return self._actorId
end

function QUIWidgetHeroHead:resetAll()
	self._ccbOwner.node_hero_image:setVisible(false)
	self._ccbOwner.node_hero_star:setVisible(false)
	self._ccbOwner.node_hero_level:setString("")
	self:setLevelVisible(false)
end

function QUIWidgetHeroHead:setHero(actorId, level)
	self._actorId = actorId

	-- 设置英雄头像
	local characherDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self._actorId)
	if characherDisplay.icon ~= nil then
		local headImageTexture =CCTextureCache:sharedTextureCache():addImage(characherDisplay.icon)
		self._ccbOwner.node_hero_image:setTexture(headImageTexture)
	    self._size = headImageTexture:getContentSize()
	   local rect = CCRectMake(0, 0, self._size.width, self._size.height)
	   self._ccbOwner.node_hero_image:setTextureRect(rect)
		self._ccbOwner.node_hero_image:setVisible(true)
	end
	 
	self:setLevel(level)
	
	local heroInfo = remote.herosUtil:getHeroByID(self._actorId)
	local breakthrough = (heroInfo and heroInfo.breakthrough) or 0
	self:setBreakthrough(breakthrough)
end

-- Set hero avatar by file name @qinyuanji
function QUIWidgetHeroHead:setHeroByFile(avatarFile)
	-- 设置英雄头像
	if avatarFile ~= nil then
		self._avatarFile = avatarFile
		local headImageTexture =CCTextureCache:sharedTextureCache():addImage(avatarFile)
		self._ccbOwner.node_hero_image:setTexture(headImageTexture)
	    self._size = headImageTexture:getContentSize()
	    local rect = CCRectMake(0, 0, self._size.width, self._size.height)
	    self._ccbOwner.node_hero_image:setTextureRect(rect)
		self._ccbOwner.node_hero_image:setVisible(true)
	end
end

--设置CD显示
function QUIWidgetHeroHead:updateCD(num)
	if self._cd == nil then
		local sprite = CCSprite:create()
		local texture = self._ccbOwner.node_hero_image:getTexture()
		sprite:setTexture(texture)
	    self._size = texture:getContentSize()
		local rect = CCRectMake(0, 0, self._size.width, self._size.height)
		sprite:setTextureRect(rect)
	    self._cd1 = QCircleUiMask.new({hideWhenFull = true})
	    self._cd1:setMaskSize(sprite:getContentSize())
	    self._cd1:addChild(sprite)
	    sprite:updateDisplayedColor(global.ui_skill_icon_disabled_overlay)
	    self._cd1:update(num)
	    self._ccbOwner.node_cd:addChild(self._cd1)
	else
		self._cd:update(num)
	end
end

--[[
	设置等级显示
]]
function QUIWidgetHeroHead:setLevel(level)
	if level ~= nil and tonumber(level) > 0 then
    	self:setLevelVisible(true)
		self._ccbOwner.node_hero_level:setString(tostring(level))
	else
		self:setLevelVisible(false)
		self._ccbOwner.node_hero_level:setString(tostring(level))
	end
end

--[[
	设置进阶显示
]]
function QUIWidgetHeroHead:setStar(starNum)
    if self._star == nil then
    	self._star = QUIWidgetHeroHeadStar.new({})
    	self._ccbOwner.node_hero_star:addChild(self._star:getView())
    end
    self._star:setStar(starNum)
	self._ccbOwner.node_hero_star:setVisible(true)
end

--[[
	设置突破显示
]]
function QUIWidgetHeroHead:setBreakthrough(breakthrough)
	for i=1,10,1 do
		local node = self._ccbOwner["break_"..i]
		if node ~= nil then
			node:setVisible(false)
		end
	end
	self._ccbOwner["break_"..(breakthrough+1)]:setVisible(true)
end

function QUIWidgetHeroHead:setContentVisible(v)
	self._ccbOwner.content:setVisible(v)
end

function QUIWidgetHeroHead:setContentScale(v)
	self._ccbOwner.content:setScale(v)
end

function QUIWidgetHeroHead:setStarVisible(v)
	self._ccbOwner.node_hero_star:setVisible(v)
end

--设置等级是否显示
function QUIWidgetHeroHead:setLevelVisible(b)
	self._ccbOwner.node_level:setVisible(b)
end 

function QUIWidgetHeroHead:setTouchEnabled(b)
	self._ccbOwner.btn_touch:setTouchEnabled(b)
end

function QUIWidgetHeroHead:showBattleForce()
	-- self._ccbOwner.node_hero_battleForce:setVisible(true)
end

function QUIWidgetHeroHead:getHeroActorID()
	return self._actorId
end

function QUIWidgetHeroHead:_onTriggerTouch()
	self:dispatchEvent({name = QUIWidgetHeroHead.EVENT_HERO_HEAD_CLICK, target = self})
end

--@qinyuanji
function QUIWidgetHeroHead:getHeroHeadSize()
	return self._size
end

return QUIWidgetHeroHead
