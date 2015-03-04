
local QUIViewController = import("..QUIViewController")
local QUIPage = class("QUIPage", QUIViewController)

local QUIWidgetOpenEffect = import("..widgets.QUIWidgetOpenEffect")

function QUIPage:ctor(ccbFile,callBacks,options)
	QUIPage.super.ctor(self, QUIViewController.TYPE_PAGE, ccbFile, callBacks, options)
end

function QUIPage:addSubViewController(controller)
    if controller == nil or controller:getView() == nil then
        return
    end

    if controller:getParentController() ~= nil then
        assert(false, "controller is already have parent!")
        return
    end

    local isAnimation = controller.isAnimation
    isAnimation = (isAnimation == nil) and false or isAnimation

    controller:viewWillAppear()
    controller:setParentController(self)
    table.insert(self._subViewControllers, controller)
    self:_addViewSubView(controller:getView())
    if controller.playEffectIn then
      controller:playEffectIn()
    end
    controller:viewDidAppear() 
end

function QUIPage:_addViewSubView(view)
    if view == nil then
        return
    end

    if self._view == nil then
        assert(false, "self view is invalid!")
        return
    end

	 self._view:addChild(view)
end

return QUIPage