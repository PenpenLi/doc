--[[
    Class name QSBSequence
    Create by julian 
--]]


local QSBNode = import("..QSBNode")
local QSBSequence = class("QSBSequence", QSBNode)

function QSBSequence:_execute(dt)
    if self:getOptions().can_be_immuned == true then
        if self._target ~= nil and self._target:isDead() == false then
            if self._target:isImmuneStatus(self._skill:getBehaviorStatus()) then
                self:finished()
                return
            end
        end
    end

    local forward_mode = self:getOptions().forward_mode

    if self._index == nil then
        self._index = 1
    end

    repeat 
        if self._index > self:getChildrenCount() then
            self:finished()
            break
        else
            local child = self:getChildAtIndex(self._index)
            if child:getState() == QSBNode.STATE_EXECUTING then
                child:visit(dt)
            elseif child:getState() == QSBNode.STATE_WAIT_START then
                child:start()
                child:visit(0)
            else
                self._index = self._index + 1
                if self._index > self:getChildrenCount() then
                    self:finished()
                    break
                end
            end

            if child:getState() ~= QSBNode.STATE_FINISHED then
                break
            end
        end
    until not forward_mode
end

return QSBSequence