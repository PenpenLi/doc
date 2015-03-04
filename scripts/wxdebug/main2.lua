package.path = package.path .. ";D:/wow-client/Client/scripts/wxdebug/?.lua;"

require("launch")

wx.wxGetApp():MainLoop()