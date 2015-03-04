--[[
    Class name QSBPlayEffect
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBPlayEffect = class("QSBPlayEffect", QSBAction)

local QActor = import("...models.QActor")
local QSkill = import("...models.QSkill")

function QSBPlayEffect:_execute(dt)
	local actors = {}
	local effectID = self._options.effect_id
	local haste = self._attacker:getMaxHaste()
    if self:isAffectedByHaste() == false then
        haste = 0.0
    end
	local options = {isFlipX = self._options.is_flip_x or false, isRandomPosition = self._options.is_random_position, time_scale = 1 / (1 + haste), followActorAnimation = self._options.follow_actor_animation}
	if self._options.is_hit_effect == true or self._options.is_second_hit_effect == true then

		if self._options.is_hit_effect == true then
			effectID = effectID or self._skill:getHitEffectID()
		elseif self._options.is_second_hit_effect == true then
			effectID = effectID or self._skill:getSecondHitEffectID()
		end

		if self._options.is_range_effect ~= true and self._skill:getRangeType() == QSkill.MULTIPLE then
			actors = self._attacker:getMultipleTargetWithSkill(self._skill, self._target)
		else
			if self._skill:getTargetType() == QSkill.SELF then
				table.insert(actors, self._attacker)
			else
				table.insert(actors, self._target)
			end
		end
	elseif self._options.is_target_effect == true then
		table.insert(actors, self._target)
	else
		table.insert(actors, self._attacker)
		effectID = effectID or self._skill:getAttackEffectID()
		options.isAttackEffect = true
		options.skillId = self._skill:getId()
	end

	if effectID == nil then
		self:finished()
		return 
	end

	if self._options.is_range_effect == true then
		local is_zone_follow = self._skill:isZoneFollow()
		if is_zone_follow and self._target then
			options.targetPosition = self._target:getPosition()
		else
			options.targetPosition = self._director:getTargetPosition()
		end
	end

	if self._options.is_rotate_to_target == true then
		if self._target ~= nil then
			local targetPos = self._target:getPosition()
	        local height = self._target:getCoreRect().size.height
			options.rotateToPosition = ccp(targetPos.x, targetPos.y + height * 0.5)
		end
	end

	local delay = self._options.delay_per_hit or 0
	local delayTime = 0
	for _, actor in ipairs(actors) do
		if delay > 0 then
			app.battle:performWithDelay(function()
                if actor:isDead() == false then
                    actor:playSkillEffect(effectID, nil, options)
                end
            end, delayTime, self._attacker)
            delayTime = delayTime + delay
		else
			actor:playSkillEffect(effectID, nil, options)
		end
	end

	self:finished()
end

return QSBPlayEffect