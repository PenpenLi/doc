
local QSkeletonViewController = class("QSkeletonViewController")

function QSkeletonViewController:sharedSkeletonViewController()
	if app._skeletonViewController == nil then
        app._skeletonViewController = QSkeletonViewController.new()
    end
    return app._skeletonViewController
end

function QSkeletonViewController:ctor()
	self._skeletonActors = {}
	self._skeletonEffects = {}
	self._skeletonActorsAttachedEffects = {}
	self._animationScale = 1.0
	self._externAnimationScale = 1.0
end

function QSkeletonViewController:getGlobalAnimationScale()
	return self._animationScale
end

function QSkeletonViewController:getExternAnimationScale()
	return self._externAnimationScale
end

function QSkeletonViewController:createSkeletonActorWithFile(file)
	local skeletonActor = QSkeletonActor:create(file)

	if skeletonActor ~= nil then
		self:_addSkeletonView(skeletonActor, self._skeletonActors)
	end

	return skeletonActor
end

function QSkeletonViewController:removeSkeletonActor(actor)
   self:_removeSkeletonView(actor, self._skeletonActors)
end

function QSkeletonViewController:createSkeletonEffectWithFile(file, actor, sizeRenderTexture)
	local skeletonView
	if sizeRenderTexture == nil then
		skeletonView = QSkeletonView:create(file)
	else
		skeletonView = QSkeletonView:create(file, sizeRenderTexture)
	end

	if skeletonView ~= nil then
		self:_addSkeletonActorAttachedEffect(skeletonView, actor)
		self:_addSkeletonView(skeletonView, self._skeletonEffects)
	end

	return skeletonView
end

function QSkeletonViewController:removeSkeletonEffect(effect)
	self:_removeSkeletonActorAttachedEffect(effect)
   	self:_removeSkeletonView(effect, self._skeletonEffects)
end

function QSkeletonViewController:setAllEffectsAnimationScale(scale)
	if scale < 0 then
        return
    end

	for _, v in ipairs(self._skeletonEffects) do
		if v.getFollowActor and not v:getFollowActor() then
			v:setAnimationScale(scale)
		end
	end

	self._externAnimationScale = scale
end

function QSkeletonViewController:resetAllEffectsAnimationScale()
	for _, v in ipairs(self._skeletonEffects) do
		v:setAnimationScale(self._animationScale)
	end
end

function QSkeletonViewController:resetAllAnimationScale()
	for _, v in ipairs(self._skeletonActors) do
		v:setAnimationScale(self._animationScale)
	end
	for _, v in ipairs(self._skeletonEffects) do
		v:setAnimationScale(self._animationScale)
	end
end

function QSkeletonViewController:_addSkeletonView(skeletonView, viewArray)
	if skeletonView == nil or viewArray == nil then
		return
	end

	for _, v in ipairs(viewArray) do
		if v == skeletonView then
			return
		end
	end
	table.insert(viewArray, skeletonView)
	skeletonView:retain()
end

function QSkeletonViewController:_removeSkeletonView(skeletonView, viewArray)
	if skeletonView == nil or viewArray == nil then
		return
	end

	for i, v in ipairs(viewArray) do
		if v == skeletonView then
			table.remove(viewArray, i)
			skeletonView:release()
			break
		end
	end
end

function QSkeletonViewController:_addSkeletonActorAttachedEffect(effect, actor)
	if effect == nil or actor == nil then
		return 
	end

	local indexOfActor = 0 
	for i, actorAttachedEffects in ipairs(self._skeletonActorsAttachedEffects) do
		if actorAttachedEffects.actor == actor then
			for _, skeletonEffect in ipairs(actorAttachedEffects.effects) do
				if skeletonEffect == effect then
					return
				end
			end
			indexOfActor = i
			break
		end
	end

	if indexOfActor > 0 then
		table.insert(self._skeletonActorsAttachedEffects[indexOfActor].effects, effect)
	else
		table.insert(self._skeletonActorsAttachedEffects, {actor = actor, effects = {effect}})
	end
end

function QSkeletonViewController:_removeSkeletonActorAttachedEffect(effect)
	if effect == nil then
		return 
	end

	local indexOfActor = 0 
	local indexOfEffect = 0
	for i, actorAttachedEffects in ipairs(self._skeletonActorsAttachedEffects) do
		for j, skeletonEffect in ipairs(actorAttachedEffects.effects) do
			if skeletonEffect == effect then
				indexOfEffect = j
				break
			end
		end
		if indexOfEffect > 0 then
			indexOfActor = i
			break
		end
	end

	if indexOfActor > 0 and indexOfEffect > 0 then
		table.remove(self._skeletonActorsAttachedEffects[indexOfActor].effects, indexOfEffect)
		if table.nums(self._skeletonActorsAttachedEffects[indexOfActor].effects) == 0 then
			table.remove(self._skeletonActorsAttachedEffects, indexOfActor)
		end
	end

end

return QSkeletonViewController