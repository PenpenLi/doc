--
-- Author: wkwang
-- Date: 2014-09-01 17:49:54
-- 自定义标志位管理类
--

local QFlag = class("QFlag")

QFlag.EVENT_UPDATE = "EVENT_UPDATE" --更新标志位

QFlag.FLAG_TEAM_LOCK = "FLAG_TEAM_LOCK" --战队解锁标志位
QFlag.FLAG_TUTORIAL_STAGE = "FLAG_TUTORIAL_STAGE" --设置新手引导步骤
QFlag.FLAG_TUTORIAL_LOCK = "FLAG_TUTORIAL_LOCK" --设置新手是否开启
QFlag.FLAG_FRIST_GOLD_CHEST = "FLAG_FRIST_GOLD_CHEST" --第一次开黄金宝箱
QFlag.FLAG_FRIST_SILVER_CHEST = "FLAG_FRIST_SILVER_CHEST" --第一次开瑟银宝箱
QFlag.FLAG_UNLOCK_TUTORIAL = "FLAG_UNLOCK_TUTORIAL" --设置功能解锁引导

function QFlag:ctor(options)
	self.data = {}
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
end

function QFlag:set(key, value, callBack)
	app:getClient():putFlag(tostring(key), tostring(value), function()
			self:saveData(key,value)
			if callBack ~= nil then
				callBack(value)
			end
		end)
end

function QFlag:get(tbl, callBack)
	local value = nil
	local resultTbl = {}
	local reqTbl = {}

	--过滤已经拉取的信息
	for _,key in pairs(tbl) do
		if self.data[key] == nil then
			if value == nil then
				value = key
			else
				value = value..";"..key
			end
			table.insert(reqTbl, key)
		else
			resultTbl[key] = self.data[key]
		end
	end

	--如果没有需要拉取的信息则直接返回
	if value == nil then
		callBack(resultTbl)
		return 
	end

	--拉取需要的信息再组合
	app:getClient():getFlag(tostring(value), function(data)
			if data.payloads == nil then
				data.payloads = {}
			end
			for _,key in pairs(reqTbl) do
				local value = ""
				for _,payload in pairs(data.payloads) do
					if payload.key == key then
						value = payload.value
					end
				end
				self:saveData(key,value)
				resultTbl[key] = self.data[key]
			end
			callBack(resultTbl)
		end)
end

function QFlag:saveData(key, value)
	self.data[key] = value
	self:dispatchEvent({name = QFlag.EVENT_UPDATE})
end

return QFlag