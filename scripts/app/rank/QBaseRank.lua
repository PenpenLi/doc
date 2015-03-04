--
-- Author: Qinyuanji
-- Date: 2015-01-15 
-- This class is the base dialog for Rank detailed list

local QBaseRank = class("QBaseRank")

QBaseRank.REFRESH_HOUR = 9

function QBaseRank:ctor(options)
	self._lastRefreshHour = tonumber(os.date("%H"))
end

function QBaseRank:needsUpdate( ... )
	if self._list == nil then
		return true
	end

	-- roughly :)
	if tonumber(os.date("%H")) >= self:getRefreshHour() and self._lastRefreshHour < self:getRefreshHour() then
		return true
	end
end

function QBaseRank:update(success)
	if success ~= nil then
		self._lastRefreshHour = tonumber(os.date("%H"))
		success()
	end
end

function QBaseRank:getList( ... )
	return self._list
end

function QBaseRank:getMyInfo( ... )
	return self._myInfo
end

function QBaseRank:getRefreshHour( ... )
	return QBaseRank.REFRESH_HOUR
end

return QBaseRank
