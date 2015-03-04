--[[
    Class name QSBSelectTarget
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBSelectTarget = class("QSBSelectTarget", QSBAction)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QSBSelectTarget:_execute(dt)
	if self._executed then
		return
	end
	self._executed = true

	local actor = self._attacker

	if not self._options.always and actor:getTarget() then
		self:finished()
		return
	end

	local range_min = 0
	local range_max = 9999
	if self._options.range then
		local min = self._options.range.min
		if min then
			range_min = min
		end
		local max = self._options.range.max
		if max then
			range_max = max
		end
	end
	range_min = range_min * range_min * global.pixel_per_unit * global.pixel_per_unit
	range_max = range_max * range_max * global.pixel_per_unit * global.pixel_per_unit

	local target = actor:getTarget()
	local enemies = app.battle:getMyEnemies(actor)
	local candidates = {}
	local target_as_candidate = nil
	for _, enemy in ipairs(enemies) do
        if not enemy:isDead() then
            local x = enemy:getPosition().x - actor:getPosition().x
            local y = enemy:getPosition().y - actor:getPosition().y
            local d = x * x + y * y * 4
            if d <= range_max and d >= range_min then
            	if enemy == target then
            		target_as_candidate = enemy
            	else
            		table.insert(candidates, enemy)
            	end
            end
        end
	end

	if #candidates > 0 then
		actor:setTarget(candidates[math.random(1, #candidates)])
		local view = app.scene:getActorViewFromModel(actor)
		view:_verifyFlip()
		self:finished()
	elseif target_as_candidate then
		self:finished()
	else
		if self._options.cancel_if_not_found then
			scheduler.performWithDelayGlobal(function()
				actor:_cancelCurrentSkill()
			end, 0)
		else
			self:finished()
		end
	end
end

return QSBSelectTarget