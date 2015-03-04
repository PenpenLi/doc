
local QBaseUiMask = import(".QBaseUiMask")
local QRectUiMask = class("QRectUiMask", QBaseUiMask)

function QRectUiMask:ctor(options)
    QRectUiMask.super.ctor(self, options)

    self._stencil = CCRectShape:create(CCSize(1, 1))
    self._stencil:setFill(true)
    self:setStencil(self._stencil)

    self._isLeftToRight = true
end

function QRectUiMask:setFromLeftToRight(isLeftToRight)
    self._isLeftToRight = isLeftToRight
end

function QRectUiMask:update(percent)
    if self:preUpdate(percent) == QDEF.HANDLED then
        return 
    end

    local size = self:getCascadeBoundingBox().size
    local margin = 0 -- TBD: move the magic number to config file
    local w = size.width - margin * 2
    local stencil = self._stencil
    stencil:setSize(CCSizeMake(w * percent, size.height))
    if self._isLeftToRight == true then
        stencil:setPosition(w * (percent - 1.0) * 0.5 + margin, 0)
    else
        stencil:setPosition(w * (1.0 - percent) * 0.5 + margin, 0)
    end
end

return QRectUiMask
