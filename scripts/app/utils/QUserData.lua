local QUserData = class("QUserData")

QUserData.NPC_TIP_SHOWN = "NPC_TIP_SHOWN"
QUserData.DEVICE_ID = "DEVICE_ID"
QUserData.USER_NAME = "USER_NAME"
QUserData.PASSWORD = "PASSWORD"
QUserData.AUTO_LOGIN = "AUTO_LOGIN"
QUserData.STRING_TRUE = "true"
QUserData.STRING_FALSE = "false"
QUserData.TEAM = "TEAM"
QUserData.MUSIC_STATE = "MUSIC_STATE"
QUserData.SOUNDEFFECT_STATE = "SOUNDEFFECT_STATE"
QUserData.SYSTEM_SETTING = "SYSTEM_SETTING"
QUserData.DEFAULT_SERVERID = "DEFAULT_SERVERID"

function QUserData:ctor()
    self._userDefault = QUserDefault:sharedUserDefault()
end

function QUserData:setUserName(userName)
    self._userDefault:setUserName(userName)
end

-- if value not found, return nil
function QUserData:getValueForKey(key)
    return self._userDefault:getStringForKey(key)
end

function QUserData:setValueForKey(key, value)
    self._userDefault:setStringForKey(key, value)
end

function QUserData:getUserValueForKey(key)
    return self._userDefault:getUserStringForKey(key)
end

function QUserData:setUserValueForKey(key, value)
    self._userDefault:setUserStringForKey(key, value)
end

function QUserData:getId()
    local id = self._userDefault:getStringForKey(QUserData.DEVICE_ID)
    if(id == nil or string.len(id) == 0) then
        id = UUID()
        self._userDefault:setStringForKey(QUserData.DEVICE_ID, id)
    end

    return id
end

-- 检查名字为"displayID"的NPC的新手提示是否已经被显示过了
function QUserData:isNpcTipShown(displayID)
    displayID = string.trim(displayID)

    local data = self._userDefault:getUserStringForKey(QUserData.NPC_TIP_SHOWN)
    local displayIDs = string.split(data, ",")

    for i, v in ipairs(displayIDs) do
        if v == displayID then 
            return true 
        end
    end

    return false
end

-- 设置名字为"displayID"的NPC的新手提示已经显示过了
function QUserData:setNpcTipShown(displayID)
    displayID = string.trim(displayID)
    
    local data = self._userDefault:getUserStringForKey(QUserData.NPC_TIP_SHOWN)
    local displayIDs = string.split(data, ",")
    for i, v in ipairs(displayIDs) do
        if v == displayID then 
            return 
        end
    end

    self._userDefault:setUserStringForKey(QUserData.NPC_TIP_SHOWN, data .. "," .. displayID)
end

-- 设置战队
function QUserData:setTeam(key, team)
    self._userDefault:setUserStringForKey(key, table.join(team, ";"))
end

function QUserData:getTeam(key)
    local str = self._userDefault:getUserStringForKey(key)
    if str == nil then
        return {}
    end
    local arr = string.split(str, ";")
    local tbl = {}
    for _,actorId in pairs(arr) do
        tbl[#tbl+1] = tonumber(actorId)
    end
   return tbl
end

-- 设置系统设定
function QUserData:setSystemSetting(setting)
    self._userDefault:setUserStringForKey(QUserData.SYSTEM_SETTING, table.join(setting, ";"))
end

function QUserData:getSystemSetting()
    local str = self._userDefault:getUserStringForKey(QUserData.SYSTEM_SETTING)
    if str == nil then
        return {}
    end
   return string.split(str, ";")
end

-- 设置是否刚刚通关过
function QUserData:setDungeonIsPass(isPass)
    self._userDefault:setUserStringForKey(QUserData.NPC_TIP_SHOWN, isPass)
end

--获取是否刚刚通关过
function QUserData:getDungeonIsPass()
    return (self._userDefault:getUserStringForKey(QUserData.NPC_TIP_SHOWN) or "")
end

return QUserData