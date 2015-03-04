

local QUIWidget = import("..QUIWidget")
local QUIWidgetSkeletonEffect = class("QUIWidgetSkeletonEffect", QUIWidget)

local QSoundEffect = import("....utils.QSoundEffect")
local QSkeletonViewController = import("....controllers.QSkeletonViewController")
local QStaticDatabase = import("....controllers.QStaticDatabase")

function QUIWidgetSkeletonEffect.createEffectByID(effectID, options)
    if effectID == nil then
        return nil
    end

    if options == nil then
        options = {}
    end

    if options.time_scale then
        delayTime = delayTime * options.time_scale
    end

    local dataBase = QStaticDatabase.sharedDatabase()
    local frontEffectFile, backEffectFile = dataBase:getEffectFileByID(effectID)
    local soundId = dataBase:getEffectSoundIdById(effectID)
    local soundStop = dataBase:getEffectSoundStopByID(effectID)
    local delayTime = (dataBase:getEffectDelayByID(effectID) or 0)

    local externalScale = options.externalScale or 1
    local externalRotate = options.externalRotate or 0

    local frontEffectView = nil
    if frontEffectFile ~= nil or soundId ~= nil then
        frontEffectView = QUIWidgetSkeletonEffect.new(frontEffectFile, soundId, soundStop, {delay = delayTime})
    end

    local backEffectView = nil
    if backEffectFile ~= nil then
        if frontEffectView ~= nil then
            backEffectView = QUIWidgetSkeletonEffect.new(backEffectFile, nil, soundStop, {delay = delayTime})
        else
            backEffectView = QUIWidgetSkeletonEffect.new(backEffectFile, soundId, soundStop, {delay = delayTime})
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

    return frontEffectView, backEffectView
end

function QUIWidgetSkeletonEffect:ctor(effectFile, audioId, audioStop, options)
    if effectFile ~= nil then
        local effectScale = 1.0
        if options == nil then
            options = {}
        end
        if options.scale ~= nil then
            effectScale = options.scale
        end
        
        local skeletonViewController = QSkeletonViewController.sharedSkeletonViewController()
        self._skeletonEffect = skeletonViewController:createSkeletonEffectWithFile(effectFile)
        self._skeletonEffect:setScale(effectScale)

        if options.offsetX ~= nil and options.offsetY ~= nil then
            self._skeletonEffect:setPosition(ccp(options.offsetX, options.offsetY))
        end

        self._delayTime = 0
        if options.delay ~= nil then
            self._delayTime = options.delay
        end

        self:addChild(self._skeletonEffect)
        self._skeletonEffect:setVisible(false)
    end

    self._audioEffect = nil
    if audioId ~= nil then
        self._audioEffect = QSoundEffect.new(audioId)
    end

    self._audioStop = audioStop
    self._isRunDelayAction = false
    self._isStoped = true

    self:setNodeEventEnabled(true)
end

function QUIWidgetSkeletonEffect:getSkeletonView()
    return self._skeletonEffect
end

function QUIWidgetSkeletonEffect:playAnimation(name, isLoop)
    if self._skeletonEffect == nil or name == nil then
        return
    end
    
    if isLoop == nil then
        isLoop = false
    end

    if self._delayTime > 0 then
        self._isRunDelayAction = true

        local array = CCArray:create()
        array:addObject(CCDelayTime:create(self._delayTime))
        array:addObject(CCCallFunc:create(function()
        	self:_doPlayAnimation(name, isLoop)
        	if self._callFunc ~= nil then
        		self._callFunc(self._callFuncParam)
        	end
        end))
        self:runAction(CCSequence:create(array))
    else
        self:_doPlayAnimation(name, isLoop)
    end
    -- self._animationName = name
    -- self._isLoop = isLoop
    self._isStoped = false
end

function QUIWidgetSkeletonEffect:_doPlayAnimation(name, isLoop)
    if self._skeletonEffect == nil then
        return
    end

    self._skeletonEffect:setVisible(true)
    if self._skeletonEffect:playAnimation(name, isLoop) == false then
        printInfo(self._animationFile .. " can not find animation named: " .. name)
    end
end

function QUIWidgetSkeletonEffect:afterAnimationComplete(callback)
    if self._isRunDelayAction == true then
        self._callFunc = handler(self, self._doAfterAnimationComplete)
        self._callFuncParam = callback;
    else
        self:_doAfterAnimationComplete(callback)
    end
end

function QUIWidgetSkeletonEffect:_doAfterAnimationComplete(callback)
    if self._skeletonEffect == nil then
        return
    end

    self._skeletonEffect:connectAnimationEventSignal(function(eventType, trackIndex, animationName, loopCount)
        if eventType == SP_ANIMATION_COMPLETE then
            self._skeletonEffect:disconnectAnimationEventSignal()
            self._isStoped = true
            if self._audioStop then
                self:stopSoundEffect()
            end
            callback()
        end
    end)
end

function QUIWidgetSkeletonEffect:stopAnimation()
    if self._isRunDelayAction == true then
        self:stopAllActions()
    else
        if self._skeletonEffect ~= nil then
            self._skeletonEffect:disconnectAnimationEventSignal()
            self._skeletonEffect:stopAnimation()
        end
    end
    
    if self._audioStop then
        self:stopSoundEffect()
    end
    self._isStoped = true
end

function QUIWidgetSkeletonEffect:playSoundEffect(loop)
    if self._audioEffect ~= nil then
        self._audioEffect:play(loop)
    end
end

function QUIWidgetSkeletonEffect:stopSoundEffect()
    if self._audioEffect ~= nil then
        self._audioEffect:stop()
    end
end

function QUIWidgetSkeletonEffect:onCleanup()
    local skeletonViewController = QSkeletonViewController.sharedSkeletonViewController()
    skeletonViewController:removeSkeletonEffect(self._skeletonEffect)
end

return QUIWidgetSkeletonEffect