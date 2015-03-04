local QDailySignIn = class("QDailySignIn")

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QDailySignIn:ctor()
  self._checkIn = nil
  self._checkInAt = nil
  self._addUpDailySignNum = nil
  self._addUpDailySignAward = nil
end

function QDailySignIn:updateComplete(checkin, checkinAt)
  self._checkIn = checkin
  self._checkInAt = checkinAt
end

--更新累积签到次数
function QDailySignIn:updateAddUpSignInNum(addUpDailySignNum, addUpDailySignAward)
  if addUpDailySignNum ~= nil then
    self._addUpDailySignNum = addUpDailySignNum
  end
  if addUpDailySignAward ~= nil then
    self._addUpDailySignAward = addUpDailySignAward
  end
end

function QDailySignIn:getDailySignIn()
  return self._checkIn, self._checkInAt
end

function QDailySignIn:getAddUpSignIn()
  return self._addUpDailySignNum, self._addUpDailySignAward
end

--检查是否签到
function QDailySignIn:checkTodaySignIn()
  if self._checkInAt == nil or self._checkInAt == 0 then
    return false
  end
  local refreshTime = q.refreshTime(global.freshTime.sginin_freshTime)
  if self._checkInAt/1000 >= refreshTime then
    return true
  end
  return false
end

--检查是否可以领取签到奖励
function QDailySignIn:checkAddUpAward()
  if self._addUpDailySignNum ~= nil and self._addUpDailySignAward ~= nil then
    self.award, self.nowNum, self.maxNum = QStaticDatabase:sharedDatabase():getAddUpSignInItmeByMonth(self._addUpDailySignNum, self._addUpDailySignAward)
    if self.nowNum == self.maxNum then
      return true
    end
  end
end

--重置签到次数
function QDailySignIn:checkSignTime()
  local currTime = os.date("*t", q.serverTime() - 4 * 3600)
  local signInTime = os.date("*t", self._checkInAt/1000)
  if currTime["month"] ~= signInTime["month"] then
    self._checkIn = 0
  end
  
end

return QDailySignIn