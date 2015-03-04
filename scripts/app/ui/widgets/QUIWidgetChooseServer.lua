--
-- Author: Your Name
-- Date: 2014-05-08 16:07:32
--

local QUIWidget = import(".QUIWidget")
local QUIWidgetChooseServer = class("QUIWidgetChooseServer", QUIWidget)

local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QNavigationController = import("...controllers.QNavigationController")

QUIWidgetChooseServer.EVENT_SELECT = "EVENT_SELECT"

function QUIWidgetChooseServer:ctor(options)
	local ccbFile = "ccb/Widget_ChooseServer.ccbi"
	local callBacks = {
	
	}
	QUIWidgetChooseServer.super.ctor(self,ccbFile,callBacks,options)
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

	self._point = options.point
	self._server = options.server
	self._number = options.number
	self._w = 520
	self._h = 40

	self._layer = CCLayerColor:create(ccc4(20, 0, 0, 120), self._w, self._h)--size.width, size.height

	self._layer:setPositionX(-self._w/2 + 20)
	self._layer:setPositionY(-self._h/2)
	self._layer:setVisible(false)


	self._ccbOwner.node_root:addChild(self._layer)

	self:mytouch(self._ccbOwner.node_root)

	
end

function QUIWidgetChooseServer:mytouch(node)
	node:setTouchEnabled(true)
    node:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    node:setTouchSwallowEnabled(false)
    node:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, QUIWidgetChooseServer.onTouch))
    node:setCascadeBoundingBox(CCRect(self._point.x - self._w/2, self._point.y - self._h/2, self._w, self._h))
end

function QUIWidgetChooseServer:setInfo(tbl)
	self._ccbOwner.label_name:setString(tbl.name)
	-- self._ccbOwner.label_region:setString(tbl.serverId.."区")
	local count = tbl.count or 0
	if count < 100 then
		self._ccbOwner.label_fluent:setVisible(true)
		self._ccbOwner.label_full:setVisible(false)
	else
		self._ccbOwner.label_fluent:setVisible(false)
		self._ccbOwner.label_full:setVisible(true)
	end
	local time = tbl.startTime 
	if time ~= nil and time < 24*60*60 then
		self._ccbOwner.label_new:setVisible(true)
		self._ccbOwner.label_fullnew:setVisible(false)
	else
		self._ccbOwner.label_new:setVisible(false)
		self._ccbOwner.label_fullnew:setVisible(true)
	end
end

function QUIWidgetChooseServer:onTouch(event)
	if event.name == "began" then
		printInfo("%d, %d", self._point.x, self._point.y)
    	self._layer:setVisible(true)
    	return true
    elseif event.name == "moved" then
    	
    elseif event.name == "ended" or event.name == "cancelled" then
    	
    	self._layer:setVisible(false)
    	app:getNavigationController():getTopPage():showControls(true)
    	app:getNavigationController():getTopPage():setInfo({areaname = self._server.name, area = self._number})
    	app:getNavigationController():getTopPage():setServer(self._server)
      	--app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
      	self:dispatchEvent({name = QUIWidgetChooseServer.EVENT_SELECT})
    end
end

return QUIWidgetChooseServer