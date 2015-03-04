local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetDailySignIn = class("QUIWidgetDailySignIn", QUIWidget)

local QUIWidgetDailySignInBox = import("..widgets.QUIWidgetDailySignInBox") 
local QStaticDatabase = import("...controllers.QStaticDatabase")

QUIWidgetDailySignIn.IS_DONE = "IS_DONE"
QUIWidgetDailySignIn.IS_READY = "IS_READY"
QUIWidgetDailySignIn.IS_WAITING = "IS_WAITING"

function QUIWidgetDailySignIn:ctor(options)
  local ccbFile = "ccb/Widget_DailySignIn.ccbi"
  local callBacks = {}
  QUIWidgetDailySignIn.super.ctor(self, ccbFile, callBacks, options)
  
  self._time = options.time
  self._signNum = options.signNum
  self._visibleHeight = options.visibleHeight
  self._index = 1
  
  self:initItme()
  self:signCompleted()
end

function QUIWidgetDailySignIn:onEnter()
end

function QUIWidgetDailySignIn:onExit()
--    if #self.itmeBox < 31 then
--      
--    end 
    -- for _,value in pairs(self.itmeBox) do
    --     app.widgetCache:setWidgetForName(value, value:getName())
    -- end
    self.itmeBox = {}
end

function QUIWidgetDailySignIn:initItme()
  local reward = QStaticDatabase.sharedDatabase():getDailySignInItmeByMonth(self._time)
  
  self.itmeBox = {}
  local i = 1
  local height = 0
  while reward["type_"..i] ~= nil do
      self.itmeBox[i] = QUIWidgetDailySignInBox.new()
      self._ccbOwner["node"..i]:addChild(self.itmeBox[i])
      if i <= self._signNum then
        self.itmeBox[i]:setState(QUIWidgetDailySignIn.IS_DONE)
      elseif i == self._signNum + 1 then
        if remote.daily:checkTodaySignIn() then
          self.itmeBox[i]:setState(QUIWidgetDailySignIn.IS_WAITING)
        else  
          self.itmeBox[i]:setState(QUIWidgetDailySignIn.IS_READY)
        end
      elseif i > self._signNum + 1 then
        self.itmeBox[i]:setState(QUIWidgetDailySignIn.IS_WAITING)
      end
      self.itmeBox[i]:setItmeBoxInfo(reward["type_"..i], reward["id_"..i], reward["num_"..i], i)

      local bgSize = self.itmeBox[1]:getBoxSize()
      if ((i-1)/5 + 1)*bgSize.height > (self._visibleHeight + bgSize.height) then
        self._index = i
        break
      end
      i = i + 1
  end
  
  local bgSize = self.itmeBox[1]:getBoxSize()
  if #self.itmeBox > 30 then
    self._ccbOwner.floor:setContentSize(CCSize(self:getBgSize().width, (bgSize.height + 13) * 7))
  else
    self._ccbOwner.floor:setContentSize(CCSize(self:getBgSize().width, (bgSize.height + 13) * 6))
  end
end

function QUIWidgetDailySignIn:updateVisibleRange(posY)
  local bgSize = self.itmeBox[1]:getBoxSize()
  if ((self._index-1)/5 + 1)*bgSize.height - posY < (self._visibleHeight + bgSize.height) then
    local reward = QStaticDatabase.sharedDatabase():getDailySignInItmeByMonth(self._time)
    
    local i = self._index + 1
    while reward["type_"..i] ~= nil do
        self.itmeBox[i] = QUIWidgetDailySignInBox.new()
        self._ccbOwner["node"..i]:addChild(self.itmeBox[i])
        if i <= self._signNum then
          self.itmeBox[i]:setState(QUIWidgetDailySignIn.IS_DONE)
        elseif i == self._signNum + 1 then
          if remote.daily:checkTodaySignIn() then
            self.itmeBox[i]:setState(QUIWidgetDailySignIn.IS_WAITING)
          else  
            self.itmeBox[i]:setState(QUIWidgetDailySignIn.IS_READY)
          end
        elseif i > self._signNum + 1 then
          self.itmeBox[i]:setState(QUIWidgetDailySignIn.IS_WAITING)
        end
        self.itmeBox[i]:setItmeBoxInfo(reward["type_"..i], reward["id_"..i], reward["num_"..i], i)

        local bgSize = self.itmeBox[1]:getBoxSize()
        if ((i-1)/5 + 1)*bgSize.height - posY > (self._visibleHeight + bgSize.height) then
          self._index = i
          break
        end
        i = i + 1
    end

    if reward["type_"..i] == nil then
      self._index = i - 1
    end
    local bgSize = self.itmeBox[1]:getBoxSize()
    if #self.itmeBox > 30 then
      self._ccbOwner.floor:setContentSize(CCSize(self:getBgSize().width, (bgSize.height + 13) * 7))
    else
      self._ccbOwner.floor:setContentSize(CCSize(self:getBgSize().width, (bgSize.height + 13) * 6))
    end
  end
end

--获取可签到位置
function QUIWidgetDailySignIn:getSignPosition()
  for k , value in pairs(self.itmeBox) do
    if value._state == QUIWidgetDailySignIn.IS_READY then
        local index = math.floor((k - 1)/5)
        return index, #self.itmeBox
    end
  end
  return nil, nil  
end

--初始化已签到的格子
function QUIWidgetDailySignIn:signCompleted()
--  if self._signNum == 0 then
--    
--  else
--    for i = 1, self._signNum, 1 do 
--      self.itmeBox[i]:setSignIsDone()
--    end
--  end
end

function QUIWidgetDailySignIn:getBgSize()
  return self._ccbOwner.floor:getContentSize()
end

return QUIWidgetDailySignIn