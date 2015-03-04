local QUIDialog = import(".QUIDialog")
local QUIDialogUnlockSucceed = class("QUIDialogUnlockSucceed", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("..controllers.QNotificationCenter")
local QTips = import(".utils.QTips")

QUIDialogUnlockSucceed.UNLOCK_SKILL = "UNLOCK_SKILL"
QUIDialogUnlockSucceed.UNLOCK_ELITECOPY = "UNLOCK_ELITECOPY"
QUIDialogUnlockSucceed.UNLOCK_GOBLIN_SHOP = "UNLOCK_GOBLIN_SHOP"
QUIDialogUnlockSucceed.UNLOCK_BLACK_MARKET_SHOP = "UNLOCK_BLACK_MARKET_SHOP"
QUIDialogUnlockSucceed.SPACE_TIME_TRANSMITTER = "SPACE_TIME_TRANSMITTER"
QUIDialogUnlockSucceed.GOLD_CHALLENGE = "GOLD_CHALLENGE"
QUIDialogUnlockSucceed.UNLOCK_SHOP = "UNLOCK_SHOP"
QUIDialogUnlockSucceed.UNLOCK_ARENA = "UNLOCK_ARENA"
QUIDialogUnlockSucceed.UNLOCK_SUNWELL = "UNLOCK_SUNWELL"

function QUIDialogUnlockSucceed:ctor(options)
  local ccbFile = "ccb/Dialog_UnlockSucceed.ccbi"
  local callBacks = {}
  QUIDialogUnlockSucceed.super.ctor(self, ccbFile, callBacks, options)
  
  self._ccbOwner.node_mask:setVisible(false)
  QTips.UNLOCK_TIP_ISTRUE = true
  self._ccbOwner.parent_node:setScale(0)
  self:getView():setPosition(ccp(display.width/2, display.height/2 - 90))
  self:setContent(options.type)
  self:fadeOut()
end

function QUIDialogUnlockSucceed:viewDidAppear()
end

function QUIDialogUnlockSucceed:setContent(type)
    local information = app.tip:getUnlockTipInformation(type)
    self.icon = CCSprite:create(information.icon)
    self.icon:setVisible(true)
    self.icon:setScale(0.8)
    self._ccbOwner.head_node:addChild(self.icon)
    self._ccbOwner.unlock_name:setString(information.name)
end

function QUIDialogUnlockSucceed:fadeOut()
    local time = UNLOCK_DELAY_TIME
    
--    makeNodeCascadeOpacityEnabled(self._ccbOwner.parent_node, true)

    local delayTime = CCDelayTime:create(time)
    local scale = CCScaleTo:create(0.2, 1.2)
    local scale1 = CCScaleTo:create(0, 1)
    local fadeOut = CCFadeOut:create(time)
    local callFunc = CCCallFunc:create(function()
      QTips.UNLOCK_TIP_ISTRUE = false
      app:getNavigationThirdLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
      app.tip._unlockTip = nil
      app.tip:showNextTip()
    end)
    local fadeAction = CCArray:create()
    fadeAction:addObject(scale)
    fadeAction:addObject(scale1)
    fadeAction:addObject(delayTime)
--    fadeAction:addObject(fadeOut)
    fadeAction:addObject(callFunc)
    local ccsequence = CCSequence:create(fadeAction)
    self._ccbOwner.parent_node:runAction(ccsequence)
    
    
--    local bg_delayTime1 = CCDelayTime:create(time)
--    local bg_fadeOut1 = CCFadeTo:create(time + 1, 0)
--    local bg_fadeAction1 = CCArray:create()
--    bg_fadeAction1:addObject(bg_delayTime1)
--    bg_fadeAction1:addObject(bg_fadeOut1)
--    local bg_ccsequence1 = CCSequence:create(bg_fadeAction1)
--    self._ccbOwner.left_bg:runAction(bg_ccsequence1)
--    
--    local bg_delayTime2 = CCDelayTime:create(time)
--    local bg_fadeOut2 = CCFadeTo:create(time + 1, 0)
--    local bg_fadeAction2 = CCArray:create()
--    bg_fadeAction2:addObject(bg_delayTime2)
--    bg_fadeAction2:addObject(bg_fadeOut2)
--    local bg_ccsequence2 = CCSequence:create(bg_fadeAction2)
--    self._ccbOwner.right_bg:runAction(bg_ccsequence2)
    
end

return QUIDialogUnlockSucceed