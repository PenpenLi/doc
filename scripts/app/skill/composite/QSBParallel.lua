--[[
    Class name QSBParallel
    Create by julian 
--]]


local QSBNode = import("..QSBNode")
local QSBParallel = class("QSBParallel", QSBNode)

function QSBParallel:_execute(dt)    
    if self:getOptions().can_be_immuned == true then
        if self._target ~= nil and self._target:isDead() == false then
            if self._target:isImmuneStatus(self._skill:getBehaviorStatus()) then
                self:finished()
                return
            end
        end
    end

	local count = self:getChildrenCount()
	local isAllChildFinished = true
    for index = 1, count, 1 do
        local child = self:getChildAtIndex(index)
        if child:getState() == QSBNode.STATE_EXECUTING then
        	child:visit(dt)
        	isAllChildFinished = false
        elseif child:getState() == QSBNode.STATE_WAIT_START then
        	child:start()
            child:visit(0)
        	isAllChildFinished = false
        end
    end

    if isAllChildFinished == true then
    	self:finished()
    end
    
end

return QSBParallel