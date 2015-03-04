
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetTopStatusShow = class("QUIWidgetTopStatusShow", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QTextFiledScrollUtils = import("...utils.QTextFiledScrollUtils")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetEnergyPrompt = import("..widgets.QUIWidgetEnergyPrompt")

QUIWidgetTopStatusShow.EVENT_CLICK = "EVENT_CLICK"

function QUIWidgetTopStatusShow:ctor(options)
	
	local ccbFile = "ccb/Widget_tap.ccbi"
	local callBacks = {
        {ccbCallbackName = "onPlus", callback = handler(self, QUIWidgetTopStatusShow._onPlus)}
    }
	QUIWidgetTopStatusShow.super.ctor(self,ccbFile,callBacks,options)
	self._kind = options

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
	
	self._effectTime = 2 --2miao

	self._text1Update = QTextFiledScrollUtils.new()
	-- self._text2Update = QTextFiledScrollUtils.new()
end

function QUIWidgetTopStatusShow:onEnter( ... )
	self._ccbOwner.prompt:setTouchEnabled(true)
  	self._ccbOwner.prompt:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
  	self._ccbOwner.prompt:setTouchSwallowEnabled(true)
  	self._ccbOwner.prompt:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIWidgetTopStatusShow._onTouch))
end

function QUIWidgetTopStatusShow:onExit()
	self._ccbOwner.prompt:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
	self._text1Update:stopUpdate()
	-- self._text2Update:stopUpdate()
	if self._actionHandler ~= nil then
		self._showIcon:stopAction(self._actionHandler)
	end
end

function QUIWidgetTopStatusShow:setText(kind,text1,text2)
	self._text1 = text1
	self._text2 = text2
	self._scale = 1
	if 1 == kind then		
	    local wordLen = q.wordLen(text1, 42, 21)
	    if wordLen > 147 then
	      self._scale = 147/wordLen
	      self._ccbOwner.CCLabelBMFont_MidNum:setScale(147/wordLen)
	    else
	      self._scale = 1
        self._ccbOwner.CCLabelBMFont_MidNum:setScale(1)
    	end
      self._ccbOwner.CCLabelBMFont_MidNum:setString(text1)
    	self._ccbOwner.CCLabelBMFont_LeftNum:setVisible(false)
    	self._ccbOwner.CCLabelBMFont_RightNum:setVisible(false)
    elseif 2 == kind then
    	if tonumber(text1) >= tonumber(text2) then
    		self._ccbOwner.CCLabelBMFont_LeftNum:setString(text1)
			self._ccbOwner.CCLabelBMFont_RightNum:setString("/" ..text2)
    	else
    		self._ccbOwner.CCLabelBMFont_LeftNum:setString("")
			self._ccbOwner.CCLabelBMFont_RightNum:setString(text1.."/" ..text2)
    	end
   		self._ccbOwner.CCLabelBMFont_MidNum:setVisible(false)
	end
end

function QUIWidgetTopStatusShow:update(kind,text1,text2)
	if self._text1 == nil then
		self:setText(kind,text1,text2)
		return 
	end
	-- self:iconEffect(text1, self._text1)
	if 1 == kind then	
		if text1 ~= nil and self._text1 ~= text1 then
			if tonumber(self._text1) > tonumber(text1) then
				self._text1Update:addUpdate(self._text1, text1, handler(self, self.tfMidUpdate), self._effectTime)
			else
        self:setText(kind,text1,text2)
				self:nodeEffect(self._ccbOwner.CCLabelBMFont_MidNum)
			end
		end
	elseif 2 == kind then
		if text1 ~= nil and self._text1 ~= text1 then
			if tonumber(self._text1) > tonumber(text1) then
				self._text1Update:addUpdate(self._text1, text1, handler(self, self.tfLeftUpdate), self._effectTime)
			else
				if tonumber(self._text1) >= tonumber(self._text2) then
					self:nodeEffect(self._ccbOwner.CCLabelBMFont_LeftNum)
				else
					self:nodeEffect(self._ccbOwner.CCLabelBMFont_RightNum)
				end
				self:setText(kind,text1,text2)
			end
		end
		-- if text2 ~= nil and self._text2 ~= text2 then
		-- 	if self._text2 > text2 then
		-- 		self._text2Update:addUpdate(self._text2, text2, handler(self, self.tfRightUpdate), self._effectTime)
		-- 	else
		-- 		self:nodeEffect(self._ccbOwner.CCLabelBMFont_LeftNum, text2)
		-- 		self:setText(kind,text1,text2)
		-- 	end
		-- end
	end
end

function QUIWidgetTopStatusShow:tfMidUpdate(value)
--	self._text1 = value
	self:setText(1,math.ceil(value))
--	self._ccbOwner.CCLabelBMFont_MidNum:setString(math.ceil(value))
end

function QUIWidgetTopStatusShow:tfLeftUpdate(value)
	self._text1 = math.ceil(value)
	if tonumber(self._text1) >= tonumber(self._text2) then
		self._ccbOwner.CCLabelBMFont_LeftNum:setString(self._text1)
		self._ccbOwner.CCLabelBMFont_RightNum:setString("/" ..self._text2)
	else
		self._ccbOwner.CCLabelBMFont_LeftNum:setString("")
		self._ccbOwner.CCLabelBMFont_RightNum:setString(self._text1.."/" ..self._text2)
	end
end

function QUIWidgetTopStatusShow:tfRightUpdate(value)
	self._text2 = value
	self._ccbOwner.CCLabelBMFont_RightNum:setString("/" ..math.ceil(value))
end

function QUIWidgetTopStatusShow:nodeEffect(node)
	if node ~= nil then
		node:setScale(self._scale)
	    local actionArrayIn = CCArray:create()
        actionArrayIn:addObject(CCScaleTo:create(0.23, self._scale + 1))
        actionArrayIn:addObject(CCScaleTo:create(0.23, self._scale))
	    local ccsequence = CCSequence:create(actionArrayIn)
		node:runAction(ccsequence)
	end
end

function QUIWidgetTopStatusShow:showIcon(kind)
	
	if 1 == kind then
		self._showIcon = self._ccbOwner.sprite_gold
		self._ccbOwner.sprite_gold:setVisible(true)
		self._ccbOwner.sprite_rune:setVisible(false)
		self._ccbOwner.sprite_energy:setVisible(false)
	elseif 2 == kind then
		self._showIcon = self._ccbOwner.sprite_rune
		self._ccbOwner.sprite_gold:setVisible(false)
		self._ccbOwner.sprite_rune:setVisible(true)
		self._ccbOwner.sprite_energy:setVisible(false)
	else
		self._showIcon = self._ccbOwner.sprite_energy
		self._ccbOwner.sprite_gold:setVisible(false)
		self._ccbOwner.sprite_rune:setVisible(false)
		self._ccbOwner.sprite_energy:setVisible(true)
	end
end

function QUIWidgetTopStatusShow:_onTouch(event)
  	if event.name == "began" then
  		if self._kind == 3 then 
      		QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetEnergyPrompt.EVENT_BEGAIN , eventTarget = self})
      	else
      		self._ccbOwner.plus:setHighlighted(true)
      	end
    	return true
  	elseif event.name == "ended" or event.name == "cancelled" then 
  		if self._kind == 3 then
   			QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetEnergyPrompt.EVENT_END , eventTarget = self})
   		else
   			self._ccbOwner.plus:setHighlighted(false)
   			-- Don't trigger function if touch is moved out of area
   			if self:touchInArea(self._ccbOwner.prompt, ccp(event.x, event.y)) then
   				self:_onPlus()
   			end
   		end
    	return true
  	end
end

function QUIWidgetTopStatusShow:touchInArea(ccbElement, touchPoint)
	local position = ccbElement:convertToWorldSpaceAR(ccp(0, 0))
	local size = ccbElement:getContentSize()
	if touchPoint.x > position.x and touchPoint.x < (position.x + size.width) and touchPoint.y > position.y and touchPoint.y < (position.y + size.height) then
		return true
	end

	return false  
end

function QUIWidgetTopStatusShow:_onPlus()
	self:dispatchEvent({name=QUIWidgetTopStatusShow.EVENT_CLICK,kind = self._kind})
    app.sound:playSound("common_increase")
	-- if self._kind == 3 then
	-- 	app:getClient():buyEnergy()
	-- 	self:setText(2, tostring(remote.user.energy), QStaticDatabase:getConfig().max_energy)
	-- end
end

return QUIWidgetTopStatusShow