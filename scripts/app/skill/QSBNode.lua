--[[
    Class name QSBNode
    Create by julian 
--]]

local QNode = import("..base.QNode")
local QSBNode = class("QSBNode", QNode)

QSBNode.STATE_WAIT_START = "STATE_WAIT_START"
QSBNode.STATE_EXECUTING = "STATE_EXECUTING"
QSBNode.STATE_FINISHED = "STATE_FINISHED"

--[[
    options is a table. Valid key below:
--]]
function QSBNode:ctor(director, attacker, target, skill, options )
    QSBNode.super.ctor(self, options)
    self._attacker = attacker
    self._target = target
    self._skill = skill
    self._director = director
    self._state = QSBNode.STATE_WAIT_START

    self._revertable = self:getOptions().revertable
end

function QSBNode:getState()
    return self._state
end

function QSBNode:getSkill()
    return sel._skill
end

function QSBNode:start()
    if self._state ~= QSBNode.STATE_WAIT_START then
        return
    end

    self._state = QSBNode.STATE_EXECUTING
end

function QSBNode:finished()
    self._state = QSBNode.STATE_FINISHED
end

function QSBNode:visit(dt)
    if self._state ~= QSBNode.STATE_EXECUTING then
        return
    end

    self:_execute(dt)
end

function QSBNode:_execute(dt)
    self:finished()
end

function QSBNode:cancel()
    if self._state ~= QSBNode.STATE_EXECUTING then
        return
    end
    
    self:_onCancel()

    local count = self:getChildrenCount()
    for index = 1, count, 1 do
        local child = self:getChildAtIndex(index)
        child:cancel()
    end

    self:finished()
end

function QSBNode:_onCancel()
    
end

function QSBNode:revert()
    if self._state == QSBNode.STATE_FINISHED and self._revertable == true then
        self:_onRevert()
    end

    local count = self:getChildrenCount()
    for index = count, 1, -1 do
        local child = self:getChildAtIndex(index)
        child:revert()
    end
end

function QSBNode:_onRevert()

end

return QSBNode