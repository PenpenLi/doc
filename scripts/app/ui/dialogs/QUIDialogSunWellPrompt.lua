local QUIDialog = import("..widgets.QUIDialog")
local QUIDialogSunWellPrompt = class("QUIDialogSunWellPrompt", QUIDialog)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QNavigationController = import("...controllers.QNavigationController")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIDialogSunWellPrompt:ctor(options)
  local ccbFile = "ccb/Widget_SunWell_Prompt.ccbi"
  local callBack = {}
  QUIDialogSunWellPrompt.super.ctor(self, ccbFile, callBack, options)
  self.isAnimation = true
  
  if options ~= nil then
    self.index = options.index
  end  

  local rewardItem = QUIWidgetItemsBox.new()
  rewardItem:setGoodsInfo(0, ITEM_TYPE.MONEY, 0)
  self._ccbOwner.reward_icon:addChild(rewardItem)
  
  self:resetAll()
end

function QUIDialogSunWellPrompt:resetAll()
  if self.index == 3 or self.index == 6 or self.index == 9 or self.index == 12 or self.index == 15 then
    self._ccbOwner.reward_icon2:setVisible(false)
    self._ccbOwner.item_nums1:setString("太阳之尘")
    local itemBox = QUIWidgetItemsBox.new()
    itemBox:setGoodsInfo(0, ITEM_TYPE.SUNWELL_MONEY, 0)
    self._ccbOwner.item_icon1:addChild(itemBox)
  else
    local contentY = self._ccbOwner.itme_bg:getContentSize().height
    self._ccbOwner.item_icon2:setVisible(false)
    self._ccbOwner.item_nums2:setString("")
    self._ccbOwner.itme_bg:setScaleY((contentY - 60)/contentY)
  end
end

function QUIDialogSunWellPrompt:_backClickHandler()
    self:close()
end

function QUIDialogSunWellPrompt:close()
  self:playEffectOut()
end

function QUIDialogSunWellPrompt:viewAnimationOutHandler()
  app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogSunWellPrompt