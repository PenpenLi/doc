local QBattleDialog = import(".QBattleDialog")
local QDialogArenaRankTop = class("QDialogArenaRankTop", QBattleDialog)

function QDialogArenaRankTop:ctor(options, owner)
  local ccbFile = "ccb/Dialog_Arena_RankTop.ccbi"
  local callBacks = {
    {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QDialogArenaRankTop._onTriggerConfirm)}
  }
  if owner == nil then
    owner = {}
  end
  QDialogArenaRankTop.super.ctor(self, ccbFile, owner,callBacks)
  
  self._ccbOwner.parent_node:setScale(0)
  if options ~= nil then
    self.rankInfo = options.rankInfo
  end
  self.animationIsDone = false
  self:outAnimation()
  self:resetAll()
  self:setInfo()
end

function QDialogArenaRankTop:resetAll()
  self._ccbOwner.last_rank:setString(0)
  self._ccbOwner.top_rank:setString(0)
  self._ccbOwner.add_rank:setString(0)
  self._ccbOwner.rank_award:setString("x 0")
end

function QDialogArenaRankTop:setInfo()
  local tonken = string.split(self.rankInfo.mails[1].attachment, "^")
  self._ccbOwner.last_rank:setString(self.rankInfo.arenaResponse.self.lastRank)
  self._ccbOwner.top_rank:setString(self.rankInfo.arenaResponse.self.topRank)
  self._ccbOwner.add_rank:setString(self.rankInfo.arenaResponse.self.lastRank - self.rankInfo.arenaResponse.self.topRank)
  self._ccbOwner.rank_award:setString("x "..tonken[2])
end

function QDialogArenaRankTop:outAnimation()
    local delay = CCDelayTime:create(0.2)
    local scale = CCScaleTo:create(0.2, 1.2)
    local scale1 = CCScaleTo:create(0, 1)
    local func = CCCallFunc:create(function() 
      self.animationIsDone = true
    end)
    local fadeAction = CCArray:create()
    fadeAction:addObject(delay)
    fadeAction:addObject(scale)
    fadeAction:addObject(scale1)
    fadeAction:addObject(func)
    local ccsequence = CCSequence:create(fadeAction)
    self._ccbOwner.parent_node:runAction(ccsequence)
end

function QDialogArenaRankTop:_backClickHandler()
  if self.animationIsDone == true then
    self:_onTriggerConfirm()
  end
end

function QDialogArenaRankTop:_onTriggerConfirm()  
  if self.animationIsDone == true then
    app.sound:playSound("common_item")
    self._ccbOwner:onCloseRankTop()
  end
end

return QDialogArenaRankTop
