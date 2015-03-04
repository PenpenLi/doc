--
-- Author: Qinyuanji
-- Date: 2015-01-15 
-- 

local QBaseRank = import(".QBaseRank")
local QArenaRank = class("QArenaRank", QBaseRank)

function QArenaRank:ctor(options)
	QArenaRank.super.ctor(self, options)
end

function QArenaRank:update(success, fail)
	app:getClient():arenaTop50RankRequest(function (data)
		if data.arenaResponse == nil or data.arenaResponse.top50 == nil then 
			self.super:update(fail)
			return 
		end

		self._list = nil
		self._list = clone(data.arenaResponse.top50)
		if self._list ~= nil then
			table.sort(self._list, function (x, y)
				return x.rank < y.rank
			end)

			self.super:update(success)
		end
	end, fail)
end




return QArenaRank
