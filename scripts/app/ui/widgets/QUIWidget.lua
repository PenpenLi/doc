
local QUIWidget = class("QUIWidget", function()
    return display.newNode()
end)

function QUIWidget:ctor(ccbFile,callBacks,options)
	self._ccbOwner = {}

    if callBacks ~= nil then
        self:_setCCBOwnerValue(callBacks)
    end

    if ccbFile ~= nil then
        self._ccbView = app.ccbNodeCache:loadCCBI(ccbFile, self._ccbOwner)
        if self._ccbView == nil then
            assert(false, "load ccb file:" .. ccbFile .. " faild!")
        end
        self:addChild(self._ccbView)
    end

    self:setNodeEventEnabled(true)
end

function QUIWidget:getView()
    return self
end

function QUIWidget:getCCBView()
    return self._ccbView
end

function QUIWidget:onEnter()

end

function QUIWidget:onExit()

end

function QUIWidget:_setCCBOwnerValue(callbacks)
    if callbacks == nil then
        return
    end

    for i, v in ipairs(callbacks) do
        local ccbCallbackName = v.ccbCallbackName
        local callback = v.callback
        if ccbCallbackName ~= nil and callback ~= nil then
            self._ccbOwner[ccbCallbackName] = callback
        end
    end
end

return QUIWidget