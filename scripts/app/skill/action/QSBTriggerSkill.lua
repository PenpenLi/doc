--[[
    Class name QSBTriggerSkill
    Create by julian 
--]]
local QSBAction = import(".QSBAction")
local QSBTriggerSkill = class("QSBTriggerSkill", QSBAction)

local QActor 			= import("...models.QActor")
local QSkill 			= import("...models.QSkill")
local QStaticDatabase 	= import("...controllers.QStaticDatabase")

function QSBTriggerSkill:_execute(dt)
	local actor = self._attacker
	local skill_id = self:getOptions().skill_id
	local wait_finish = self

	if skill_id == nil or skill_id == "" then
		self:finished()
		return	
	end

	if self._triggered == true then
		local finished = true
		for _, sbDirector in ipairs(actor._sbDirectors) do
			if sbDirector == self._triggerSBDirector then
				finished = false 
				break
			end
		end
		if finished then
			self:finished()
		end
		return
	end

	local triggerSkill = actor._skills[skill_id]
    if triggerSkill == nil then
        local database = QStaticDatabase.sharedDatabase()
        triggerSkill = QSkill.new(skill_id, database:getSkillByID(skill_id), actor)
        actor._skills[skill_id] = triggerSkill
    end
    if triggerSkill:isReadyAndConditionMet() then
        self._triggerSBDirector = actor:triggerAttack(triggerSkill)
        self._triggered = true

        if not wait_finish then
        	self:finished()
        end
    else
    	self:finished()
    end
end

return QSBTriggerSkill