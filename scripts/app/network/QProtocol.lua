
local QProtocol = class("QProtocol")

local protobuf = require("protobuf")

QProtocol.pb = {
	"protocol.pb"
}

function QProtocol:ctor(options)
	self._protobuf = protobuf
	self:_registerProtocol()
end

function QProtocol:_registerProtocol()
	local sharedFileUtils = CCFileUtils:sharedFileUtils()
	for _, pbFile in ipairs(QProtocol.pb) do
		local fullPath = sharedFileUtils:fullPathForFilename(pbFile)
		if sharedFileUtils:isFileExist(fullPath) == true then
			local buffer = QUtility:decryptFile(fullPath)
			if buffer == nil then
				assert(false, "decryptFile " .. fullPath .. " faild!")
			else
				self._protobuf.register(buffer)
			end
		else
			assert(false, pbFile .. " is not exist")
		end
	end
end

function QProtocol:encodeMessageToBuffer(messageName, message)
	if messageName == nil or string.len(messageName) == 0 or message == nil then
		return nil
	end

	return self._protobuf.encode(messageName, message)
end

function QProtocol:decodeBufferToMessage(messageName, buffer)
	if messageName == nil or string.len(messageName) == 0 or buffer == nil then
		return nil
	end

	local message = self._protobuf.decode(messageName, buffer)
	self:_expandMessage(message)
	local result = self:_removeMetatable(message)
	return result
end

function QProtocol:_expandMessage(message)
	if message == nil or type(message) ~= "table" then
		return
	end

	for _, value in pairs(message) do
		if value ~= nil and type(value) == "table" then
			local object = getmetatable(value)
			if object ~= nil and object.__pairs ~= nil then
				object.__pairs(value)
			end
			self:_expandMessage(value)
		end
	end
end

function QProtocol:_removeMetatable(message)
	if message == nil or type(message) ~= "table" then
		return
	end

	local newMessage = {}
	for k, v in pairs(message) do
		if type(v) == "table" then
			newMessage[k] = self:_removeMetatable(v)
		else
			newMessage[k] = v
		end
	end

	return newMessage
end


return QProtocol