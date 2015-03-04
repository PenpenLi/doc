
local QUIViewController = class("QUIViewController")

QUIViewController.TYPE_PAGE = "UI_TYPE_PAGE"
QUIViewController.TYPE_DIALOG = "UI_TYPE_DIALOG"
-- QUIViewController.TYPE_WIDGET = "UI_TYPE_WIDGET"

-- callbacks is table like: {{ccbCallbackName=name, callBack=function}}
-- function can be get like: handler(self, ClassName.function)
function QUIViewController:ctor(type, ccbFile, callbacks, options)
    self._type = type
    self._ccbOwner = {}

    if callbacks ~= nil then
        self:_setCCBOwnerValue(callbacks)
    end

    if ccbFile ~= nil then
        local proxy = CCBProxy:create()
        self._view = CCBuilderReaderLoad(ccbFile, proxy, self._ccbOwner)
        if self._view == nil then
            assert(false, "load ccb file:" .. ccbFile .. " faild!")
        end
    end

    self._parentViewController = nil
    self._subViewControllers = {}
end

function QUIViewController:getType()
    return self._type
end

function QUIViewController:getView()
    return self._view
end

function QUIViewController:setParentController(controller)
    if controller == nil then
        return
    end

    self._parentViewController = controller
end

function QUIViewController:getParentController()
    return self._parentViewController
end

function QUIViewController:getNodeFromName(name)
    local node = self._ccbOwner[name]
    
    if node ~= nil then
        if type(node) == "function" then
            node = nil
        end
    end

    return node
end

function QUIViewController:addSubViewController(controller)
    if controller == nil or controller:getView() == nil then
        return
    end

    if controller:getParentController() ~= nil then
        assert(false, "controller is already have parent!")
        return
    end

    controller:viewWillAppear()
    controller:setParentController(self)
    table.insert(self._subViewControllers, controller)
    self:_addViewSubView(controller:getView())
    controller:viewDidAppear()
end

function QUIViewController:removeSubViewController(controller)
    if controller == nil or controller:getView() == nil then
        return
    end

    for i, v in ipairs(self._subViewControllers) do
        if controller == v then
            controller:viewWillDisappear()
            self:_removeViewSubView(controller:getView())
            controller:setParentController(nil)
            table.remove(self._subViewControllers, i)
            controller:viewDidDisappear()
            break
        end
    end
end

function QUIViewController:removeFromParentController()
    if self._parentViewController == nil then
        return
    end

    self._parentViewController:removeSubViewController(self)
end

function QUIViewController:viewWillAppear()

end

function QUIViewController:viewDidAppear()

end

function QUIViewController:viewWillDisappear()
    
end

function QUIViewController:viewDidDisappear()
    
end

function QUIViewController:_addViewSubView(view)
    if view == nil then
        return
    end

    if self._view == nil then
        assert(false, "self view is invalid!")
        return
    end

    self._view:addChild(view)
end

function QUIViewController:_removeViewSubView(view)
    if view == nil then
        return
    end

    if self._view == nil then
        assert(false, "self view is invalid!")
        return
    end

    self._view:removeChild(view, true)
end

function QUIViewController:_setCCBOwnerValue(callbacks)
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

return QUIViewController