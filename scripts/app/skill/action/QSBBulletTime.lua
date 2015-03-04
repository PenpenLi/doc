
local QSBAction = import(".QSBAction")
local QSBBulletTime = class("QSBBulletTime", QSBAction)

local QSkeletonViewController = import("...controllers.QSkeletonViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")

function QSBBulletTime:_execute(dt)
	if app.battle:isPVPMode() and self._attacker:getType() == ACTOR_TYPES.NPC then
		self:finished()
		return
	end

	if self._options.turn_on == true and not self._director:isInBulletTime() then
		QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QNotificationCenter.EVENT_BULLET_TIME_TURN_ON, actor = self._attacker})
		self._director:setIsInBulletTime(true)
	elseif not self._options.turn_on and self._director:isInBulletTime() then
		QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QNotificationCenter.EVENT_BULLET_TIME_TURN_OFF, actor = self._attacker})
		self._director:setIsInBulletTime(false)
	end
	self._executed = true
	self:finished()
end

return QSBBulletTime