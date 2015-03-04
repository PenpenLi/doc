--[[
    Class name QBaseEffectView 
    Create by julian 
    This class is a base class of effect.
    Other effect class is inherit from this.
--]]
local QBaseEffectView = class("QBaseEffectView", function()
    return display.newNode()
end)

local QSoundEffect = import("..utils.QSoundEffect")
local QSkeletonViewController = import("..controllers.QSkeletonViewController")
local QStaticDatabase = import("..controllers.QStaticDatabase")

function QBaseEffectView.createEffectByID(effectID, attachedActorView, effectClass, options)
    if effectID == nil then
        return nil
    end

    if effectClass == nil then
        effectClass = QBaseEffectView
    end

    if options == nil then
        options = {}
    end

    local dataBase = QStaticDatabase.sharedDatabase()
    local frontEffectFile, backEffectFile = dataBase:getEffectFileByID(effectID)
    local soundId = dataBase:getEffectSoundIdById(effectID)
    local soundStop = dataBase:getEffectSoundStopByID(effectID)
    local delayTime = (dataBase:getEffectDelayByID(effectID) or 0)

    if options.time_scale then
        delayTime = delayTime * options.time_scale
    end

    local externalScale = options.externalScale or 1
    local externalRotate = options.externalRotate or 0

    local frontEffectView = nil
    if frontEffectFile ~= nil or soundId ~= nil then
        frontEffectView = effectClass.new(frontEffectFile, soundId, soundStop, {delay = delayTime, actorView = attachedActorView, sizeRenderTexture = options.size_render_texture})
    end

    local backEffectView = nil
    if backEffectFile ~= nil then
        if frontEffectView ~= nil then
            backEffectView = effectClass.new(backEffectFile, nil, soundStop, {delay = delayTime, actorView = attachedActorView, sizeRenderTexture = options.size_render_texture})
        else
            backEffectView = effectClass.new(backEffectFile, soundId, soundStop, {delay = delayTime, actorView = attachedActorView, sizeRenderTexture = options.size_render_texture})
        end
    end

    local scale = dataBase:getEffectScaleByID(effectID)
    local playSpeed = dataBase:getEffectPlaySpeedByID(effectID)
    local rotation = dataBase:getEffectRotationByID(effectID)

    if frontEffectView ~= nil and frontEffectView:getSkeletonView() ~= nil then
        frontEffectView:getSkeletonView():setSkeletonScaleX(scale * externalScale)
        frontEffectView:getSkeletonView():setSkeletonScaleY(scale * externalScale)
        frontEffectView:getSkeletonView():setAnimationScaleOriginal(playSpeed)
        frontEffectView:getSkeletonView():setPosition(dataBase:getEffectOffsetByID(effectID))
        frontEffectView:getSkeletonView():setRotation(rotation + externalRotate)
    end

    if backEffectView ~= nil and backEffectView:getSkeletonView() ~= nil then
        backEffectView:getSkeletonView():setSkeletonScaleX(scale * externalScale)
        backEffectView:getSkeletonView():setSkeletonScaleY(scale * externalScale)
        backEffectView:getSkeletonView():setAnimationScaleOriginal(playSpeed)
        backEffectView:getSkeletonView():setPosition(dataBase:getEffectOffsetByID(effectID))
        backEffectView:getSkeletonView():setRotation(rotation + externalRotate)
    end

    -- use for print log
    if frontEffectView then
        frontEffectView._effectID = effectID
        frontEffectView._frontAndBack = "front"
    end
    if backEffectView then
        backEffectView._effectID = effectID
        backEffectView._frontAndBack = "back"
    end

    if frontEffectView == nil and backEffectView == nil and soundId ~= nil then
        frontEffectView = effectClass.new(nil, soundId, soundStop, {delay = delayTime, actorView = attachedActorView})
    end
    
    return frontEffectView, backEffectView
end

function QBaseEffectView:ctor(effectFile, audioId, audioStop, options)
    if effectFile ~= nil then
        local effectScale = 1.0
        if options == nil then
            options = {}
        end
        if options.scale ~= nil then
            effectScale = options.scale
        end
        
        self._animationFile = effectFile .. ".json"
        local skeletonViewController = QSkeletonViewController.sharedSkeletonViewController()
        self._skeletonView = skeletonViewController:createSkeletonEffectWithFile(effectFile, options.actorView, options.sizeRenderTexture)
        local _self = self
        function self._skeletonView:getFollowActor()
            if _self.getFollowActor == nil then
                return nil
            end
            return _self:getFollowActor()
        end
        self._skeletonView:setScale(effectScale)

        if options.offsetX ~= nil and options.offsetY ~= nil then
            self._skeletonView:setPosition(ccp(options.offsetX, options.offsetY))
        end

        self._delayTime = 0
        if options.delay ~= nil then
            self._delayTime = options.delay
        end

        self:addChild(self._skeletonView)
        self._skeletonView:setVisible(false)
    end

    self._audioEffect = nil
    if audioId ~= nil then
        self._audioEffect = QSoundEffect.new(audioId, {isInBattle = true})
    end
    self._audioStop = audioStop
    self._isRunDelayAction = false
    self._isStoped = true
    self:setNodeEventEnabled(true)
end

function QBaseEffectView:getSkeletonView()
    return self._skeletonView
end

function QBaseEffectView:onEnter()
    
end

function QBaseEffectView:onExit()
    if self._frameId then
        scheduler.unscheduleGlobal(self._frameId)
        self._frameId = nil
    end
end

function QBaseEffectView:onCleanup()
    if self._skeletonView ~= nil then
        QSkeletonViewController.sharedSkeletonViewController():removeSkeletonEffect(self._skeletonView)
    end
end

function QBaseEffectView:_onFrame(dt)
    if self._isStoped == true or app.battle == nil or type(self._lastTime) ~= "number" then
        return
    end

    local currentTime = app.battle:getTime()
    local deltaTime = currentTime - self._lastTime
    local scale = 1.0
    if self._skeletonView ~= nil then
        scale = self._skeletonView:getAnimationScale()
    end
    local deltaTime = deltaTime * scale
    self._timePassed = self._timePassed + deltaTime
    self._lastTime = currentTime

    if self._isRunDelayAction == true then
        if self._timePassed > self._delayTime then
            self._isRunDelayAction = false
            self._skeletonView:setVisible(true)
            self:_doPlayAnimation(self._animationName, self._isLoop)
            self:_doAnimationEventSignal()
        else
            return
        end
    else
        if self._skeletonView ~= nil and (not self._followActor or not self._followActor:isInTimeStop())then
            self._skeletonView:updateAnimation(deltaTime)
        end
    end

end

function QBaseEffectView:isRunDelayAction()
    return self._isRunDelayAction
end

function QBaseEffectView:playAnimation(name, isLoop)
    if self._skeletonView == nil then
        return
    end

    if name == nil then
        return
    end
    
    if isLoop == nil then
        isLoop = false
    end

    if self._delayTime > 0 then
        self._isRunDelayAction = true
        self._skeletonView:setVisible(false)
    else
        self:_doPlayAnimation(name, isLoop)
    end
    self._animationName = name
    self._isLoop = isLoop
    self._lastTime = app.battle:getTime()
    self._timePassed = 0
    self._isStoped = false

    if self._frameId == nil then
        self._frameId = scheduler.scheduleUpdateGlobal(handler(self, self._onFrame))
    end
end

function QBaseEffectView:_doPlayAnimation(name, isLoop)
    if self._skeletonView == nil then
        return
    end

    self._skeletonView:setVisible(true)
    if self._skeletonView:playAnimation(name, isLoop) == false then
        printInfo(self._animationFile .. " can not find animation named: " .. name)
    end
    self._skeletonView:pauseAnimation()
end

function QBaseEffectView:stopAnimation()
    if self._isRunDelayAction == true then
        if self._callFuncParam ~= nil then
            self._callFuncParam()
        end
    else
        if self._skeletonView ~= nil then
            self._skeletonView:disconnectAnimationEventSignal()
            self._skeletonView:stopAnimation()
            if self._func ~= nil then
                self._func()
            end
        end
    end
    
    if self._audioStop then
        self:stopSoundEffect()
    end
    self._isStoped = true
end

function QBaseEffectView:_doAnimationEventSignal()
    if self._callFunc == nil then
        return
    end

    if self._callFuncParam == nil then
        local func = self._callFunc
        func()
    else
        local func = self._callFunc
        func(self._callFuncParam)
    end

    self._callFunc = nil
    self._callFuncParam = nil;
end

function QBaseEffectView:removeSelfAfterAnimationComplete()
    if self._isRunDelayAction == true then
        self._callFunc = handler(self, self._doRemoveSelfAfterAnimationComplete)
        self._callFuncParam = nil;
    else
        self:_doRemoveSelfAfterAnimationComplete()
    end
end

function QBaseEffectView:_doRemoveSelfAfterAnimationComplete()
    if self._skeletonView == nil then
        return
    end

    self._skeletonView:connectAnimationEventSignal(function(eventType, trackIndex, animationName, loopCount)
        if eventType == SP_ANIMATION_COMPLETE then
            self._skeletonView:disconnectAnimationEventSignal()
            self._isStoped = true
            if self._audioStop then
                self:stopSoundEffect()
            end
            app.battle:performWithDelay(function()
                self:removeFromParent()
            end, 0)
            
        end
    end)
end

function QBaseEffectView:afterAnimationComplete(func)
    if self._isRunDelayAction == true then
        self._callFunc = handler(self, self._doAfterAnimationComplete)
        self._callFuncParam = func;
    else
        self:_doAfterAnimationComplete(func)
    end
end

function QBaseEffectView:_doAfterAnimationComplete(func)
    if func == nil then
        return
    end

    if self._skeletonView == nil then
        if func ~= nil then
            func()
        end
        return
    end

    self._func = func

    self._skeletonView:connectAnimationEventSignal(function(eventType, trackIndex, animationName, loopCount)
        if eventType == SP_ANIMATION_COMPLETE then
            self._skeletonView:disconnectAnimationEventSignal()
            self._isStoped = true
            if self._audioStop then
                self:stopSoundEffect()
            end
            app.battle:performWithDelay(function()
                if func ~= nil then
                    func()
                end
                self._func = nil
            end, 0)
        end
    end)
end

function QBaseEffectView:playSoundEffect(loop)
    if SKIP_BATTLE_SOUND == true then
        return
    end

    if self._audioEffect ~= nil then
        self._audioEffect:play(loop)
    end
end

function QBaseEffectView:pauseSoundEffect()
    if SKIP_BATTLE_SOUND == true then
        return
    end

    if self._audioEffect ~= nil then
        self._audioEffect:pause()
    end
end

function QBaseEffectView:resumeSoundEffect()
    if SKIP_BATTLE_SOUND == true then
        return
    end

    if self._audioEffect ~= nil then
        self._audioEffect:resume()
    end
end

function QBaseEffectView:stopSoundEffect()
    if SKIP_BATTLE_SOUND == true then
        return
    end
    
    if self._audioEffect ~= nil then
        self._audioEffect:stop()
    end
end

function QBaseEffectView:isLoopSoundEffect()
    if self._audioEffect ~= nil then
        return self._audioEffect:isLoop()
    else
        return false
    end
end

function QBaseEffectView:setScissorEnabled(enabled)
    if self._skeletonView.setScissorEnabled then
        self._skeletonView:setScissorEnabled(enabled)
    end
end

function QBaseEffectView:setScissorRects(mask1, grad1, grad2, mask2)
    if self._skeletonView.setScissorRects then
        self._skeletonView:setScissorRects(mask1, grad1, grad2, mask2)
    end
end

function QBaseEffectView:setOpacityActor(opacity)
    if self._skeletonView.setOpacityActor then
        self._skeletonView:setOpacityActor(opacity)
    end
end

function QBaseEffectView:setScissorBlendFunc(func)
    if self._skeletonView.setScissorBlendFunc then
        self._skeletonView:setScissorBlendFunc(func)
    end
end

function QBaseEffectView:setScissorColor(color)
    if self._skeletonView.setScissorColor then
        self._skeletonView:setScissorColor(color)
    end
end

function QBaseEffectView:setScissorOpacity(opacity)
    if self._skeletonView.setScissorOpacity then
        self._skeletonView:setScissorOpacity(opacity)
    end
end

function QBaseEffectView:setRenderTextureBlendFunc(func)
    if self._skeletonView.setRenderTextureBlendFunc then
        self._skeletonView:setRenderTextureBlendFunc(func)
    end
end

function QBaseEffectView:setFollowActor(followActor)
    self._followActor = followActor
end

function QBaseEffectView:getFollowActor()
    return self._followActor
end

return QBaseEffectView