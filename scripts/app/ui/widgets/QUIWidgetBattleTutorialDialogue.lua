
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetBattleTutorialDialogue = class("QUIWidgetBattleTutorialDialogue", QUIWidget)

local leftPositionX = display.cx
local leftPositionY = 86

local rightPositionX = display.cx
local rightPositionY = 85

function QUIWidgetBattleTutorialDialogue:ctor(options)
	local ccbFile = "ccb/Widget_NewPlayer_1.ccbi"
    if options.isLeftSide == false then
        ccbFile = "ccb/Widget_NewPlayer2_1.ccbi"
    end
	local callbacks = {}
	QUIWidgetBattleTutorialDialogue.super.ctor(self, ccbFile, callbacks, options)

    self._maxWidth = 312 * 2  -- dialog max width( 如果会溢出则换行显示，如果换行仍会移除，则换屏显示)
    self._height = 32

    if options.isLeftSide == true then
        self:setPosition(leftPositionX,leftPositionY)
    else
        self:setPosition(rightPositionX,rightPositionY)
    end
    self._isSay = options.isSay ~= nil and true or false
    self:addWord(options.text, options.sayFun, options.name)
end

function QUIWidgetBattleTutorialDialogue:onEnter()

end

function QUIWidgetBattleTutorialDialogue:onExit()
    self:stopSay()
end

function QUIWidgetBattleTutorialDialogue:addWord(word,callFun,name)
    self._word = q.autoWrap(word,26,13,self._maxWidth)
    self._sayFun = callFun
    self._isSaying = false
    if self._word ~= nil and self._isSay == false then
      self._ccbOwner.label_text:setString(self._word)
    else
        self:say()
    end
    if self._sayFun ~= nil then
      self._sayFun()
    end
    if name then
        self._name = name
        self._ccbOwner.label_name:setString(self._name)
    end
end

function QUIWidgetBattleTutorialDialogue:say()
    if self._isSaying == true or self._isSay == false then return end
    self._isSaying = true
    self._sayWord = ""
    self._sayPosition = 1
    self._startPosition = 1
    self._lineNum = 1
    self:sayWord()
end

function QUIWidgetBattleTutorialDialogue:sayWord()
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
function QUIWidgetBattleTutorialDialogue:_nodeRunAction(posY)
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

function QUIWidgetBattleTutorialDialogue:stopSay()
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

function QUIWidgetBattleTutorialDialogue:setActorImage(imageFile)
    if imageFile == nil then
        return
    end

    self._ccbOwner.sprite_icon:setTexture(CCTextureCache:sharedTextureCache():addImage(imageFile))
end

function QUIWidgetBattleTutorialDialogue:setName(name)
    if name then 
        self._ccbOwner.label_name:setString(name)
    end
end

return QUIWidgetBattleTutorialDialogue