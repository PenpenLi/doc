local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetSunWellRuleClient = class("QUIWidgetSunWellRuleClient", QUIWidget)

function QUIWidgetSunWellRuleClient:ctor(options)
  local ccbFile = "ccb/Widget_SunWell_Rule.ccbi"
  local callBack = {}
  QUIWidgetSunWellRuleClient.super.ctor(self, ccbFile, callBack, options)
end

return QUIWidgetSunWellRuleClient