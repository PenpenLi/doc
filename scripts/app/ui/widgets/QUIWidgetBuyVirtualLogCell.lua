--
-- Author: Your Name
-- Date: 2015-02-14 16:08:43
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetBuyVirtualLogCell = class("QUIWidgetBuyVirtualLogCell", QUIWidget)

function QUIWidgetBuyVirtualLogCell:ctor(options)
	local ccbFile = "ccb/Widget_BuyAgain_Prompt_client.ccbi"
	local callBacks = {}
	QUIWidgetBuyVirtualLogCell.super.ctor(self, ccbFile, callBacks, options)
end

function QUIWidgetBuyVirtualLogCell:addLog(cost, receive, crit)
	self._ccbOwner.tf_need_num:setString(cost or 0)
	self._ccbOwner.tf_receive_num:setString(receive or 0)
	self._ccbOwner.tf_crit:setString(crit or 0)
	if crit ~= nil and crit > 1 then
		self._ccbOwner.sp_crit:setVisible(true)
	else
		self._ccbOwner.sp_crit:setVisible(false)
	end
end

return QUIWidgetBuyVirtualLogCell