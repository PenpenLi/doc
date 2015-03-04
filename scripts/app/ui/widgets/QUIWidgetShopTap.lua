local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetShopTap = class("QUIWidgetShopTap", QUIWidget)

function QUIWidgetShopTap:ctor(options)
  local ccbFile = "ccb/Widget_tap2.ccbi"
  local callBacks = {}
  QUIWidgetShopTap.super.ctor(self, ccbFile, callBacks, options)
  self:setMoney(options.money)
  if options.type == "sunwell" then
  	self._ccbOwner.arena_gold:setVisible(false)
  	self._ccbOwner.sunwell_icon:setVisible(true)
  else
  	self._ccbOwner.arena_gold:setVisible(true)
  	self._ccbOwner.sunwell_icon:setVisible(false)
  end
end

function QUIWidgetShopTap:setMoney(money)
    self._ccbOwner.CCLabelBMFont_MidNum:setString(money or 0)
end

return QUIWidgetShopTap