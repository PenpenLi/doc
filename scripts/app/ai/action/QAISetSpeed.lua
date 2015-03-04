
local QAIAction = import("..base.QAIAction")
local QAISetSpeed = class("QAISetSpeed", QAIAction)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QAISetSpeed:ctor( options )
    QAISetSpeed.super.ctor(self, options)
    self:setDesc("设置QActor的速度")
end

function QAISetSpeed:_evaluate(args)
    local actor = args.actor
    if actor == nil or actor:isDead() == true then
        return false
    end

    if type(self:getOptions().speed) ~= "number" and self:getOptions().speed ~= "character_speed" then
        return false
    end

    return true
end

function QAISetSpeed:_execute(args)
    local actor = args.actor

    if type(self:getOptions().speed) == "number" then
        actor:set("speed", self:getOptions().speed)
    elseif self:getOptions().speed == "character_speed" then
        local udid = actor:getUDID()
        local character_id = string.sub(udid, 1, string.len(udid) - string.find(string.reverse(udid), "_", 1, true))
        local properties = QStaticDatabase.sharedDatabase():getCharacterByID(character_id)
        actor:set("speed", properties.speed)
    end

    return true
end

return QAISetSpeed