--
-- Author: wkwang
-- Date: 2014-12-13 16:03:06
--
local QSound = class("QSound")
local QStaticDatabase = import("..controllers.QStaticDatabase")
	
function QSound:ctor(options)
	self:reloadSoundConfig()
end

function QSound:reloadSoundConfig()
	self._soundConfig = QStaticDatabase:sharedDatabase():getSound()
end

function QSound:playSound(soundId)
    return audio.playSound(self:getSoundURLById(soundId), false)
end

function QSound:playMusic(soundId)
    return audio.playMusic(self:getSoundURLById(soundId))
end

function QSound:playBackgroundMusic(soundId)
    return audio.playBackgroundMusic(self:getSoundURLById(soundId))
end

function QSound:getSoundURLById(soundId)
	if self._soundConfig == nil then
		printError("QSound._soundConfig not exist")
		return "not_exist"
	end

	if self._soundConfig[soundId] == nil then
		assert(false, string.format("soundId: %s not in soundConfig !", soundId))
	end
	return self._soundConfig[soundId].sound
end

return QSound