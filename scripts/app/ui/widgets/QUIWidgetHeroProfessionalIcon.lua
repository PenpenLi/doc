
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroProfessionalIcon = class("QUIWidgetHeroProfessionalIcon", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetHeroProfessionalIcon:ctor(options)
	local ccbFile = "ccb/Widget_ProfessionalIcon.ccbi"
	QUIWidgetHeroProfessionalIcon.super.ctor(self,ccbFile,callBacks,options)
end

function QUIWidgetHeroProfessionalIcon:setHero(actorId)
	local characher = QStaticDatabase:sharedDatabase():getCharacterByID(actorId)
	local talent = QStaticDatabase:sharedDatabase():getTalentByID(characher.talent).func
	self:hideAllIcon()
	if talent == 't' then
		self._ccbOwner.node_hero_professional_t:setVisible(true)
	elseif talent == 'dps' then
		self._ccbOwner.node_hero_professional_dps:setVisible(true)
	elseif talent == 'health' then
		self._ccbOwner.node_hero_professional_health:setVisible(true)
	end
	
end

function QUIWidgetHeroProfessionalIcon:hideAllIcon()
	self._ccbOwner.node_hero_professional_t:setVisible(false)
	self._ccbOwner.node_hero_professional_dps:setVisible(false)
	self._ccbOwner.node_hero_professional_health:setVisible(false)
end

return QUIWidgetHeroProfessionalIcon

