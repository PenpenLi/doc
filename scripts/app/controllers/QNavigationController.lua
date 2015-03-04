
local QNavigationController = class("QNavigationController")

local QStat = import("..utils.QStat")
local QUIViewController = import("..ui.QUIViewController")
local QUIPage = import("..ui.pages.QUIPage")
local QUIDialog = import("..ui.dialogs.QUIDialog")
local QUITransition = import("..ui.transitions.QUITransition")
local QNotificationCenter = import(".QNotificationCenter")

QNavigationController.TRANSITION_TYPE_NONE = "TRANSITION_TYPE_NONE"
QNavigationController.TRANSITION_TYPE_FADE = "TRANSITION_TYPE_FADE"

QNavigationController.POP_TOP_CONTROLLER = "POP_TOP_CONTROLLER"
QNavigationController.POP_SPECIFIC_CONTROLLER = "POP_SPECIFIC_CONTROLLER"
QNavigationController.POP_TO_CURRENT_PAGE = "POP_TO_CURRENT_PAGE"
QNavigationController.POP_CURRENT_PAGE = "POP_CURRENT_PAGE"

QNavigationController.EVENT_BACK_PAGE = "EVENT_BACK_PAGE"

function QNavigationController:ctor(rootController, name)
    if rootController == nil then
        assert(false, "root controller can not be nil!")
        return
    end
    self._controllerClassCache = {}
    self._transitionClassCache = {}
    -- stack is much like { {page, dialog, dialog}, {page}, ... } 
    self._stack = {}
    self._currentIndex = 0
    self._currentPage = nil
    self._currentTransition = nil
    self._rootController = rootController
    self._name = name or "A NavigationController"
end

--[[ 
    controllerParams:
    uiType: page, dialog or widget. see QUIViewController
    uiClass: the class name
    options: recreate options

    transitionParams:
    transitionClass: the class name
    isPopCurrentDialog: boolean value only use for push dialog
    transitionOptions: recreate options
--]]

function QNavigationController:pushViewController(controllerParams, transitionParams)
    -- check is valid param
    if self:_checkIsValidControllerParam(controllerParams) == false then
        assert(false, "the controller Params is invalid, please check it again!")
        return
    end

    if transitionParams == nil then
        transitionParams = {transitionClass = "QUITransition"}
    elseif transitionParams.transitionClass == nil then
        transitionParams.transitionClass = "QUITransition"
    end

    if transitionParams ~= nil and self:_checkIsValidTransitionParam(transitionParams) == false then
        assert(false, "the transition Params is invalid, please check it again!")
        return
    end
    
    if self._currentIndex > 0 then
        local count = table.nums(self._stack[self._currentIndex])
        if count > 0 then
            if self._stack[self._currentIndex][count].uiClass == controllerParams.uiClass then
                printInfo(controllerParams.uiClass.." is exist !")
                return
            end
        end
    end

    return self:addController(controllerParams,transitionParams)
end

function QNavigationController:addController(controllerParams, transitionParams)
    -- check if can push a none page controller
    if controllerParams.uiType ~= QUIViewController.TYPE_PAGE then
        if self._currentPage == nil then
            self:pushViewController({uiType = QUIViewController.TYPE_PAGE, uiClass = "QUIPageEmpty"})
        end
    end

    QUtility:addUserOperation(self._name .. " will push controller. Class:" .. controllerParams.uiClass .. " \n")
    app:recordNavigationStack()

    -- create controller
    local controllerClass = self._controllerClassCache[controllerParams.uiClass]
    local controller = controllerClass.new(controllerParams.options)

    -- add to scene tree
    controllerParams["controller"] = controller
    local transitionClass = self._transitionClassCache[transitionParams.transitionClass]
    if controllerParams.uiType ~= QUIViewController.TYPE_PAGE then
        local count = table.nums(self._stack[self._currentIndex])
        local currentTopController = self._stack[self._currentIndex][count].controller
        if transitionClass ~= nil then
            QNotificationCenter.sharedNotificationCenter():addEventListener(QUITransition.EVENT_TRANSITION_START, self.onTransitionEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QUITransition.EVENT_TRANSITION_FINISHED, self.onTransitionEvent, self)
            self._currentTransition = transitionClass.new(controller, currentTopController, self)
            if count > 1 then
                self._currentTransition:setPopOldDialog(transitionParams.isPopCurrentDialog)
            end
        end
        controllerParams.lock = controller:getLock()
        table.insert(self._stack[self._currentIndex], controllerParams)
        self._currentPage:addSubViewController(controller)
        
        if self._currentTransition ~= nil then
            self._currentTransition:start()
        end
    else
        if transitionClass ~= nil then
            QNotificationCenter.sharedNotificationCenter():addEventListener(QUITransition.EVENT_TRANSITION_START, self.onTransitionEvent, self)
            QNotificationCenter.sharedNotificationCenter():addEventListener(QUITransition.EVENT_TRANSITION_FINISHED, self.onTransitionEvent, self)
            self._currentTransition = transitionClass.new(controller, self._currentPage, self)
        end

        table.insert(self._stack, {controllerParams})
        self._currentIndex = self._currentIndex + 1
        self._currentPage = controller
        self._rootController:addSubViewController(controller)

        if self._currentTransition ~= nil then
            self._currentTransition:start()
        end
    end

    QUtility:addUserOperation(self._name .. " did push controller. Class:" .. controllerParams.uiClass .. " \n")
    app:recordNavigationStack()

    return controller
end

-- translation is only for push operator
-- pop don't have translation
function QNavigationController:onTransitionEvent(event)
    if event == nil or event.name == nil or event.transition == nil then
        return
    end

    if event.name == QUITransition.EVENT_TRANSITION_START then

    elseif event.name == QUITransition.EVENT_TRANSITION_FINISHED then
        if event.controller ~= self then return end
        if self._currentIndex < 1 then
            return
        end
        -- remove old viewController
        local oldController = event.transition:getOldController()
        local newController = event.transition:getNewController()
        -- remove old page if have it
        if newController:getType() == QUIViewController.TYPE_PAGE and self._currentIndex > 1 then
            local count = table.nums(self._stack[self._currentIndex - 1])
            for i = count, 1, -1 do
                local controller = self._stack[self._currentIndex - 1][i].controller
                if controller ~= nil then
                    controller:removeFromParentController()
                    self._stack[self._currentIndex - 1][i].controller = nil
                    self._stack[self._currentIndex - 1][i].isNeedRecreate = true
                end
            end
        else
            if oldController and oldController:getType() == QUIViewController.TYPE_DIALOG then
                local findLock = false
                if newController:getLock() == true then
                    local count = table.nums(self._stack[self._currentIndex])
                    for i=1,count,1 do
                        local tbl = self._stack[self._currentIndex][i]
                        if tbl.lock == true and (tbl.controller == nil or tbl.controller ~= newController) then
                            findLock = true
                            while #self._stack[self._currentIndex] > i do
                                local data = table.remove(self._stack[self._currentIndex],#self._stack[self._currentIndex] - 1)
                                if data.controller ~= nil then
                                    data.controller:removeFromParentController()
                                    data.controller = nil
                                end
                            end
                            break
                        end
                    end
                end
                if event.transition:isPopOldDialog() == true and findLock == false then
                    local count = table.nums(self._stack[self._currentIndex])
                    for i = count, 1, -1 do
                        local controller = self._stack[self._currentIndex][i].controller
                        if controller ~= nil and controller == oldController then
                            if self._stack[self._currentIndex][i].options == nil then
                                self._stack[self._currentIndex][i].options = controller:getOptions()
                                self._stack[self._currentIndex][i].lock = controller:getLock()
                            end
                            controller:removeFromParentController()
                            self._stack[self._currentIndex][i].controller = nil
                            break
                        end
                    end
                end
            end
        end

        QNotificationCenter.sharedNotificationCenter():removeEventListener(QUITransition.EVENT_TRANSITION_START, self.onTransitionEvent, self)
        QNotificationCenter.sharedNotificationCenter():removeEventListener(QUITransition.EVENT_TRANSITION_FINISHED, self.onTransitionEvent, self)
        self._currentTransition = nil

        QStat.onPageStart(newController.__cname)
    end
end

function QNavigationController:popViewController(popType, isCreat, controller)    
    if self._currentIndex == 0 then
        return
    end

    if isCreat == nil then
        isCreat = true
    end

    local count = table.nums(self._stack[self._currentIndex])
    if popType == QNavigationController.POP_TOP_CONTROLLER then
        if count > 1 then
            self:_popTopDialog(isCreat)
        else
            self:_popTopPage()
        end
    elseif popType == QNavigationController.POP_SPECIFIC_CONTROLLER then
        if controller ~= nil then
            self:_popSpecificController(controller)
        end
    elseif popType == QNavigationController.POP_TO_CURRENT_PAGE then
        if count > 1 then
            self:_popAllDialogOfTopPage()
        end
    elseif popType == QNavigationController.POP_CURRENT_PAGE then
         self:_popTopPage()
    end
end

function QNavigationController:setDialogOptions(options)
    if self._currentIndex == 0 then
        return
    end 

    local count = table.nums(self._stack[self._currentIndex])
    if count > 1 then
        self._stack[self._currentIndex][count].options = options
    end
end

function QNavigationController:_checkIsValidControllerParam(controllerParams)
    if controllerParams == nil 
        or controllerParams.uiType == nil 
        or controllerParams.uiClass == nil
        then
        return false
    end

    -- check ui type
    if controllerParams.uiType ~= QUIViewController.TYPE_PAGE
        and controllerParams.uiType ~= QUIViewController.TYPE_DIALOG
        then
        return false
    end

    -- check lua file is exist
    if self._controllerClassCache[controllerParams.uiClass] == nil then
        local typeString = "pages."
        if controllerParams.uiType == QUIViewController.TYPE_DIALOG then
            typeString = "dialogs."
        end
        local controllerClass = import(app.packageRoot .. ".ui." .. typeString .. controllerParams.uiClass)
        if controllerClass == nil then
            assert(false, "the ui controller: " .. controllerParams.uiClass .. " does not exist.")
            return false
        else
            self._controllerClassCache[controllerParams.uiClass] = controllerClass
        end
    end

    return true
end

function QNavigationController:_checkIsValidTransitionParam(transitionParams)
    if transitionParams == nil or transitionParams.transitionClass == nil then
        return false
    end

    if self._transitionClassCache[transitionParams.transitionClass] == nil then
        local transitionClass = import(app.packageRoot .. ".ui.transitions." .. transitionParams.transitionClass)
        if transitionClass == nil then
            assert(false, "the ui transition: " .. transitionParams.transitionClass .. " does not exist.")
            return false
        else
            self._transitionClassCache[transitionParams.transitionClass] = transitionClass
        end
    end

    return true
end

function QNavigationController:_popTopDialog(createLastDialog)
    local count = table.nums(self._stack[self._currentIndex])
    if count <= 1 then
        return false
    end

    local className = self._stack[self._currentIndex][count].uiClass
    QUtility:addUserOperation(self._name .. " will pop controller. Class:" .. className .. " \n")
    app:recordNavigationStack()

    local controller = self._stack[self._currentIndex][count].controller
    if controller ~= nil then
        QStat.onPageEnd(controller.__cname)

        controller:removeFromParentController()
        self._stack[self._currentIndex][count].controller = nil
    end
    table.remove(self._stack[self._currentIndex], count)

    if createLastDialog == true then
        count = table.nums(self._stack[self._currentIndex])
        -- check is page 
        if count > 1 and self._stack[self._currentIndex][count].controller == nil then
          local controllerClass = self._controllerClassCache[self._stack[self._currentIndex][count].uiClass]
          self._stack[self._currentIndex][count].controller = controllerClass.new(self._stack[self._currentIndex][count].options)
          self._currentPage:addSubViewController(self._stack[self._currentIndex][count].controller)
        end
    end
    local count = table.nums(self._stack[self._currentIndex])
    if count == 1 then
        QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QNavigationController.EVENT_BACK_PAGE, currentTarget = self})
    end

    QUtility:addUserOperation(self._name .. " did pop controller. Class:" .. className .. " \n")
    app:recordNavigationStack()

    return true
end

function QNavigationController:_popSpecificController(controller)
    if controller == nil then
        return 
    end

    local isControllerExist = false
    if controller:getType() == QUIViewController.TYPE_PAGE then
        -- page
        local index = 0
        for i, pageStack in ipairs(self._stack) do
            if pageStack[1].controller == controller then
                index = i
                break
            end
        end

        if index > 0 then
            -- controller exist in ui stack
            while self._stack[self._currentIndex][1].controller ~= controller do
                self:_popTopPage()
            end
            self:_popTopPage()
        end

    else
        -- dialog
        local pageIndex = 0
        local dialogIndex = 0
        for i, pageStack in ipairs(self._stack) do
            for j, controllerInfo in ipairs(pageStack) do
                 if controllerInfo.controller == controller then
                    pageIndex = i
                    dialogIndex = j
                    break
                end
            end
        end

        if pageIndex > 0 and dialogIndex > 0 then
            while pageIndex ~= self._currentIndex do
                self:_popTopPage()
            end

            local count = table.nums(self._stack[self._currentIndex])

            for i = count, dialogIndex, -1 do
                if i == dialogIndex then
                    self:_popTopDialog(true)
                else
                    self:_popTopDialog(false)
                end
            end
        end
    end

end

function QNavigationController:_popAllDialogOfTopPage()
    while self:_popTopDialog(false) == true do end
end

function QNavigationController:_popTopPage()
    if self._currentIndex <= 0 then
        return
    end

    if self._stack[self._currentIndex][1].controller == nil then
        return
    end

    local className = self._stack[self._currentIndex][1].uiClass
    QUtility:addUserOperation(self._name .. " will pop controller. Class:" .. className .. " \n")
    app:recordNavigationStack()

    -- remove page
    local count = table.nums(self._stack[self._currentIndex])
    --if count > 1 then
    g_scalingFlag = true
    --end
    for i = count, 1, -1 do
        local controller = self._stack[self._currentIndex][i].controller
        if controller ~= nil then
            QStat.onPageEnd(controller.__cname)
            
            controller:removeFromParentController()
            self._stack[self._currentIndex][i].controller = nil
        end
    end

    table.remove(self._stack, self._currentIndex)
    self._currentIndex = self._currentIndex - 1
    self._currentPage = nil

    -- recreate current page
    if self._currentIndex <= 0 then
        return
    end

    local count = table.nums(self._stack[self._currentIndex])
    -- create page
    if count >= 1 then
        local param = self._stack[self._currentIndex][1]
        local controllerClass = self._controllerClassCache[param.uiClass]
        local controller = controllerClass.new(param.options)
        self._stack[self._currentIndex][1].controller = controller
        self._rootController:addSubViewController(controller)
        self._currentPage = controller
    end

    -- create top dialog
    if count >= 2 then
        for i = 2, count, 1 do
            if self._stack[self._currentIndex][i].controller == nil 
                and self._stack[self._currentIndex][i].isNeedRecreate == true then
                local param = self._stack[self._currentIndex][i]
                local controllerClass = self._controllerClassCache[param.uiClass]
                local controller = controllerClass.new(param.options)
                self._stack[self._currentIndex][i].controller = controller
                self._stack[self._currentIndex][i].isNeedRecreate = nil
                self._currentPage:addSubViewController(controller)
            end
        end
    end

    QUtility:addUserOperation(self._name .. " did pop controller. Class:" .. className .. " \n")
    app:recordNavigationStack()
end

function QNavigationController:getTopDialog()
    if self._currentIndex < 1 then
        return nil
    end

    local count = table.nums(self._stack[self._currentIndex])
    if count < 1 then
        return nil
    end

    return self._stack[self._currentIndex][count].controller
end

function QNavigationController:getTopPage()
    if self._currentIndex < 1 then
        return nil
    end

    return self._stack[self._currentIndex][1].controller
end

function QNavigationController:getRoot()
    return self._rootController
end

function QNavigationController:dumpControllerStack()
    local stackInfo = self._name .. " controller stack: \n"

    local stackCount = table.nums(self._stack)
    for i = stackCount, 1, -1 do
        local controllerCount = table.nums(self._stack[i])
        for j = controllerCount, 1, -1 do
            stackInfo = stackInfo .. self._name .. " Class:" .. self._stack[i][j].uiClass .. " Controller:" .. tostring(self._stack[i][j].controller) .. "\n"
        end
    end

    stackInfo = stackInfo .. self._name .. " Class:" .. self._rootController.__cname .. " Controller:" .. tostring(self._rootController) .. "\n"
    return stackInfo
end

return QNavigationController
