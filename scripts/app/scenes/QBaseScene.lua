--[[
    Class name: QBaseScene
    Create by Julian
    QBaseScene is a base scene that affort some base function and event bind
--]]

--require "CCBReaderLoad"

local QBaseScene = class("QBaseScene", function()
    return display.newScene("QBaseScene")
end)

--[[
    member of QBaseScene:
    _ccbProxy: a instance of CCBProxy
    _touchLayer: handle touch event if touch enabled
    _skeletonLayer: display skeleton views
    _dragLineLayer: display drag line
    _uiLayer: display ui on scene
    _overlayLayer: over lay
    _dialogLayer: display dialog
--]]

--[[
    options is a table. Valid key below:
    ccbi : the ccbi file that need loaded
--]]
function QBaseScene:ctor( options )
    if options ~= nil and type(options) == "table" and table.nums(options) > 0 then
        self:parseOptions(options)
    end

    self._backgroundOverLayer = CCLayerColor:create(ccc4(0, 0, 0, 0), display.width * 2, display.height * 2)
    self._backgroundOverLayer:setVisible(false)
    -- self:addChild(self._backgroundOverLayer)

    self._backgroundLayer = display.newNode()
    self._trackLineLayer = display.newNode()
    self._skeletonLayer = display.newNode()
    self._dragLineLayer = display.newNode() -- drag or select hero and enemy
    self._overSkeletonLayer = display.newNode()
    self._uiLayer = display.newNode()
    self._overlayLayer = display.newNode()
    self._dialogLayer = display.newNode()
    
    self:addChild(self._backgroundLayer)
    self:addChild(self._trackLineLayer)
    self:addChild(self._skeletonLayer)
    self:addChild(self._dragLineLayer)
    self:addChild(self._overSkeletonLayer)
    self:addChild(self._uiLayer)
    self:addChild(self._overlayLayer)
    self:addChild(self._dialogLayer)

    local scale = UI_DESIGN_WIDTH / BATTLE_SCREEN_WIDTH
    self._backgroundLayer:setScale(scale)
    self._trackLineLayer:setScale(scale)
    self._skeletonLayer:setScale(scale)
    self._dragLineLayer:setScale(scale)
    self._overSkeletonLayer:setScale(scale)

    self:addSkeletonContainer(self._backgroundOverLayer)

    self:setNodeEventEnabled(true)

end

--[[
    the option is from ctor
--]]
function QBaseScene:parseOptions( options )
    if options["ccbi"] ~= nil and type(options["ccbi"]) == "string" then
        printInfo("create scene " .. self.name .. " from " .. options["ccbi"])

--      load ccbi and add root node to self
        local ccbi = options["ccbi"]
        self._ccbProxy = CCBProxy:create()
        self._ccbOwner = options.owner
        local node = CCBuilderReaderLoad(ccbi, self._ccbProxy, self._ccbOwner)
        self:addChild(node)

    end
end

function QBaseScene:onEnter()
    if device.platform == "android" then
        local layer = CCLayer:create()
        self:addChild(layer)
        layer:setKeypadEnabled(true)
        layer:addKeypadEventListener(function(event)
            if event == "back" then 
                app:onClickBackButton()
            end
        end)
    end
end

function QBaseScene:onExit()

end

function QBaseScene:addSkeletonContainer(container)
    if container == nil then
        return
    end
    self._skeletonLayer:addChild(container)
end

function QBaseScene:addDragLine(dragLine)
    if dragLine == nil then
        return
    end
    self._dragLineLayer:addChild(dragLine)
end

function QBaseScene:addTrackLine(trackLine)
    if trackLine == nil then
        return
    end
    self._trackLineLayer:addChild(trackLine)
end

function QBaseScene:addUI(uiView)
    if uiView == nil then
        return
    end
    self._uiLayer:addChild(uiView)
end

function QBaseScene:addOverlay(overlay)
    assert(overlay ~= nil)
    self._overlayLayer:addChild(overlay)
end

function QBaseScene:addDialog(dlg)
    assert(dlg ~= nil)
    self._dialogLayer:addChild(dlg)
end

function QBaseScene:getBackgroundOverLayer()
    return self._backgroundOverLayer
end

return QBaseScene