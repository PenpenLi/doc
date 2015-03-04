
local QSBAction = import(".QSBAction")
local QSBActorScale = class("QSBActorScale", QSBAction)

function QSBActorScale:_execute(dt)
	local actor = nil
	if self._options.is_attacker == true then
		actor = self._attacker
	else
		actor = self._target
	end

	if actor ~= nil then
		local actorView = app.scene:getActorViewFromModel(actor)
		if actorView ~= nil then
			local scale = self._options.scale_to or 1.0
			local duration = self._options.duration or 0.1
			actorView:runAction(CCEaseIn:create(CCScaleTo:create(duration, scale), 3))
			self._actorView = actorView
			self._duration = duration
			self._scaleTo = scale
		end
	end
	
	if self._actorView ~= nil then
		self._delayHandle = app.battle:performWithDelay(function()
			self._director:setActorScale(self._scaleTo)
	        self:finished()
	    end, self._duration, self._attacker)
	else
		self:finished()
	end
	
end

function QSBActorScale:_onCancel()
	if self._delayHandle ~= nil then
		app.battle:removePerformWithHandler(self._delayHandle)
    end
	if self._actorView ~= nil then
    	self._actorView:stopAllActions()
    	self._actorView:setScale(1.0)
    end
end

return QSBActorScale