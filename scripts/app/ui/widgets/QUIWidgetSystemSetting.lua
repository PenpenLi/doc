--
-- Author: Qinyuanji
-- Date: 2014-11-20
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetSystemSetting = class("QUIWidgetSystemSetting", QUIWidget)
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QSystemSetting = import("...controllers.QSystemSetting")

QUIWidgetSystemSetting.PAGE_MARGIN = 40
QUIWidgetSystemSetting.EVENT_RESPOND_IGNORE = 0.3


function QUIWidgetSystemSetting:ctor()
	local ccbFile = "ccb/Widget_SystemSetting.ccbi"
	local callBacks = {
		{ccbCallbackName = "onbtn1_handler", callback = handler(self, QUIWidgetSystemSetting._onbtn1_handler)},
		{ccbCallbackName = "onbtn2_handler", callback = handler(self, QUIWidgetSystemSetting._onbtn2_handler)},
		{ccbCallbackName = "onbtn3_handler", callback = handler(self, QUIWidgetSystemSetting._onbtn3_handler)},
		{ccbCallbackName = "onbtn4_handler", callback = handler(self, QUIWidgetSystemSetting._onbtn4_handler)},
		{ccbCallbackName = "onbtn5_handler", callback = handler(self, QUIWidgetSystemSetting._onbtn5_handler)},
		{ccbCallbackName = "onMusicSwitch", callback = handler(self, QUIWidgetSystemSetting._onMusicSwitch)},
		{ccbCallbackName = "onSoundEffectSwitch", callback = handler(self, QUIWidgetSystemSetting._onSoundEffectSwitch)},
	}
	QUIWidgetSystemSetting.super.ctor(self, ccbFile, callBacks, options)

    self._contentHeight = self._ccbOwner.setting_size:getContentSize().height + self._ccbOwner.client_size:getContentSize().height + QUIWidgetSystemSetting.PAGE_MARGIN 

    -- lastMoveTime is used to know whether an event is a click or gesture movement
	self._lastMoveTime = q.time()

	self:loadSystemSettingState()
end

function QUIWidgetSystemSetting:onEnter()
	self:loadSystemSettingState()
	self:refreshSystemSettingState()
end

function QUIWidgetSystemSetting:onExit()
end

-- Remember the last state
function QUIWidgetSystemSetting:loadSystemSettingState()
	-- set settings state 
	self._musicOn = app:getSystemSetting():getMusicState() == "on" and true or false
	self._soundEffectOn = app:getSystemSetting():getSoundState() == "on" and true or false

	self._btn1State = app:getSystemSetting():getSystemSetting(1) == "on" and true or false
	self._btn2State = app:getSystemSetting():getSystemSetting(2) == "on" and true or false
	self._btn3State = app:getSystemSetting():getSystemSetting(3) == "on" and true or false
	self._btn4State = app:getSystemSetting():getSystemSetting(4) == "on" and true or false
	self._btn5State = app:getSystemSetting():getSystemSetting(5) == "on" and true or false
end

function QUIWidgetSystemSetting:refreshSystemSettingState()
    self._ccbOwner.btn1:setHighlighted(self._btn1State)
    self._ccbOwner.btn2:setHighlighted(self._btn2State)
    self._ccbOwner.btn3:setHighlighted(self._btn3State)
    self._ccbOwner.btn4:setHighlighted(self._btn4State)
    self._ccbOwner.btn5:setHighlighted(self._btn5State)
    self._ccbOwner.music_on:setVisible(self._musicOn)
    self._ccbOwner.music_off:setVisible(not self._musicOn)
    self._ccbOwner.soundeffect_on:setVisible(self._soundEffectOn)
    self._ccbOwner.soundeffect_off:setVisible(not self._soundEffectOn)
end

-- button1 handler 12:00
function QUIWidgetSystemSetting:_onbtn1_handler()
	if q.time() - self._lastMoveTime < QUIWidgetSystemSetting.EVENT_RESPOND_IGNORE then
		return
	end
	app.sound:playSound("common_item")

	self._btn1State = not self._btn1State
    self._ccbOwner.btn1:setHighlighted(self._btn1State)
    app:getSystemSetting():setSystemSetting(1, self._btn1State and "on" or "off")
end

-- 18:00
function QUIWidgetSystemSetting:_onbtn2_handler()
	if q.time() - self._lastMoveTime < QUIWidgetSystemSetting.EVENT_RESPOND_IGNORE then
		return
	end
	app.sound:playSound("common_item")

	self._btn2State = not self._btn2State
	self._ccbOwner.btn2:setHighlighted(self._btn2State)
    app:getSystemSetting():setSystemSetting(2, self._btn2State and "on" or "off")
end

-- 21:00
function QUIWidgetSystemSetting:_onbtn3_handler()
	if q.time() - self._lastMoveTime < QUIWidgetSystemSetting.EVENT_RESPOND_IGNORE then
		return
	end
	app.sound:playSound("common_item")

	self._btn3State = not self._btn3State
    self._ccbOwner.btn3:setHighlighted(self._btn3State)
    app:getSystemSetting():setSystemSetting(3, self._btn3State and "on" or "off")
end

function QUIWidgetSystemSetting:_onbtn4_handler()
	if q.time() - self._lastMoveTime < QUIWidgetSystemSetting.EVENT_RESPOND_IGNORE then
		return
	end
	app.sound:playSound("common_item")

	self._btn4State = not self._btn4State
    self._ccbOwner.btn4:setHighlighted(self._btn4State)
    app:getSystemSetting():setSystemSetting(4, self._btn4State and "on" or "off")
end

function QUIWidgetSystemSetting:_onbtn5_handler()
 	if q.time() - self._lastMoveTime < QUIWidgetSystemSetting.EVENT_RESPOND_IGNORE then
		return
	end
	app.sound:playSound("common_item")

	self._btn5State = not self._btn5State
    self._ccbOwner.btn5:setHighlighted(self._btn5State)
    app:getSystemSetting():setSystemSetting(5, self._btn5State and "on" or "off")

end

function QUIWidgetSystemSetting:_onMusicSwitch()
 	if q.time() - self._lastMoveTime < QUIWidgetSystemSetting.EVENT_RESPOND_IGNORE then
		return
	end
	app.sound:playSound("common_item")

	self._musicOn = not self._musicOn
    self._ccbOwner.music_on:setVisible(self._musicOn)
    self._ccbOwner.music_off:setVisible(not self._musicOn)
    audio.setMusicVolume(self._musicOn and 1 or 0)
	app:getSystemSetting():setMusicState(self._musicOn and "on" or "off")
end

function QUIWidgetSystemSetting:_onSoundEffectSwitch()
 	if q.time() - self._lastMoveTime < QUIWidgetSystemSetting.EVENT_RESPOND_IGNORE then
		return
	end
	app.sound:playSound("common_item")

	self._soundEffectOn = not self._soundEffectOn
    self._ccbOwner.soundeffect_on:setVisible(self._soundEffectOn)
    self._ccbOwner.soundeffect_off:setVisible(not self._soundEffectOn)
    audio.setSoundsVolume(self._soundEffectOn and 1 or 0)
	app:getSystemSetting():setSoundState(self._soundEffectOn and "on" or "off")
end

-- React on movement gesture
function QUIWidgetSystemSetting:onMove()
	self._lastMoveTime = q.time()
end

function QUIWidgetSystemSetting:endMove()
	self._lastMoveTime = q.time()
end

function QUIWidgetSystemSetting:getContentHeight()
	return self._contentHeight
end

return QUIWidgetSystemSetting