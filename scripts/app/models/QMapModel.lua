--
-- Author: Your Name
-- Date: 2014-05-08 10:45:30
--

local QModelBase = import(".QModelBase")
local QMapModel = class("QMapModel", QModelBase)

local QStaticDatabase = import("..controllers.QStaticDatabase")

--定义属性
QBuff.schema = clone(cc.mvc.ModelBase.schema)

QBuff.schema["name"]           = {"string"} -- 字符串类型，没有默认值

function QMapModel:ctor(option)

end

return QMapModel