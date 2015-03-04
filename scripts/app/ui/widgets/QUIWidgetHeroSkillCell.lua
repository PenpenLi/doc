--
-- Author: wkwang
-- Date: 2014-10-21 10:41:36
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroSkillCell = class("QUIWidgetHeroSkillCell", QUIWidget)

local QUIWidgetAnimationPlayer = import("..widgets.QUIWidgetAnimationPlayer")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QRemote = import("...models.QRemote")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QTutorialEvent = import("..event.QTutorialEvent")
local QUIViewController = import("..QUIViewController")

QUIWidgetHeroSkillCell.SHOW_EFFECT = "SHOW_EFFECT"
QUIWidgetHeroSkillCell.EVENT_BEGAIN = "SKILL_EVENT_BEGAIN"
QUIWidgetHeroSkillCell.EVENT_END = "SKILL_EVENT_END"
QUIWidgetHeroSkillCell.EVENT_BUY = "SKILL_EVENT_BUY"

function QUIWidgetHeroSkillCell:ctor(options)
	self._skillName = options.skillName
	self._actorId = options.actorId
	self._content = options.content
	self._heroInfo = remote.herosUtil:getHeroByID(self._actorId)
	self._skillId = self:getHeroSkillIdBySkillName(self._skillName)
	local ccbFile = ""
	local callBacks = {}
	if self._skillId ~= nil then
		ccbFile = "ccb/Widget_HeroSkillUpgarde_client.ccbi"
		table.insert(callBacks,  {ccbCallbackName = "onPlus", callback = handler(self, QUIWidgetHeroSkillCell._onPlus)})
	else
		ccbFile = "ccb/Widget_HeroSkillUpgarde_gray.ccbi"
	end

	QUIWidgetHeroSkillCell.super.ctor(self, ccbFile, callBacks, options)
	cc.GameObject.extend(self)
	self:addComponent("components.behavior.EventProtocol"):exportMethods()

	if self._skillId ~= nil then
		self:initSkillForHave()
	else
		self:initSkillForNone()
	end
	self._effectPlay = false
end

function QUIWidgetHeroSkillCell:getHeight()
	return 118
end

function QUIWidgetHeroSkillCell:onEnter()
    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(QRemote.HERO_UPDATE_EVENT, handler(self, self.onEvent))
    self._ccbOwner.node_layer:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._ccbOwner.node_layer:setTouchEnabled(true)
    self._ccbOwner.node_layer:setTouchSwallowEnabled(false)
    self._ccbOwner.node_layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIWidgetHeroSkillCell._onTouch))
end

function QUIWidgetHeroSkillCell:onExit()
    self._remoteProxy:removeAllEventListeners()
    self._ccbOwner.node_icon:setTouchEnabled(false)
    self._ccbOwner.node_icon:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
end

function QUIWidgetHeroSkillCell:onEvent()
	self:initSkillForHave()
end

--[[
	拥有该技能
]]
function QUIWidgetHeroSkillCell:initSkillForHave()
	local skillConfig = QStaticDatabase:sharedDatabase():getSkillByID(self._skillId)
	if self._skillId == nil or skillConfig == nil then return end
	self:setText("tf_name", skillConfig.local_name)
	self:setText("tf_level", "Lv："..skillConfig.level)
--	self:setText("tf_money", nextSkillConfig.item_cost)]
	self:setIconPath(skillConfig.icon)
	local nextSkillConfig = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(skillConfig.name, skillConfig.level+1)
	if nextSkillConfig == nil or nextSkillConfig.hero_level > self._heroInfo.level then
		-- self._ccbOwner.btn_plus:setEnabled(false)
		makeNodeFromNormalToGrayLuminance(self._ccbOwner.btn_plus)
	else
		-- self._ccbOwner.btn_plus:setEnabled(true)
  		self:setText("tf_money", nextSkillConfig.item_cost or 0)
	end
end

--[[
	没有该技能
]]
function QUIWidgetHeroSkillCell:initSkillForNone()
	local skillConfig = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(self._skillName, 1)
	self:setText("tf_name", skillConfig.local_name)
	self:setText("tf_unlock", "")
	self:setIconPath(skillConfig.icon)
	local breakthroughConfig = QStaticDatabase:sharedDatabase():getBreakthroughHeroByActorId(self._actorId)
    if breakthroughConfig ~= nil then
    	for _,value in pairs(breakthroughConfig) do
    		if value.skills == self._skillName then
    			self:setText("tf_unlock", value.desc or "")--"英雄突破+"..value.breakthrough_level.."解锁")
    			break
    		end
    	end
    end
    makeNodeFromNormalToGray(self)
end

function QUIWidgetHeroSkillCell:setIconPath(path)
	if self._skillIcon == nil then
			self._skillIcon = CCSprite:create()
			self._ccbOwner.node_iconContent:addChild(self._skillIcon)
		end
	self._skillIcon:setTexture(CCTextureCache:sharedTextureCache():addImage(path))
end

function QUIWidgetHeroSkillCell:setText(name, text)
	if self._ccbOwner[name] then
		self._ccbOwner[name]:setString(text)
	end
end

function QUIWidgetHeroSkillCell:skillUpgradeSucc()
	app.sound:playSound("hero_skill_up")
  	QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTutorialEvent.EVENT_SKILL_SUCCESS})
	if self._effect == nil then
		self._effect = 	QUIWidgetAnimationPlayer.new()
		self._ccbOwner.node_iconContent:addChild(self._effect)
	end
	self._effect:playAnimation("ccb/effects/SkillUpgarde.ccbi")

	self._skillId = self:getHeroSkillIdBySkillName(self._skillName)
	self:initSkillForHave()
	local skillConfig = QStaticDatabase:sharedDatabase():getSkillByID(self._skillId)
	local desc = skillConfig.addition_float
	if desc ~= nil then
		for _,value in pairs(string.split(desc, ";")) do
			self:playPropEffect(value)
			-- remote.herosUtil:dispacthHeroPropUpdate(self._actorId, value)
		end
	end
	remote.user:addPropNumForKey("todaySkillImprovedCount")
end

--显示特效
function QUIWidgetHeroSkillCell:playPropEffect(value)
	if self._effectTbl == nil then
		self._effectTbl = {}
	end
	table.insert(self._effectTbl, value)
	self._timeDelay = 0.3
	if (2/#self._effectTbl) < self._timeDelay then
		self._timeDelay = 2/#self._effectTbl
	end
	if self._effectPlay == false then
		self._effectPlay = true
		self._handler = scheduler.performWithDelayGlobal(handler(self,self._playPropEffect),self._timeDelay)
	end
end

function QUIWidgetHeroSkillCell:_playPropEffect()
	if self._effectTbl == nil or #self._effectTbl == 0 then
		self._effectPlay = false
		if self._handler ~= nil then
			scheduler.unscheduleGlobal(self._handler)
			self._handler = nil
		end
		return 
	else
		self._handler = scheduler.performWithDelayGlobal(handler(self,self._playPropEffect),self._timeDelay)
	end
	local value = self._effectTbl[1]
	table.remove(self._effectTbl,1)
	local effect = QUIWidgetAnimationPlayer.new()
	local p = self._ccbOwner.node_iconContent:getParent():convertToWorldSpaceAR(ccp(0,0))
	p = self._content:convertToNodeSpaceAR(p)
	effect:setPosition(p.x,p.y)
	self._content:addChild(effect)
	effect:playAnimation("ccb/effects/YellowSkill.ccbi", function(ccbOwner)
				ccbOwner.tf_value:setString(value)
            end,function()
            	effect:removeFromParentAndCleanup(true)
            end)
end


function QUIWidgetHeroSkillCell:getHeroSkillIdBySkillName(skillName)
	self._heroInfo = remote.herosUtil:getHeroByID(self._actorId)
    for _,skillId in pairs(self._heroInfo.skills) do
        local skillConfig = QStaticDatabase:sharedDatabase():getSkillByID(skillId)
        if skillConfig.name == skillName then
            return skillId
        end
    end
    return nil
end

function QUIWidgetHeroSkillCell:_onPlus()
	local skillConfig = QStaticDatabase:sharedDatabase():getSkillByID(self._skillId)
	local nextSkillConfig = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(skillConfig.name, skillConfig.level+1)
	if nextSkillConfig == nil then
    	app.tip:floatTip("技能已升级到顶级")
		return
	elseif nextSkillConfig.hero_level > self._heroInfo.level then
    	app.tip:floatTip("技能等级已至上限，请升级英雄等级！")
		return
	end

	if nextSkillConfig.item_cost > remote.items:getItemsNumByID(12) then
--		app:alert({content="雕文不足，现在就去购买？",title="系统提示", comfirmBack = function(data)
--				app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogBuyVirtual", options = {typeName=ITEM_TYPE.MONEY}}, {isPopCurrentDialog = false})
--			end, callBack = function ()
--			end}, false)
      app.tip:floatTip("雕文不足")
      return
	end

	local point, lastTime = remote.herosUtil:getSkillPointAndTime()
	if point > 0 then
		local oldHero = clone(remote.herosUtil:getHeroByID(self._actorId))
		app:getClient():improveSkill(self._actorId, self._skillName,function()
				if self.skillUpgradeSucc ~= nil then
					self:skillUpgradeSucc()			
				end	
			end)
	else
        self:dispatchEvent({name = QUIWidgetHeroSkillCell.EVENT_BUY})
	end
end

function QUIWidgetHeroSkillCell:_onTouch(event)
  if event.name == "began" then
    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetHeroSkillCell.EVENT_BEGAIN , eventTarget = self, skillID = self._skillId, skillName = self._skillName})
    return true
  elseif event.name == "ended" or event.name == "cancelled" then
   QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetHeroSkillCell.EVENT_END })
    return true
  end
end

return QUIWidgetHeroSkillCell