--
-- Author: Your Name
-- Date: 2014-10-21 18:30:20
--
local QUIDialog = import("..Dialogs.QUIDialog")
local QUIDialogFloatTip = class("QUIDialogFloatTip", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogFloatTip:ctor(options)
  local ccbFile = "ccb/Dialog_Float_Tips.ccbi"
  local callbacks = {}
  QUIDialogFloatTip.super.ctor(self, ccbFile, callbacks, options)

  if options.words ~= nil then 
    self.tipWord = options.words
  end
  
  self:_init()
  self:tipAction()

end

--[[
  这里自定义了之后不会调用父级的蒙板效果
]]
function QUIDialogFloatTip:viewDidAppear()

end

--初始化浮动框
function QUIDialogFloatTip:_init()
  self._ccbOwner.words1:setString(self.tipWord)
  
  self.size = self._ccbOwner.words1:getContentSize()
  self.tipSize = self._ccbOwner.float_tips:getContentSize()

  self._ccbOwner.float_tips:setScaleX((self.size.width + 25)/self.tipSize.width)
end
--浮动提示延迟一秒后淡出
function QUIDialogFloatTip:tipAction()
  local time = 1.0
  
  makeNodeCascadeOpacityEnabled(self._ccbOwner.parent_node, true)
  
  local delayTime = CCDelayTime:create(time)
  local fadeOut = CCFadeOut:create(time)
  local func = CCCallFunc:create(function() 
    if self:getView() ~= nil then
      app:getNavigationThirdLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    end
  end)
  local fadeAction = CCArray:create()
  fadeAction:addObject(delayTime)
  fadeAction:addObject(fadeOut)
  fadeAction:addObject(func)
  local bg_ccsequence = CCSequence:create(fadeAction)
  
  self._ccbOwner.parent_node:runAction(bg_ccsequence)
end

return QUIDialogFloatTip
