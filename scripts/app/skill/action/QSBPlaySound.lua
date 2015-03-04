--[[
    Class name QSBPlaySound
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBPlaySound = class("QSBPlaySound", QSBAction)

local QSoundEffect = import("...utils.QSoundEffect")

function QSBPlaySound:_execute(dt)
	local soundId = self._options.sound_id
	local isLoop =  self._options.is_loop or false

	if soundId == nil then
		self:finished()
		return 
	end

	local soundEffect = QSoundEffect.new(soundId, {isInBattle = true})
	soundEffect:play(isLoop)
	self._director:addSoundEffect(soundEffect)

	self:finished()
end

return QSBPlaySound