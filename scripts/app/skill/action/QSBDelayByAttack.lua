--[[
    Class name QSBDelayByAttack
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBDelayByAttack = class("QSBDelayByAttack", QSBAction)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QSBDelayByAttack:_execute(dt)
	if self._isExecuting == true then
		return
	end

    local haste = self._attacker:getMaxHaste()
    if self:isAffectedByHaste() == false then
        haste = 0.0
    end
	
    local displayId = self._attacker:getDisplayID()
    local characterDisplay = QStaticDatabase.sharedDatabase():getCharacterDisplayByID(displayId)
    local animationName = self._options.animation or self._skill:getActorAttackAnimation()
    local delayFrame = characterDisplay[animationName] or HIT_DELAY_FRAME
    local delay = delayFrame / SPINE_RUNTIME_FRAME * (1 / (1 + haste))
	self._delayHandle = app.battle:performWithDelay(function()
        self:finished()
    end, delay, self._attacker)

    self._isExecuting = true
end

function QSBDelayByAttack:_onCancel()
    if self._delayHandle ~= nil then
        app.battle:removePerformWithHandler(self._delayHandle)
    end
end

return QSBDelayByAttack