
local QBattleDialog = import(".QBattleDialog")
local QBattleDialogAutoSkill = class("QBattleDialogAutoSkill", QBattleDialog)

local QUserData = import("...utils.QUserData")
local QTeam = import("...utils.QTeam")
local QStaticDatabase = import("...controlers.QStaticDatabase")

function QBattleDialogAutoSkill:ctor(owner, options)
	local ccbFile = "Battle_AutoSkill.ccbi"
	if owner == nil then
		owner = {}
	end

	owner.clickSkill1 = handler(self, QBattleDialogAutoSkill.onClickSkill1)
	owner.clickSkill2 = handler(self, QBattleDialogAutoSkill.onClickSkill2)
	owner.clickSkill3 = handler(self, QBattleDialogAutoSkill.onClickSkill3)
	owner.clickSkill4 = handler(self, QBattleDialogAutoSkill.onClickSkill4)

	owner.clickSkillButton1 = handler(self, QBattleDialogAutoSkill.onClickSkill1)
	owner.clickSkillButton2 = handler(self, QBattleDialogAutoSkill.onClickSkill2)
	owner.clickSkillButton3 = handler(self, QBattleDialogAutoSkill.onClickSkill3)
	owner.clickSkillButton4 = handler(self, QBattleDialogAutoSkill.onClickSkill4)

	owner.onCastSwitch = handler(self, QBattleDialogAutoSkill.oneClickCastSpell)

	self:setNodeEventEnabled(true)
	QBattleDialogAutoSkill.super.ctor(self, ccbFile, owner)

	self._castSwitchOn = true
	self._suffix = "-autoUseSkill"
	local dungeonConfig = app.battle:getDungeonConfig()
	local dungeonInfo = remote.activityInstance:getDungeonById(dungeonConfig.id)
	if dungeonInfo ~= nil then
		self._suffix = "-autoUseSkill-active"
	end
	if app.battle:isPVPMode() == true and app.battle:isInSunwell() == true then
        self._suffix = "-autoUseSkill-sunwell"
    end

	self._openStateSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("but_open.png")
	self._openStateSpriteFrame:retain()
	self._closeStateSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("but_close.png")
	self._closeStateSpriteFrame:retain()

	self._hero1 = nil
	self._hero2 = nil
	self._hero3 = nil
	self._hero4 = nil

	self._skill1 = nil
	self._skill2 = nil
	self._skill3 = nil
	self._skill4 = nil

	local heroes = app.battle:getHeroes()
	local deadHeroes = app.battle:getDeadHeroes()

	local teamName = QTeam.INSTANCE_TEAM
	local dungeonConfig = app.battle:getDungeonConfig()
	if dungeonConfig.teamName ~= nil then
        teamName = dungeonConfig.teamName
    end
    
	for i, heroId in ipairs(remote.teams:getTeams(teamName)) do
        local heroInfo = remote.herosUtil:getHeroByID(heroId)
        local hero = nil
        for _, actor in ipairs(heroes) do
        	if actor:getActorID() == heroInfo.actorId then
        		hero = actor
        		break
        	end
        end
        if hero == nil then
        	for _, actor in ipairs(deadHeroes) do
	        	if actor:getActorID() == heroInfo.actorId then
	        		hero = actor
	        		break
	        	end
	        end
        end

  		if hero ~= nil then
  			self["_hero" .. tostring(i)] = hero
  			local skills = {}
  			for _, skill in pairs(hero:getManualSkills()) do
  				table.insert(skills, skill)
  			end
  			 
  			if #skills > 0 then
  				self["_skill" .. tostring(i)] = skills[1]
  			end
  		end
    end

    self:_setupSkillWithIndex(1)
    self:_setupSkillWithIndex(2)
    self:_setupSkillWithIndex(3)
    self:_setupSkillWithIndex(4)

    if self._castSwitchOn then
		self._ccbOwner["btn_open"]:setVisible(false)
		self._ccbOwner["btn_close"]:setVisible(true)
    else
		self._ccbOwner["btn_open"]:setVisible(true)
		self._ccbOwner["btn_close"]:setVisible(false)
    end
end

function QBattleDialogAutoSkill:_setupSkillWithIndex(index)
	if index == nil or index <= 0 or index > 4 then
		return 
	end

	index = tostring(index)
	local skill = self["_skill" .. index]
	local hero = self["_hero" .. index]

	if skill == nil then
		local skillTexture = CCTextureCache:sharedTextureCache():addImage(global.ui_skill_icon_placeholder)
		self._ccbOwner["sprite_skillIcon" .. index]:setTexture(skillTexture)
		local size = skillTexture:getContentSize()
        local rect = CCRectMake(0, 0, size.width, size.height)
        self._ccbOwner["sprite_skillIcon" .. index]:setDisplayFrame(CCSpriteFrame:createWithTexture(skillTexture, rect))
		self._ccbOwner["sprite_highlight" .. index]:setVisible(false)
		self._ccbOwner["node_gray" .. index]:setVisible(true)
		self._ccbOwner["node_ok" .. index]:setVisible(false)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateNormal)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateHighlighted)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateDisabled)
		self._ccbOwner["button_skill" .. index]:setEnabled(false)
		self._ccbOwner["ccb_animationSkill" .. index]:setVisible(false)
		self._ccbOwner["node_skillName" .. index]:setVisible(false)
	else
		local skillTexture = CCTextureCache:sharedTextureCache():addImage(skill:getIcon())
		self._ccbOwner["sprite_skillIcon" .. index]:setTexture(skillTexture)
		local size = skillTexture:getContentSize()
        local rect = CCRectMake(0, 0, size.width, size.height)
        self._ccbOwner["sprite_skillIcon" .. index]:setDisplayFrame(CCSpriteFrame:createWithTexture(skillTexture, rect))
		self._ccbOwner["sprite_highlight" .. index]:setVisible(true)
		self._ccbOwner["node_gray" .. index]:setVisible(false)
		self._ccbOwner["node_ok" .. index]:setVisible(true)
		self._ccbOwner["button_skill" .. index]:setEnabled(true)
		local autoUseSkill = app:getUserData():getUserValueForKey(hero:getActorID() .. self._suffix)
		if autoUseSkill == nil or autoUseSkill ~= QUserData.STRING_TRUE then
			self._ccbOwner["ccb_animationSkill" .. index]:setVisible(false)
			self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateNormal)
			self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateHighlighted)
			self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateDisabled)
			self._castSwitchOn = false -- If there is at least one cast not auto spell, show "一键开启" text.
		else
			self._ccbOwner["ccb_animationSkill" .. index]:setVisible(true)
			self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._openStateSpriteFrame, CCControlStateNormal)
			self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._openStateSpriteFrame, CCControlStateHighlighted)
			self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._openStateSpriteFrame, CCControlStateDisabled)
		end
		self._ccbOwner["node_skillName" .. index]:setVisible(true)
		self._ccbOwner["node_skillName" .. index]:setString(skill:getLocalName())
	end
end

function QBattleDialogAutoSkill:oneClickCastSpell()
	self._castSwitchOn = not self._castSwitchOn
	if self._castSwitchOn then 
		self:changeAutoSkillState(1, "on")
		self:changeAutoSkillState(2, "on")
		self:changeAutoSkillState(3, "on")
		self:changeAutoSkillState(4, "on")
		self._ccbOwner["btn_open"]:setVisible(false)
		self._ccbOwner["btn_close"]:setVisible(true)
	else
		self:changeAutoSkillState(1, "off")
		self:changeAutoSkillState(2, "off")
		self:changeAutoSkillState(3, "off")
		self:changeAutoSkillState(4, "off")
		self._ccbOwner["btn_open"]:setVisible(true)
		self._ccbOwner["btn_close"]:setVisible(false)
	end
end

function QBattleDialogAutoSkill:_onTriggerAutoUseSkilWithIndex(index)
	if index == nil or index <= 0 or index > 4 then
		return 
	end

	index = tostring(index)
	local skill = self["_skill" .. index]
	local hero = self["_hero" .. index]

	if skill == nil then
		return
	end

	local autoUseSkill = app:getUserData():getUserValueForKey(hero:getActorID() .. self._suffix)
	if autoUseSkill == nil or autoUseSkill ~= QUserData.STRING_TRUE then
		self:changeAutoSkillState(index, "on")
	else
		self:changeAutoSkillState(index, "off")
	end
end

function QBattleDialogAutoSkill:onExit()
	if self._openStateSpriteFrame ~= nil then
		self._openStateSpriteFrame:release()
		self._openStateSpriteFrame = nil
	end

	if self._closeStateSpriteFrame ~= nil then
		self._closeStateSpriteFrame:release()
		self._closeStateSpriteFrame = nil
	end
end

-- state should be "on" or "off"
function QBattleDialogAutoSkill:changeAutoSkillState(index, state)
	local skill = self["_skill" .. index]
	local hero = self["_hero" .. index]

	if skill == nil then
		return
	end

	if state == "on" then
		self._ccbOwner["ccb_animationSkill" .. index]:setVisible(true)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._openStateSpriteFrame, CCControlStateNormal)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._openStateSpriteFrame, CCControlStateHighlighted)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._openStateSpriteFrame, CCControlStateDisabled)
		hero:setForceAuto(true)
		app:getUserData():setUserValueForKey(hero:getActorID() .. self._suffix, QUserData.STRING_TRUE)
	else
		self._ccbOwner["ccb_animationSkill" .. index]:setVisible(false)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateNormal)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateHighlighted)
		self._ccbOwner["button_skill" .. index]:setBackgroundSpriteFrameForState(self._closeStateSpriteFrame, CCControlStateDisabled)
		hero:setForceAuto(false)
		app:getUserData():setUserValueForKey(hero:getActorID() .. self._suffix, QUserData.STRING_FALSE)
	end
end

function QBattleDialogAutoSkill:onClickSkill1()
	self:_onTriggerAutoUseSkilWithIndex(1)
	self:updateOneClickButton()
end

function QBattleDialogAutoSkill:onClickSkill2()
	self:_onTriggerAutoUseSkilWithIndex(2)
	self:updateOneClickButton()
end

function QBattleDialogAutoSkill:onClickSkill3()
	self:_onTriggerAutoUseSkilWithIndex(3)
	self:updateOneClickButton()
end

function QBattleDialogAutoSkill:onClickSkill4()
	self:_onTriggerAutoUseSkilWithIndex(4)
	self:updateOneClickButton()
end
                         
function QBattleDialogAutoSkill:getAutoSkillState(index)
	if index == nil or index <= 0 or index > 4 then
		return false
	end

	index = tostring(index)
	local hero = self["_hero" .. index]

	if hero == nil then
		return nil
	end

	local autoUseSkill = app:getUserData():getUserValueForKey(hero:getActorID() .. self._suffix)
	if autoUseSkill == nil or autoUseSkill ~= QUserData.STRING_TRUE then
		return false
	else
		return true
	end
end

-- Update text of one-click button if all the switchs are on or off
function QBattleDialogAutoSkill:updateOneClickButton()
	local allOn = true
	local allOff = true
	for i = 1, 4 do
		if self:getAutoSkillState(i) == nil then
			-- do nothing, next loop
		elseif self:getAutoSkillState(i) then
			allOff = false
		else
			allOn = false
		end
	end

	if allOn then
		self._ccbOwner["btn_open"]:setVisible(false)
		self._ccbOwner["btn_close"]:setVisible(true)
		self._castSwitchOn = true
	elseif allOff then
		self._ccbOwner["btn_open"]:setVisible(true)
		self._ccbOwner["btn_close"]:setVisible(false)
		self._castSwitchOn = false
	end
end

return QBattleDialogAutoSkill