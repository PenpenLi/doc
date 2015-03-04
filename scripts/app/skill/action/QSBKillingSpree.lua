--[[
    Class name QSBKillingSpree
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBKillingSpree = class("QSBKillingSpree", QSBAction)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QBaseEffectView = import("...views.QBaseEffectView")

local SHUTTLE_FRAME_COUNT = 4

function QSBKillingSpree:_execute(dt)
	if not self._done_select_target then
		self:_selectTarget()
		self._done_select_target = true
	elseif not self._done_teleport then
		self:_teleport()
		self._done_teleport = true
	elseif not self._done_shuttle then
		self._done_shuttle = self:_shuttle()
	else
		self:finished()
	end
end

function QSBKillingSpree:_shuttle()
	local actor = self._attacker
	local target = actor:getTarget()

	if not target then
		self:finished()
		return
	end

	if not self._shuttle_inited then
		-- 初始化，穿梭的起始帧
		self._shuttle_frame = 1
		-- 朝向初始化
		local view = app.scene:getActorViewFromModel(actor)
		if math.xor(self._shuttle_distance > 0, view:getDirection() == view.DIRECTION_LEFT) then
			view:_setFlipX()
		end
		self._shuttle_inited = true
	end

	if self._shuttle_frame <= SHUTTLE_FRAME_COUNT then
		-- 播放残影特效
		local frontEffect, backEffect = QBaseEffectView.createEffectByID("killing_spree_3")
		local effect = frontEffect or backEffect
		effect:setPosition(actor:getPosition().x, actor:getPosition().y)
		effect:setScaleX((self._shuttle_distance < 0) and 1 or -1)
	    app.scene:addEffectViews(effect, {isFrontEffect = false})
    	effect:playAnimation(EFFECT_ANIMATION, true)
		local arr = CCArray:create()
		arr:addObject(CCFadeOut:create(0.2))
		arr:addObject(CCCallFunc:create(function()
			effect:stopAnimation()
			app.scene:removeEffectViews(effect)
		end))
    	effect:getSkeletonView():runAction(CCSequence:create(arr))
		-- 播放刀剑特效
		if self._shuttle_frame == 1 then
			local frontEffect, backEffect = QBaseEffectView.createEffectByID("killing_spree_1")
			local effect = frontEffect or backEffect
			local pos = clone(target:getCenterPosition())
			pos.x = pos.x + 80 * self._shuttle_distance / math.abs(self._shuttle_distance)
			effect:setPosition(pos.x, pos.y)
			effect:setScaleX((self._shuttle_distance < 0) and 1 or -1)
		    app.scene:addEffectViews(effect, {isFrontEffect = true})
	    	effect:playAnimation(EFFECT_ANIMATION, true)
	        effect:afterAnimationComplete(function()
	            app.scene:removeEffectViews(effect)
	        end)
		end
		-- 制造实际伤害
		if self._shuttle_frame == 2 then
			local target = self._attacker:getTarget() 
			if target and not target:isDead() then
				self._attacker:onHit(self._skill, target, nil, nil)
			end
		end
		-- 步进
		self._shuttle_frame = self._shuttle_frame + 1
		local position = clone(actor:getPosition())
		position.x = position.x + self._shuttle_distance / (SHUTTLE_FRAME_COUNT - 1)
		app.grid:moveActorTo(actor, position, true, true, true)
		return false
	else
		return true
	end
end

function QSBKillingSpree:_teleport()
	local in_range = self._options.in_range

	local actor = self._attacker
	local target = actor:getTarget()

	if not target then
		self:finished()
		return
	end

	local director = self._director
	if self._director._killing_spree_direction == nil then
		self._director._killing_spree_direction = math.random(1, 100) > 50 and "left" or "right"
	end

	local direction = self._director._killing_spree_direction
	local pos = clone(target:getPosition())
	local end_pos = clone(target:getPosition())
    local distance = (actor:getRect().size.width + target:getRect().size.width) / 2
	if direction == "right" then
		pos.x = pos.x - distance
		end_pos.x = end_pos.x + distance
	else
		pos.x = pos.x + distance
		end_pos.x = end_pos.x - distance
	end
	local isOutOfRange, gridPos = app.grid:_toGridPos(end_pos.x, end_pos.y)
	if in_range and isOutOfRange then
		direction = direction == "left" and "right" or "left"
		if direction == "right" then
			pos.x = pos.x - distance * 2
			end_pos.x = end_pos.x + distance * 2
		else
			pos.x = pos.x + distance * 2
			end_pos.x = end_pos.x - distance * 2
		end
	end
	app.grid:setActorTo(actor, pos, true, true)
	self._shuttle_distance = (actor:getTarget():getPosition().x - actor:getPosition().x) * 2
	self._director._killing_spree_direction = self._director._killing_spree_direction == "left" and "right" or "left"
end

function QSBKillingSpree:_selectTarget()
	local actor = self._attacker

	if not self._options.always and actor:getTarget() then
		return
	end

	if self._options.original_target then
		local target = self._director:getTarget()
		if target and not target:isDead() then
			actor:setTarget(target)
			return
		end
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
		if self._director:getTarget() == nil then
			self._director:setTarget(actor:getTarget())
		end
	elseif target_as_candidate then
	else
		if self._options.cancel_if_not_found then
			scheduler.performWithDelayGlobal(function()
				actor:_cancelCurrentSkill()
			end, 0)
		end
	end
end

return QSBKillingSpree