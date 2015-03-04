local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetRewardRulesReward = class("QUIWidgetRewardRulesReward", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetRewardRulesReward:ctor(options)
  local ccbFile = "ccb/Widget_RewardRules_client3.ccbi"
  local callBacks = {}
  QUIWidgetRewardRulesReward.super.ctor(self, ccbFile, callBacks, options)
  
  self:resetAll()
  self:setBox()
end

function QUIWidgetRewardRulesReward:resetAll()
  self._ccbOwner.rank:setString("0")
  for i = 1, 5, 1 do
    self._ccbOwner["reward_nums"..i]:setString("")
  end
end

function QUIWidgetRewardRulesReward:setBox()
  self.rankItemBox = {}
  for i = 1, 5, 1 do
    self.rankItemBox[i] = QUIWidgetItemsBox.new()
    self._ccbOwner["item"..i]:addChild(self.rankItemBox[i])
    self.rankItemBox[i]:setVisible(false)
  end
end

function QUIWidgetRewardRulesReward:setItemBox(index)
  local rankItemInfo = QStaticDatabase:sharedDatabase():getAreanRewardByRank(index)
  local i = 1
  while rankItemInfo["num_"..i] ~= nil do
    if rankItemInfo["id_"..i] ~= nil then
      self.rankItemBox[i]:setGoodsInfo(rankItemInfo["id_"..i], ITEM_TYPE.ITEM, 0)
    else
      self.rankItemBox[i]:setGoodsInfo(rankItemInfo["id_"..i], rankItemInfo["type_"..i], 0)
    end
    self._ccbOwner["reward_nums"..i]:setString("x"..rankItemInfo["num_"..i])
    self.rankItemBox[i]:setBoxScale(0.5)
    self.rankItemBox[i]:setVisible(true)
    self._ccbOwner.rank:setString(index)
    i = i + 1
  end
end

function QUIWidgetRewardRulesReward:getName()
  return "QUIWidgetRewardRulesReward"
end

return QUIWidgetRewardRulesReward