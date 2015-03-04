local QUIWidget = import(".QUIWidget")
local QUIWidgetBattleWinHeroHead = class("QUIWidgetBattleWinHeroHead", QUIWidget)

local QUIWidgetHeroHead = import("..widgets.QUIWidgetHeroHead")
local QUIWidgetUpGradeTips = import("..widgets.QUIWidgetUpGradeTips")
local QRectUiMask = import(".QRectUiMask")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIWidgetBattleWinHeroHead.UP_GRADE = "UP_GRADE"

function QUIWidgetBattleWinHeroHead:ctor(options)
  local ccbFile = "ccb/Battle_Dialog_Victory_client.ccbi"
  local callBacks = {}
  
  QUIWidgetBattleWinHeroHead.super.ctor(self, ccbFile, callBacks, options)
  
  self.data = options
  self:resetAll()
  self.hero_head = QUIWidgetHeroHead.new() 
  self.hero_head:setTouchEnabled(false)
  self._ccbOwner.hero_head:addChild(self.hero_head:getView())
  self.tipsPositionY = self._ccbOwner.hero_head:getPositionY() + 10
  self.tipsPositionX = self._ccbOwner.hero_head:getPositionX() + 12
  
end

function QUIWidgetBattleWinHeroHead:setHeroHead(actorId, level)
  self.hero_head:setHero(actorId, level)
end

function QUIWidgetBattleWinHeroHead:resetAll()
  self._ccbOwner.spExp:setScaleX(0)
  self._ccbOwner.txtExp:setString("")
end

function QUIWidgetBattleWinHeroHead:onExit()
  if self._schedulerHandler ~= nil then
    scheduler.unscheduleGlobal(self._schedulerHandler)
    self._schedulerHandler = nil
  end
end

--没有升级动画
function QUIWidgetBattleWinHeroHead:setExpBar(Exp, addExp, totalExp)

  self._ccbOwner.spExp:setScaleX((Exp-addExp)/totalExp)
  
  local animationTime = Exp/totalExp * 0.5
  local scaleAction = CCScaleTo:create(animationTime, Exp/totalExp, 1)
  local actionArrayIn = CCArray:create()
  local callFun = CCCallFunc:create(function()
    self._ccbOwner.txtExp:setString("经验+" .. addExp)
  end)
      actionArrayIn:addObject(scaleAction)
      actionArrayIn:addObject(callFun)
  local ccsequence = CCSpawn:create(actionArrayIn)
  self._ccbOwner.spExp:runAction(ccsequence)

end

--升级动画
function QUIWidgetBattleWinHeroHead:setUpExpBar(oldInfo, oldTotalExp, addExp, newInfo, totalExp)
  self._ccbOwner.spExp:setScaleX(oldInfo.exp/oldTotalExp)
  
  self.hero_head:setLevel(oldInfo.level)
  
  local animationTime = (oldTotalExp - oldInfo.exp)/oldTotalExp * 0.5
  local countLevel = newInfo.level - oldInfo.level
  
  local scaleAction1 = CCScaleTo:create(animationTime, 1, 1)
  local callFun = CCCallFunc:create(function()
    
       if countLevel > 1 then
          self:repetExp(countLevel, oldInfo, oldTotalExp, addExp, newInfo, totalExp)
       else
          if self.upGradeTips ~= nil then
            self.upGradeTips:removeFromParent()
          end
          self.upGradeTips = QUIWidgetUpGradeTips.new() 
          self.upGradeTips:setPositionY(self.tipsPositionY)
          self.upGradeTips:setPositionX(self.tipsPositionX)
          self._ccbOwner.hero_head:addChild(self.upGradeTips)
          self.hero_head:setLevel(oldInfo.level + 1)
          self:updateExp(oldInfo, oldTotalExp, addExp, newInfo, totalExp)
       end
    
  end)
  local action1 = CCArray:create()
      action1:addObject(scaleAction1)
      action1:addObject(callFun)
  
  local ccsequence1 = CCSequence:create(action1)
  
  self._ccbOwner.spExp:runAction(ccsequence1)

end
--升多级重复动画
function QUIWidgetBattleWinHeroHead:repetExp(countLevel, oldInfo, oldTotalExp, addExp, newInfo, totalExp)
    local upLevel = oldInfo.level + 1
    self.hero_head:setLevel(upLevel)
    
    if self.upGradeTips ~= nil then
            self.upGradeTips:removeFromParent()
          end
     self.upGradeTips = QUIWidgetUpGradeTips.new()
     self.upGradeTips:setPositionY(self.tipsPositionY)
     self.upGradeTips:setPositionX(self.tipsPositionX)
     self._ccbOwner.hero_head:addChild(self.upGradeTips)
  
    local scaleAction2 = CCScaleTo:create(0, 0, 1)
    local scaleAction3 = CCScaleTo:create(0.5, 1, 1)
    local callFun = CCCallFunc:create(function()
      upLevel = upLevel + 1
      self.hero_head:setLevel(upLevel)
      
      if self.upGradeTips ~= nil then
            self.upGradeTips:removeFromParent()
      end
     self.upGradeTips = QUIWidgetUpGradeTips.new()
     self.upGradeTips:setPositionY(self.tipsPositionY)
     self.upGradeTips:setPositionX(self.tipsPositionX)
     self._ccbOwner.hero_head:addChild(self.upGradeTips)
    end)
    local action2 = CCArray:create()
        action2:addObject(scaleAction2)
        action2:addObject(scaleAction3)
        action2:addObject(callFun)
    local ccsequence2 = CCSequence:create(action2)
    local _repeat = CCRepeat:create(ccsequence2, countLevel - 1) 
    self._ccbOwner.spExp:runAction(_repeat) 
    self._schedulerHandler = scheduler.performWithDelayGlobal(function()
        self:updateExp(oldInfo, oldTotalExp, addExp, newInfo, totalExp)
    end, 0.5 * (countLevel - 1))
    
end
--升一级动画
function QUIWidgetBattleWinHeroHead:updateExp(oldInfo, oldTotalExp, addExp, newInfo, totalExp)
  local animationTime = (totalExp - newInfo.exp)/totalExp * 0.5
  local scaleAction4 = CCScaleTo:create(0, 0, 1)
  local scaleAction5 = CCScaleTo:create(animationTime, newInfo.exp/totalExp, 1) 
  local callFun = CCCallFunc:create(function()
      self._ccbOwner.txtExp:setString("经验+" .. addExp)
      self.hero_head:setLevel(newInfo.level)
  end)
  local action3 = CCArray:create()
     action3:addObject(scaleAction4)
     action3:addObject(scaleAction5)
     action3:addObject(callFun)
  local ccsequence3 = CCSequence:create(action3)
  self._ccbOwner.spExp:runAction(ccsequence3)
end

function QUIWidgetBattleWinHeroHead:expFull(Exp, totalExp)
  self._ccbOwner.spExp:setScaleX(Exp/totalExp)
  local animationTime = (totalExp - Exp)/totalExp * 0.5
  local scaleAction = CCScaleTo:create(animationTime, 1, 1)
  local actionArrayIn = CCArray:create()
  local callFun = CCCallFunc:create(function()
    self._ccbOwner.txtExp:setString("经验已满")
  end)
      actionArrayIn:addObject(scaleAction)
      actionArrayIn:addObject(callFun)
  local ccsequence = CCSpawn:create(actionArrayIn)
  self._ccbOwner.spExp:runAction(ccsequence)
end

function QUIWidgetBattleWinHeroHead:expOldFull()
  self._ccbOwner.spExp:setScaleX(1)
  self._ccbOwner.txtExp:setString("经验已满")
end

function QUIWidgetBattleWinHeroHead:noExpAdd(curLevelExp, heroMaxLevel)
  self._ccbOwner.spExp:setScaleX(curLevelExp/heroMaxLevel)
end

return QUIWidgetBattleWinHeroHead