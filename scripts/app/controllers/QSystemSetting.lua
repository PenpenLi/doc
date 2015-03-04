--
-- Author: qinyuanji
-- Date: 2014-11-28 
-- Note: this class is to wrap the system setting functions, but it has hard code like 12,18,21 o'clock notifiction


local QSystemSetting = class("QSystemSetting")
local QNotificationWrapper = import("..utils.QNotificationWrapper")

QSystemSetting.SYSTEM_SETTING = "SYSTEM_SETTING"
QSystemSetting.MUSIC_STATE = "MUSIC_STATE"
QSystemSetting.SOUND_STATE = "SOUND_STATE"

QSystemSetting.REPEAT_TIME = 60 * 24 -- in minute
QSystemSetting.PROMPT_12 = NOTIFICATION_12
QSystemSetting.PROMPT_18 = NOTIFICATION_18
QSystemSetting.PROMPT_21 = NOTIFICATION_21
QSystemSetting.PROMPT_ENERGY_RECOVERED = NOTIFICATION_ENERGY_RECOVERED
QSystemSetting.PROMPT_SKILL_RECOVERED = NOTIFICATION_SKILL_RECOVERED
QSystemSetting.NAME_12 = "12" -- Android uses numeric value to identify notificaiton
QSystemSetting.NAME_18 = "18"
QSystemSetting.NAME_21 = "21"
QSystemSetting.NAME_ENERGY_RECOVERED= "22"
QSystemSetting.NAME_SKILL_RECOVERED = "23"
QSystemSetting.HOUR_12 = 12
QSystemSetting.HOUR_18 = 18
QSystemSetting.HOUR_21 = 21

function QSystemSetting:ctor()
   	self._musicState = app:getUserData():getValueForKey(QSystemSetting.MUSIC_STATE)
   	self._soundState = app:getUserData():getValueForKey(QSystemSetting.SOUND_STATE)

   	self._notificationWrapper = QNotificationWrapper.new()

	self:disable()
end

function QSystemSetting:reload()
	local str = app:getUserData():getUserValueForKey(QSystemSetting.SYSTEM_SETTING)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    if str == nil then
        self._settings = {}
        self:setSystemSetting(1, "on")
        self:setSystemSetting(2, "on")
        self:setSystemSetting(3, "on")
        self:setSystemSetting(4, "on")
        self:setSystemSetting(5, "on")
    else
   		self._settings = string.split(str, ";")
   	end

   	self:disable()
end

-- turn on all the open notificaitons
function QSystemSetting:enable()
	if self._settings ~= nil then
	   	self:setLocalNotification_12(self._settings[1])
	   	self:setLocalNotification_18(self._settings[2])
	   	self:setLocalNotification_21(self._settings[3])
	   	self:setLocalNotification_EnergyRecovered(self._settings[4])
	   	self:setLocalNotification_SkillRecovered(self._settings[5])
   	end
end

-- turn off all the notifications
function QSystemSetting:disable()
   	self:setLocalNotification_12("off")
   	self:setLocalNotification_18("off")
   	self:setLocalNotification_21("off")
   	self:setLocalNotification_EnergyRecovered("off")
   	self:setLocalNotification_SkillRecovered("off")
end

-- on or off
function QSystemSetting:setMusicState(state)
	self._musicState = state
	app:getUserData():setValueForKey(QSystemSetting.MUSIC_STATE, state)
end

function QSystemSetting:getMusicState()
	return self._musicState or "on"
end

-- on or off
function QSystemSetting:setSoundState(state)
	self._soundState = state
	app:getUserData():setValueForKey(QSystemSetting.SOUND_STATE, state)
end

function QSystemSetting:getSoundState()
	return self._soundState or "on"
end

-- on or off
function QSystemSetting:setSystemSetting(index, state)
	if self._settings == nil then
		return
	end

	for i = 1, index - 1 do
		if self._settings[i] == nil then
			self._settings[i] = "off"
		end
	end
	self._settings[index] = state
	app:getUserData():setUserValueForKey(QSystemSetting.SYSTEM_SETTING, table.join(self._settings, ";"))
end

function QSystemSetting:getSystemSetting(index)
	if self._settings == nil then
		return "off"
	end

	return self._settings[index]
end

-- on or off
function QSystemSetting:setLocalNotification_12(state)
	if state == "on" then
    	self._notificationWrapper:addLocalNotificationTo(QSystemSetting.NAME_12, QSystemSetting.PROMPT_12, QSystemSetting.HOUR_12, 0, 0, QSystemSetting.REPEAT_TIME)
    else
    	self._notificationWrapper:removeLocalNotification(QSystemSetting.NAME_12)		
	end
end

function QSystemSetting:setLocalNotification_18(state)
	if state == "on" then
	   	self._notificationWrapper:addLocalNotificationTo(QSystemSetting.NAME_18, QSystemSetting.PROMPT_18, QSystemSetting.HOUR_18, 0, 0, QSystemSetting.REPEAT_TIME)
    else
    	self._notificationWrapper:removeLocalNotification(QSystemSetting.NAME_18)		
	end
end

function QSystemSetting:setLocalNotification_21(state)
	if state == "on" then
	   	self._notificationWrapper:addLocalNotificationTo(QSystemSetting.NAME_21, QSystemSetting.PROMPT_21, QSystemSetting.HOUR_21, 0, 0, QSystemSetting.REPEAT_TIME)
    else
    	self._notificationWrapper:removeLocalNotification(QSystemSetting.NAME_21)		
	end
end

-- We need to re-calculate the time to recovered energy, so we re-create the notification 
function QSystemSetting:setLocalNotification_EnergyRecovered(state)
	if state == "on" then
		self._notificationWrapper:removeLocalNotification(QSystemSetting.NAME_ENERGY_RECOVERED)	

		if remote.user.energy == nil or remote.user.energy >= global.config.max_energy then
			return
		end	

		-- We can't calculate the remaining time by using (maximumEnergy - currentEnergy) * interval
		-- Because we don't know how long it elapsed for one point
		-- So we have to use energyRefreshAt to know the time of latest changed energy and get the elapsed time for one point.
		local secondsToMaximum2 = (global.config.max_energy - remote.user.energy) * global.config.energy_refresh_interval
		local secondsToMaximum = secondsToMaximum2 - math.floor((q.time() * 1000 - remote.user.energyRefreshedAt)/1000)%global.config.energy_refresh_interval
		self._notificationWrapper:addLocalNotificationBy(QSystemSetting.NAME_ENERGY_RECOVERED, QSystemSetting.PROMPT_ENERGY_RECOVERED, secondsToMaximum, 0)
    else
    	self._notificationWrapper:removeLocalNotification(QSystemSetting.NAME_ENERGY_RECOVERED)		
	end
end

function QSystemSetting:setLocalNotification_SkillRecovered(state)
	if state == "on" then
		self._notificationWrapper:removeLocalNotification(QSystemSetting.NAME_SKILL_RECOVERED)		

		local point, lastTime = remote.herosUtil:getSkillPointAndTime()
		if point < global.config.max_skill then
			local secondsToMaximum = (global.config.max_skill - point - 1) * global.config.skill_refresh_interval + lastTime
	   		self._notificationWrapper:addLocalNotificationBy(QSystemSetting.NAME_SKILL_RECOVERED, QSystemSetting.PROMPT_SKILL_RECOVERED, secondsToMaximum, 0)
	   	end
    else
    	self._notificationWrapper:removeLocalNotification(QSystemSetting.NAME_SKILL_RECOVERED)		
	end
end

return QSystemSetting