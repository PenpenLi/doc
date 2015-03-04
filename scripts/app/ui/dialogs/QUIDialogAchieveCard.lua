--
-- Author: Your Name
-- Date: 2014-09-22 17:01:05
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogAchieveCard = class("QUIDialogAchieveCard", QUIDialog)
local QUIWidgetHeroCard = import("..widgets.QUIWidgetHeroCard")
local QUIWidgetAnimationPlayer = import("..widgets.QUIWidgetAnimationPlayer")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogAchieveCard:ctor(options)
	self.actorId = options.actorId
	self.callBack = options.callBack
	self._isHave = options.isHave or false
	self._data = options.data
	local ccbFile = nil
	if self.actorId ~= nil then
	    local heroInfo = QStaticDatabase:sharedDatabase():getCharacterByID(self.actorId)
	    if heroInfo ~= nil then
	    	if heroInfo.effect_colour == 1 then
				ccbFile = "ccb/Dialog_AchieveCard_Blue.ccbi"
			elseif heroInfo.effect_colour == 2 then
				ccbFile = "ccb/Dialog_AchieveCard_Orange.ccbi"
			end
		end
	end
    local callBacks = {}
    if ccbFile == nil then 
    	printError("hero ccbi is nil !")
    	return 
    end
    QUIDialogAchieveCard.super.ctor(self, ccbFile, callBacks, options)

    audio.playSound("audio/sound/ui/task_complete.mp3",false)

    self._card = QUIWidgetHeroCard.new()
    self._card:setIsEffect(false)
    self._card:setHero(self.actorId)
    self._ccbOwner.node_card:addChild(self._card)
    app.sound:playSound("common_award_hero")

	self._isplayer = false
end

function QUIDialogAchieveCard:viewDidAppear()
    QUIDialogAchieveCard.super.viewDidAppear(self)
    self._card:addEventListener(QUIWidgetHeroCard.EVENT_CLICK, handler(self, self._backClickHandler))
end

function QUIDialogAchieveCard:viewWillDisappear()
    QUIDialogAchieveCard.super.viewWillDisappear(self)
    self._card:removeAllEventListeners()
end

function QUIDialogAchieveCard:showEffect()
	self._isplayer = true
	local effectPlayer = QUIWidgetAnimationPlayer.new()
	self._ccbOwner.node_card:addChild(effectPlayer)
	effectPlayer:playAnimation("ccb/effects/Widget_AchieveCard.ccbi",function(ccbOwner)
        	local config = QStaticDatabase:sharedDatabase():getGradeByHeroActorLevel(self._data.id , self._data.grade or 0)
        	local star = (self._data.grade or 0)+1
        	local str = "已拥有此英雄，"..star.."星卡牌转化为灵魂碎片"..config.soul_return_count.."个"
        	ccbOwner.tf_info:setString(str)
			self._card:retain()
			self._card:removeFromParent()
			ccbOwner.node_card:addChild(self._card)
			self._card:release()
		end, function()
			self._isplayer = false
			self._isHave = false
		end, false)
end

function QUIDialogAchieveCard:_backClickHandler()
	if self._isplayer == true then
		return 
	end
	if self._isHave == true and self._data ~= nil then
		self:showEffect()
	else
    	app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    	if self.callBack ~= nil then
    		self.callBack()
    	end
    end
end

return QUIDialogAchieveCard