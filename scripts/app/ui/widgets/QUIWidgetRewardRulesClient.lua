local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetRewardRulesClient = class("QUIWidgetRewardRulesClient", QUIWidget)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QUIWidgetRewardRulesReward = import("..widgets.QUIWidgetRewardRulesReward")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIWidgetRewardRulesClient:ctor(options)
  local ccbFile = "ccb/Widget_RewardRules_client.ccbi"
  local callBacks = {}
  QUIWidgetRewardRulesClient.super.ctor(self, ccbFile, callBacks, options)
  
  if options ~= nil then
    self.info = options.info
  end
  self:resetAll()
  self:init()
end

function QUIWidgetRewardRulesClient:onExit()
    -- for _,value in pairs(self.rewardItemBox) do
    --     app.widgetCache:setWidgetForName(value, value:getName())
    -- end
    self.rewardItemBox = {}
end

function QUIWidgetRewardRulesClient:resetAll()
  self._ccbOwner.larget_rank:setString("0")
  self._ccbOwner.rank_nums:setString("0")
  self._ccbOwner.rank_sectio:setString("")
  self._ccbOwner.rank_nums1:setString("")
  self._ccbOwner.rank_nums2:setString("")
  self._ccbOwner.rank_nums3:setString("")
  self._ccbOwner.rank_nums4:setString("")
  self._ccbOwner.rank_nums5:setString("")
end

function QUIWidgetRewardRulesClient:init()
  self._ccbOwner.rank_nums:setString(self.info.rank)
  self._ccbOwner.larget_rank:setString(self.info.topRank)
  local rankItemInfo, low, larget = QStaticDatabase:sharedDatabase():getAreanRewardByRank(self.info.rank)
  if self.info.rank >= 10 then
    if low ~= nil and larget ~= nil then
      self._ccbOwner.rank_sectio:setString("（第"..low.."至"..larget.."名），可领取以下奖励：")
    else
      self._ccbOwner.rank_sectio:setString("，可领取以下奖励：")
    end
  else
    self._ccbOwner.rank_sectio:setString("，可领取以下奖励：")
  end
  
  self.rankItemBox = {}
  local i = 1
  while rankItemInfo["num_"..i] ~= nil do
    self.rankItemBox[i] = QUIWidgetItemsBox.new()
    self._ccbOwner["rank_item"..i]:addChild(self.rankItemBox[i])
    self.rankItemBox[i]:setBoxScale(0.5)
    if rankItemInfo["id_"..i] ~= nil then
      self.rankItemBox[i]:setGoodsInfo(rankItemInfo["id_"..i], ITEM_TYPE.ITEM, 0)
    else
      self.rankItemBox[i]:setGoodsInfo(rankItemInfo["id_"..i], rankItemInfo["type_"..i], 0)
    end
    self._ccbOwner["rank_nums"..i]:setString("x"..rankItemInfo["num_"..i])
    i = i + 1
  end
  self.rewardItemBox = {}
  for i = 1, 10, 1 do
    self.rewardItemBox[i] = QUIWidgetRewardRulesReward.new()
    self._ccbOwner["row"..i]:addChild(self.rewardItemBox[i])
    -- self.rewardItemBox[i] =  app.widgetCache:getWidgetForName("QUIWidgetRewardRulesReward", self._ccbOwner["row"..i])
    self.rewardItemBox[i]:setItemBox(i)
  end
end

return QUIWidgetRewardRulesClient