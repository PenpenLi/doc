--
-- Author: Your Name
-- Date: 2014-06-18 17:55:35
--
local QUIDialog = import(".QUIDialog")
local QUIDialogBreakthrough = class("QUIDialogBreakthrough", QUIDialog)

local QUIWidgetHeroHead = import("..wdigets.QUIWidgetHeroHead")
local QHeroModel = import("...models.QHeroModel")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")
local QTutorialEvent = import("..event.QTutorialEvent")
local QNotificationCenter = import("...controllers.QNotificationCenter")

function QUIDialogBreakthrough:ctor(options)
	local ccbFile = "ccb/Dialog_HeroBreakthroughSuccess.ccbi";
	local callBacks = {
		{ccbCallbackName = "onTriggerClose", 	callback = handler(self, QUIDialogBreakthrough._onTriggerClose)},
	}
	QUIDialogBreakthrough.super.ctor(self,ccbFile,callBacks,options)
    self.isAnimation = true --是否动画显示

	self._actorId = options.actorId
	self._isEnd = false
    audio.playSound("audio/sound/ui/task_complete.mp3",false)
    -- self:removeAll()
	self._ccbOwner.node_status2:setVisible(false)

    self._animationProxy = QCCBAnimationProxy:create()
    self._animationProxy:retain()
    self._animationManager = tolua.cast(self._view:getUserObject(), "CCBAnimationManager")
    self._animationProxy:connectAnimationEventSignal(self._animationManager, handler(self, self.viewAnimationEndHandler))
    self._animationManager:runAnimationsForSequenceNamed("Default Timeline")

    local heroInfo = remote.herosUtil:getHeroByID(self._actorId)
    if heroInfo ~= nil then
    	local oldHeroInfo = clone(heroInfo)
    	oldHeroInfo.breakthrough = oldHeroInfo.breakthrough - 1

    	local oldModel = QHeroModel.new(oldHeroInfo)
    	local newModel = QHeroModel.new(heroInfo)
		self._ccbOwner.tf_battleforce:setString(oldModel:getBattleForce())
		self._ccbOwner.tf_battleforce_new:setString(newModel:getBattleForce())

		local oldHead = QUIWidgetHeroHead.new()
		local newHead = QUIWidgetHeroHead.new()
		self._ccbOwner.old_head:addChild(oldHead)
		self._ccbOwner.new_head:addChild(newHead)
		oldHead:setHero(self._actorId)
		oldHead:setLevel(oldHeroInfo.level)
		oldHead:setStar(oldHeroInfo.grade)
		oldHead:setBreakthrough(oldHeroInfo.breakthrough)
		newHead:setHero(self._actorId)
		newHead:setLevel(heroInfo.level)
		newHead:setStar(heroInfo.grade)

		self._ccbOwner.tf_skill_name:setString("")
		self._ccbOwner.tf_skill_desc:setString("")
		self._ccbOwner.node_skill:setCascadeOpacityEnabled(true)
		self._ccbOwner.node_skill:setOpacity(0)

		local heroBreakthroughConfig = QStaticDatabase:sharedDatabase():getBreakthroughByHeroActorLevel(self._actorId, heroInfo.breakthrough)
		if heroBreakthroughConfig and heroBreakthroughConfig.skills ~= nil and heroBreakthroughConfig.skills ~= "" then
			local skillConfig = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(heroBreakthroughConfig.skills, 1)
			if skillConfig ~= nil then
				self._ccbOwner.node_status2:setVisible(true)
				self._ccbOwner.node_status1_bg:setVisible(false)
				self:setIconPath(skillConfig.icon)

				local actionArrayIn = CCArray:create()

				actionArrayIn:addObject(CCDelayTime:create(3))
				actionArrayIn:addObject(CCFadeIn:create(0.5))
				actionArrayIn:addObject(CCCallFunc:create(function ()
				  	self._actionHandler = nil
				  	self:wordTypewriterEffect(self._ccbOwner.tf_skill_name, "新技能："..skillConfig.local_name, function ()
				  		self:wordTypewriterEffect(self._ccbOwner.tf_skill_desc, skillConfig.description, function ()
    						self._isEnd = true
				  		end)
          				QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QTutorialEvent.EVENT_HERO_BREAKTHROUGH})  
				  	end)
				end))
				local ccsequence = CCSequence:create(actionArrayIn)
				self._actionHandler = self._ccbOwner.node_skill:runAction(ccsequence)
			end
		end
    end
end

function QUIDialogBreakthrough:wordTypewriterEffect(tf, word, callback)
	if tf == nil or word == nil then
		return false
	end
	if self._typewriterCallback ~= nil then
		return false
	end
	self._typewriterTF = tf
	self._typewriterWord = word
	self._typewriterCallback = callback

	self._sayPosition = 1
	self._typewriterSayWord = ""
	self._typewriterTF:setString(self._typewriterSayWord)
	self._delayTime = TUTORIAL_ONEWORD_TIME
	self._isExist = true

	if self._typewriterHandler == nil then
		self._typewriterHandler = function ()
			if self._isExist ~= true then return end
			local c = string.sub(self._typewriterWord,self._sayPosition,self._sayPosition)
	        local b = string.byte(c)
	        local str = c
	        if b > 128 then
	           str = string.sub(self._typewriterWord,self._sayPosition,self._sayPosition + 2)
	           self._sayPosition = self._sayPosition + 2
	        end
            self._typewriterSayWord =  self._typewriterSayWord .. str
			self._typewriterTF:setString(self._typewriterSayWord)
        	self._sayPosition = self._sayPosition + 1

        	if self._sayPosition <= #self._typewriterWord then
		        self._typewriterTimeHandler = scheduler.performWithDelayGlobal(self._typewriterHandler,self._delayTime)
		    else
		        if self._typewriterCallback ~= nil then
		        	local callBack = self._typewriterCallback
		            self._typewriterCallback = nil
		            callBack()
		        end
		        self._typewriterTimeHandler = nil
		    end
		end
	end
	self._typewriterHandler()
end

function QUIDialogBreakthrough:setIconPath(path)
	self._ccbOwner.node_icon:setTexture(CCTextureCache:sharedTextureCache():addImage(path))
end

function QUIDialogBreakthrough:viewWillDisappear()
	QUIDialogBreakthrough.super.viewWillDisappear(self)
    self._isExist = false
    if self._actionHandler ~= nil then
    	self._ccbOwner.node_skill:stopAction(self._actionHandler)
    	self._actionHandler = nil
    end
    if self._typewriterTimeHandler ~= nil then
    	scheduler.unscheduleGlobal(self._typewriterTimeHandler)
    	self._typewriterTimeHandler = nil
    end
	if self._animationProxy ~= nil then
        self._animationProxy:disconnectAnimationEventSignal()
        self._animationProxy:release()
        self._animationProxy = nil
	end
end

-------event--------------
function QUIDialogBreakthrough:_onTriggerClose()
	if self._isEnd == true then
		self:playEffectOut()
	else
	    if self._typewriterTimeHandler ~= nil then
	    	scheduler.unscheduleGlobal(self._typewriterTimeHandler)
	    	self._typewriterTimeHandler = nil
	    end
	    if self._actionHandler ~= nil then
	    	self._ccbOwner.node_skill:stopAction(self._actionHandler)
	    	self._actionHandler = nil
	    end
	    local heroInfo = remote.herosUtil:getHeroByID(self._actorId)
		local heroBreakthroughConfig = QStaticDatabase:sharedDatabase():getBreakthroughByHeroActorLevel(self._actorId, heroInfo.breakthrough)
		if heroBreakthroughConfig and heroBreakthroughConfig.skills ~= nil and heroBreakthroughConfig.skills ~= "" then
			local skillConfig = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(heroBreakthroughConfig.skills, 1)
			self._ccbOwner.node_skill:setOpacity(255)
			self._ccbOwner.tf_skill_name:setString("新技能："..skillConfig.local_name)
			self._ccbOwner.tf_skill_desc:setString(q.autoWrap(skillConfig.description, 21, 11, 400)) 
		end
    	self._animationManager:runAnimationsForSequenceNamed("endTime")
		self._isEnd = true
	end
end

function QUIDialogBreakthrough:_backClickHandler()
	self:_onTriggerClose()
end

function QUIDialogBreakthrough:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogBreakthrough