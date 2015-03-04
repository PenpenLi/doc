--[[
    Class name QSoundEffect
    Create by julian 
    This class is a base class of play sound effect in battle.
--]]

local QSoundEffect = class("QSoundEffect")

local QStaticDatabase = import("..controllers.QStaticDatabase")

function QSoundEffect:ctor(soundId, options)
	assert(soundId ~= nil, "soundId is nil value")

	local soundInfo = QStaticDatabase.sharedDatabase():getSoundById(soundId)
	assert(soundInfo ~= nil, soundId .." is a invalid id of sound")

	self._soundId = soundId
	self._soundInfo = clone(soundInfo)

	-- fill default value
	if self._soundInfo.delay == nil then
		self._soundInfo.delay = 0
	end
	if self._soundInfo.volume == nil then
		self._soundInfo.volume = 1.0
	end
	if self._soundInfo.count == nil then
		self._soundInfo.count = 1
	end

	-- get sound file
	if self._soundInfo.sound == nil then
		printInfo("sound file is nil of sound id " .. soundId)
		self._soundInfo.sound = "unknow.mp3"
	end
	local suffix = string.sub(self._soundInfo.sound, -4)
	if suffix ~= ".mp3" then
		if self._soundInfo.count == 1 then
			self._soundInfo.sound = self._soundInfo.sound .. ".mp3"
		else
			local index = math.random(1, 10240) % self._soundInfo.count + 1
        	self._soundInfo.sound = self._soundInfo.sound .. "_" .. tostring(index) .. ".mp3"
		end
	end

	-- other options
	self._soundHandle = nil
    self._isLoop = false
    self._delayHandle = nil
    if options.isInBattle == true and app.battle ~= nil then
    	self._schedulerInBattle = true 
    else
    	self._schedulerInBattle = false
    end
end

function QSoundEffect:play(isLoop)
	if isLoop == nil then
		isLoop = false
	end

	self._isLoop = isLoop

	if self._soundInfo.delay > 0 then
		local delayCallback = function()
				self._delayHandle = nil
				self:_doPlay()
			end
		if self._schedulerInBattle == true then
			self._delayHandle = app.battle:performWithDelay(delayCallback, self._soundInfo.delay)
		else
			self._delayHandle = scheduler.performWithDelayGlobal(delayCallback, self._soundInfo.delay)
		end
	else
		self:_doPlay()
	end
end

function QSoundEffect:_doPlay()
	if SKIP_BATTLE_SOUND == true then
        return
    end

	self._soundHandle = audio.playSound(self._soundInfo.sound, self._isLoop, self._soundInfo.volume)
end

function QSoundEffect:stop()
	if SKIP_BATTLE_SOUND == true then
        return
    end

    if self._delayHandle ~= nil then
    	if self._schedulerInBattle == true then
    		app.battle:removePerformWithHandler(self._delayHandle)
    	else
    		scheduler.unscheduleGlobal(self._delayHandle)
    	end
    	self._delayHandle = nil
    else
    	if self._soundHandle ~= nil then
    		audio.stopSound(self._soundHandle)
    		self._soundHandle = nil
    		self._isLoop = false
    	end
    end
end

function QSoundEffect:pause()
	if SKIP_BATTLE_SOUND == true then
        return
    end
	
	if self._soundHandle ~= nil then
		audio.pauseSound(self._soundHandle)
	end
end

function QSoundEffect:resume()
	if SKIP_BATTLE_SOUND == true then
        return
    end
	
	if self._soundHandle ~= nil then
		audio.resumeSound(self._soundHandle)
	end
end

function QSoundEffect:getSoundId()
	return self._soundId
end

function QSoundEffect:isLoop()
	return self._isLoop
end

return QSoundEffect

