
local QUIScene = class("QUIScene", function()
    return display.newScene("UIScene")
end)

function QUIScene:onEnter()
    -- if device.platform == "android" then
        local layer = CCLayer:create()
        self:addChild(layer)
        layer:setKeypadEnabled(true)
        layer:addKeypadEventListener(function(event)
            if event == "back" then 
            	app:onClickBackButton()
            end
        end)
    -- end
end

function QUIScene:onExit()

end

return QUIScene

