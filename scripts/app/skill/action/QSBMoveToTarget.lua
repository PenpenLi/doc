--[[
    冲锋技能第一阶段
--]]

local QSBAction = import(".QSBAction")
local QSBMoveToTarget = class("QSBMoveToTarget", QSBAction)

local MOVE_TIMEOUT = 0.7 -- 多少秒以后依然没有移动认为超时，该动作结束

function QSBMoveToTarget:_execute(dt)
	if self._target == nil then
		self:finished()
		return
	end

	if self._attacker:getTarget() ~= self._target then
        -- 过程中可能target挂了，此刻attacker中的target会被设置为nil
		self:finished()
        return
	end

	if self:getOptions().is_position and self._first == nil then
		local actor = self._attacker
		local target = self._target
	--	app.grid:moveActorTo(actor, target:getPosition(), false)
		app.grid:moveActorToTarget(actor, target, false, true)
    	self._first = true
	end

	if self._attacker:isWalking() then
	    --当对象开始移动后，记录一个标志位
		self._moveStarted = true
	else
	    -- 如果此刻对象没有移动，则判断是否移动过，如果是，则停止冲锋
	    if self._moveStarted == true then
	        self:finished()
        elseif self._moveWaitFrom == nil then 
            -- 如果始终没有移动，则超时后停止冲锋
            self._moveWaitFrom = app.battle:getTime()
        elseif app.battle:getTime() - self._moveWaitFrom >= MOVE_TIMEOUT then
            self:finished()
        end
   end

end

function QSBMoveToTarget:_onCancel()
end

return QSBMoveToTarget
