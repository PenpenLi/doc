
local QTcpSocket = class("QTcpSocket")

require("pack")
local socket = require("socket")

QTcpSocket.CHECK_CONNECTED_INTERVAL = 0.1
QTcpSocket.CHECK_RECEIVE_INTERVAL = 0.1
QTcpSocket.RECONNECT_COUNT = 3
QTcpSocket.RECONNECT_INTERVAL = 2

QTcpSocket.State_Close = "Close"
QTcpSocket.State_Connected = "Connected"
QTcpSocket.State_Connecting = "Connecting"

QTcpSocket.ReadPackageSize = 1
QTcpSocket.ReadPackageData = 2

QTcpSocket.PackageTitleSize = 2

QTcpSocket.EVENT_START_CONNECT = "QTCPSOCKET_EVENT_START_CONNECT"
QTcpSocket.EVENT_CONNECT_SUCCESS = "QTCPSOCKET_EVENT_CONNECT_SUCCESS"
QTcpSocket.EVENT_CONNECT_FAILED = "QTCPSOCKET_EVENT_CONNECT_FAILED"
QTcpSocket.EVENT_CONNECT_CLOSE = "QTCPSOCKET_EVENT_CONNECT_CLOSE"

function QTcpSocket:ctor(host, port)
	assert(host or port, "QTcpSocket:ctor host and port are necessary!")
	cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

	self._host = host
	self._port = port

	self._state = QTcpSocket.State_Close
	self._connectCount = 0

	--send
	self._resendRequests = {}
	self._sendedRequests = {}

	-- receive
	self._binary = ""
	self._binaryTitle = ""
	self._binarySize = -1
	self._readPackageState = QTcpSocket.ReadPackageSize
end

function QTcpSocket:_createTcpObject()
	if self._tcp ~= nil then
		self:_removeTcpObject()
	end

	self._tcp = socket.tcp()

	--[[
		Note: Starting with LuaSocket 2.0, the settimeout method affects the behavior of connect, 
		causing it to return with an error in case of a timeout. 
		If that happens, you can still call socket.select with the socket in the sendt table. 
		The socket will be writable when the connection is established.
	--]]
	self._tcp:settimeout(0)
end

function QTcpSocket:_removeTcpObject()
	if self._tcp == nil then
		return
	end

	self._tcp = nil
end

function QTcpSocket:getState()
	return self._state
end

function QTcpSocket:getHost()
	return self._host
end

function QTcpSocket:setHost(host)
	if host ~= nil then
		self._host = host
	end
end

function QTcpSocket:getPort()
	return self._port
end

function QTcpSocket:setPort(port)
	if port ~= nil then
		self._port = port
	end
end

function QTcpSocket:connect()
	if self._state ~= QTcpSocket.State_Close then
		return
	end

	self:_createTcpObject()
	self._state = QTcpSocket.State_Connecting

	-- delay one frame to connet server
	scheduler.performWithDelayGlobal(function()
		if self._connectCount == 0 then
			self:dispatchEvent({name = QTcpSocket.EVENT_START_CONNECT})
		end

		if self:_checkConnect() == false then
			self._connectScheduler = scheduler.scheduleGlobal(handler(self, self._onCheckConnectUpdate), QTcpSocket.CHECK_CONNECTED_INTERVAL)
		end
	end, 0)

end

function QTcpSocket:disConnect()
	if self._state == QTcpSocket.State_Connected then
		--[[
			Mode tells which way of the connection should be shut down and can take the value:
			"both": disallow further sends and receives on the object. This is the default mode;
			"send": disallow further sends on the object;
			"receive": disallow further receives on the object.
		--]]
		self._tcp:shutdown("both")
		self:_close(true)
		self:_removeTcpObject()
	elseif self._state == QTcpSocket.State_Connecting then
		if self._connectScheduler ~= nil then
			scheduler.unscheduleGlobal(self._connectScheduler)
			self._connectScheduler = nil
		end
		self:_close(true)
		self:_removeTcpObject()
	end
end

--[[
	add requets to resend list front
]]
function QTcpSocket:addRequestToResend(api, data, respond)
	if api == nil then
		if DEBUG > 0 then
			assert(false, "QTcpSocket:send invaild api")
		end
		return
	end

	if data == nil or string.len(data) == 0 then
		if DEBUG > 0 then
			assert(false, "QTcpSocket:send invaild data")
		end
		return
	end

	if DEBUG > 0 then
		printInfo("QTcpSocket:add send api:" .. tostring(string.len(api)))
		printInfo("QTcpSocket:add send package size:" .. tostring(string.len(data)))
	end

	local sendData = string.pack(">H", string.len(data)) .. data
	table.insert(self._resendRequests, 1, {api = api, sendData = sendData, respond = respond})
end

-- respond: received callback 
function QTcpSocket:send(api, data, respond)
	if api == nil then
		if DEBUG > 0 then
			assert(false, "QTcpSocket:send invaild api")
		end
		return
	end

	if data == nil or string.len(data) == 0 then
		if DEBUG > 0 then
			assert(false, "QTcpSocket:send invaild data")
		end
		return
	end

	if self._state ~= QTcpSocket.State_Connected then
		if DEBUG > 0 then
			printInfo("QTcpSocket:send current state is " .. self._state .. " can not send data!")
		end
		return
	end

	if DEBUG > 0 then
		printInfo("QTcpSocket:send send api:" .. tostring(string.len(api)))
		printInfo("QTcpSocket:send send package size:" .. tostring(string.len(data)))
	end

	local sendData = string.pack(">H", string.len(data)) .. data

	--[[
		client:send(data, i, j)
		Sends data through client object.
		Data is the string to be sent. The optional arguments i and j work exactly like the standard string.sub Lua function to allow the selection of a substring to be sent.
		If successful, the method returns the index of the last byte within [i, j] that has been sent. 
		Notice that, if i is 1 or absent, this is effectively the total number of bytes sent. 
		In case of error, the method returns nil, followed by an error message, followed by the index of the last byte within [i, j] that has been sent. You might want to try again from the byte following that. 
		The error message can be 'closed' in case the connection was closed before the transmission was completed or the string 'timeout' in case there was a timeout during the operation.
		Note: Output is not buffered. For small strings, it is always better to concatenate them in Lua (with the '..' operator) and send the result in one call instead of calling the method several times.
	--]]

	local result, errorCode = self._tcp:send(sendData)
	if errorCode ~= nil then
		table.insert(self._resendRequests, {api = api, sendData = sendData, respond = respond})
		self:_onReceiveError(errorCode)
		return false
	end

	table.insert(self._sendedRequests, {api = api, sendData = sendData, respond = respond})

	return true
end

function QTcpSocket:_checkConnect()
	if self:_doConnect() == true then
		if self._updateScheduler == nil then
			self._updateScheduler = scheduler.scheduleGlobal(handler(self, self._onUpdate), QTcpSocket.CHECK_RECEIVE_INTERVAL)
			self:dispatchEvent({name = QTcpSocket.EVENT_CONNECT_SUCCESS})
		end
		return true
	else
		return false
	end
end

function QTcpSocket:_onCheckConnectUpdate(dt)
	if self._checkConnectDuration == nil then
		self._checkConnectDuration = dt
	else
		self._checkConnectDuration = self._checkConnectDuration + dt
	end

	if self:_checkConnect() == true then
		self._checkConnectDuration = nil
		scheduler.unscheduleGlobal(self._connectScheduler)
		self._connectScheduler = nil
		self._connectCount = 0

	elseif self._checkConnectDuration > QTcpSocket.RECONNECT_INTERVAL then
		self._checkConnectDuration = nil
		scheduler.unscheduleGlobal(self._connectScheduler)
		self._connectScheduler = nil
		self:_close()

		self._connectCount = self._connectCount + 1
		if self._connectCount >= QTcpSocket.RECONNECT_COUNT then
			self._connectCount = 0
			self:dispatchEvent({name = QTcpSocket.EVENT_CONNECT_FAILED})
		else
			self:connect()
		end
	end
end

function QTcpSocket:_doConnect()
	if self._tcp == nil then
		return
	end

--[[
	In case of error, the method returns nil followed by a string describing the error. 
	In case of success, the method returns 1.
--]]
	if DEBUG > 0 then
		printInfo("QTcpSocket want to connect " .. self._host .. ":" .. tostring(self._port))
	end

	local isSuccess, errorCode = self._tcp:connect(self._host, self._port)
	if isSuccess == 1 or errorCode == "already connected" then
		if DEBUG > 0 then
			printInfo("QTcpSocket connect success with error:" .. tostring(errorCode))
		end

		self._state = QTcpSocket.State_Connected
		return true
	else
		self:_onReceiveError(errorCode)
		return false
	end
end

function QTcpSocket:_onUpdate()
	if self._state ~= QTcpSocket.State_Connected then
		return
	end

	while #self._resendRequests > 0 do
		local success = self:_resendData()
		if success == false then
			break
		end
	end

	if #self._resendRequests == 0 and #self._sendedRequests > 0 then

		while true do
			local success = false
			if self._readPackageState == QTcpSocket.ReadPackageSize then
				success = self:_readPackageSize()
			elseif self._readPackageState == QTcpSocket.ReadPackageData then
				success = self:_readPackageData(self._binarySize - string.len(self._binary))
			else
				if DEBUG > 0 then
					assert(false, "QTcpSocket:_onUpdate invalid receive state:" .. tostring(self._readPackageState))
				end
			end

			if self._binarySize == string.len(self._binary) then
				if #self._sendedRequests > 0 then
					local request = self._sendedRequests[1]
					table.remove(self._sendedRequests, 1)
					if request.respond ~= nil then
						request.respond(self._binary)
					end
				end
				self._binary = ""
				self._binaryTitle = ""
				self._binarySize = -1
			end

			if success == false then
				break
			end

			if #self._sendedRequests == 0 then
				break
			end
		end
	end

end

function QTcpSocket:_resendData()
	if self._state ~= QTcpSocket.State_Connected then
		return
	end

	if #self._resendRequests == 0 then
		return
	end

	local request = self._resendRequests[1]

	local result, errorCode = self._tcp:send(request.sendData)
	if errorCode ~= nil then
		self:_onReceiveError(errorCode)
		return false
	end

	table.insert(self._sendedRequests, request)
	table.remove(self._resendRequests, 1)
	return true
end

--[[
	client:receive(pattern, prefix)

	Pattern can be any of the following:
	'*a': reads from the socket until the connection is closed. No end-of-line translation is performed;
	'*l': reads a line of text from the socket. The line is terminated by a LF character (ASCII 10), optionally preceded by a CR character (ASCII 13). The CR and LF characters are not included in the returned line. In fact, all CR characters are ignored by the pattern. This is the default pattern;
	number: causes the method to read a specified number of bytes from the socket.

	Prefix is an optional string to be concatenated to the beginning of any received data before return.

	If successful, the method returns the received pattern. 
	In case of error, the method returns nil followed by an error message which can be the string 'closed' in case the connection was closed before the transmission was completed or the string 'timeout' in case there was a timeout during the operation. 
	Also, after the error message, the function returns the partial result of the transmission.

	Important note: 
	This function was changed severely. 
	It used to support multiple patterns (but I have never seen this feature used) and now it doesn't anymore. 
	Partial results used to be returned in the same way as successful results. 
	This last feature violated the idea that all functions should return nil on error. Thus it was changed too.
--]]

function QTcpSocket:_readPackageSize()
	if self._readPackageState ~= QTcpSocket.ReadPackageSize then
		if DEBUG > 0 then
			assert(false, "QTcpSocket:_readPackageSize last package is not receive completed")
		end
		return false
	end

	local data, errorCode, partial = self._tcp:receive(QTcpSocket.PackageTitleSize)

	local receiveData = data
	if errorCode ~= nil then
		receiveData = partial
		if DEBUG > 0 then
			assert(data == nil, "receive with error:" .. errorCode .. ", but receive data is still have value")
		end
	end

	if receiveData ~= nil and string.len(receiveData) > 0 then
		if self._binaryTitle == nil then
			self._binaryTitle = receiveData
		else
			self._binaryTitle = self._binaryTitle .. receiveData
		end

		if string.len(self._binaryTitle) == QTcpSocket.PackageTitleSize then
			local n, value = string.unpack(self._binaryTitle, ">H")
			self._binarySize = value
			self._readPackageState = QTcpSocket.ReadPackageData
			if DEBUG > 0 then
				printInfo("QTcpSocket:_readPackageSize received binary size:" .. tostring(self._binarySize))
			end
		elseif string.len(self._binaryTitle) >= QTcpSocket.PackageTitleSize then
			assert(false, "QTcpSocket:_readPackageSize title size is:" .. tostring(string.len(self._binaryTitle)) .. " large then " .. tostring(QTcpSocket.PackageTitleSize))
		end
	end

	if errorCode ~= nil then
		self:_onReceiveError(errorCode)
		return false
	end	

	return true
end

function QTcpSocket:_readPackageData(size)
	if size <= 0 then
		return false
	end

	if self._readPackageState ~= QTcpSocket.ReadPackageData then
		if DEBUG > 0 then
			assert(false, "QTcpSocket:_readPackageData package title is not receive completed")
		end
		return false
	end


	local beginTime = q.time()
	local data, errorCode, partial = self._tcp:receive(size)
	local endTime = q.time()

	if DEBUG > 0 then
		if device.platform == "ios" or device.platform == "android" then
			-- CCMessageBox("receive data time cost:" .. tostring(endTime - beginTime), "Debug Info")
		else
			printInfo("receive data time cost:" .. tostring(endTime - beginTime))
		end
	end
	

	local receiveData = data
	if errorCode ~= nil then
		receiveData = partial
		if DEBUG > 0 then
			assert(data == nil, "receive with error:" .. errorCode .. ", but receive data is still have value")
		end
	end

	if receiveData ~= nil and string.len(receiveData) > 0 then
		if self._binary == nil then
			self._binary = receiveData
		else
			self._binary = self._binary .. receiveData
		end

		if string.len(self._binary) == self._binarySize then
			self._readPackageState = QTcpSocket.ReadPackageSize
		elseif string.len(self._binary) > self._binarySize then
			assert(false, "QTcpSocket:_readPackageData data size is:" .. tostring(string.len(self._binary)) .. " large then " .. tostring(self._binarySize))
		end
	end

	if errorCode ~= nil then
		self:_onReceiveError(errorCode)
		return false
	end

	return true
end

--[[
	luaSocket error describing string in usocket.c:
	"address already in use"
    "already connected"
    "permission denied"
    "connection refused"
    "closed"
    "timeout"
--]]
function QTcpSocket:_onReceiveError(errorCode)
	if errorCode == "closed" then
		self:_close(true)
		self:connect()
	elseif errorCode == "timeout" then
		if DEBUG > 0 then
			printInfo("QTcpSocket:_onReceiveError with error:" .. errorCode)
		end
	else
		if DEBUG > 0 then
			printInfo("QTcpSocket:_onReceiveError with error:" .. errorCode)
		end
	end
end

function QTcpSocket:_close(isManually)
	if self._updateScheduler ~= nil then
		scheduler.unscheduleGlobal(self._updateScheduler)
		self._updateScheduler = nil
	end

	if self._tcp ~= nil then
		self._tcp:close()
		self._state = QTcpSocket.State_Close
		if isManually == true then
			self:dispatchEvent({name = QTcpSocket.EVENT_CONNECT_CLOSE})
		end
	end
end

return QTcpSocket