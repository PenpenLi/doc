--
-- Author: Your Name
-- Date: 2014-06-19 11:41:29
--
local QUIDialog = import(".QUIDialog")
local QUIDialogGrade = class("QUIDialogGrade",QUIDialog)

local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QUIWidgetAnimationPlayer = import("..widgets.QUIWidgetAnimationPlayer")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")

QUIDialogGrade.GRAY_COLOR = ccc3(253, 234, 183)
QUIDialogGrade.LIGHT_COLOR = ccc3(0, 197, 0)

QUIDialogGrade.EVENT_GRADE_SUCC = "EVENT_GRADE_SUCC"

function QUIDialogGrade:ctor(options)
	local ccbFile = "ccb/Dialog_HeroGradeSuccess.ccbi";
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", 	callback = handler(self, QUIDialogGrade._onTriggerClose)},
	}
	QUIDialogGrade.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true --是否动画显示

    self._isEnd = false
	self.actorId = options.actorId
    audio.playSound("audio/sound/ui/task_complete.mp3",false)
    self:removeAll()

    local heroInfo = remote.herosUtil:getHeroByID(self.actorId)
    if heroInfo ~= nil then
    	local oldHeroInfo = clone(heroInfo)
    	oldHeroInfo.grade = oldHeroInfo.grade - 1
    	local oldProp = remote.herosUtil:getHeroPropByHeroInfo(oldHeroInfo)
    	local newProp = remote.herosUtil:getHeroPropByHeroInfo(heroInfo)
		self._ccbOwner.tf_hp:setString(oldProp.hp_grow)
		self._ccbOwner.tf_hp_new:setString(newProp.hp_grow)
		self._ccbOwner.tf_attack:setString(oldProp.attack_grow)
		self._ccbOwner.tf_attack_new:setString(newProp.attack_grow)
		self._ccbOwner.tf_hp_add:setString("（生命＋"..(newProp.hp_grow-oldProp.hp_grow)*heroInfo.level.."）")
		self._ccbOwner.tf_attack_add:setString("（攻击＋"..(newProp.attack_grow-oldProp.attack_grow)*heroInfo.level.."）")

		local oldHead = QUIWidgetHeroHead.new()
		local newHead = QUIWidgetHeroHead.new()
		self._ccbOwner.old_head:addChild(oldHead)
		oldHead:setHero(self.actorId)
		oldHead:setLevel(oldHeroInfo.level)
		oldHead:setStar(oldHeroInfo.grade)
		newHead:setHero(self.actorId)
		newHead:setLevel(heroInfo.level)
		newHead:setStar(-1)
		self.heroInfo = heroInfo
		self.newHead = newHead
		self.newHead:retain()
		self._position = self._ccbOwner.new_head:convertToWorldSpaceAR(ccp(0,0))
		self._position = self:getView():convertToNodeSpaceAR(self._position)
		self._effectPlayer = QUIWidgetAnimationPlayer.new()
		self._effectPlayer:setPosition(self._position.x, self._position.y)
		self:getView():addChild(self._effectPlayer)
		local ccbFile = "ccb/effects/HeroHeadStar"..(heroInfo.grade+1)..".ccbi"
		self._effectPlayer:playAnimation(ccbFile,function (ccbOwner,ccbView)
			ccbOwner.node_head:removeAllChildren()
			ccbOwner.node_head:addChild(self.newHead)
			self.newHead:release()
		end,function()
			self._ccbOwner.node_light:setVisible(true)
		end,false)
		self:autoLayout()
    end
    app.sound:playSound("hero_grow_up")
end

function QUIDialogGrade:viewWillDisappear()
	QUIDialogGrade.super.viewWillDisappear(self)
    self._isEnd = true
end

function QUIDialogGrade:autoLayout()
	local gap = 10
	local totalWidth = self._ccbOwner.node_hp_title:getContentSize().width
	totalWidth = totalWidth + gap
	totalWidth = totalWidth + self._ccbOwner.tf_hp:getContentSize().width
	totalWidth = totalWidth + gap
	totalWidth = totalWidth + self._ccbOwner.node_hp:getContentSize().width
	totalWidth = totalWidth + gap
	totalWidth = totalWidth + self._ccbOwner.tf_hp_new:getContentSize().width
	totalWidth = totalWidth + gap
	totalWidth = totalWidth + self._ccbOwner.tf_hp_add:getContentSize().width
	local startPX = self._ccbOwner.node_bg:getPositionX() - totalWidth/2
	self._ccbOwner.node_hp_title:setPositionX(startPX)
	self._ccbOwner.node_attack_title:setPositionX(startPX)
	startPX = startPX + self._ccbOwner.node_hp_title:getContentSize().width + gap
	self._ccbOwner.tf_hp:setPositionX(startPX)
	self._ccbOwner.tf_attack:setPositionX(startPX)
	startPX = startPX + self._ccbOwner.tf_hp:getContentSize().width + gap
	self._ccbOwner.node_hp:setPositionX(startPX)
	self._ccbOwner.node_attack:setPositionX(startPX)
	startPX = startPX + self._ccbOwner.node_hp:getContentSize().width + gap
	self._ccbOwner.tf_hp_new:setPositionX(startPX)
	self._ccbOwner.tf_attack_new:setPositionX(startPX)
	startPX = startPX + self._ccbOwner.tf_hp_new:getContentSize().width + gap
	self._ccbOwner.tf_hp_add:setPositionX(startPX)
	self._ccbOwner.tf_attack_add:setPositionX(startPX)
end

function QUIDialogGrade:removeAll()
	self._ccbOwner.node_light:setVisible(false)
	self._ccbOwner.tf_hp:setString("")
	self._ccbOwner.tf_attack:setString("")
	self._ccbOwner.tf_hp_new:setString("")
	self._ccbOwner.tf_attack_new:setString("")
	self._ccbOwner.tf_hp_add:setString("")
	self._ccbOwner.tf_attack_add:setString("")
end

-------event--------------
function QUIDialogGrade:_onTriggerClose()
	self:playEffectOut()
end

function QUIDialogGrade:_backClickHandler()
	self:_onTriggerClose()
end

function QUIDialogGrade:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogGrade