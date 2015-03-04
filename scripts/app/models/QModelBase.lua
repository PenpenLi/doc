

local QModelBase = class("QModelBase", cc.mvc.ModelBase)

QModelBase.schema = clone(cc.mvc.ModelBase.schema)

function QModelBase:ctor(properties)
    QModelBase.super.ctor(self, properties)
    self._cache = {}
end

function QModelBase:get(propName)
    local values = self:getProperties({propName})
    if values[propName] == nil then
        printError(propName .. " does not exists!")
        return nil
    end

    return values[propName]
end

function QModelBase:set(propName, propValue)
    local properties = {}
    properties[propName] = propValue

    assert(type(properties) == "table", "Invalid properties")
        -- string.format("%s [%s:setProperties()] Invalid properties", tostring(self), self.class.__cname))

    for field, schema in pairs(self.class.schema) do
        if propName == field then
            local typ, def = unpack(schema)
            local propname = field .. "_"

            local val = properties[field] or def
            if val ~= nil then
                if typ == "number" then val = tonumber(val) end
                assert(type(val) == typ,
                       string.format("%s [%s:setProperties()] Type mismatch, %s expected %s, actual is %s",
                                     tostring(self), self.class.__cname, field, typ, type(val)))
                self[propname] = val
            end
        end
    end

    return self
end

-- static utility function
function QModelBase.itemById(list, id)
    for k, item in pairs(list) do
        if item ~= nil and item:getId() == id then
            return item
        end
    end
    return nil
end

return QModelBase