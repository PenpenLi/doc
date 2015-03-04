local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroEquipmentStrengthen = class("QUIWidgetHeroEquipmentStrengthen", QUIWidget)

function QUIWidgetHeroEquipmentStrengthen:ctor(options)
  local ccbFile = "ccb/Widget_HeroEquipment_Stengthen.ccbi"
  local callBacks = {}
  QUIWidgetHeroEquipmentStrengthen.super.ctor(self, ccbFile, callBacks, options)
end

function QUIWidgetHeroEquipmentStrengthen:setHeroInfo(actorId, itemId)
  self.actorId = actorId
  self.itemId = itemId
end

return QUIWidgetHeroEquipmentStrengthen