
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetTutorialDialogue = class("QUIWidgetTutorialDialogue", QUIWidget)

local leftPositionX = display.cx - 200
local leftPositionY = 100

local rightPositionX = display.cx + 200
local rightPositionY = 100

function QUIWidgetTutorialDialogue:ctor(options)
  local ccbFile = "ccb/Widget_NewPlayer.ccbi"
  if options.isLeftSide == false then
    ccbFile = "ccb/Widget_NewPlayer2.ccbi"
  end
  local callbacks = {}
  QUIWidgetTutorialDialogue.super.ctor(self, ccbFile, callbacks, options)


  self._maxWidth = self._ccbOwner.label_text:getContentSize().width -- dialog max width( 如果会溢出则换行显示，如果换行仍会移除，则换屏显示)
  self._height = 29
  self.fullWidth = 29
  self.width = 18

  self.oldBgContentSize = self._ccbOwner.sprite_back:getContentSize()

  if options.isLeftSide == true then
    self:setPosition(leftPositionX,leftPositionY)
  else
    self:setPosition(rightPositionX,rightPositionY)
  end
  self._isSay = options.isSay ~= nil and true or false
  self:addWord(options.text, options.sayFun)
end

function QUIWidgetTutorialDialogue:onEnter()

end

function QUIWidgetTutorialDialogue:onExit()
  self:stopSay()
end

function QUIWidgetTutorialDialogue:addWord(word,callFun)
  self._word = q.autoWrap(word, self.fullWidth, self.width, self._maxWidth)
  self._sayFun = callFun
  self._isSaying = false

  self._ccbOwner.sprite_back:setPreferredSize(CCSize(self.oldBgContentSize.width, self.oldBgContentSize.height))
  self.wordLen = q.wordLen(word, self.fullWidth, self.width)
  if self.wordLen < self._maxWidth then
    self:setBgContentSize()
  end

  if self._word ~= nil and self._isSay == false then
    self._ccbOwner.label_text:setString(self._word)
  else
    self:say()
  end
  if self._sayFun ~= nil then
    self._sayFun()
  end
end

function QUIWidgetTutorialDialogue:say()
  if self._isSaying == true or self._isSay == false then return end
  self._isSaying = true
  self._sayWord = ""
  self._sayPosition = 1
  self._startPosition = 1
  self._lineNum = 1
  self:sayWord()
end

function QUIWidgetTutorialDialogue:sayWord()
  local delayTime = TUTORIAL_ONEWORD_TIME
  if self._isSaying == true then
    local c = string.sub(self._word,self._sayPosition,self._sayPosition)
    local b = string.byte(c)
    local str = c
    if b > 128 then
      str = string.sub(self._word,self._sayPosition,self._sayPosition + 2)
      self._sayPosition = self._sayPosition + 2
      self._sayWord =  self._sayWord .. str
    else
      self._sayWord =  self._sayWord .. c
    end
    if str == "\n" then
      if self._lineNum >= 2 and #self._word > self._sayPosition then
        self._startPosition = self._sayPosition + 1
        self._sayWord = ""
        self._lineNum = 1
        delayTime = 0.1
      else
        self._lineNum = self._lineNum + 1
      end
    else
      self._ccbOwner.label_text:setString(self._sayWord)
    end
    self._sayPosition = self._sayPosition + 1
  end
  if self._sayPosition <= #self._word then
    self._time = scheduler.performWithDelayGlobal(function()
      if self.sayWord then -- self is a CCObject not retained in lua space, it might just had had been released and disposed here
        self:sayWord()
      end
    end,delayTime)
  else
    self._isSaying = false
    if self._sayFun ~= nil then
      self._sayFun()
      self:stopSay()
    end
  end
end

-- 移动到指定位置
function QUIWidgetTutorialDialogue:_nodeRunAction(posY)
  self._isMove = true
  local actionArrayIn = CCArray:create()
  actionArrayIn:addObject(CCMoveBy:create(0.2, ccp(0,posY)))
  actionArrayIn:addObject(CCCallFunc:create(function ()
    self._isMove = false
    self._actionHandler = nil
  end))
  local ccsequence = CCSequence:create(actionArrayIn)
  self._actionHandler = self._ccbOwner.label_text:runAction(ccsequence)
end

function QUIWidgetTutorialDialogue:stopSay()
  self._sayFun = nil
  self._isSaying = false
  if self._time ~= nil then
    scheduler.unscheduleGlobal(self._time)
  end
  if self._actionHandler ~= nil then
    self._ccbOwner.label_text:stopAction(self._actionHandler)
    self._actionHandler = nil
  end
end

--将所有文字一次性打印出来
function QUIWidgetTutorialDialogue:printAllWord(word)
  if self._isSaying ~= false then
    self:stopSay()
  end
  self._ccbOwner.label_text:setString(q.autoWrap(word, self.fullWidth, self.width, self._maxWidth))
end

--对话背景框随着对话的长度变化
function QUIWidgetTutorialDialogue:setBgContentSize()
  local change = self.oldBgContentSize.width - (self._maxWidth - self.wordLen)
  if change < 300 then
    change = 300
  end
  self._ccbOwner.sprite_back:setPreferredSize(CCSize(change, self.oldBgContentSize.height))
end


function QUIWidgetTutorialDialogue:setActorImage(imageFile)
  if imageFile == nil then
    return
  end

  self._ccbOwner.sprite_icon:setTexture(CCTextureCache:sharedTextureCache():addImage(imageFile))
end

return QUIWidgetTutorialDialogue
