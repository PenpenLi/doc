
local QNpcTipView = class("QNpcTipView", function()
    return display.newNode()
end)

local QNpcTipIcon = import(".QNpcTipIcon")

function QNpcTipView:ctor()
    self._icons = {}
end

function QNpcTipView:add(displayID)
    if app:getUserData():isNpcTipShown(displayID) then return end

    for i, icon in ipairs(self._icons) do
        assert(icon ~= nil)
        if icon:getDisplayID() == displayID then
            return
        end
    end

    local icon = QNpcTipIcon.new(displayID)
    table.insert(self._icons, icon)
    self:addChild(icon)
    self:_update()
end

function QNpcTipView:remove(displayID)
    for i, icon in ipairs(self._icons) do
        assert(icon ~= nil)
        if icon:getDisplayID() == displayID then
            table.remove(self._icons, i)
            icon:removeSelf()
            break
        end
    end

    self:_update()
end

function QNpcTipView:_update()
    local max = 2
    local height = 0
    for i, icon in ipairs(self._icons) do
        if i > max then return end

        icon:setPosition(ccp(0, height))
        height = height - icon:getCascadeBoundingBox().size.height

        if i == 1 then
            icon:setClickThisVisible(false)
        else
            icon:setClickThisVisible(false)
        end
    end
end

return QNpcTipView