

local QUIDBDirector = class("QUIDBDirector")

local QUIDBNode = import(".QUIDBNode")
local QFileCache = import("....utils.QFileCache")

function QUIDBDirector:ctor(widgetActor, behaviorName, options)
	self._widgetActor = widgetActor
	if self:_createDisplayBehavior(behaviorName) == false then
		assert(false, " can not find a display behavior name:" .. tostring(behaviorName))
		return
	end

    self._soundEffects = {}

	self._isFinished = false
end

function QUIDBDirector:isFinished()
	return self._isFinished
end

function QUIDBDirector:_createDisplayBehavior(name)
	if name == nil then
		return false
	end

    local config = QFileCache.sharedFileCache():getDisplayConfigByName(name)
    if config ~= nil then
        self._displayBehavior = self:_createDisplayBehaviorNode(config)
    end

	return (self._displayBehavior ~= nil)
end

function QUIDBDirector:_createDisplayBehaviorNode(config)
	if config == nil or type(config) ~= "table" then
        return nil
    end

    local displayClass = QFileCache.sharedFileCache():getDisplayClassByName(config.CLASS)
    local options = clone(config.OPTIONS)
    local node = displayClass.new(self._widgetActor, self, options)

    local args = config.ARGS
    if args ~= nil then
        for k, v in pairs(args) do
            local child = self:_createDisplayBehaviorNode(v)
            if child ~= nil then
                node:addChild(child)
            end
        end
    end

    return node
end

function QUIDBDirector:visit(dt)
    if self._isFinished == true then
        return
    end

    if self._displayBehavior:getState() == QUIDBNode.STATE_FINISHED then
    	self._isFinished = true
        self._widgetActor:resetActor()
    elseif self._displayBehavior:getState() == QUIDBNode.STATE_EXECUTING then
    	self._displayBehavior:visit(dt)
    elseif self._displayBehavior:getState() == QUIDBNode.STATE_WAIT_START then
    	self._displayBehavior:start()
    end
end

function QUIDBDirector:cancel()
    self._displayBehavior:cancel()
    self._widgetActor:resetActor()
    self:_stopAllSoundEffect()
end

function QUIDBDirector:addSoundEffect(soundEffect)
    if soundEffect ~= nil then
        table.insert(self._soundEffects, soundEffect)
    end
end

function QUIDBDirector:stopSoundEffectById(id)
    if id == nil then
        return
    end
    
    for _, soundEffect in ipairs(self._soundEffects) do
        if soundEffect:getSoundId() == id then
            soundEffect:stop()
        end
    end
end

function QUIDBDirector:_stopAllSoundEffect()
    for _, soundEffect in ipairs(self._soundEffects) do
        soundEffect:stop()
    end
end

return QUIDBDirector