--[[
    Class name QNotificationCenter 
    Create by julian 
    This class is a handle notification push stuff
--]]

local EventProtocol = require("framework.cc.components.behavior.EventProtocol")
local QNotificationCenter = class("QNotificationCenter", EventProtocol)

QNotificationCenter.EVENT_BULLET_TIME_TURN_ON = "NOTIFICATION_EVENT_BULLET_TIME_TURN_ON"
QNotificationCenter.EVENT_BULLET_TIME_TURN_OFF = "NOTIFICATION_EVENT_BULLET_TIME_TURN_OFF"

QNotificationCenter.EVENT_BULLET_TIME_TURN_START = "NOTIFICATION_EVENT_BULLET_TIME_TURN_START"
QNotificationCenter.EVENT_BULLET_TIME_TURN_FINISH = "NOTIFICATION_EVENT_BULLET_TIME_TURN_FINISH"

QNotificationCenter.EVENT_TRIGGER_BACK = "NOTIFICATION_EVENT_TRIGGER_BACK"
QNotificationCenter.EVENT_TRIGGER_HOME = "NOTIFICATION_EVENT_TRIGGER_HOME"

function QNotificationCenter:sharedNotificationCenter( )
    if app._notificationCenter == nil then
        app._notificationCenter = QNotificationCenter.new()
    end
    return app._notificationCenter
end

function QNotificationCenter:ctor(options)
    -- cc.GameObject.extend(self)
    -- self:addComponent("components.behavior.EventProtocol"):exportMethods()
    QNotificationCenter.super.ctor(self)
    self._handlesInfo = {}
end

function QNotificationCenter:addEventListener(eventName, listener, tag)
	local key1 = listener
	local key2 = tag
	local ttag = type(tag)
    if ttag == "table" or ttag == "userdata" then
        key1 = handler(tag, listener)
        key2 = ""
    end
	local handle = QNotificationCenter.super.addEventListener(self, eventName, key1, key2)
	if listener ~= nil and tag ~= nil then
		table.insert(self._handlesInfo, {handle = handle, listener = listener, tag = tag, eventName = eventName})
	end
end

-- key1 is listener and key2 is tag
function QNotificationCenter:removeEventListener(eventNameOrHandle, key1, key2)
	if key1 ~= nil or key2 ~= nil then
		local handle = nil
		for i, handlerInfo in ipairs(self._handlesInfo) do
			if eventNameOrHandle == handlerInfo.eventName and handlerInfo.listener == key1 and handlerInfo.tag == key2 then
				handle = handlerInfo.handle
				table.remove(self._handlesInfo, i)
				break
			end
		end
		if handle ~= nil then
			return QNotificationCenter.super.removeEventListener(self, handle)
		else
			printInfo("WARN: cannot find event handle for event name " .. eventNameOrHandle)
		end
	else
		return QNotificationCenter.super.removeEventListener(self, eventNameOrHandle, key1, key2)
	end
end

function QNotificationCenter:triggerMainPageEvent(eventName)
	if self._mainPageList == nil then return end
	local lastTarget = self._mainPageList[#self._mainPageList]
	if eventName == QNotificationCenter.EVENT_TRIGGER_BACK then
		if lastTarget ~= nil and lastTarget.onTriggerBackHandler ~= nil then
			lastTarget:onTriggerBackHandler()
		end
	elseif eventName == QNotificationCenter.EVENT_TRIGGER_HOME then
		if lastTarget ~= nil and lastTarget.onTriggerHomeHandler ~= nil then
			lastTarget:onTriggerHomeHandler()
		end
	end
end

function QNotificationCenter:addMainPageEvent(target)
	if self._mainPageList == nil then
		self._mainPageList = {}
	end
	table.insert(self._mainPageList, target)
end

function QNotificationCenter:removeMainPageEvent(target)
	if self._mainPageList == nil then return end
	for index,value in pairs(self._mainPageList) do
		if value == target then
			table.remove(self._mainPageList,index)
		end
	end
end

return QNotificationCenter