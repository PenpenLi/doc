local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogDailySignInRewardExplain = class("QUIDialogDailySignInRewardExplain", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogDailySignInRewardExplain:ctor(options)
  local ccbFile = "ccb/Widget_DailySignIn_ItemPrompt3.ccbi"
  local callBacks = {}
  QUIDialogDailySignInRewardExplain.super.ctor(self, ccbFile, callBacks, options)
  self.isAnimation = true
    
  self.oldDecSize = self._ccbOwner.content:getContentSize()
  self.oldPosition = ccp(self._ccbOwner.content:getPosition())
  self.word = "每日签到，将会获得当天特有的奖励。"
  self._ccbOwner.content:setString(q.autoWrap(self.word or "", 21, 40/3, self.oldDecSize.width))
  self._ccbOwner.content:setPosition(self.oldPosition.x, self.oldPosition.y)
  
end

function QUIDialogDailySignInRewardExplain:viewDidAppear()
    self._backTouchLayer = CCLayerColor:create(ccc4(0, 0, 0, 0), display.width, display.height)
    self._backTouchLayer:setPosition(-display.width/2, -display.height/2)
    self._backTouchLayer:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self._backTouchLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIDialogDailySignInRewardExplain._onTouchEnable))
    self._backTouchLayer:setTouchEnabled(true)
    self:getView():addChild(self._backTouchLayer,-1)
end

function QUIDialogDailySignInRewardExplain:viewAnimationOutHandler()
    self:removeSelfFromParent()
end

function QUIDialogDailySignInRewardExplain:_onTouchEnable(event)
  if event.name == "began" then
    return true
    elseif event.name == "moved" then
        
    elseif event.name == "ended" then
        scheduler.performWithDelayGlobal(function()
            self:_onTriggerClose()
            end,0)
    elseif event.name == "cancelled" then
        
  end
end

function QUIDialogDailySignInRewardExplain:_onTriggerClose()
    self:playEffectOut()
end

function QUIDialogDailySignInRewardExplain:removeSelfFromParent()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

return QUIDialogDailySignInRewardExplain